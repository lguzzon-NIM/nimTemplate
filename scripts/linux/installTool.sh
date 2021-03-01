#!/usr/bin/env bash

# Common Script Header Begin
# Tips: all the quotes  --> "'`
# Tips: other chars --> ~

trap ctrl_c INT

readonly UNAME_S=$(uname -s)

function ctrl_c() {
  echo "** Trapped CTRL-C"
  [[ -z "$(jobs -p)" ]] || kill "$(jobs -p)"
}

readlink_() {
  if [[ $UNAME_S == "Darwin" ]]; then
    (which greadlink >/dev/null 2>&1 || brew install coreutils >/dev/null 2>&1)
    greadlink "$@"
  else
    readlink "$@"
  fi
}

function getScriptDir() {
  local lScriptPath="$1"
  local ls
  local link
  # Need this for relative symlinks.
  while [ -h "${lScriptPath}" ]; do
    ls="$(ls -ld "${lScriptPath}")"
    link="$(expr "${ls}" : '.*-> \(.*\)$')"
    if expr "${link}" : '/.*' >/dev/null; then
      lScriptPath="${link}"
    else
      lScriptPath="$(dirname "${lScriptPath}")/${link}"
    fi
  done
  readlink_ -f "${lScriptPath%/*}"
}

readonly current_dir="$(pwd)"
readonly script_path="$(readlink_ -f "${BASH_SOURCE[0]}")"
readonly script_dir="$(getScriptDir "${script_path}")"
readonly script_file="$(basename "${script_path}")"
readonly script_name="${script_file%\.*}"
readonly script_ext="$([[ ${script_file} == *.* ]] && echo ".${script_file##*.}" || echo '')"

# Common Script Header End

# Script Begin

readonly lcCordovaApk="cordova/platforms/android/app/build/outputs/apk"

architectureOs() {
  uname -m
}

architectureNim() {
  local -r lLinuxArchitecture=$(architectureOs)
  local lArchitecture=${lLinuxArchitecture}
  case ${lLinuxArchitecture} in
    aarch64*)
      lArchitecture="arm64"
      ;;
    x86_64*)
      lArchitecture="x64"
      ;;
  esac
  echo "${lArchitecture}"
}

urlNimDevel() {
  local -r lArchitecture=$(architectureNim)
  curl -sSL https://api.github.com/repos/nim-lang/nightlies/releases | jq -r "[ .[]?.assets[] | select(.browser_download_url | test(\"latest-devel/linux_${lArchitecture}\")) | {updated_at, browser_download_url} ] | sort_by(.updated_at) | reverse | .[0].browser_download_url"
}

urlNimVersion() {
  local -r lArchitecture=$(architectureNim)
  curl -sSL https://api.github.com/repos/nim-lang/nightlies/releases | jq -r "[ .[]?.assets[] | select(.browser_download_url | test(\"latest-version-\")) | select(.browser_download_url | test(\"linux_$lArchitecture\")) | {updated_at, browser_download_url} ] | sort_by(.browser_download_url) | reverse | .[0].browser_download_url"
}

nim_i() {
  local -r APPS_DIR_NAME=APPs
  local -r APPS_PATH="${HOME}/${APPS_DIR_NAME}"
  [ -d "/data" ] && APPS_PATH="/data/${APPS_DIR_NAME}"
  echo "APPS_PATH [${APPS_PATH}]"
  mkdir -p "${APPS_PATH}"
  local -r TOOL_NAME="NIM"
  local -r TOOL_URL="${1:-$(urlNimDevel)}"
  local -r APP_PATH="$APPS_PATH/nim"
  local -r BASHRC_PATH="${HOME}/.bashrc"
  (hash curl 2>/dev/null || sudo apt -y install curl) \
    && (hash jq 2>/dev/null || sudo apt -y install jq) \
    && curl -o nim.tar.xz -sSL "${TOOL_URL}" \
    && (rm -rf "$(dirname "$(dirname "$(which nim)")")" 2>/dev/null \
      || rm -rf "$APP_PATH" 2>/dev/null \
      || true) \
    && tar -xvf nim.tar.xz \
    && rm nim.tar.xz || true \
    && mv nim-* "$APP_PATH" \
    && export PATH="$APP_PATH/bin${PATH:+:$PATH}" \
    && sed "/### +++ ${TOOL_NAME} +++ ###/,/### --- ${TOOL_NAME} --- ###/d" -i "$BASHRC_PATH" \
    && {
      echo "### +++ ${TOOL_NAME} +++ ###"
      echo "[ -d \"$APP_PATH/bin\" ] && export PATH=\"$APP_PATH/bin\${PATH:+:\$PATH}\""
      echo "### --- ${TOOL_NAME} --- ###"
    } >>"$BASHRC_PATH" \
    && which nin \
    && nim --version
}

