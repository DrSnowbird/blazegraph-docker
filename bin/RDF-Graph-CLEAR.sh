#!/bin/bash 

GSP_ENDPOINT=${1:-"http://0.0.0.0:13030/d3fend/"}
GRAPH_IRI=${2:-"<http://d3fend.mitre.org/ontologies>"}
if [ $# -lt 2 ]; then
    echo -e "** ERROR: $(basename $0) <ENDPOINT> <GRAPH_IRI>"
    echo -e "e.g."
    echo 
    echo -e "$(basename $0) ${GSP_ENDPOINT} ${GRAPH_IRI}"
    exit 9
fi

#curl -L -X POST "http://0.0.0.0:13030/d3fend/" -H "Content-Type: application/sparql-update" --data-raw "CLEAR GRAPH <http://d3fend.mitre.org/ontologies> ;"
curl -L -X POST "${GSP_ENDPOINT}" \
	-H "Content-Type: application/sparql-update" \
	--data-raw "CLEAR GRAPH ${GRAPH_IRI} ;"
