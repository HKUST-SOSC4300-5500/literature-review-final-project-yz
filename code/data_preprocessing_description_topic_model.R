library(stringr)
library(quanteda)
library(data.table)
library(stm)
library(geometry)
library(Rtsne)
library(rsvd)
library(igraph)
library(stmCorrViz)
library(pheatmap)
library(doParallel)
library(foreach)

#Load data and merge it with features
party <- read.csv("C:/Users/yeyzh/Desktop/media_info.csv", quote="\"", encoding = "UTF-8")
newsdata <- fread("C:/Users/yeyzh/Desktop/SOSC 5500/data_final.csv", quote="\"", encoding = "UTF-8")
newsdata <- as.data.frame(newsdata)
df = df[-(df['paper'].isin(c["计算机世界","中国计算机报","计算机世界","电脑商报","体育周报"]))]
newsdata <- merge(newsdata, party, by = "media")
newsdata <- newsdata[order(newsdata$V1),]

#Delete info which would not be used in this study.
party <- NULL
newsdata$links <- NULL
newsdata$paper <- NULL
newsdata$content <- NULL
newsdata$content_len <- NULL
newsdata$title <- NULL
newsdata$useful <- NULL
newsdata$words_seg <- NULL
newsdata$sentiment_key <- NULL
newsdata$nationwide.x <- NULL
newsdata$reference.x <- NULL
newsdata$song.x <- NULL
newsdata$`party newspaper`<-NULL
newsdata$song.y <- NULL
newsdata$reference.y <- NULL
newsdata$province.y <- NULL
newsdata$city.y <- NULL
newsdata$nationwide.y <- NULL

#Generate dfm
content <- str_replace_all(newsdata$`0`, "[[:punct:]]", "")
content <- tokens(content,what="fastestword")
content <- tokens_keep(content, min_nchar = 2)
newsdata$dfm <- dfm(content, what = 'fastestword', verbose = TRUE)
content <- NULL
newsdata$`0` <- NULL

save.image(file="C:/Users/yeyzh/Desktop/SOSC 5500/data_cleaned_1221.RData")

#Check the dfm features
str_length(dimnames(newsdata$dfm)$features)
topfeatures(newsdata$dfm, 1000)
textplot_wordcloud(newsdata$dfm,max_words =  500)
sparsity(newsdata$dfm)

#descriptive
des_table <- table(newsdata$province.x,newsdata$year)
des_table1 <- des_table
des_table1[des_table1 == 0] <- NA 
pheatmap(des_table1, cluster_rows =F, cluster_cols = F, legend = T, main = "Spatiotemporal Distribution of Report No. of Ineqaulity")

yearno <- table(newsdata$year)
plot(yearno, main = "Report No. of Inequality Per Year, 2003-2019", xlab = "Year", ylab = "Report No.", type = "l")

medianame <- sort(table(newsdata$media), decreasing=T)
plot(medianame, main = "Distribution of Report No. of Inequality among Media", xlab = "Media", ylab = "Report No.")

#find the appropriate K
model1 <- stm(newsdata$dfm, K=0, init.type = "Spectral", seed = 8, verbose = T, max.em.its = 10)
# Firstly, we use data driven approach, from which we find out 95 topics, but we think many of them are very similar. Hence, we merge similar topics together. Finally, we have 20 topics. Details please see the appendix

# To compare performance of different K, we use searchK function. This part is conducted in server.
out = convert(newsdata$dfm, to ="stm")
stopCluster(cl)
registerDoSEQ()
cl <- makeCluster(detectCores()-2)
registerDoParallel(cl)
searchK.parallel-final <- foreach(k = c(18:23), .packages = "stm") %dopar% {
  searchK(out$documents,out$vocab,K = k)
}
stopCluster(cl)

out[["exclus"]] <- mean(unlist(exclusivity(model, 
                                           M = M, frexw = 0.7)))
out[["semcoh"]] <- mean(unlist(semanticCoherence(model, 
                                                 heldout$documents, M)))
out[["heldout"]] <- eval.heldout(model, heldout$missing)$expected.heldout
out[["residual"]] <- checkResiduals(model, heldout$documents)$dispersion
out[["bound"]] <- max(model$convergence$bound)
out[["lbound"]] <- max(model$convergence$bound) + lfactorial(model$settings$dim$K)
out[["em.its"]] <- length(model$convergence$bound)
return(out)
#Then we find the best one is 22.

#Four articles are removed because none of their words in 10,000 most frequent list.
newsdata <- newsdata[-34789,]
newsdata <- newsdata[-32972,]
newsdata <- newsdata[-29611,]
newsdata <- newsdata[-28387,]


