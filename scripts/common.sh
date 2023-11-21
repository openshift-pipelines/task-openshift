#!/usr/bin/env bash

# tekton's home directory
declare -rx TEKTON_HOME="${TEKTON_HOME:-/tekton/home}"

#
# Functions
#

function fail() {
    echo "ERROR: ${*}" 2>&1
    exit 1
}

function phase() {
    echo "---> Phase: ${*}..."
}

# assert local variables are exporeted on the environment
function exported_or_fail() {
    declare -a _required_vars="${@}"

    for v in ${_required_vars[@]}; do
        [[ -z "${!v}" ]] &&
            fail "'${v}' environment variable is not set!"
    done

    return 0
}

