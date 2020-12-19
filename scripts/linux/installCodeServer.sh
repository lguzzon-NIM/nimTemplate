#!/bin/bash

export APPS_DIR_NAME=APPs
export APPS_PATH="${HOME}/${APPS_DIR_NAME}"
[ -d "/data" ] && APPS_PATH="/data/${APPS_DIR_NAME}"
echo "APPS_PATH [${APPS_PATH}]"
mkdir -p "${APPS_PATH}"

# curl -fsSL https://code-server.dev/install.sh | sh -s -- --prefix "${APPS_PATH}" --dry-run 
curl -fsSL https://code-server.dev/install.sh | sh -s -- --prefix "${APPS_PATH}"
which code-server && ls -la "$(which code-server)"
cd "${HOME}" || exit 1
PASSWORD=rat1onaL code-server --auth password --bind-addr 0.0.0.0:443 --cert --disable-telemetry &
