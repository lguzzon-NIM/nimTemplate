#!/usr/bin/env bash
set -e
set -o pipefail
set -o xtrace

function getScriptDir() {
  local lScriptPath="$1"
  # Need this for relative symlinks.
  while [ -h "$lScriptPath" ]; do
    ls=$(ls -ld "$lScriptPath")
    link=$(expr "$ls" : '.*-> \(.*\)$')
    if expr "$link" : '/.*' >/dev/null; then
      lScriptPath="$link"
    else
      lScriptPath=$(dirname "$lScriptPath")"/$link"
    fi
  done
  readlink -f "${lScriptPath%/*}"
}

# readonly current_dir=$(pwd)
# readonly script_path=$(readlink -f "${0}")
# readonly script_dir=$(getScriptDir "${script_path}")

readonly sudoCmd="sudo -E"
readonly aptGetCmd="${sudoCmd} DEBIAN_FRONTEND=noninteractive apt-get -y -qq"
readonly aptGetInstallCmd="${aptGetCmd} install"

#Before Install
if [ -z ${USE_GCC+x} ]; then
  export USE_GCC="9"
fi
if [ -z ${NIM_VERBOSITY+x} ]; then
  export NIM_VERBOSITY=0
fi

if [ -z ${NIM_TAG_SELECTOR+x} ]; then
  export NIM_TAG_SELECTOR=devel
fi

if [ -z ${DISPLAY+x} ]; then
  export DISPLAY=":99.0"
fi

installRepositoryIfNotPresent() {
  local -r lPPAName="$1"
  local lResult=1
  export lResult
  while IFS= read -r -d '' APT; do
    while read -r ENTRY; do
      echo "${ENTRY}" | grep "${lPPAName}"
      lResult=$?
      if [[ ${lResult} -eq 0 ]]; then
        break
      fi
    done < <(grep -o '^deb http://ppa.launchpad.net/[a-z0-9\-]\+/[a-z0-9\-]\+' "${APT}")
    # https://superuser.com/questions/688882/how-to-test-if-a-variable-is-equal-to-a-number-in-shell
    if [[ ${lResult} -eq 0 ]]; then
      break
    fi
  done < <(find /etc/apt/ -name \*.list -print0)
  if [[ ${lResult} -eq 1 ]]; then
    installIfNotPresent software-properties-common
    retryCmd "$sudoCmd" add-apt-repository -y "ppa:${lPPAName}" \
      && retryCmd "${aptGetCmd}" update
    lResult=$?
  fi
  return ${lResult}
}

installIfNotPresent() {
  local -r lPackageName="$1"
  local -r lPreCommandToRun="${2:-true}"
  local -r lPostCommandToRun="${3:-true}"
  local lResult=0
  if [[ $(dpkg-query -W -f='${Status}' "${lPackageName}" 2>/dev/null | grep -c "ok installed") -eq 0 ]]; then
    eval "${lPreCommandToRun}" \
      && retryCmd "${aptGetInstallCmd}" "${lPackageName}" \
      && eval "${lPostCommandToRun}"
    lResult=$?
  fi
  return ${lResult}
}

patchUdev() {
  if [[ -f "/etc/init.d/udev" ]]; then
    # shellcheck disable=1004,2143
    [ ! "$(grep -A1 '### END INIT INFO' /etc/init.d/udev | grep 'dpkg --configure -a || exit 0')" ] \
      && sudo -E sed -i 's/### END INIT INFO/### END INIT INFO\
dpkg --configure -a || exit 0/' /etc/init.d/udev
  fi
  return 0
}

waitLock() {
  while sudo -E fuser /var/{lib/{dpkg,apt/lists},cache/apt/archives}/lock >/dev/null 2>&1; do
    sleep $((RANDOM % 5 + 2))
  done
  return 0
}

