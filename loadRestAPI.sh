#!/bin/bash

#As of version 2.0.0, the DataLoader is also available via the REST API. This also bulk load into a running Blazegraph Nano Sparql Server (NSS). A guide to configuring the REST API load is here.
#
#The 2.0.0 deployers could use a loadRestAPI.sh script. It takes one parameter, the file or directory to load.
#
#Usage example of loading data from several sources (file1, dir1, file2, dir2):
#
#sh loadRestAPI.sh  file1, dir1, file2, dir2

FILE_OR_DIR=$1

if [ -f "/etc/default/blazegraph" ] ; then
    . "/etc/default/blazegraph" 
else
    JETTY_PORT=9999
fi

LOAD_PROP_FILE=/tmp/$$.properties

export NSS_DATALOAD_PROPERTIES=/usr/local/blazegraph/conf/RWStore.properties
#export NSS_DATALOAD_PROPERTIES=/usr/blazegraph/conf/RWStore.properties
#export NSS_DATALOAD_PROPERTIES=/mnt/ntfs/github/docker-github-PUBLIC/blazegraph/RWStore.properties

#Probably some unused properties below, but copied all to be safe.

cat <<EOT >> $LOAD_PROP_FILE
quiet=false
verbose=0
closure=false
durableQueues=true
#Needed for quads
#defaultGraph=
com.bigdata.rdf.store.DataLoader.flush=false
com.bigdata.rdf.store.DataLoader.bufferCapacity=100000
com.bigdata.rdf.store.DataLoader.queueCapacity=10
#Namespace to load
namespace=kb
#Files to load
fileOrDirs=$1
#Property file (if creating a new namespace)
propertyFile=$NSS_DATALOAD_PROPERTIES
EOT

echo "Loading with properties..."

cat $LOAD_PROP_FILE

curl -X POST --data-binary @${LOAD_PROP_FILE} --header 'Content-Type:text/plain' http://localhost:${JETTY_PORT}/blazegraph/dataloader

#Let the output go to STDOUT/ERR to allow script redirection

rm -f $LOAD_PROP_FILE
