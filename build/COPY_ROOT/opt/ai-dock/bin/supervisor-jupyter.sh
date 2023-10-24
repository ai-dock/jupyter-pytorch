#!/bin/bash

trap cleanup EXIT

LISTEN_PORT=18888
METRICS_PORT=28888
PROXY_SECURE=true

function cleanup() {
    kill $(jobs -p) > /dev/null 2>&1
    rm /run/http_ports/$PROXY_PORT > /dev/null 2>&1
}

function start() {
    if [[ -z $JUPYTER_MODE || ! "$JUPYTER_MODE" = "notebook" ]]; then
        JUPYTER_MODE="lab"
    fi
    
    if [[ -z $JUPYTER_PORT ]]; then
        JUPYTER_PORT=8888
    fi
    
    PROXY_PORT=$JUPYTER_PORT
    SERVICE_NAME="Jupyter ${JUPYTER_MODE^}"
    
    if [[ ${SERVERLESS,,} = "true" ]]; then
        printf "Refusing to start $SERVICE_NAME service in serverless mode\n"
        exit 0
    fi
    
    file_content="$(
      jq --null-input \
        --arg listen_port "${LISTEN_PORT}" \
        --arg metrics_port "${METRICS_PORT}" \
        --arg proxy_port "${PROXY_PORT}" \
        --arg proxy_secure "${PROXY_SECURE,,}" \
        --arg service_name "${SERVICE_NAME}" \
        '$ARGS.named'
    )"
    
    printf "%s" "$file_content" > /run/http_ports/$PROXY_PORT
    
    # Delay launch until micromamba is ready
    if [[ -f /run/workspace_moving ]]; then
        /usr/bin/python3 /opt/ai-dock/fastapi/logviewer/main.py \
            -p $LISTEN_PORT \
            -r 5 \
            -s "${SERVICE_NAME}" \
            -t "Preparing ${SERVICE_NAME}" &
        fastapi_pid=$!
        
        while [[ -f /run/workspace_moving ]]; do
            sleep 1
        done
        
        printf "\nStarting %s... " ${SERVICE_NAME:-service}
        kill $fastapi_pid &
        wait -n
        printf "OK\n"
    else
        printf "Starting %s...\n" ${SERVICE_NAME}
    fi
    
    kill -9 $(lsof -t -i:$LISTEN_PORT) > /dev/null 2>&1 &
    wait -n
    
    printf "Starting Jupyter %s...\n" ${JUPYTER_MODE^}
    
    micromamba run -n jupyter jupyter \
        $JUPYTER_MODE \
        --allow-root \
        --ip=127.0.0.1 \
        --port=$LISTEN_PORT \
        --no-browser \
        --ServerApp.token='' \
        --ServerApp.password='' \
        --ServerApp.trust_xheaders=True \
        --ServerApp.disable_check_xsrf=False \
        --ServerApp.allow_remote_access=True \
        --ServerApp.allow_origin='*' \
        --ServerApp.allow_credentials=True \
        --ServerApp.root_dir=$WORKSPACE \
        --ServerApp.preferred_dir=$WORKSPACE \
       --KernelSpecManager.ensure_native_kernel=False
}

start 2>&1