# Based on the measurement of each K's performance and the judgement 
#Nake model only conducting LDA
model0 <- stm(newsdata$dfm, K=22, init.type = "Spectral", seed = 8, verbose = T)
#Model with year, province and party
model1 <- stm(newsdata$dfm, K=22, init.type = "Spectral", prevalence = ~newsdata$year+newsdata$party.newspaper+province, seed = 8, verbose = T)
#Model added inertaction of yr and party
model2 <- stm(newsdata$dfm, K=22, init.type = "Spectral", prevalence = ~newsdata$year*newsdata$party.newspaper+province, seed = 8, verbose = T)
#Content model
model3 <- stm(newsdata$dfm, K=22, init.type = "Spectral", prevalence = ~newsdata$year +newsdata$party.newspaper+province, content = ~party.newspaper, data = newsdata, seed = 8,verbose = T)

#Detect the topics and assign labels
table1_22topics_labels <- labelTopics(model0)
figure1_22topics_MostProb10 <- plot.STM(model0, type = "summary", n =10)
topiclabel <- c("Government and Market", "Finance", "Internet", "International Economic", "History", "Entertainment", "Family", "House", "Sports", "International Politics","Gender","Occupation", "Consumption", "Culture","Society", "Football", "International Trade", "Traffic", "Education", "Law", "Medicine", "Privilege")

#correlation figure
topic_prop <- rep(NA,22)
for(i in 1:22){
  topic_prop[i]<-mean(model0$theta[,i])*500
}
figure2_22topics_Corr <- plot(topicCorr(model0), vlabels = topiclabel, vertex.color = "grey", vertex.size = topic_prop)

#coef. estimation
model1coef <- estimateEffect(c(1:22) ~ year+party.newspaper+province, model1, newsdata)
model2coef <- estimateEffect(c(1:22) ~ year*party.newspaper+province, model2, newsdata)
model3coef1 <- estimateEffect(c(1:22) ~ year+party.newspaper+province, model3, newsdata)
plot(model3coef1, covariate = "party.newspaper", topics = c(1:22), model3, method = "difference",cov.value1 = "0", cov.value2 = "1")


table2_model1coef <- summary(model1coef)
table3_model2coef <- summary(model2coef)

#party direct effect 
figure3_22topics_PartyEffect <- plot(model1coef, covariate = "party.newspaper", topics = c(1:22), model1, method = "difference",cov.value1 = "0", cov.value2 = "1", labeltype = "custom", custom.labels = topiclabel, verbose.labels =F, main = "The Effect of Party Supervision on Inequality Topic Preference", xlab = "Preference")
figure4_22topics_PartyEffect_inwords <- plot.STM(model1, type = "perspectives", topics = c(7,15), plabels = c("Society", "Family"), n =50,main = "Difference of Words between Topics Preferred by Party and Non-party newspapaer")

#content analysis
plot(model3, type = "perspectives", topics = 1,n=50)
plot(model3, type = "perspectives", topics = 2,n=50)
plot(model3, type = "perspectives", topics = 3,n=50)
plot(model3, type = "perspectives", topics = 4,n=50)
plot(model3, type = "perspectives", topics = 5,n=50)
plot(model3, type = "perspectives", topics = 6,n=50)
plot(model3, type = "perspectives", topics = 7,n=50)
plot(model3, type = "perspectives", topics = 8,n=50, main = "Difference of Words between Party and Non-party media in same topic", plabels = c("Non-party media","Party media"))
plot(model3, type = "perspectives", topics = 9,n=50)
plot(model3, type = "perspectives", topics = 10,n=50)
plot(model3, type = "perspectives", topics = 11,n=50)
plot(model3, type = "perspectives", topics = 12,n=50)
plot(model3, type = "perspectives", topics = 13,n=50)
plot(model3, type = "perspectives", topics = 14,n=50)
plot(model3, type = "perspectives", topics = 15,n=50)
plot(model3, type = "perspectives", topics = 16,n=50)
plot(model3, type = "perspectives", topics = 17,n=50)
plot(model3, type = "perspectives", topics = 18,n=50)
plot(model3, type = "perspectives", topics = 19,n=50)
plot(model3, type = "perspectives", topics = 20,n=50)
plot(model3, type = "perspectives", topics = 21,n=50)
plot(model3, type = "perspectives", topics = 22,n=50)

#time trend
figure5_1_22topics_timevariant <- plot(model1coef, covariate = "year", topics = c(1:22), model2, method = "continuous",ci.level = 0)
figure5_2_22topics_timevariant <- plot(model1coef, covariate = "year", topics = c(3,4,7,10:13,16,17), model2, method = "continuous",ci.level = 0,labeltype = "custom", custom.labels = c("Internet", "International Economic", "Family", "International Politics","Gender","Occupation", "Consumption","Sports","International Trade"),xlab = "Year", main = "Change of Selected Topics Prevalence")

