import argparse

import requests
from bs4 import BeautifulSoup

parser = argparse.ArgumentParser("scrape")
parser.add_argument("url", help="url to scrape", type=str)
args = parser.parse_args()
print(args.url)
exit(0)

url = "https://pokemondb.net/pokedex/national"
response = requests.get(url)
soup = BeautifulSoup(response.text, "html.parser")

# Example: Find all <a> tags with class 'ent-name'
links = soup.find_all("a", class_="ent-name")
for link in links:
    print(*link.contents)
