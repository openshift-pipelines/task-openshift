#!/usr/bin/env bash

shopt -s inherit_errexit
set -eu -o pipefail

source "$(dirname ${BASH_SOURCE[0]})/common.sh"
source "$(dirname ${BASH_SOURCE[0]})/oc-common.sh"

[[ "${WORKSPACES_MANIFEST_DIR_BOUND}" == "true" ]] && \
      cd ${WORKSPACES_MANIFEST_DIR_PATH}

[[ "${WORKSPACES_KUBECONFIG_DIR_BOUND}" == "true" ]] && \
[[ -f ${WORKSPACES_KUBECONFIG_DIR_PATH}/kubeconfig ]] && \
export KUBECONFIG=${WORKSPACES_KUBECONFIG_DIR_PATH}/kubeconfig

eval "${PARAMS_SCRIPT}"

