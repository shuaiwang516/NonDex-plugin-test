# use github API to get a list of Gradle repos

import requests
import math

url_1 = 'https://api.github.com/search/repositories?q=gradle+in:topic+'
url_2 = '&per_page=100&sort=stars&order=desc&page='

session = requests.Session()
session.auth = ('MarcyGO','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')

parts = ["stars:>50", "stars:17..50", "stars:9..16", "stars:6..8", "stars:4..5", "stars:3", 
        "stars:2+created:>2018-06-01", "stars:2+created:<=2018-06-01", 
        "stars:1+created:<=2016-01-01", "stars:1+created:2016-01-02..2018-01-01", "stars:1+created:2018-01-02..2019-06-01", "stars:1+created:2019-06-02..2021-01-01", "stars:1+created:>2021-01-01"]

f = open("repos_raw.txt", "x")
for part in parts:
    for page in range(10):
        r = session.get(url_1 + part + url_2 + str(page+1))  # page 1-started
        r = r.json()
        for item in r['items']:
            f.write(item["full_name"]+"\n")
f.close()

# r = session.get(url_1 + "stars:>0" + url_2 + str(1))
# r=r.json()
# print(r['total_count'])
