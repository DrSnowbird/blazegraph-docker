#!/bin/bash

set +e

MY_DIR=$(dirname "$(readlink -f "$0")")

echo
echo
echo "==========================================================="


if [ $# -lt 1 ]; then
    echo "--------------------------------------------------------"
    echo "Usage: "
    echo "  ${0} <container_shell_command>"
    echo "e.g.: "
    echo "  ${0} ls -al "
    echo "  ${0} /bin/bash "
    echo "--------------------------------------------------------"
fi

###########################################################################
#### ---- RUN Configuration (CHANGE THESE if needed!!!!)           --- ####
###########################################################################
## ------------------------------------------------------------------------
## Valid "BUILD_TYPE" values: 
##    0: (default) has neither X11 nor VNC/noVNC container build image type
##    1: X11/Desktip container build image type
##    2: VNC/noVNC container build image type
## ------------------------------------------------------------------------
BUILD_TYPE=0

####################################################
#### ---- NVIDIA GPU Check/Setup or not:  ---- #####
####################################################
IS_TO_RUN_CPU=0
IS_TO_RUN_GPU=1

###################################################
#### ---- Parse Command Line Arguments:  ---- #####
###################################################
RESTART_OPTION_VALUES=" no on-failure unless-stopped always "
RESTART_OPTION=${RESTART_OPTION:-no}

## ------------------------------------------------------------------------
## "RUN_OPTION" values: 
##    "-it" : (default) Interactive Container -
##       ==> Best for Debugging Use
##    "-d" : Detach Container / Non-Interactive 
##       ==> Usually, when not in debugging mode anymore, then use 1 as choice.
##       ==> Or, your frequent needs of the container for DEV environment Use.
## ------------------------------------------------------------------------
RUN_OPTION=${RUN_OPTION:-" -it "}

PARAMS=""
while (( "$#" )); do
  case "$1" in
    -c|--cpu)
      IS_TO_RUN_CPU=1
      IS_TO_RUN_GPU=0
      GPU_OPTION=
      shift
      ;;
    -g|--gpu)
      IS_TO_RUN_CPU=0
      IS_TO_RUN_GPU=1
      GPU_OPTION=" --gpus all "
      shift
      ;;
    -d|--detach)
      RUN_OPTION=" -d "
      shift
      ;;
    -it)
      RUN_OPTION=" -it "
      shift
      ;;
    -t|--imageTag)
      imageTag=$2
      shift 2
      ;;
    -r|--restart)
      ## Valid "RESTART_OPTION" values:
      ##  { no, on-failure, unless-stopped, always }
      if [[ "${RESTART_OPTION_VALUES}" =~ .*" $2 ".* ]]; then
          RESTART_OPTION=$2
          shift 2
      else
          echo "--- INFO: -r|--restart options: { no, on-failure, unless-stopped, always }"
          echo "--- default to 'always' "
          RESTART_OPTION=unless-stopped
      fi
      ;;
    -*|--*=) # unsupported flags
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;
    *) # preserve positional arguments
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done
# set positional arguments in their proper place
eval set -- "$PARAMS"

echo "-c (IS_TO_RUN_CPU): $IS_TO_RUN_CPU"
echo "-g (IS_TO_RUN_GPU): $IS_TO_RUN_GPU"

echo ">>> RUN_OPTION: ${RUN_OPTION}"
echo ">>>> imageTag=${imageTag}"


echo "remiaing args:"
echo $@

## ------------------------------------------------------------------------
## -- Container 'hostname' use: 
## -- Default= 2 (use HOST_NAME)
## -- 1: HOST_IP
## -- 2: HOST_NAME
## ------------------------------------------------------------------------
HOST_USE_IP_OR_NAME=${HOST_USE_IP_OR_NAME:-2}

########################################
#### ---- NVIDIA GPU Checking: ---- ####
########################################
## ------------------------------------------------------------------------
## Run with GPU or not
##    0: (default) Not using host's USER / GROUP ID
##    1: Yes, using host's USER / GROUP ID for Container running.
## ------------------------------------------------------------------------ 

