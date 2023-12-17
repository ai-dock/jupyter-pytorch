#!/bin/false

source /opt/ai-dock/etc/environment.sh
kernel_path=/usr/local/share/jupyter/kernels/

build_common_main() {
    build_common_install_jupyter
    build_common_install_ipykernel
}

build_common_install_jupyter() {
    $MAMBA_CREATE -n jupyter python=3.10
    $MAMBA_INSTALL -n jupyter \
        jupyter \
        jupyterlab \
        nodejs=18
    # This must remain clean. User software should not be in this environment
    printf "Removing default ipython kernel...\n"
    rm -rf /opt/micromamba/envs/jupyter/share/jupyter/kernels/python3
}

build_common_do_mamba_install() {
        $MAMBA_INSTALL -n "$1" -y \
            ipykernel \
            ipywidgets
}

build_common_do_kernel_install() {
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

build_common_install_ipykernel() {
    if [[ $PYTHON_VERSION != "all" ]]; then
        major=${PYTHON_VERSION:0:1}
        build_common_do_mamba_install "${PYTHON_MAMBA_NAME}"
        build_common_do_kernel_install "${PYTHON_MAMBA_NAME}" "${PYTHON_VERSION}" "python${major}" "Python${major} (ipykernel)"
    else
        # Multi Python - Use $PYTHON_MAMBA_NAME as default kernel
        
        build_common_do_mamba_install "python_310"
        if [[ $PYTHON_MAMBA_NAME = "python_310" ]]; then
            build_common_do_kernel_install "python_310" "3.10" "python3" "Python3 (ipykernel)"
        else
            build_common_do_kernel_install "python_310" "3.10"
        fi
        
        do_mamba_install "python_311"
        if [[ $PYTHON_MAMBA_NAME = "python_311" ]]; then
            build_common_do_kernel_install "python_311" "3.11" "python3" "Python3 (ipykernel)"
        else
            build_common_do_kernel_install "python_311" "3.11"
        fi
    fi
}

build_common_main "$@"