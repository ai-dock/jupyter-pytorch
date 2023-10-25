#!/bin/bash

if [[ -f /run/container_config || -f /run/workspace_sync ]]; then
    printf "** The container is still being prepared **\n\n"
    printf "Your service will start automatically - Check the logs for progress (logtail.sh)\n\n"
elif [[ -z $1 ]]; then
    printf "Please specify a service to start\n\n"
else
    supervisorctl start $1
fi