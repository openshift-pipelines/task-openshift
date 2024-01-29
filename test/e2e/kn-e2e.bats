#!/usr/bin/env bats

source ./test/helper/helper.sh

# E2E tests parameters for the test pipeline

# Testing the kn task,
@test "[e2e] kn task" {
     [ -n "${E2E_KN_PARAMS_ARGS}" ]
    
    run kubectl delete taskrun --all
    assert_success

    run tkn task start kn \
        --param="ARGS=${E2E_KN_PARAMS_ARGS}" \
        --showlog >&3
    assert_success

    # waiting a few seconds before asserting results
    sleep 15
    
    # assering the taskrun status, making sure all steps have been successful
    declare tmpl_file="${BASE_DIR}/go-template.tpl"
    # the following template is able to extract information from TaskRun and PipelineRun resources,
    # and as well supports the current Tekton Pipeline version using a different `.task.results`
    # attribute
    cat >${tmpl_file} <<EOS
{{- range .status.conditions }}
    {{- if and (eq .type "Succeeded") (eq .status "True") }}
        {{- printf "%s\n" .message -}}
    {{- end -}}
{{- end }}
{{- range .status.results }}
    {{- printf "%s=%s\n" .name .value -}}
{{- end -}}
EOS

    run tkn taskrun describe --last --output=go-template-file --template=${tmpl_file}
    assert_success
    assert_output "All Steps have completed executing"
}
