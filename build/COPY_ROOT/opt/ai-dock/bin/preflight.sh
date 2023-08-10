#!/bin/bash

function main() {
    write_bashrc
}

function write_bashrc() {
    a='alias jupyter="micromamba run -n jupyter jupyter"'
    printf "%s\n" "$a" >> /root/.bashrc
}

main "$@"; exit