shfmt_i() {
  local -r APPS_DIR_NAME=APPs
  local -r APPS_PATH="${HOME}/${APPS_DIR_NAME}"
  [ -d "/data" ] && APPS_PATH="/data/${APPS_DIR_NAME}"
  echo "APPS_PATH [${APPS_PATH}]"
  mkdir -p "${APPS_PATH}"
  local -r lLinuxArchitecture=$(architectureOs)
  local lArchitecture=${lLinuxArchitecture}
  case ${lLinuxArchitecture} in
    aarch64*)
      lArchitecture="arm64"
      ;;
    x86_64*)
      lArchitecture="amd64"
      ;;
  esac
  local -r lGitHubUser="mvdan"
  local -r lGitHubRepo="sh"
  local -r lGitHubApp="shfmt"
  local -r lGitHubAppPath="${script_dir}/${lGitHubApp}"
  local -r lGitHubUserRepo="${lGitHubUser}/${lGitHubRepo}"
  local -r lGitHubAppLatestRelease=$(curl -fsSL -H 'Accept: application/json' "https://github.com/${lGitHubUserRepo}/releases/latest")
  local -r lGitHubAppLatestReleaseVersion=$(echo "${lGitHubAppLatestRelease}" | sed -e 's/.*"tag_name":"\([^"]*\)".*/\1/')
  local -r lBin="/usr/local/bin/"
  local -r APP_PATH="$APPS_PATH/$lGitHubApp"
  local -r BASHRC_PATH="${HOME}/.bashrc"
  mkdir -p "$APP_PATH" \
    && (hash curl 2>/dev/null || sudo apt -y install curl) \
    && curl -o "${lGitHubAppPath}" -fsSL "https://github.com/${lGitHubUserRepo}/releases/download/${lGitHubAppLatestReleaseVersion}/${lGitHubApp}_${lGitHubAppLatestReleaseVersion}_linux_${lArchitecture}" \
    && chmod +x "${lGitHubAppPath}" \
    && mv "${lGitHubAppPath}" "$APP_PATH" \
    && export PATH="$APP_PATH${PATH:+:$PATH}" \
    && sed "/### +++ ${lGitHubApp} +++ ###/,/### --- ${lGitHubApp} --- ###/d" -i "$BASHRC_PATH" \
    && {
      echo "### +++ ${lGitHubApp} +++ ###"
      echo "[ -d \"$APP_PATH\" ] && export PATH=\"$APP_PATH\${PATH:+:\$PATH}\""
      echo "### --- ${lGitHubApp} --- ###"
    } >>"$BASHRC_PATH" \
    && which ${lGitHubApp} \
    && ${lGitHubApp} -version
  return $?
}

main() {
  local -r helpString=$(printf '%s\n%s' "Help, valid options are :" "$(tr "\n" ":" <"${script_path}" | grep -o '# Commands start here:.*# Commands finish here' | tr ":" "\n" | grep -o '^ *\-[^)]*)' | sed 's/.$//' | sed 's/^ *//' | sed 's/^\(.\)/    \1/' | sort)")
  if [[ $# -gt 0 ]]; then
    local lOption
    while [ "$#" -gt 0 ]; do
      lOption=$(tr ':' '_' <<<"$1")
      case $lOption in
        # Commands start here
        -h | --help) echo "${helpString}" ;;
        -t | --test)
          echo "$@"
          break
          ;;
        -archNim | --architectureNim) architectureNim ;;
        -archOs | --architectureOs) architectureOs ;;
        -urlNimDevel | --urlNimDevel) urlNimDevel ;;
        -urlNimVersion | --urlNimVersion) urlNimVersion ;;
        -nim_i | --nimInstall) nim_i ;;
        -shfmt_i | --shfmtInstall) shfmt_i ;;
        # Commands finish here
        *)
          echo "Error: can't understand --> $lOption <-- as option/parameter"
          echo "${helpString}"
          return 1
          ;;
      esac
      shift
    done
  else
    echo "${helpString}"
    return 1
  fi
  # set +x
  return $?
}

main "$@"
exit $?

# Script End
