#!/bin/bash -x

#### ---------------------------------
#### --- PROGRAM_TYPE: py, java, js -- 
#### ---------------------------------
#### MANDATORY: ONLY choose one here
PROGRAM_TYPE="py"
#PROGRAM_TYPE="java"
#PROGRAM_TYPE="js"

# -------------------------------
# ----------- Usage -------------
# -------------------------------
# To test on host machine:
# Run the Application:
#   ./setup.sh
# -------------------------------
# -- debug use only --
verify=1

set -e
env

#### ---------------------------------
#### --- Process command arguments ---
#### ---------------------------------
#program_name=$(basename $0)
#function usage() {
#    echo -e "Usage: $program_name <APP_RUN_DIR> <APP_RUN_CMD>"
#}
#usage

# -- debug use only --
verify=1

#### ---------------------------
#### --- APP: LOCATION       ---
#### ---------------------------
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [[ "$DIR" =~ "/app" ]]; then
    APP_HOME=${APP_HOME:-${DIR}}
else
     # - find possilbe app directory: 
    APP_HOME=`realpath $(find ./ -name app)`
fi

echo "PWD=$PWD"

#### ---------------------------
#### --- APP: DATA Directory ---
#### ---------------------------
APP_DATA_DIR=${APP_DATA_DIR:-$HOME/data}

#### ---------------------------
#### --- APP: UTILITY        --- 
#### ---------------------------
function verifyDirectory() {
    if [ $verify -eq 0 ]; then
        return
    fi
    if [ "$1" = "" ] || [ ! -d "$1" ]; then
        echo "*** ERROR ***: NOT_EXISTING: App's mandatory directory: $1: Can't continue! Abort!"
        exit 1
    fi
}

function verifyFile() {
    if [ $verify -eq 0 ]; then
        return
    fi
    if [ "$1" != "" ] && [ ! -s "$1" ]; then
        echo "*** ERROR ***: NOT_FOUND: App's mandatory file: $1: Can't continue! Abort!"
        exit 1
    fi
}

function verifyCommand() {
    if [ $verify -eq 0 ]; then
        return
    fi
    if [ "$1" == "" ]; then
        return
    fi
    if [ ! `which $1` ]; then
        echo "*** ERROR ***: NOT_FOUND: App's mandatory tool: $1: Can't continue! Abort!"
        exit 1
    fi
}

function runCommands() {
    if [ $verify -eq 0 ]; then
        return
    fi
    CD_CMD=$1
    EXE_CMD=$2
    if [ "$1" != "" ] && [ -d "$1" ]; then
        cd $1
        shift
    fi
    if [ "$2" != "" ]; then
        /bin/bash -c "$*"
    fi
}

echo ">>>>>>>APP_RUN_CMD=$APP_RUN_CMD"
verifyCommand ${APP_RUN_CMD%% *}

# -------------------------------------------------------------------------------------

### --- APP: SETUP ---
#APP_HOME=${APP_HOME:-$HOME/app}
APP_HOME=${APP_HOME:-${DIR}}

### --- APP: RUN ---
APP_RUN_DIR=${APP_RUN_DIR:-$APP_HOME}
if [ "$PP_RUN_MAIN" != "" ]; then
    APP_RUN_MAIN_base=$(basename $APP_RUN_MAIN)
    APP_RUN_MAIN_dir=$(dirname $APP_RUN_MAIN)
    if [ ${APP_RUN_MAIN_dir} = "." ] || [ ${APP_RUN_MAIN_dir} = "" ]; then
        APP_RUN_MAIN_dir=${APP_RUN_DIR}
        echo "    >>>> APP_RUN_DIR=${APP_RUN_DIR}"
        echo "    >>>> APP_RUN_MAIN_dir=${APP_RUN_MAIN_dir}"
        echo "    >>>> APP_RUN_MAIN_base=${APP_RUN_MAIN_base}"
    fi
fi

if [ "$APP_RUN_CMD" = "" ]; then
    # Need to check APP_RUN_MAIN defined or not
    if [ "$APP_RUN_MAIN_base" = "" ]; then
        ## AUTO-detection/finding of runnable main program Need to detect main python as best efforts or error out
        #echo "*** ERROR: Neither APP_RUN_CMD nor APP_RUN_MAIN defined! Abort!"
        #exit 1
        # --- Auto detection and pick the first Python with main() to run --
        ABS_APP_DIR="${APP_RUN_DIR%app*}app" 
        echo "ABS_APP_DIR=$ABS_APP_DIR"
        FOUND_PROGRAM=`ls ${ABS_APP_DIR}/*.${PROGRAM_TYPE} | head -n 1 | awk '{print $1}' `
        if [ "$FOUND_PROGRAM" != "" ]; then
            APP_RUN_DIR=$(dirname $FOUND_PROGRAM)
            APP_RUN_MAIN=$FOUND_PROGRAM
            APP_RUN_CMD="python3 ${APP_RUN_MAIN}"
            echo ">>> Auto detect (in app/) APP_RUN_DIR : $APP_RUN_DIR"
            echo ">>> Auto detect (in app/) APP_RUN_MAIN: $APP_RUN_MAIN"
            echo ">>> Auto detect (in app/) APP_RUN_CMD : $APP_RUN_CMD"
        else
            echo "*** ERROR ***: FAIL: Can't find any Python to run! Abort"
            exit 1
        fi
    else
        echo "--> APP_RUN_MAIN_base: ${APP_RUN_MAIN_base} will be used to launch Python as main."
        echo ">>> Given (in .env) APP_RUN_DIR : $APP_RUN_DIR"
        echo ">>> Given (in .env) APP_RUN_MAIN: $APP_RUN_MAIN"
        echo ">>> Given (in .env) APP_RUN_CMD : $APP_RUN_CMD"
        APP_RUN_CMD="python3 ${APP_RUN_MAIN}"
    fi
else
    echo "--> APP_RUN_CMD: ${APP_RUN_CMD} will be used to launch Python as main."
    echo ">>> Given (in .env) APP_RUN_DIR : $APP_RUN_DIR"
    echo ">>> Given (in .env) APP_RUN_MAIN: $APP_RUN_MAIN"
    echo ">>> Given (in .env) APP_RUN_CMD : $APP_RUN_CMD"
fi

verifyDirectory $APP_HOME
verifyDirectory $APP_RUN_DIR
verifyFile $APP_RUN_MAIN

#### ---- Application ----
cd ${APP_RUN_DIR} 
ls -al 

#### ---- RUN Application ----
## e.g. Java Jar file
## cd ${APP_HOME}/dist && java -jar my_jar.jar
runCommands ${APP_RUN_DIR} ${APP_RUN_CMD}

