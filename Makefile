.DEFAULT_GOAL := help
# pipefail so a failed curl does not leave a truncated binary behind.
SHELL := bash
.SHELLFLAGS := -eo pipefail -c
.DELETE_ON_ERROR:

# renovate: datasource=github-releases depName=helm/helm
HELM_VERSION := v4.3.1
# renovate: datasource=github-releases depName=yannh/kubeconform
KUBECONFORM_VERSION := v0.8.0
# renovate: datasource=github-releases depName=helm-unittest/helm-unittest
HELM_UNITTEST_VERSION := v1.2.1
# datreeio/CRDs-catalog commit with the actions.github.com CRDs from ARC 0.15.0,
# the newest it carries. 0.15.1 only adds a few min/max bounds on top of them.
CRDS_CATALOG_REF := c4b1316c2c97f15d376ab84594a1ad880a707eb7

CHART := charts/errand
REGISTRY := oci://ghcr.io/autobutler-org/charts
OS := $(shell uname -s | tr '[:upper:]' '[:lower:]')
ARCH := $(shell uname -m | sed -e 's/x86_64/amd64/' -e 's/aarch64/arm64/')
HELM := bin/helm
KUBECONFORM := bin/kubeconform
# Plugins live under bin/ so nothing in the user's own helm setup is touched.
export HELM_PLUGINS := $(CURDIR)/bin/plugins
HELM_UNITTEST := $(HELM_PLUGINS)/unittest

.PHONY: help tools doctor deps lint template validate test check package push clean

help: ## show this help
	@grep -E '^[a-z]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-10s %s\n", $$1, $$2}'

tools: $(HELM) $(KUBECONFORM) $(HELM_UNITTEST) ## download pinned helm, kubeconform and helm-unittest into bin/

# Downloads are checked against each project's published checksums.
# ponytail: checksums come from the same host as the tarball, so this catches
# corruption, not a compromised release; pin hashes here if that matters.
HELM_TGZ := helm-$(HELM_VERSION)-$(OS)-$(ARCH).tar.gz
KUBECONFORM_TGZ := kubeconform-$(OS)-$(ARCH).tar.gz
KUBECONFORM_URL := https://github.com/yannh/kubeconform/releases/download/$(KUBECONFORM_VERSION)

bin/helm-$(HELM_VERSION):
	@mkdir -p bin/dl
	cd bin/dl && curl -fsSLO https://get.helm.sh/$(HELM_TGZ) && curl -fsSL https://get.helm.sh/$(HELM_TGZ).sha256sum | shasum -a 256 -c -
	tar -xzOf bin/dl/$(HELM_TGZ) $(OS)-$(ARCH)/helm > $@
	chmod +x $@

bin/kubeconform-$(KUBECONFORM_VERSION):
	@mkdir -p bin/dl
	cd bin/dl && curl -fsSLO $(KUBECONFORM_URL)/$(KUBECONFORM_TGZ) && curl -fsSL $(KUBECONFORM_URL)/CHECKSUMS | grep ' $(KUBECONFORM_TGZ)$$' | shasum -a 256 -c -
	tar -xzOf bin/dl/$(KUBECONFORM_TGZ) kubeconform > $@
	chmod +x $@

# Helm 4 wants a .prov signature to install a plugin tarball. Unpacking the
# checksummed platform tarball into HELM_PLUGINS loads it without an install.
HELM_UNITTEST_TGZ := helm-unittest-$(subst darwin,macos,$(OS))-$(ARCH)-$(HELM_UNITTEST_VERSION:v%=%).tgz
HELM_UNITTEST_URL := https://github.com/helm-unittest/helm-unittest/releases/download/$(HELM_UNITTEST_VERSION)

bin/helm-unittest-$(HELM_UNITTEST_VERSION)/plugin.yaml:
	@mkdir -p bin/dl $(@D)
	cd bin/dl && curl -fsSLO $(HELM_UNITTEST_URL)/$(HELM_UNITTEST_TGZ) && curl -fsSL $(HELM_UNITTEST_URL)/helm-unittest-checksum.sha | grep '/$(HELM_UNITTEST_TGZ)$$' | sed 's# \*.*/#  #' | shasum -a 256 -c -
	tar -xzf bin/dl/$(HELM_UNITTEST_TGZ) -C $(@D)

$(HELM): bin/helm-$(HELM_VERSION)
	ln -sf helm-$(HELM_VERSION) $@

$(KUBECONFORM): bin/kubeconform-$(KUBECONFORM_VERSION)
	ln -sf kubeconform-$(KUBECONFORM_VERSION) $@

$(HELM_UNITTEST): bin/helm-unittest-$(HELM_UNITTEST_VERSION)/plugin.yaml
	@mkdir -p $(HELM_PLUGINS)
	ln -sfn ../helm-unittest-$(HELM_UNITTEST_VERSION) $@

doctor: ## check prerequisites and print the fix for anything missing
	@ok=1; \
	command -v curl >/dev/null || { echo "missing curl: install it with your package manager"; ok=0; }; \
	command -v tar >/dev/null || { echo "missing tar: install it with your package manager"; ok=0; }; \
	[ -x bin/helm-$(HELM_VERSION) ] || { echo "missing helm $(HELM_VERSION): run 'make tools'"; ok=0; }; \
	[ -x bin/kubeconform-$(KUBECONFORM_VERSION) ] || { echo "missing kubeconform $(KUBECONFORM_VERSION): run 'make tools'"; ok=0; }; \
	[ -f bin/helm-unittest-$(HELM_UNITTEST_VERSION)/plugin.yaml ] || { echo "missing helm-unittest $(HELM_UNITTEST_VERSION): run 'make tools'"; ok=0; }; \
	[ $$ok = 1 ] && echo "all good" || exit 1

# The chart pulls its dependencies into charts/errand/charts/ (gitignored).
deps: $(HELM) ## fetch the chart's dependencies from Chart.lock
	@$(HELM) dependency build $(CHART) >&2

lint: deps ## helm lint --strict the chart
	$(HELM) lint --strict $(CHART)

template: deps ## render the chart to stdout
	@$(HELM) template errand $(CHART)

# ARC's CRDs come from the pinned catalog commit, so they are validated, not
# skipped. A kind with no schema anywhere fails rather than slipping through.
validate: deps $(KUBECONFORM) ## validate rendered manifests with kubeconform
	$(HELM) template errand $(CHART) | $(KUBECONFORM) -strict -summary \
	  -schema-location default \
	  -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/$(CRDS_CATALOG_REF)/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json'

test: deps $(HELM_UNITTEST) ## run the helm-unittest suites in charts/errand/tests
	$(HELM) unittest $(CHART)

check: lint validate test ## lint, validate and test (what CI runs)

package: deps ## package the chart into dist/
	$(HELM) package $(CHART) --destination dist

push: $(HELM) ## push the packaged chart to ghcr.io
	@ls dist/errand-*.tgz >/dev/null 2>&1 || { echo "no chart in dist/: run 'make package' first"; exit 1; }
	@for pkg in dist/errand-*.tgz; do \
	  $(HELM) push $$pkg $(REGISTRY) || { echo "push failed: if you are not logged in, run 'helm registry login ghcr.io'"; exit 1; }; \
	done

clean: ## remove bin/ and dist/
	rm -rf bin dist
