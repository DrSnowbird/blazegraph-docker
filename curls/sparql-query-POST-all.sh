#!/bin/bash -x

curl -L -X POST "http://0.0.0.0:9999/bigdata/sparql?query=SELECT%20*%20WHERE%20%7B%20%20%3Fs%20%3Fp%20%3Fo%20.%20%7D" -H "Accept: application/sparql-results+json"
