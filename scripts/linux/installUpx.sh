#!/bin/bash

(hash curl || sudo apt -y install curl) &&
    (hash git || sudo apt -y install git)
readonly lUPXVersion=$(git ls-remote --tags "https://github.com/upx/upx.git" |
    awk '{print $2}' |
    grep -v '{}' |
    awk -F"/" '{print $3}' |
    tail -1 |
    sed "s/v//g")
echo "${lUPXVersion}"
readonly lLinuxArchitecture=$(uname -m)
echo "${lLinuxArchitecture}"
lArchitecture=${lLinuxArchitecture}
case ${lLinuxArchitecture} in
aarch64*)
    lArchitecture="arm64"
    ;;
esac
echo ${lArchitecture}

readonly lUpxUrl="https://github.com/upx/upx/releases/download/v${lUPXVersion}/upx-${lUPXVersion}-${lArchitecture}_linux.tar.xz"
echo "${lUpxUrl}"
curl -z upx.tar.xz -o upx.tar.xz -L "${lUpxUrl}" &&
    tar -xvf upx.tar.xz &&
    rm upx.tar.xz || true &&
    rm -rf "${HOME}/.upx" || true &&
    mv "upx-${lUPXVersion}-${lArchitecture}_linux" "${HOME}/.upx" &&
    export PATH="$HOME/.upx${PATH:+:$PATH}" &&
    echo "export PATH=\"\$HOME/.upx\${PATH:+:\$PATH}\"" >>"${HOME}/.bashrc" &&
    upx --version