#party moderated time effect
plot(model2coef, covariate = "year", topics = c(15),model = model2,method = "continuous", xlab = "Year", moderator = "party.newspaper", moderator.value = 1, linecol = "Red", ylim = c(0, .15), printlegend = F, main = "The Moderation Effect of Party Supervision in Topics 'Society'")
plot(model2coef, covariate = "year", topics = c(15),model = model2,method = "continuous", xlab = "Year", moderator = "party.newspaper", moderator.value = 0, linecol = "Blue",  add = T, printlegend = F)
legend(0, .08, c("Party", "Non-party"), lwd = 2, col = c( "red","blue"))

#coef. heatmap for 5*22 matrix
table_coef_sig_1 <- matrix(nrow = 5,ncol = 22)
for (i in 1:22){
  table_coef_sig[1,i][table2_model1coef$tables[[i]][2,4]<=0.001]<-table2_model1coef$tables[[i]][2,1]
  table_coef_sig[2,i][table2_model1coef$tables[[i]][3,4]<=0.001]<-table2_model1coef$tables[[i]][3,1]
  table_coef_sig[3,i][table3_model2coef$tables[[i]][2,4]<=0.001]<-table3_model2coef$tables[[i]][2,1]
  table_coef_sig[4,i][table3_model2coef$tables[[i]][3,4]<=0.001]<-table3_model2coef$tables[[i]][3,1]
  table_coef_sig[5,i][table3_model2coef$tables[[i]][4,4]<=0.001]<-table3_model2coef$tables[[i]][4,1]
}

table_coef_sig[table_coef_sig>0]<- 1
table_coef_sig[table_coef_sig<0]<- -1
pheatmap(table_coef_sig, cluster_rows =F, cluster_cols = F, 
         legend = F, gaps_row = 2,
         main = "Time and Party Supervision Effect on Topic Preference, Province Controlled", 
         labels_col = topiclabel, labels_row = c("Year","Party","Year", "Party", "Interaction"))


#features analysis
#full covariates
#merge features and clean
media = read.csv('media_info_final1.csv')
features = read.csv('features.csv')
fea_add = read.csv('feature_add.csv')
newsdata1 = merge(newsdata,media,by = "media",all.x = TRUE)
colnames(newsdata1)[which(colnames(newsdata1)=='provincecheck_en')] <- 'province'
colnames(newsdata1)[which(colnames(newsdata1)=='year.x')] <- 'year'
newsdata2 = merge(newsdata1,features,by = c("province","year"),all.x = TRUE)
newsdata3 = merge(newsdata2,fea_add,by = c("province","year"),all.x = TRUE) 
miss = function(x){
  return(sum(is.na(x)))
}
missing = apply(newsdata2[,-14],2,miss)
rm(newsdata1,newsdata2,newsdata)
topiclabel <- c("Gov&Mkt", "Finance", "Family", "House", "Gender","Occupation", "Consumption","Society","Education", "Law", "Medicine", "Privilege")

#estimate
subsample = newsdata3[(!is.na(newsdata3$newspaper))&(!is.na(newsdata3$bed_per_capita))
                      &(!is.na(newsdata3$senior_str))&(!is.na(newsdata3$prop_women_senior_high_school))
                      &(!is.na(newsdata3$urbanization)),]

model_full_covariates = stm(subsample$dfm, K=22, init.type = "Spectral",
                                   prevalence = ~subsample$year*subsample$party+subsample$party+subsample$hshsize*subsample$party+
                                     subsample$gdp_per_capita*subsample$party+subsample$cpi*subsample$party+subsample$marriage*subsample$party+
                                     subsample$divorce*subsample$party+subsample$newspaper*subsample$party+subsample$traffic_accident*subsample$party+
                                     subsample$bed_per_capita*subsample$party+subsample$senior_str*subsample$party+
                                     subsample$prop_women_senior_high_school*subsample$party+subsample$urbanization*subsample$party,
                                   data=subsample,seed = 8,verbose = TRUE)

coeffullcov <- estimateEffect(c(1:22)~year*party+party+hshsize*party+
                          gdp_per_capita*party+cpi*party+marriage*party+
                          divorce*party+newspaper*party+
                          bed_per_capita*party+senior_str*party+
                          prop_women_senior_high_school*party+urbanization*party,model_full_covariates, metadata = subsample)
coefsum <- summary(coeffullcov)

