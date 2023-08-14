#!/bin/bash

trap 'kill $(jobs -p)' EXIT

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

printf "Starting Jupyter %s...\n" $JUPYTER_MODE

if [[ $CF_QUICK_TUNNELS = "true" ]]; then
    cloudflared tunnel --url localhost:${JUPYTER_PORT} > /var/log/supervisor/quicktunnel-jupyter.log 2>&1 &
fi

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
