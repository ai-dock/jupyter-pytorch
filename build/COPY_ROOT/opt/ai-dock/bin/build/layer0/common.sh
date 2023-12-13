#!/bin/bash

# Must exit and fail to build if any command fails
set -eo pipefail

kernel_path=/usr/local/share/jupyter/kernels/

main() {
    install_jupyter
    install_ipykernel
}

install_jupyter() {
    $MAMBA_CREATE -n jupyter -c defaults python=3.10
    micromamba -n jupyter install -c defaults -y \
        jupyter \
        jupyterlab \
        nodejs=18
    # This must remain clean. User software should not be in this environment
    printf "Removing default ipython kernel...\n"
    rm -rf /opt/micromamba/envs/jupyter/share/jupyter/kernels/python3
}

do_mamba_install() {
        $MAMBA_INSTALL -n "$1" -c defaults -y \
            ipykernel \
            ipywidgets
}

do_kernel_install() {
    if [[ -n $4 ]]; then
        # Add a clone, probably the often-present Python3 (ipykernel) pointed to our default python install
        dir="${kernel_path}${3}/"
        file="${dir}kernel.json"
        cp -rf ${kernel_path}../_template ${dir}
            
        sed -i 's/DISPLAY_NAME/'"$4"'/g' ${file}
        sed -i 's/PYTHON_MAMBA_NAME/'"$1"'/g' ${file}
    fi
    dir="${kernel_path}$1/"
    file="${dir}kernel.json"
    cp -rf ${kernel_path}../_template ${dir}
    
    sed -i 's/DISPLAY_NAME/'"Python $2"'/g' ${file}
    sed -i 's/PYTHON_MAMBA_NAME/'"$1"'/g' ${file}
}

install_ipykernel() {
    if [[ $PYTHON_VERSION != "all" ]]; then
        major=${PYTHON_VERSION:0:1}
        do_mamba_install "${PYTHON_MAMBA_NAME}"
        do_kernel_install "${PYTHON_MAMBA_NAME}" "${PYTHON_VERSION}" "python${major}" "Python${major} (ipykernel)"
    else
        # Multi Python - Use $PYTHON_MAMBA_NAME as default kernel
        
        do_mamba_install "python_310"
        if [[ $PYTHON_MAMBA_NAME = "python_310" ]]; then
            do_kernel_install "python_310" "3.10" "python3" "Python3 (ipykernel)"
        else
            do_kernel_install "python_310" "3.10"
        fi
        
        do_mamba_install "python_311"
        if [[ $PYTHON_MAMBA_NAME = "python_311" ]]; then
            do_kernel_install "python_311" "3.11" "python3" "Python3 (ipykernel)"
        else
            do_kernel_install "python_311" "3.11"
        fi
        
        do_mamba_install "python_312"
        if [[ $PYTHON_MAMBA_NAME = "python_312" ]]; then
            do_kernel_install "python_312" "3.12" "python3" "Python3 (ipykernel)"
        else
            do_kernel_install "python_312" "3.12"
        fi
    fi
}

main "$@"; exit