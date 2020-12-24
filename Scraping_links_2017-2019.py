# News with keyword '夏季',from Jan 1,2015 to Dec 31,2016
import requests
import re
from itertools import chain
import pandas as pd
from spyder_kernels.customize.spydercustomize import runfile

links = list()
for page in range(1,493 ):
    headers = {
    'Accept':'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
    'Accept-Encoding':'gzip, deflate',
    'Accept-Language':'zh-CN,zh;q=0.9,en;q=0.8,zh-TW;q=0.7',
    'Cache-Control':'max-age=0',
    'Connection':'keep-alive',
    'Cookie':'__utmc=53764021; __reLoginUrl=""; cMACHINECOOKIE=1761030b2ad; cUSERNAME="HKUST@ipaccess"; __lst_wisesearch.wisers.net=1606856544483; gallery-simplegallery1=1; __lsid=^t1ms1.wisers.com^364589157; __lst_libwisenews.wisers.net=1607202142991; JSESSIONID=E7AC15F77EB9D6DCBF207C7E220B380B.wise19; __p_scid_HKUST_ipaccess="HKUST@ipaccess|364589157|6|t1ms1|6176366ce74a"; __lst_libwisesearch.wisers.net=1607202142772; __utma=53764021.1381410902.1606589207.1607137263.1607230877.12; __utmz=53764021.1607230877.12.9.utmcsr=libwisenews.wisers.net|utmccn=(referral)|utmcmd=referral|utmcct=/; __utmt=1; __utmb=53764021.1.10.1607230877',
    'Host':'libwisesearch.wisers.net',
    'Upgrade-Insecure-Requests':'1',
    'User-Agent':'Mozilla/5.0 (Macintosh; Intel Mac OS X 11_0_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/87.0.4280.67 Safari/537.36'
    }
    left = 100*(page - 1)
    right = 100 * page - 1
    url = 'http://libwisesearch.wisers.net/wortal/fs-search-result.do?adhoc-clip-folder-id=search-result&result-count=&sort-count=&fs-search=true&currentsubdb=federated&menu-id=&cp&cp_s=' + str(left) + '&cp_e='+ str(right) + '&result-filter-by-db=allsubdb&result-filter-by-media=newspaper'
    web_page = requests.get(url,headers = headers)
    pattern = re.compile('<div class="results_type">\s*<a href=\'javascript:OpenDocuments\("(.*)","news:')
    link = re.findall(pattern, web_page.text)
    links.append(link)
    print(page)

links = list(chain.from_iterable(links))
df = pd.DataFrame(links)
df.to_csv('links.csv')

