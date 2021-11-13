import requests

url = """http://0.0.0.0:9999/bigdata/sparql?query=PREFIX dig: <http://dig.isi.edu/>
PREFIX : <http://dig.isi.edu/>

SELECT *
WHERE {
    :event ?p ?o .
}"""

payload={}
files={}
headers = {
  'Accept': 'application/sparql-results+json'
}

response = requests.request("POST", url, headers=headers, data=payload, files=files)

print(response.text)