NVIDIA_DOCKER_AVAILABLE=0
function check_NVIDIA() {
    NVIDIA_PCI=`lspci | grep VGA | grep -i NVIDIA`
    if [ "$NVIDIA_PCI" == "" ]; then
        echo "---- No Nvidia PCI found! No Nvidia/GPU physical card(s) available! Use CPU only!"
        GPU_OPTION=
    else
        which nvidia-smi
        if [ $? -ne 0 ]; then
            echo "---- No nvidia-smi command! No Nvidia/GPU driver setup! Use CPU only!"
            GPU_OPTION=
        else
            NVIDIA_SMI=`nvidia-smi | grep -i NVIDIA | grep -i CUDA`
            if [ "$NVIDIA_SMI" == "" ]; then
                echo "---- No nvidia-smi command not function correctly. Use CPU only!"
                GPU_OPTION=
            else
                echo ">>>> Found Nvidia GPU: Use all GPU(s)!"
                echo "${NVIDIA_SMI}"
                GPU_OPTION=" --gpus all "
            fi
            if [ ${IS_TO_RUN_CPU} -gt 0 ]; then
                GPU_OPTION=
            fi
        fi
    fi
}
if [ ${IS_TO_RUN_GPU} -gt 0 ]; then
    check_NVIDIA
    #### ---- NVIDIA Docker run recommendations: ----
    # NOTE: The SHMEM allocation limit is set to the default of 64MB.  This may be
    #   insufficient for PyTorch.  NVIDIA recommends the use of the following flags:
    #   docker run --gpus all --ipc=host --ulimit memlock=-1 --ulimit stack=67108864 ...
    # -ipc=host --ulimit memlock=-1 --ulimit stack=67108864
    GPU_OPTION="${GPU_OPTION} --ulimit memlock=-1 --ulimit stack=67108864 "
    echo "GPU_OPTION= ${GPU_OPTION}"
fi
echo "$@"

## ------------------------------------------------------------------------
## Change to one (1) if run.sh needs to use host's user/group to run the Container
## Valid "USER_OPTIONS_NEEDED" values: 
##    0: (default) Not using host's USER / GROUP ID
##    1: Yes, using host's USER / GROUP ID for Container running.
## ------------------------------------------------------------------------
USER_OPTIONS_NEEDED=1

## ------------------------------------------------------------------------
## More optional values:
##   Add any additional options here
## ------------------------------------------------------------------------
#MORE_OPTIONS="--privileged=true"
MORE_OPTIONS=

## ------------------------------------------------------------------------
## Multi-media optional values:
##   Add any additional options here
## ------------------------------------------------------------------------
#MEDIA_OPTIONS=" --device /dev/snd --device /dev/dri  --device /dev/video0  --group-add audio  --group-add video "
#MEDIA_OPTIONS=" --group-add audio  --group-add video --device /dev/snd --device /dev/dri  "
MEDIA_OPTIONS=

###############################################################################
###############################################################################
###############################################################################
#### ---- DO NOT Change the code below UNLESS you really want to !!!!) --- ####
#### ---- DO NOT Change the code below UNLESS you really want to !!!!) --- ####
#### ---- DO NOT Change the code below UNLESS you really want to !!!!) --- ####
###############################################################################
###############################################################################
###############################################################################

########################################
#### ---- Correctness Checking ---- ####
########################################
RESTART_OPTION=`echo ${RESTART_OPTION} | sed 's/ //g' | tr '[:upper:]' '[:lower:]' `
REMOVE_OPTION=" --rm "
if [ "${RESTART_OPTION}" != "no" ]; then
    REMOVE_OPTION=""
fi

echo "REMOVE_OPTION=${REMOVE_OPTION}"

###########################################################################
## -- docker-compose or docker-stack use only --
###########################################################################

## -- (this script will include ./.env only if "./docker-run.env" not found
DOCKER_ENV_FILE="./.env"

###########################################################################
#### (Optional - to filter Environmental Variables for Running Docker)
###########################################################################
ENV_VARIABLE_PATTERN=""

###################################################
#### ---- Change this only to use your own ----
###################################################
ORGANIZATION=${ORGANIZATION:-openkbs}
baseDataFolder="$HOME/data-docker"

###################################################
#### **** Container HOST information ****
###################################################
SED_MAC_FIX="''"
CP_OPTION="--backup=numbered"
HOST_IP=127.0.0.1
HOST_NAME=localhost
function get_HOST_IP() {
    if [[ "$OSTYPE" == "linux-gnu" ]]; then
        # Linux ...
        HOST_NAME=`hostname -f`
        HOST_IP=`ip route get 1|grep via | awk '{print $7}'`
        SED_MAC_FIX=
        echo -e ">>>> HOST_IP: ${HOST_IP}"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # Mac OSX
        HOST_NAME=`hostname -f`
        HOST_IP=`ifconfig | grep "inet " | grep -Fv 127.0.0.1 | grep -Fv 192.168 | awk '{print $2}'`
        CP_OPTION=
    else
        HOST_NAME=`hostname -f`
        echo "**** Unknown/unsupported HOST OS type: $OSTYPE"
        echo ">>>> Use defaults: HOST_IP=$HOST_IP ; HOST_NAME=$HOST_NAME"
    fi
    echo ">>> HOST_IP=${HOST_IP}"
    echo ">>> HOST_NAME=${HOST_NAME}"
}
get_HOST_IP
HOST_IP=${HOST_IP:-127.0.0.1}
HOST_NAME=${HOST_NAME:-localhost}

