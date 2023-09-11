#!/bin/bash

trap cleanup EXIT

function cleanup() {
    kill $(jobs -p) > /dev/null 2>&1
    rm /run/http_ports/$PORT > /dev/null 2>&1
}

if [[ -z $JUPYTER_MODE || ! "$JUPYTER_MODE" = "notebook" ]]; then
    JUPYTER_MODE="lab"
fi

if [[ -z $JUPYTER_PORT ]]; then
    JUPYTER_PORT=8888
fi

# Deal with providers who clobber the token
if [[ -n $JUPYTER_PASSWORD ]]; then
    export JUPYTER_TOKEN="${JUPYTER_PASSWORD}"
fi

PORT=$JUPYTER_PORT
METRICS_PORT=1888
SERVICE_NAME="Jupyter ${JUPYTER_MODE^}"

printf "{\"port\": \"$PORT\", \"metrics_port\": \"$METRICS_PORT\", \"service_name\": \"$SERVICE_NAME\"}" > /run/http_ports/$PORT

printf "Starting Jupyter %s...\n" ${JUPYTER_MODE^}

micromamba run -n jupyter jupyter \
    $JUPYTER_MODE \
    --allow-root \
    --ip=0.0.0.0 \
    --port=$JUPYTER_PORT \
    --no-browser \
    --ServerApp.trust_xheaders=True \
    --ServerApp.disable_check_xsrf=False \
    --ServerApp.allow_remote_access=True \
    --ServerApp.allow_origin='*' \
    --ServerApp.allow_credentials=True \
    --ServerApp.root_dir=$WORKSPACE \
    --ServerApp.preferred_dir=$WORKSPACE \
    --KernelSpecManager.ensure_native_kernel=False

