# use github API to get a list of Gradle repos

import requests
import math

url = 'https://api.github.com/search/repositories?q=gradle.build in:filename&per_page=100&sort=stars&order=desc&page='

session = requests.Session()
session.auth = ('MarcyGO','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')

f = open("repos_all.txt", "x")
for page in range(10):
    r = session.get(url + str(page))
    r = r.json()
    for item in r['items']:
        f.write(item["full_name"]+"\n")

f.close()