##################################################
## ---- Setup accessing HOST's /etc/hosts: ---- ##
##################################################
IS_USE_HOST_OPTIONS=1
function container_host_options() {
    ## **************** WARNING: *********************
    ## **************** WARNING: *********************
    ## **************** WARNING: *********************
    #  => this might open up more attack surface since
    #   /etc/hosts has other nodes IP/name information
    # ------------------------------------------------
    if [ ${IS_USE_HOST_OPTIONS} -gt 0 ]; then
        if [ ${HOST_USE_IP_OR_NAME} -eq 2 ]; then
            HOSTS_OPTIONS="-h ${HOST_NAME} -v /etc/hosts:/etc/hosts "
        else
            # default use HOST_IP
            HOSTS_OPTIONS="-h ${HOST_IP} -v /etc/hosts:/etc/hosts "
        fi
    fi
}
container_host_options

###################################################
#### **** Container package information ****
###################################################
DOCKER_IMAGE_REPO=`echo $(basename $PWD)|tr '[:upper:]' '[:lower:]'|tr "/: " "_" `
imageTag=${imageTag:-"${ORGANIZATION}/${DOCKER_IMAGE_REPO}"}
#PACKAGE=`echo ${imageTag##*/}|tr "/\-: " "_"`
PACKAGE="${imageTag##*/}"

###################################################
#### ---- (DEPRECATED but still supported)    -----
#### ---- Volumes to be mapped (change this!) -----
###################################################
# (examples)
# IDEA_PRODUCT_NAME="IdeaIC2017"
# IDEA_PRODUCT_VERSION="3"
# IDEA_INSTALL_DIR="${IDEA_PRODUCT_NAME}.${IDEA_PRODUCT_VERSION}"
# IDEA_CONFIG_DIR=".${IDEA_PRODUCT_NAME}.${IDEA_PRODUCT_VERSION}"
# IDEA_PROJECT_DIR="IdeaProjects"
# VOLUMES_LIST="${IDEA_CONFIG_DIR} ${IDEA_PROJECT_DIR}"

# ---------------------------
# Variable: VOLUMES_LIST
# (NEW: use docker.env with "#VOLUMES_LIST=data workspace" to define entries)
# ---------------------------
## -- If you defined locally here, 
##    then the definitions of volumes map in "docker.env" will be ignored.
# VOLUMES_LIST="data workspace"

# ---------------------------
# OPTIONAL Variable: PORT PAIR
# (NEW: use docker.env with "#PORTS=18000:8000 17200:7200" to define entries)
# ---------------------------
## -- If you defined locally here, 
##    then the definitions of ports map in "docker.env" will be ignored.
#### Input: PORT - list of PORT to be mapped
# (examples)
#PORTS_LIST="18000:8000"
#PORTS_LIST=

#########################################################################################################
######################## DON'T CHANGE LINES STARTING BELOW (unless you need to) #########################
#########################################################################################################
LOCAL_VOLUME_DIR="${baseDataFolder}/${PACKAGE}"
## -- Container's internal Volume base DIR
DOCKER_VOLUME_DIR="/home/developer"

###################################################
#### ---- Detect Docker Run Env files ----
###################################################

function detectDockerRunEnvFile() {
    curr_dir=`pwd`
    if [ -s "${DOCKER_ENV_FILE}" ]; then
        echo "--- INFO: Docker Run Environment file '${DOCKER_ENV_FILE}' FOUND!"
    else
        echo "*** WARNING: Docker Run Environment file '${DOCKER_ENV_FILE}' NOT found!"
        echo "*** WARNING: Searching for .env or docker.env as alternative!"
        echo "*** --->"
        if [ -s "./docker-run.env" ]; then
            echo "--- INFO: ./docker-run.env FOUND to use as Docker Run Environment file!"
            DOCKER_ENV_FILE="./docker-run.env"
        else
            if [ -s "./.env" ]; then
                echo "--- INFO: ./.env FOUND to use as Docker Run Environment file!"
                DOCKER_ENV_FILE="./.env"
            else
                echo "--- INFO: ./.env Docker Environment file (.env) NOT found!"
                if [ -s "./docker.env" ]; then
                    echo "--- INFO: ./docker.env FOUND to use as Docker Run Environment file!"
                    DOCKER_ENV_FILE="./docker.env"
                else
                    echo "*** WARNING: Docker Environment file (.env) or (docker.env) NOT found!"
                fi
            fi
        fi
    fi
}
detectDockerRunEnvFile

################################################
#### ---- USER_OPTIONS: Optional setup:---- ####
################################################
USER_OPTION=
function user_ids_options() {
    #USER_OPTIONS="--user $(id -g):$(id -u)"
    USER_ID=`cat ${DOCKER_ENV_FILE} | grep  "^USER_ID=" | cut -d'=' -f2 | sed 's/ *$//g'`
    GROUP_ID=`cat ${DOCKER_ENV_FILE} | grep  "^GROUP_ID=" | cut -d'=' -f2 | sed 's/ *$//g'`
    if [ "${USER_ID}" != "" ] && [ "${USER_ID}" != "" ]; then
        USER_OPTIONS="--user ${USER_ID:-$(id -g)}:${GROUP_ID:-$(id -u)}"
    fi
}
user_ids_options

