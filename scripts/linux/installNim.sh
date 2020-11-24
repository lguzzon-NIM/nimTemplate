#!/bin/bash

(hash curl 2>/dev/null || sudo apt -y install curl) &&
    curl https://nim-lang.org/choosenim/init.sh -sSf | CHOOSE_VERSION=devel sh -s -- -y &&
    export PATH="$HOME/.nimble/bin${PATH:+:$PATH}" &&
    echo "export PATH=\"\$HOME/.nimble/bin\${PATH:+:\$PATH}\"" >>"${HOME}/.bashrc" &&
    nim --version
