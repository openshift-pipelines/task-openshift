#!/usr/bin/env bash

shopt -s inherit_errexit
set -eu -o pipefail

source "$(dirname ${BASH_SOURCE[0]})/common.sh"
source "$(dirname ${BASH_SOURCE[0]})/oc-common.sh"

[[ "$(workspaces.manifest_dir.bound)" == "true" ]] && \
      cd $(workspaces.manifest_dir.path)

[[ "$(workspaces.kubeconfig_dir.bound)" == "true" ]] && \
[[ -f $(workspaces.kubeconfig_dir.path)/kubeconfig ]] && \
export KUBECONFIG=$(workspaces.kubeconfig_dir.path)/kubeconfig

"${params.SCRIPT}"