###################################################
#### ---- Function: Generate volume mappings  ----
####      (Don't change!)
###################################################
VOLUME_MAP=""
#### Input: VOLUMES - list of volumes to be mapped
hasPattern=0
function hasPattern() {
    detect=`echo $1|grep "$2"`
    if [ "${detect}" != "" ]; then
        hasPattern=1
    else
        hasPattern=0
    fi
}

DEBUG=0
function debug() {
    if [ $DEBUG -gt 0 ]; then
        echo $*
    fi
}

function cutomizedVolume() {
    DATA_VOLUME=$1 
    if [ "`echo $DATA_VOLUME|grep 'volume-'`" != "" ]; then
        docker_volume=`echo $DATA_VOLUME | cut -d'-' -f2 | cut -d':' -f1`
        dest_volume=`echo $DATA_VOLUME | cut -d'-' -f2 | cut -d':' -f2`
        source_volume=$(basename $imageTag)_${docker_volume}
        sudo docker volume create ${source_volume}
        VOLUME_MAP="-v ${source_volume}:${dest_volume} ${VOLUME_MAP}"
    else
        echo "---- ${DATA_VOLUME} already is defined! Hence, ignore setup ${DATA_VOLUME} ..."
        echo "---> VOLUME_MAP=${VOLUME_MAP}"
    fi
}

function checkHostVolumePath() {
    _left=$1
    if [ ! -s ${_left} ]; then 
        echo "--- checkHostVolumePath: ${_left}: Not existing!"
        mkdir -p ${_left}
    fi
    _SYS_PATHS="/dev /var /etc"
    if [[ $_SYS_PATHS != *"${_left}"* ]]; then
        sudo chown -R ${USER_ID}:${USER_ID} ${_left}
        ls -al ${_left}
    fi
}

function generateVolumeMapping() {
    if [ "$VOLUMES_LIST" == "" ]; then
        ## -- If locally defined in this file, then respect that first.
        ## -- Otherwise, go lookup the docker.env as ride-along source for volume definitions
        VOLUMES_LIST=`cat ${DOCKER_ENV_FILE}|grep "^#VOLUMES_LIST= *"|sed "s/[#\"]//g"|cut -d'=' -f2-`
    fi
    for vol in $VOLUMES_LIST; do
        echo
        echo ">>>>>>>>> $vol"
        hasColon=`echo $vol|grep ":"`
        ## -- allowing change local volume directories --
        if [ "$hasColon" != "" ]; then
            if [ "`echo $vol|grep 'volume-'`" != "" ]; then
                cutomizedVolume $vol
            else
                echo "************* hasColon=$hasColon"
                left=`echo $vol|cut -d':' -f1`
                right=`echo $vol|cut -d':' -f2`
                leftHasDot=`echo $left|grep "^\./"`
                if [ "$leftHasDot" != "" ]; then
                    ## has "./data" on the left
                    debug "******** A. Left HAS Dot pattern: leftHasDot=$leftHasDot"
                    if [[ ${right} == "/"* ]]; then
                        ## -- pattern like: "./data:/containerPath/data"
                        echo "******* A-1 -- pattern like ./data:/data --"
                        VOLUME_MAP="${VOLUME_MAP} -v `pwd`/${left#./}:${right}"
                    else
                        ## -- pattern like: "./data:data"
                        echo "******* A-2 -- pattern like ./data:data --"
                        VOLUME_MAP="${VOLUME_MAP} -v `pwd`/${left#./}:${DOCKER_VOLUME_DIR}/${right}"
                    fi
                    checkHostVolumePath "`pwd`/${left}"
                else
                    ## No "./data" on the left
                    debug "******** B. Left  No ./data on the left: leftHasDot=$leftHasDot"
                    leftHasAbsPath=`echo $left|grep "^/.*"`
                    if [ "$leftHasAbsPath" != "" ]; then
                        debug "******* B-1 ## Has pattern like /data on the left "
                        if [[ ${right} == "/"* ]]; then
                            ## -- pattern like: "/data:/containerPath/data"
                            echo "****** B-1-a pattern like /data:/containerPath/data --"
                            VOLUME_MAP="${VOLUME_MAP} -v ${left}:${right}"
                        else
                            ## -- pattern like: "/data:data"
                            echo "----- B-1-b pattern like /data:data --"
                            VOLUME_MAP="${VOLUME_MAP} -v ${left}:${DOCKER_VOLUME_DIR}/${right}"
                        fi
                        checkHostVolumePath "${left}"
                    else
                        debug "******* B-2 ## No pattern like /data on the left"
                        rightHasAbsPath=`echo $right|grep "^/.*"`
                        debug ">>>>>>>>>>>>> rightHasAbsPath=$rightHasAbsPath"
                        if [[ ${right} == "/"* ]]; then
                            echo "****** B-2-a pattern like: data:/containerPath/data"
                            debug "-- pattern like ./data:/data --"
                            VOLUME_MAP="${VOLUME_MAP} -v ${LOCAL_VOLUME_DIR}/${left}:${right}"
                        else
                            debug "****** B-2-b ## -- pattern like: data:data"
                            VOLUME_MAP="${VOLUME_MAP} -v ${LOCAL_VOLUME_DIR}/${left}:${DOCKER_VOLUME_DIR}/${right}"
                        fi
                        checkHostVolumePath "${left}"
                    fi
                    mkdir -p ${LOCAL_VOLUME_DIR}/${left}
                    if [ $DEBUG -gt 0 ]; then ls -al ${LOCAL_VOLUME_DIR}/${left}; fi
                fi
            fi
        else
            ## -- pattern like: "data"
            debug "-- default sub-directory (without prefix absolute path) --"
            VOLUME_MAP="${VOLUME_MAP} -v ${LOCAL_VOLUME_DIR}/$vol:${DOCKER_VOLUME_DIR}/$vol"
            checkHostVolumePath "${LOCAL_VOLUME_DIR}/$vol"
            if [ $DEBUG -gt 0 ]; then ls -al ${LOCAL_VOLUME_DIR}/$vol; fi
        fi       
        echo ">>> expanded VOLUME_MAP: ${VOLUME_MAP}"
    done
}
#### ---- Generate Volumes Mapping ----
generateVolumeMapping
echo ${VOLUME_MAP}

