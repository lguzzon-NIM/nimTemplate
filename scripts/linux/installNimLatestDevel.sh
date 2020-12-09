#!/bin/bash

readonly lLinuxArchitecture=$(uname -m)
echo "lLinuxArchitecture ${lLinuxArchitecture}"
lArchitecture=${lLinuxArchitecture}
case ${lLinuxArchitecture} in
aarch64*)
    lArchitecture="arm64"
    ;;
x86_64*)
    lArchitecture="x64"
    ;;
esac
echo "lArchitecture ${lArchitecture}"

(hash curl 2>/dev/null || sudo apt -y install curl) &&
    (hash jq 2>/dev/null || sudo apt -y install jq) &&
    curl -o nim.tar.xz -sSL $(curl -sSL https://api.github.com/repos/nim-lang/nightlies/releases | jq -r "[ .[]?.assets[] | select(.browser_download_url | test(\"latest-devel/linux_$lArchitecture\")) | {updated_at, browser_download_url} ] | sort_by(.updated_at) | reverse | .[0].browser_download_url") &&
    rm -rf "$HOME/.nim" &&
    tar -xvf nim.tar.xz &&
    rm nim.tar.xz || true &&
    mv nim-* "$HOME/.nim" &&
    export PATH="$HOME/.nim/bin${PATH:+:$PATH}" &&
    echo "[ -d \"$HOME/.nim/bin\" ] && export PATH=\"$HOME/.nim/bin\${PATH:+:\$PATH}\"" >>"${HOME}/.bashrc" &&
    nim --version
