#!/usr/bin/env bats

source ./test/helper/helper.sh

# E2E tests parameters for the test pipeline

# Testing the openshift task,
@test "[e2e] openshift task" {
    [ -n "${E2E_OPENSHIFT_PARAMS_SCRIPT}" ]

    run tkn task start openshift-client \
        --param="SCRIPT=${E2E_OPENSHIFT_PARAMS_SCRIPT}" \
	--use-param-defaults \
	--skip-optional-workspace \
        --showlog
    assert_success

    # waiting a few seconds before asserting results
    sleep 30

    kubectl get pods -o yaml
    kubectl get tasks -o yaml
    kubectl get taskruns -o yaml
    
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
    tkn taskrun describe --last --output=go-template-file --template=${tmpl_file}
    assert_success
    assert_output "Succeeded"
}
