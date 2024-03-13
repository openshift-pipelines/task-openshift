#!/usr/bin/env bash

shopt -s inherit_errexit
set -eu -o pipefail

source "$(dirname ${BASH_SOURCE[0]})/common.sh"
source "$(dirname ${BASH_SOURCE[0]})/opc-common.sh"

[[ "${WORKSPACES_KUBECONFIG_DIR_BOUND}" == "true" ]] && \
[[ -f ${WORKSPACES_KUBECONFIG_DIR_PATH}/kubeconfig ]] && \
export KUBECONFIG=${WORKSPACES_KUBECONFIG_DIR_PATH}/kubeconfig

${PARAMS_SCRIPT}
