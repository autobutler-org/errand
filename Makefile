.DEFAULT_GOAL := help
# pipefail so a failed curl does not leave a truncated binary behind.
SHELL := bash
.SHELLFLAGS := -eo pipefail -c
.DELETE_ON_ERROR:

# renovate: datasource=github-releases depName=helm/helm
HELM_VERSION := v4.3.1
# renovate: datasource=github-releases depName=yannh/kubeconform
KUBECONFORM_VERSION := v0.8.0

CHART := charts/errand
REGISTRY := oci://ghcr.io/autobutler-org/charts
OS := $(shell uname -s | tr '[:upper:]' '[:lower:]')
ARCH := $(shell uname -m | sed -e 's/x86_64/amd64/' -e 's/aarch64/arm64/')
HELM := bin/helm
KUBECONFORM := bin/kubeconform

.PHONY: help tools doctor lint template validate check package push clean

help: ## show this help
	@grep -E '^[a-z]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-10s %s\n", $$1, $$2}'

tools: $(HELM) $(KUBECONFORM) ## download pinned helm and kubeconform into bin/

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

$(HELM): bin/helm-$(HELM_VERSION)
	ln -sf helm-$(HELM_VERSION) $@

$(KUBECONFORM): bin/kubeconform-$(KUBECONFORM_VERSION)
	ln -sf kubeconform-$(KUBECONFORM_VERSION) $@

doctor: ## check prerequisites and print the fix for anything missing
	@ok=1; \
	command -v curl >/dev/null || { echo "missing curl: install it with your package manager"; ok=0; }; \
	command -v tar >/dev/null || { echo "missing tar: install it with your package manager"; ok=0; }; \
	[ -x bin/helm-$(HELM_VERSION) ] || { echo "missing helm $(HELM_VERSION): run 'make tools'"; ok=0; }; \
	[ -x bin/kubeconform-$(KUBECONFORM_VERSION) ] || { echo "missing kubeconform $(KUBECONFORM_VERSION): run 'make tools'"; ok=0; }; \
	[ $$ok = 1 ] && echo "all good" || exit 1

lint: $(HELM) ## helm lint --strict the chart
	$(HELM) lint --strict $(CHART)

template: $(HELM) ## render the chart to stdout
	@$(HELM) template errand $(CHART)

# -ignore-missing-schemas: ARC's CRDs (AutoscalingRunnerSet and friends) have
# no published JSON schema, so kubeconform would otherwise fail on them.
validate: $(HELM) $(KUBECONFORM) ## validate rendered manifests with kubeconform
	$(HELM) template errand $(CHART) | $(KUBECONFORM) -strict -summary -ignore-missing-schemas

check: lint validate ## lint and validate (what CI runs)

package: $(HELM) ## package the chart into dist/
	$(HELM) package $(CHART) --destination dist

push: $(HELM) ## push the packaged chart to ghcr.io
	@ls dist/errand-*.tgz >/dev/null 2>&1 || { echo "no chart in dist/: run 'make package' first"; exit 1; }
	@for pkg in dist/errand-*.tgz; do \
	  $(HELM) push $$pkg $(REGISTRY) || { echo "push failed: if you are not logged in, run 'helm registry login ghcr.io'"; exit 1; }; \
	done

clean: ## remove bin/ and dist/
	rm -rf bin dist
