#!/usr/bin/env bash
#
# Renders and copies documentation files into the informed RELEASE_DIR, the script search for
# task templates on a specific glob expression. The templates are rendered using the actual
# task name and documentation is searched for and copied over to the task release directory.
#

shopt -s inherit_errexit
set -eu -o pipefail

readonly RELEASE_DIR="${1:-}"

# Print error message and exit non-successfully.
panic() {
    echo "# ERROR: ${*}"
    exit 1
}

# Extracts the filename only, without path or extension.
extract_name() {
    declare filename=$(basename -- "${1}")
    declare extension="${filename##*.}"
    echo "${filename%.*}"
}

# Finds the respective documentation for the task name
find_doc() {
    declare task_name="${1}"
    find docs/ -name "${task_name}*.md"
}

#
# Main
#

release() {
    # making sure the release directory exists, this script should only create releative
    # directories using it as root
    [[ ! -d "${RELEASE_DIR}" ]] &&
        panic "Release dir is not found '${RELEASE_DIR}'!"

    # releasing all task templates using the following glob expression
    for t in $(ls -1 templates/task-*.yaml); do
        declare task_name=$(extract_name ${t})
        [[ -z "${task_name}" ]] &&
            panic "Unable to extract Task name from '${t}'!"

        declare task_doc="$(find_doc ${task_name})"
        [[ -z "${task_doc}" ]] &&
            panic "Unable to find documentation file for '${task_name}'!"

        declare task_dir="${RELEASE_DIR}/tasks/${task_name}"
        [[ ! -d "${task_dir}" ]] &&
            mkdir -p "${task_dir}"

        # rendering the helm template for the specific file, using the resource name for the
        # filename respectively
        echo "# Rendering '${task_name}' at '${task_dir}'..."
        helm template --show-only=${t} . >${task_dir}/${task_name}.yaml ||
            panic "Unable to render '${t}'!"

        # finds the respective documentation file copying as "README.md", on the same
        # directory where the respective task is located
        echo "# Copying '${task_name}' documentation file '${task_doc}'..."
        cp -v -f ${task_doc} "${task_dir}/README.md" ||
            panic "Unable to copy '${task_doc}' into '${task_dir}'"
    done
}

release