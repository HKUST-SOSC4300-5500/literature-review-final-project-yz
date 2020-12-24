import pandas as pd
import re
import requests
from opencc import OpenCC
cc = OpenCC('hk2s')

df = pd.read_csv('data.csv',index_col=0)


headers = {
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
    'Accept-Encoding': 'gzip, deflate',
    'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8,zh-TW;q=0.7',
    'Connection': 'keep-alive',
    'Host': 'libwisesearch.wisers.net',
    'Upgrade-Insecure-Requests': '1',
    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 11_0_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/87.0.4280.67 Safari/537.36'
}


for i in range(31000,48776):
    url = 'http://libwisesearch.wisers.net/wortal' + df.loc[i, 'links']
    web_page = requests.get(url, headers=headers)
    pattern1 = re.compile('<div id="content_source">\s*(.*)\s*</div>')
    paper = re.findall(pattern1, web_page.text)
    pattern2 = re.compile('<div id="content_bar">\s*<div id="content_details">.*&nbsp;(\d{4})', re.DOTALL)
    year = re.findall(pattern2, web_page.text)
    pattern3 = re.compile('<div id="content_bar">\s*<div id="content_details">.*&nbsp;\d{4}(\d{2})', re.DOTALL)
    month = re.findall(pattern3, web_page.text)
    pattern4 = re.compile('<div id="content_bar">\s*<div id="content_details">.*&nbsp;\d{4}\d{2}(\d{2})', re.DOTALL)
    day = re.findall(pattern4, web_page.text)
    pattern5 = re.compile('<span class="bluebold">(.*)</span>')
    title = re.findall(pattern5, web_page.text)
    pattern6 = re.compile('<td colspan="3" class="content">\s*(.*)')
    content = re.findall(pattern6, web_page.text)
    content = re.sub('\\\\u3000', '', str(content))
    content = re.sub('<.*?>', '', str(content))
    title = re.sub('\\\\u3000',' ',str(title))
    title = re.sub('<.*?>',' ', str(title))
    paper = str(paper)[2:-2]
    title = title[2:-2]
    year = str(year)[2:-2]
    month = str(month)[2:-2]
    day = str(month)[2:-2]
    content = content[2:-2]
    title = cc.convert(title)
    paper = cc.convert(paper)
    content = cc.convert(content)
    df.loc[i, 'content_len']  = len(content)
    df.loc[i,'date'] = year +'-'+month +'-'+day
    df.loc[i, 'paper'] = paper
    df.loc[i, 'year'] = year
    df.loc[i, 'month'] = month
    df.loc[i, 'day'] = day
    df.loc[i, 'title'] = title
    df.loc[i, 'content'] = content
    print(df.loc[i, 'paper'])
    print(df.loc[i, 'title'])
    print(df.loc[i, 'content'])
    print(df.loc[i,'date'])
    print(i)
    if i%100 == 0:
        df.to_csv('data.csv')

df.to_csv('data.csv')

