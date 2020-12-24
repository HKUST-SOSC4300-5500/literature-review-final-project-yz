
df = pd.read_csv('data_with_info.csv',index_col = 0)

stopwords = []
with open('stopwords.txt','r') as f:
	for line in f:
		stopwords.append(list(line.strip('\n').split(',')))
stopwords1 = []
for word in stopwords:
	stopwords1.append(str(word)[2:-2])

df = df.rename(columns={'0':'words_seg'})
pattern = re.compile(u"[\u4e00-\u9fa5]+", re.UNICODE)

all = []

for i in df.index:
	words_seg = []
	for word in re.split(',',df.loc[i,'words_seg']):
		if re.search(pattern,word) != None:
			word = re.search(pattern,word).group(0)
			if word not in stopwords1:
				words_seg.append(word)
	all.append(words_seg)
	print(i)



words_nostop = pd.Series(all)
df1 = pd.concat([df,words_nostop],axis=1)

df1 = df1.rename(columns={'0':'words_nostop'})


df1.to_csv('data_final.csv')