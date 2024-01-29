SHELL := /usr/bin/env bash
BIN = $(CURDIR)/.bin

OSP_VERSION ?= latest

# using the chart name and version from chart's metadata
CHART_NAME ?= $(shell awk '/^name:/ { print $$2 }' Chart.yaml)
CHART_VESION ?= $(shell awk '/^version:/ { print $$2 }' Chart.yaml)
RELEASE_VERSION = v$(CHART_VERSION)

CATALOGCD_VERSION = v0.1.0

# bats entry point and default flags
BATS_CORE = ./test/.bats/bats-core/bin/bats
BATS_FLAGS ?= --print-output-on-failure --show-output-of-passing-tests --verbose-run

# path to the bats test files, overwite the variables below to tweak the test scope
E2E_TESTS ?= ./test/e2e/*.bats
E2E_OPENSHIFT_PARAMS_SCRIPT ?= oc version

E2E_TKN_PARAMS_SCRIPT ?= tkn version

E2E_KN_PARAMS_ARGS ?= help

# generic arguments employed on most of the targets
ARGS ?=

# making sure the variables declared in the Makefile are exported to the excutables/scripts invoked
# on all targets
.EXPORT_ALL_VARIABLES:

$(BIN):
	@mkdir -p $@

CATALOGCD = $(or ${CATALOGCD_BIN},${CATALOGCD_BIN},$(BIN)/catalog-cd)
$(BIN)/catalog-cd: $(BIN)
	curl -fsL https://github.com/openshift-pipelines/catalog-cd/releases/download/v0.1.0/catalog-cd_0.1.0_linux_x86_64.tar.gz | tar xzf - -C $(BIN) catalog-cd

# renders the task resource file printing it out on the standard output, you can redirect the output
# of this target to a `kubectl apply -f -`, for istance
helm-template:
	helm template $(ARGS) $(CHART_NAME) .

# renders the task templates and copies documentation into the ${RELEASE_DIR}
prepare-release:
	mkdir -p $(RELEASE_DIR) || true
	hack/release.sh $(RELEASE_DIR)

# runs "catalog-cd release" to create the release payload based on the Tekton resources
# prepared by the previous step
release: $(CATALOGCD) prepare-release
	mkdir -p $(RELEASE_DIR) || true
	pushd ${RELEASE_DIR} && \
		$(CATALOGCD) release \
			--output release \
			--version $(CHART_VERSION) \
			tasks/* \
		; \
	popd

# tags the repository with the RELEASE_VERSION and pushes to "origin"
git-tag-release-version:
	if ! git rev-list "${RELEASE_VERSION}".. >/dev/null; then \
		git tag "$(RELEASE_VERSION)" && \
			git push origin --tags; \
	fi

# rolls out the current Chart version as the repository release version, uploads the release
# payload prepared to GitHub (using gh)
github-release: git-tag-release-version release
	gh release create $(RELEASE_VERSION) --generate-notes && \
	gh release upload $(RELEASE_VERSION) $(RELEASE_DIR)/release/catalog.yaml && \
	gh release upload $(RELEASE_VERSION) $(RELEASE_DIR)/release/resources.tar.gz

# renders and installs the task in the current namespace
install:
	helm template $(CHART_NAME) . |kubectl $(ARGS) apply -f -

# packages the helm-chart as a single tarball, using it's name and version to compose the file
helm-package:
	rm -f $(CHART_NAME)-*.tgz || true
	helm package $(ARGS) .
	tar -ztvpf $(CHART_NAME)-$(CHART_VESION).tgz

# removes the package helm chart, and also the chart-releaser temporary directories
clean:
	rm -rf $(CHART_NAME)-*.tgz > /dev/null 2>&1 || true

# run end-to-end tests against the current kuberentes context, it will required a cluster with tekton
# pipelines and other requirements installed, before start testing the target invokes the
# installation of the current project's task (using helm).
test-e2e: install
	$(BATS_CORE) $(BATS_FLAGS) $(ARGS) $(E2E_TESTS)

# Run all the end-to-end tests against the current openshift context.
# It is used mainly by the CI and ideally shouldn't differ that much from test-e2e
.PHONY: prepare-e2e-openshift
prepare-e2e-openshift:
	./hack/install-osp.sh $(OSP_VERSION)

.PHONY: test-e2e-openshift
test-e2e-openshift: prepare-e2e-openshift
test-e2e-openshift: test-e2e

.PHONY: test-e2e-tkn
test-e2e-tkn: prepare-e2e-openshift
test-e2e-tkn: test-e2e

# act runs the github actions workflows, so by default only running the test workflow (integration
# and end-to-end) to avoid running the release workflow accidently
act: ARGS = --workflows=./.github/workflows/test.yaml
act:
	act $(ARGS)
