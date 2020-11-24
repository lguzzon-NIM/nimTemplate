#!/bin/bash

readonly lLinuxArchitecture=$(uname -m)
echo "${lLinuxArchitecture}"
lArchitecture=${lLinuxArchitecture}
case ${lLinuxArchitecture} in
aarch64*)
    lArchitecture="arm64"
    ;;
esac
echo ${lArchitecture}

(hash curl 2>/dev/null || sudo apt -y install curl) &&
    (hash jq 2>/dev/null || sudo apt -y install jq) &&
    curl -z nim.tar.xz -o nim.tar.xz -L $(curl -sSL https://api.github.com/repos/nim-lang/nightlies/releases | jq -r "[ .[]?.assets[] | select(.browser_download_url | test(\"latest-version-\")) | select(.browser_download_url | test(\"linux_$lArchitecture\")) | {updated_at, browser_download_url} ] | sort_by(.browser_download_url) | reverse | .[0].browser_download_url") &&
    rm -rf "$HOME/.nim" &&
    tar -xvf nim.tar.xz &&
    rm nim.tar.xz || true &&
    mv nim-* "$HOME/.nim" &&
    export PATH="$HOME/.nim/bin${PATH:+:$PATH}" &&
    echo "[ -d \"$HOME/.nim/bin\" ] && export PATH=\"$HOME/.nim/bin\${PATH:+:\$PATH}\"" >>"${HOME}/.bashrc" &&
    nim --version