###################################################
#### ---- Function: Generate port mappings  ----
####      (Don't change!)
###################################################
PORT_MAP=""
function generatePortMapping() {
    if [ "$PORTS" == "" ]; then
        ## -- If locally defined in this file, then respect that first.
        ## -- Otherwise, go lookup the ${DOCKER_ENV_FILE} as ride-along source for volume definitions
        PORTS_LIST=`cat ${DOCKER_ENV_FILE}|grep "^#PORTS_LIST= *"|sed "s/[#\"]//g"|cut -d'=' -f2-`
    fi
    for pp in ${PORTS_LIST}; do
        #echo "$pp"
        port_pair=`echo $pp |  tr -d ' ' `
        if [ ! "$port_pair" == "" ]; then
            # -p ${local_dockerPort1}:${dockerPort1} 
            host_port=`echo $port_pair | tr -d ' ' | cut -d':' -f1`
            docker_port=`echo $port_pair | tr -d ' ' | cut -d':' -f2`
            PORT_MAP="${PORT_MAP} -p ${host_port}:${docker_port}"
        fi
    done
}
#### ---- Generate Port Mapping ----
generatePortMapping
echo "PORT_MAP=${PORT_MAP}"

###################################################
#### ---- Generate Environment Variables       ----
###################################################
ENV_VARS=
function generateEnvVars2() {
    key_list=`cat ${DOCKER_ENV_FILE} | grep -v "^#" |  grep -E "^[[:blank:]]*$1.+[[:blank:]]*=[[:blank:]]*.+[[:blank:]]*" |  awk 'BEGIN { FS = "=" } ; { print $1 }' `
    echo "key_list=$key_list"
    
    for key in ${key_list}; do
        echo ">>>> key=$key"
        value=`cat ${DOCKER_ENV_FILE} | grep -v "^#" |grep "$key" |  grep -E "^[[:blank:]]*$1.+[[:blank:]]*=[[:blank:]]*.+[[:blank:]]*" | awk 'BEGIN { FS = "=" } ; { k=$1; $1=""; print $0}' `
        echo "value=$value"
        #value_trim="${value##+([[:space:]])}"
        value_trim="`echo $value | sed 's/^[[:space:]]*//'`"
        echo "$key=${value_trim}" 
        ENV_VARS="${ENV_VARS} -e \"${key}=${value_trim}\""
    done
}
#generateEnvVars2
#echo ">> ENV_VARS=$ENV_VARS"

