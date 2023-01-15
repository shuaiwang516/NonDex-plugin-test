# use github API to get a list of Gradle repos with 0 star
# use **create time** to split the (around) 40000 results

import requests
import math
from json.decoder import JSONDecodeError

url_1 = 'https://api.github.com/search/repositories?q=gradle+in:topic+stars:0+created:'
url_2 = '&per_page=100&sort=stars&order=desc&page='

session = requests.Session()
session.auth = ('MarcyGO','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')

parts = ["2015-08-02..2016-01-01", "2015-02-02..2015-08-01", "2014-06-01..2015-02-01", "<2014-06-01"]

f = open("repos_raw_0star.txt", "x")

def request(url):
    cond = True
    while cond:
        cond = False
        r = session.get(url)  # page 1-started
        try: 
            r = r.json()
        except JSONDecodeError as e:
            cond = True
        if (not cond):
            cond = 'message' in r and r['message'] == 'Server Error'
    return r

def search(peroid):
    r = request(url_1 + peroid +url_2+str(1))
    print(r['total_count'], r['incomplete_results'], peroid)
    page_num = math.ceil(r['total_count']/100)
    for item in r['items']:
        f.write(item["full_name"]+"\n")
    for page in range (2, page_num+1):
        r = request(url_1 + peroid +url_2+str(page))
        for item in r['items']:
            f.write(item["full_name"]+"\n")
    return

for year in range (2022, 2015, -1):
    for month in range (12, 0, -1):
        start = str(year)+"-"+"0"*(month<10)+str(month)+"-02"
        end = str(year+(month==12))+"-"+"0"*(month<9 or month==12)+str(month%12+1)+"-01"
        search(start + ".." + end)
for part in parts:
    search(part)
        

f.close()

# for i in range(2022, 2012, -1):
    # for page in range(10):
    #     r = session.get(url_1 + str(i) + "-01-01.." + str(i+1) + "-01-01" + url_2 + str(page+1))  # page 1-started
    #     r = r.json()
    #     for item in r['items']:
    #         f.write(item["full_name"]+"\n")
# r = session.get(url_1 + parts[3] + url_2 + str(1))
# r = r.json()
# if 'total_count' in r:
#     print(r['total_count'])
# else:
#     print(r)
# f.close()

# r = session.get(url_1 + "stars:>0" + url_2 + str(1))
# r=r.json()
# print(r['total_count'])
