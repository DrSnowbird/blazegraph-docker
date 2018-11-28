#!/bin/bash -x

set -e

printenv

function waitNotDone() {
    while [ "1" -gt 0 ]; do
        sleep 3600
    done
}
if [ "$1" == "start" ] || [ "$1" == "" ]; then
    exec ${PRODUCT_FULL_PATH_EXE} "start"
    waitNotDone
else if [ "$1" == "stop" ]; then
    exec ${PRODUCT_FULL_PATH_EXE} "stop"
    waitNotDone
else if [ "$1" == "restart" ]; then
    exec ${PRODUCT_FULL_PATH_EXE} "restart"
    waitNotDone
else
    exec "$@"
fi
fi
fi