retryCmd() {
  max_retry=10
  counter=0
  result=0
  set +e
  until waitLock && $@; do
    sleep $((RANDOM % 5 + 1 + counter))
    if [[ $counter -eq $max_retry ]] && echo "Failed!"; then
      result=1
      break
    fi
    ((counter++))
  done
  set -e
  return $result
}

retryCmd "${aptGetCmd}" update

patchUdev
installRepositoryIfNotPresent "ubuntu-toolchain-r/test"
installIfNotPresent "gcc-${USE_GCC}"
installIfNotPresent "g++-${USE_GCC}"
installIfNotPresent "git"

retryCmd "$sudoCmd" update-alternatives --install /usr/bin/gcc gcc "/usr/bin/gcc-${USE_GCC}" 10
retryCmd "$sudoCmd" update-alternatives --install /usr/bin/g++ g++ "/usr/bin/g++-${USE_GCC}" 10
retryCmd "$sudoCmd" update-alternatives --set gcc "/usr/bin/gcc-${USE_GCC}"
retryCmd "$sudoCmd" update-alternatives --set g++ "/usr/bin/g++-${USE_GCC}"

if [ -n "$CI" ]; then
  retryCmd "${aptGetCmd}" clean
  retryCmd "${aptGetCmd}" autoremove
fi

gcc --version

#Install

installIfNotPresent jq
source $(dirname "$0")/installUpx.sh
if [ "$NIM_TAG_SELECTOR" = "devel" ]; then
  source $(dirname "$0")/installNim.sh
else
  source $(dirname "$0")/travisNim.sh
fi
source $(dirname "$0")/installZig.sh

if [[ ${NIM_TARGET_OS} == "windows" ]]; then
  echo "------------------------------------------------------------ targetOS: ${NIM_TARGET_OS}"

  retryCmd "${sudoCmd}" dpkg --add-architecture i386
  retryCmd "${aptGetCmd}" update
  installIfNotPresent mingw-w64
  installIfNotPresent wine32
  installIfNotPresent wine32-development
  installIfNotPresent wine64
  installIfNotPresent wine64-development

  export WINEPREFIX
  WINEPREFIX="$(pwd)/.wineNIM-${NIM_TARGET_CPU}"

  if [[ ${NIM_TARGET_CPU} == "i386" ]]; then
    echo "------------------------------------------------------------ targetCPU: ${NIM_TARGET_CPU}"
    export WINEARCH=win32
    {
      echo i386.windows.gcc.path = \"/usr/bin\"
      echo i386.windows.gcc.exe = \"i686-w64-mingw32-gcc\"
      echo i386.windows.gcc.linkerexe = \"i686-w64-mingw32-gcc\"
      echo gcc.options.linker = \"\"
    } >nim.cfg
  else
    echo "------------------------------------------------------------ targetCPU: ${NIM_TARGET_CPU}"
    export WINEARCH=win64
    if [[ ${NIM_TARGET_CPU} == "amd64" ]]; then
      {
        echo amd64.windows.gcc.path = \"/usr/bin\"
        echo amd64.windows.gcc.exe = \"x86_64-w64-mingw32-gcc\"
        echo amd64.windows.gcc.linkerexe = \"x86_64-w64-mingw32-gcc\"
        echo gcc.options.linker = \"\"
      } >nim.cfg
    fi
  fi
  wine hostname
else
  if [[ ${NIM_TARGET_OS} == "linux" ]]; then
    echo "------------------------------------------------------------ targetOS: ${NIM_TARGET_OS}"
    if [[ ${NIM_TARGET_CPU} == "i386" ]]; then
      echo "------------------------------------------------------------ targetCPU: ${NIM_TARGET_CPU}"
      installIfNotPresent gcc-${USE_GCC}-multilib
      installIfNotPresent g++-${USE_GCC}-multilib
      installIfNotPresent gcc-multilib
      installIfNotPresent g++-multilib
    fi
  fi
fi

#Before Script

#Script
nim NInstallDeps
nim CTest release
