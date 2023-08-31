#!/bin/bash

if [[ -f /run/provisioning_script ]]; then
    printf "** The container is still being provisioned **\n\n"
    printf "Your service will start automatically - Check the logs for progress (logtail.sh)\n\n"
elif [[ -z $1 ]]; then
    printf "Please specify a service to start\n\n"
else
    supervisorctl start $1
fi