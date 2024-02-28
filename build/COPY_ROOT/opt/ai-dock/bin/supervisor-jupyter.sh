#!/bin/bash

trap cleanup EXIT

function cleanup() {
    kill $(jobs -p) > /dev/null 2>&1
    fuser -k -SIGTERM ${LISTEN_PORT}/tcp > /dev/null 2>&1 &
    rm /run/http_ports/$PROXY_PORT > /dev/null 2>&1
}

function start() {
    source /opt/ai-dock/etc/environment.sh

    LISTEN_PORT=18888
    METRICS_PORT=${JUPYTER_METRICS_PORT:-28888}
    PROXY_SECURE=true
    QUICKTUNNELS=true
    
    if [[ ! -v JUPYTER_PORT || -z $JUPYTER_PORT ]]; then
        JUPYTER_PORT=${JUPYTER_PORT_HOST:-8888}
    fi
    PROXY_PORT=$JUPYTER_PORT
    
    if [[ ! -v JUPYTER_MODE || -z $JUPYTER_MODE ]]; then
        JUPYTER_MODE="notebook"
    fi
    if [[ $JUPYTER_MODE != "notebook" ]]; then
        JUPYTER_MODE="lab"
    fi
    
    SERVICE_NAME="Jupyter ${JUPYTER_MODE^}"
    
    if [[ ${SERVERLESS,,} = "true" ]]; then
        printf "Refusing to start $SERVICE_NAME service in serverless mode\n"
        exec sleep 10
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
    if [[ -f /run/workspace_sync ]]; then
        printf "Waiting for workspace sync...\n"
        /usr/bin/python3 /opt/ai-dock/fastapi/logviewer/main.py \
            -p $LISTEN_PORT \
            -r 3 \
            -s "${SERVICE_NAME}" \
            -t "Preparing ${SERVICE_NAME}" &
        fastapi_pid=$!
        
        while [[ -f /run/workspace_sync ]]; do
            sleep 1
        done
        
        kill $fastapi_pid &
        wait -n
    fi
    
    fuser -k -SIGKILL ${LISTEN_PORT}/tcp > /dev/null 2>&1 &
    wait -n
    
    # Allows running in user context when the home directory has non-standard permissions
    if [[ $WORKSPACE_MOUNTED == "true" && $WORKSPACE_PERMISSIONS == "false" ]]; then
        export JUPYTER_ALLOW_INSECURE_WRITES=true
    fi

    printf "\nStarting %s...\n" "${SERVICE_NAME:-service}"
    
    # Terminado shell_command needs fixing.
    # Bash alone invokes neither profile or bashrc.
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
            --ServerApp.root_dir=/ \
            --ServerApp.preferred_dir="$WORKSPACE" \
            --ServerApp.terminado_settings="{'shell_command': ['bash','-c','bash']}" \
            --KernelSpecManager.ensure_native_kernel=False
}

start 2>&1
