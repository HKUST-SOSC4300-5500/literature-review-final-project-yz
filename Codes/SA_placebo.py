import pandas as pd
df = pd.read_csv('datav3.csv',index_col = 0)
import paddlehub as hub
import os
os.environ["CUDA_VISIBLE_DEVICES"] = "0"
df['label'] = None
df['pos_pro'] = None
df['initial_label'] = None

senta_cnn = hub.Module(name="senta_cnn")


for i in df.index:
    result = senta_cnn.sentiment_classify([df.loc[i,'content']])
    df.loc[i,'initial_label'] = result[0]['sentiment_label']
    df.loc[i,'pos_pro'] = result[0]['positive_probs']
    if result[0]['positive_probs']>0.204:
        df.loc[i,'label'] = 1
    else:
        df.loc[i, 'label'] = 0
    print(i)