table_coef_sig <- matrix(nrow = 23,ncol = 22)
for (i in 1:22){
  for(j in 1:23){
    table_coef_sig[j,i][coefsum$tables[[i]][j+1,4]<=0.001]<-coefsum$tables[[i]][j+1,1]
  }}
table_coef_sig <- table_coef_sig[,-18]
table_coef_sig <- table_coef_sig[,-17]
table_coef_sig <- table_coef_sig[,-16]
table_coef_sig <- table_coef_sig[,-14]
table_coef_sig <- table_coef_sig[,-10]
table_coef_sig <- table_coef_sig[,-9]
table_coef_sig <- table_coef_sig[,-3:-6]
table_coef_sig[table_coef_sig>0]<- 1
table_coef_sig[table_coef_sig<0]<- -1
pheatmap(table_coef_sig, cluster_rows =F, cluster_cols = F, 
         legend = F, gaps_row = 12,
         main = "Localized features' Effect on Topic Preference", 
         labels_col = topiclabel, labels_row = c("Year","Party","Hshsize", "GDPPC", "CPI", "Marriage","Divorce","NewspaperNo.","MedBedPC","SenSTR","SenFemProp","Urbanization","YearxParty","HshsizexParty", "GDPPCxParty", "CPIxParty", "MarriagexParty","DivorcexParty","NewspaperNo.xParty","TrafficAccidxParty","MedBedPCxParty","SenSTRxParty","SenFemPropxParty","UrbanizationxParty"))

#same as above, try keep full obs with less covariates
media = read.csv('media_info_final1.csv')
features = read.csv('features.csv')
fea_add = read.csv('feature_add.csv')
newsdata1 = merge(newsdata,media,by = "media",all.x = TRUE)
colnames(newsdata1)[which(colnames(newsdata1)=='provincecheck_en')] <- 'province'
colnames(newsdata1)[which(colnames(newsdata1)=='year.x')] <- 'year'
newsdata2 = merge(newsdata1,features,by = c("province","year"),all.x = TRUE)
newsdata3 = merge(newsdata2,fea_add,by = c("province","year"),all.x = TRUE) 
miss = function(x){
  return(sum(is.na(x)))
}
missing = apply(newsdata2[,-14],2,miss)
rm(newsdata1,newsdata2,newsdata)
topiclabel <- c("Gov&Mkt", "Finance", "Family", "House", "Gender","Occupation", "Consumption","Society","Education", "Law", "Medicine", "Privilege")

subsample = newsdata3[!is.na(newsdata3$newspaper),]

model_full_obs = stm(subsample$dfm, K=22, init.type = "Spectral",
                     prevalence = ~subsample$year*subsample$party+subsample$party+subsample$hshsize*subsample$party+
                       subsample$gdp_per_capita*subsample$party+subsample$cpi*subsample$party+subsample$marriage*subsample$party+
                       subsample$divorce*subsample$party+subsample$newspaper*subsample$party+subsample$traffic_accident*subsample$party,
                     data=subsample,seed = 8,verbose = TRUE)

coeffullobs <- estimateEffect(c(1:22)~year*party+party+hshsize*party+
                                gdp_per_capita*party+cpi*party+marriage*party+
                                divorce*party+newspaper*party,model_full_obs
                              , metadata = subsample)
coef1sum <- summary(coeffullcov)

table_coef_sig <- matrix(nrow = 15,ncol = 22)
for (i in 1:22){
  for(j in 1:15){
    table_coef_sig[j,i][coef1sum$tables[[i]][j+1,4]<=0.001]<-coef1sum$tables[[i]][j+1,1]
  }}

table_coef_sig <- table_coef_sig[,-18]
table_coef_sig <- table_coef_sig[,-17]
table_coef_sig <- table_coef_sig[,-16]
table_coef_sig <- table_coef_sig[,-14]
table_coef_sig <- table_coef_sig[,-10]
table_coef_sig <- table_coef_sig[,-9]
table_coef_sig <- table_coef_sig[,-3:-6]

table_coef_sig[table_coef_sig>0]<- 1
table_coef_sig[table_coef_sig<0]<- -1

pheatmap(table_coef_sig, cluster_rows =F, cluster_cols = F, 
         legend = F, gaps_row = 8,
         main = "Localized features' Effect on Topic Preference", 
         labels_col = topiclabel, labels_row = c("Year","Party","Hshsize", "GDPPC", "CPI", "Marriage","Divorce","NewspaperNo.","YearxParty","HshsizexParty", "GDPPCxParty", "CPIxParty", "MarriagexParty","DivorcexParty","NewspaperNo.xParty","TrafficAccidxParty"))
