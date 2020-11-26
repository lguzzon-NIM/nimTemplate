#!/bin/bash

(hash curl || sudo apt -y install curl) &&
    (hash jq || sudo apt -y install jq) &&
    curl -o zig.tar.xz -sSL "$(curl -slL "https://ziglang.org/download/index.json" |
        jq -r ".master[\"$(uname -m)-linux\"].tarball")" &&
    tar -xvf zig.tar.xz &&
    rm zig.tar.xz || true &&
    mv zig-linux-$(uname -m)* "$HOME/.zig" &&
    export PATH="$HOME/.zig${PATH:+:$PATH}" &&
    echo "export PATH=\"\$HOME/.zig\${PATH:+:\$PATH}\"" >>"${HOME}/.bashrc" &&
    zig version