function generateEnvVars_v2() {
    while read line; do
        echo "Line=$line"
        key=${line%=*}
        value=${line#*=}
        key=$(eval echo $value)
        ENV_VARS="${ENV_VARS} -e ${line%=*}=$(eval echo $value)"
    done < <(grep -E "^[[:blank:]]*$1.+[[:blank:]]*=[[:blank:]]*.+[[:blank:]]*" ${DOCKER_ENV_FILE} | grep -v "^#")
    echo "ENV_VARS=$ENV_VARS"
}
generateEnvVars_v2
echo ">> ENV_VARS=$ENV_VARS"

function generateEnvVars() {
    if [ "${1}" != "" ]; then
        ## -- product key patterns, e.g., "^MYSQL_*"
        #productEnvVars=`grep -E "^[[:blank:]]*$1[a-zA-Z0-9_]+[[:blank:]]*=[[:blank:]]*[a-zA-Z0-9_]+[[:blank:]]*" ${DOCKER_ENV_FILE}`
        productEnvVars=`grep -E "^[[:blank:]]*$1.+[[:blank:]]*=[[:blank:]]*.+[[:blank:]]*" ${DOCKER_ENV_FILE} | grep -v "^#" | grep "${1}"`
    else
        ## -- product key patterns, e.g., "^MYSQL_*"
        #productEnvVars=`grep -E "^[[:blank:]]*$1[a-zA-Z0-9_]+[[:blank:]]*=[[:blank:]]*[a-zA-Z0-9_]+[[:blank:]]*" ${DOCKER_ENV_FILE}`
        productEnvVars=`grep -E "^[[:blank:]]*$1.+[[:blank:]]*=[[:blank:]]*.+[[:blank:]]*" ${DOCKER_ENV_FILE} | grep -v "^#"`
    fi
    ENV_VARS_STRING=""
    for vars in ${productEnvVars// /}; do
        debug "Entry => $vars"
        key=${vars%=*}
        value=${vars#*=}
        if [ "$1" != "" ]; then
            matched=`echo $vars|grep -E "${1}"`
            if [ ! "$matched" == "" ]; then
                ENV_VARS="${ENV_VARS} -e $key=$(eval echo $value)"
                #ENV_VARS="${ENV_VARS} ${vars}"
            fi
        else
            #ENV_VARS="${ENV_VARS} ${vars}"
            ENV_VARS="${ENV_VARS} -e $key=$(eval echo $value)"
        fi
    done
#    ## IFS default is "space tab newline" already
#    #IFS=',; ' read -r -a ENV_VARS_ARRAY <<< "${ENV_VARS_STRING}"
#    read -r -a ENV_VARS_ARRAY <<< "${ENV_VARS_STRING}"
#    # To iterate over the elements:
#    for element in "${ENV_VARS_ARRAY[@]}"
#    do
#        ENV_VARS="${ENV_VARS} -e ${element}"
#    done
#    if [ $DEBUG -gt 0 ]; then echo "ENV_VARS_ARRAY=${ENV_VARS_ARRAY[@]}"; fi
}
#generateEnvVars
#echo "ENV_VARS=${ENV_VARS}"

###################################################
#### ---- Setup Docker Build Proxy ----
###################################################
# export NO_PROXY="localhost,127.0.0.1,.openkbs.org"
# export HTTP_PROXY="http://gatekeeper-w.openkbs.org:80"
# when using "wget", add "--no-check-certificate" to avoid https certificate checking failures
# Note: You can also setup Docker CLI configuration file (~/.docker/config.json), e.g.
# {
#   "proxies": {
#     "default": {
#       "httpProxy": "http://gatekeeper-w.openkbs.org:80"
#       "httpsProxy": "http://gatekeeper-w.openkbs.org:80"
#      }
#    }
#  }
#
echo "... Setup Docker Run Proxy: ..."

PROXY_PARAM=
function generateProxyEnv() {
    if [ "${HTTP_PROXY}" != "" ]; then
        PROXY_PARAM="${PROXY_PARAM} -e HTTP_PROXY=${HTTP_PROXY}"
    fi
    if [ "${HTTPS_PROXY}" != "" ]; then
        PROXY_PARAM="${PROXY_PARAM} -e HTTPS_PROXY=${HTTPS_PROXY}"
    fi
    if [ "${NO_PROXY}" != "" ]; then
        PROXY_PARAM="${PROXY_PARAM} -e NO_PROXY=\"${NO_PROXY}\""
    fi
    if [ "${http_proxy}" != "" ]; then
        PROXY_PARAM="${PROXY_PARAM} -e http_proxy=${http_proxy}"
    fi
    if [ "${https_proxy}" != "" ]; then
        PROXY_PARAM="${PROXY_PARAM} -e https_proxy=${https_proxy}"
    fi
    if [ "${no_proxy}" != "" ]; then
        PROXY_PARAM="${PROXY_PARAM} -e no_proxy=\"${no_proxy}\""
    fi
    ENV_VARS="${ENV_VARS} ${PROXY_PARAM}"
}
generateProxyEnv
echo "ENV_VARS=${ENV_VARS}"

###################################################
#### ---- Function: Generate privilege String  ----
####      (Don't change!)
###################################################
privilegedString=""
function generatePrivilegedString() {
    OS_VER=`which yum`
    if [ "$OS_VER" == "" ]; then
        # Ubuntu
        echo "Ubuntu ... not SE-Lunix ... no privileged needed"
    else
        # CentOS/RHEL
        privilegedString="--privileged"
    fi
}
generatePrivilegedString
echo ${privilegedString}

###################################################
#### ---- Mostly, you don't need change below ----
###################################################
function cleanup() {
    containerID=`docker ps -a | grep "${instanceName}" | awk '{print $1}' `
    if [ "${containerID}" != "" ]; then
        docker rm -f ${containerID}
    fi
}

###################################################
#### ---- Display Host (Container) URL with Port ----
###################################################
function displayURL() {
    port=${1}
    echo "... Go to: http://${HOST_IP}:${port}"
    #firefox http://${HOST_IP}:${port} &
    if [ "`which google-chrome`" != "" ]; then
        /usr/bin/google-chrome http://${HOST_IP}:${port} &
    else
        firefox http://${HOST_IP}:${port} &
    fi
}

###################################################
#### ---- Replace "Key=Value" with new value   ----
###################################################
function replaceKeyValue() {
    inFile=${1:-${DOCKER_ENV_FILE}}
    keyLike=$2
    newValue=$3
    if [ "$2" == "" ]; then
        echo "**** ERROR: Empty Key value! Abort!"
        exit 1
    fi
    sed -i -E 's/^('$keyLike'[[:blank:]]*=[[:blank:]]*).*/\1'$newValue'/' $inFile
}
#### ---- Replace docker.env with local user's UID and GID ----
#replaceKeyValue ${DOCKER_ENV_FILE} "USER_ID" "$(id -u $USER)"
#replaceKeyValue ${DOCKER_ENV_FILE} "GROUP_ID" "$(id -g $USER)"

###################################################
#### ---- Get "Key=Value" withe new value ----
#### Usage: getKeyValuePair <inFile> <key>
#### Output: Key=Value
###################################################
KeyValuePair=""
function getKeyValuePair() {
    KeyValuePair=""
    inFile=${1:-${DOCKER_ENV_FILE}}
    keyLike=$2
    if [ "$2" == "" ]; then
        echo "**** ERROR: Empty Key value! Abort!"
        exit 1
    fi
    matchedKV=`grep -E "^[[:blank:]]*${keyLike}.+[[:blank:]]*=[[:blank:]]*.+[[:blank:]]*" ${DOCKER_ENV_FILE}`
    for kv in $matchedKV; do
        echo "KeyValuePair=${matchedKV// /}"
    done
}
#getKeyValuePair "${DOCKER_ENV_FILE}" "MYSQL_DATABASE"

## -- transform '-' and space to '_' 
#instanceName=`echo $(basename ${imageTag})|tr '[:upper:]' '[:lower:]'|tr "/\-: " "_"`
 instanceName=`echo $(basename ${imageTag})|tr '[:upper:]' '[:lower:]'|tr "/: " "_"`
echo "------------------------------------------->" $instanceName
################################################
##### ---- Product Specific Parameters ---- ####
################################################
#MYSQL_DATABASE=${MYSQL_DATABASE:-myDB}
#MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-password}
#MYSQL_USER=${MYSQL_USER:-user1}
#MYSQL_PASSWORD=${MYSQL_PASSWORD:-password}
#### ---- Generate Env. Variables ----
echo ${ENV_VARS}

echo "---------------------------------------------"
echo "---- Starting a Container for ${imageTag}"
echo "---------------------------------------------"

cleanup

echo "--------------------------------------------------------"
echo "==> Commands to manage Container:"
echo "--------------------------------------------------------"
echo "  ./shell.sh : to shell into the container"
echo "  ./stop.sh  : to stop the container"
echo "  ./log.sh   : to show the docker run log"
echo "  ./build.sh : to build the container"
echo "  ./commit.sh: to push the container image to docker hub"
echo "--------------------------------------------------------"

#################################
## ---- Detect Media/Sound: -- ##
#################################
MEDIA_OPTIONS=""
function detectMedia() {
    devices="/dev/snd /dev/dri"
    for device in $devices; do
        if [ -s $device ]; then
            # --device /dev/snd:/dev/snd
            if [ "${MEDIA_OPTIONS}" == "" ]; then
                MEDIA_OPTIONS=" --group-add audio --group-add video "
            fi
            # MEDIA_OPTIONS=" --group-add audio  --group-add video --device /dev/snd --device /dev/dri  "
            #MEDIA_OPTIONS="${MEDIA_OPTIONS} --device $device:$device"
            MEDIA_OPTIONS="${MEDIA_OPTIONS} --device $device"
        fi
    done
    echo "MEDIA_OPTIONS= ${MEDIA_OPTION}"
}
detectMedia

#################################
## -_-- Setup X11 Display -_-- ##
#################################
X11_OPTION=
function setupDisplayType() {
    if [[ "$OSTYPE" == "linux-gnu" ]]; then
        # ...
        xhost +SI:localuser:$(id -un) 
        xhost + 127.0.0.1
        echo ${DISPLAY}
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # Mac OSX
        # if you want to multi-media in MacOS, you need customize it here
        MEDIA_OPTIONS=""
        xhost + 127.0.0.1
        export DISPLAY=host.docker.internal:0
        echo ${DISPLAY}
    elif [[ "$OSTYPE" == "cygwin" ]]; then
        # POSIX compatibility layer and Linux environment emulation for Windows
        xhost + 127.0.0.1
        echo ${DISPLAY}
    elif [[ "$OSTYPE" == "msys" ]]; then
        # Lightweight shell and GNU utilities compiled for Windows (part of MinGW)
        xhost + 127.0.0.1
        echo ${DISPLAY}
    elif [[ "$OSTYPE" == "freebsd"* ]]; then
        # ...
        xhost + 127.0.0.1
        echo ${DISPLAY}
    else
        # Unknown.
        echo "Unknown OS TYPE: $OSTYPE! Not supported!"
        exit 9
    fi
    echo "DISPLAY=${DISPLAY}"
    echo 
}


##################################################
## ---- Setup Corporate Chain's Certificates -- ##
##################################################
CERTIFICATE_OPTIONS=
function setupCorporateCertificates() {
    cert_dir=`pwd`/certificates
    if [ -d ./certificates/ ]; then
            CERTIFICATE_OPTIONS="${CERTIFICATE_OPTIONS} -v ${cert_dir}:/certificates"
    fi
    echo "CERTIFICATE_OPTIONS=${CERTIFICATE_OPTIONS}"
}
setupCorporateCertificates

##################################################
##################################################
## ----------------- main --------------------- ##
##################################################
##################################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo -e ">>> (final) ENV_VARS=${ENV_VARS}"

set -x

MORE_OPTIONS="${MORE_OPTIONS} ${HOSTS_OPTIONS} "

            #${USER_OPTIONS} \

echo "GS output: BUILD_TYPE: " ${BUILD_TYPE} 
echo "             imageTag: " ${imageTag} 

#exit()


case "${BUILD_TYPE}" in
    0)
        #### 0: (default) has neither X11 nor VNC/noVNC container build image type
        #### ---- for headless-based / GUI-less ---- ####
        docker run \
            --name=${instanceName} \
            --restart=${RESTART_OPTION} \
            ${GPU_OPTION} \
            ${REMOVE_OPTION} ${RUN_OPTION} ${MORE_OPTIONS} ${CERTIFICATE_OPTIONS} \
            ${privilegedString} \
            ${ENV_VARS} \
            ${VOLUME_MAP} \
            ${PORT_MAP} \
            ${imageTag} \
            $@
       ;;
    1)
        #### 1: X11/Desktip container build image type
        #### ---- for X11-based ---- #### 
        setupDisplayType
        echo ${DISPLAY}
        #X11_OPTION="-e DISPLAY=$DISPLAY -v $HOME/.chrome:/data -v /dev/shm:/dev/shm -v /tmp/.X11-unix:/tmp/.X11-unix -e DBUS_SYSTEM_BUS_ADDRESS=unix:path=/host/run/dbus/system_bus_socket"
        #X11_OPTION="-e DISPLAY=$DISPLAY -v /dev/shm:/dev/shm -v /tmp/.X11-unix:/tmp/.X11-unix -e DBUS_SYSTEM_BUS_ADDRESS=unix:path=/var/run/dbus/system_bus_socket"
        X11_OPTION="-e DISPLAY=$DISPLAY -v /dev/shm:/dev/shm -v /tmp/.X11-unix:/tmp/.X11-unix"
        echo "X11_OPTION=${X11_OPTION}"
        docker run \
            --name=${instanceName} \
            --restart=${RESTART_OPTION} \
            ${GPU_OPTION} \
            ${MEDIA_OPTIONS} \
            ${REMOVE_OPTION} ${RUN_OPTION} ${MORE_OPTIONS} ${CERTIFICATE_OPTIONS} \
            ${X11_OPTION} \
            ${privilegedString} \
            ${USER_OPTIONS} \
            ${ENV_VARS} \
            ${VOLUME_MAP} \
            ${PORT_MAP} \
            ${imageTag} \
            $@
        ;;
    2)
        #### 2: VNC/noVNC container build image type
        #### ----------------------------------- ####
        #### -- VNC_RESOLUTION setup default --- ####
        #### ----------------------------------- ####
        if [ "`echo $ENV_VARS|grep VNC_RESOLUTION`" = "" ]; then
            #VNC_RESOLUTION=1280x1024
            VNC_RESOLUTION=1920x1080
            ENV_VARS="${ENV_VARS} -e VNC_RESOLUTION=${VNC_RESOLUTION}" 
        fi
        docker run \
            --name=${instanceName} \
            --restart=${RESTART_OPTION} \
            ${GPU_OPTION} \
            ${REMOVE_OPTION} ${RUN_OPTION} ${MORE_OPTIONS} ${CERTIFICATE_OPTIONS} \
            ${privilegedString} \
            ${USER_OPTIONS} \
            ${ENV_VARS} \
            ${VOLUME_MAP} \
            ${PORT_MAP} \
            ${imageTag} \
            $@
        ;;

esac


