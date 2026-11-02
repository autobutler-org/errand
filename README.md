# errand

The autobutler-org self-hosted GitHub Actions runner stack: a Helm chart built on
GitHub's [Actions Runner Controller](https://github.com/actions/actions-runner-controller)
(chart 0.15.1). You list runner labels, images and sizes; the chart installs the ARC
controller and one runner scale set per label.

## Values

```yaml
github:
  configUrl: https://github.com/autobutler-org
  secret: github-app-private-key   # existing Secret with the GitHub App credentials
  runnerGroup: errand

defaults:                          # every runner starts from these
  image: ghcr.io/actions/actions-runner:2.338.2
  resources:
    limits: { cpu: 3500m, memory: 10Gi }   # on the pod; requests default to limits
  minRunners: 0
  maxRunners: 100
  containerMode: dind
  pod:                             # raw runner pod spec
    tolerations:
      - { key: ci.autobutler.org/runner, operator: Equal, value: "true", effect: NoSchedule }
  container:                       # raw runner container
    imagePullPolicy: Always
  listener:                        # raw listener pod spec
    tolerations:
      - { key: CriticalAddonsOnly, operator: Equal, value: "true", effect: NoSchedule }

runners:
  - label: arm-small-quark-backend # scale set name and runs-on label
    arch: arm64                    # kubernetes.io/arch nodeSelector
    image: autobutlerci.azurecr.io/quark/ci-backend:latest
    resources:
      limits: { cpu: 875m, memory: 2.5Gi }

gha-runner-scale-set-controller:   # passed through to the controller chart
  tolerations:
    - { key: CriticalAddonsOnly, operator: Equal, value: "true", effect: NoSchedule }
```

Each runner is `defaults` deep-merged with its entry: maps merge key by key, lists and
scalars replace. The scale-set templates are copied from upstream `gha-runner-scale-set`
into `charts/errand/templates/_gha-rs-*.tpl`, and the controller's service account name
and namespace come from this release, so nothing calls `lookup`.
[`charts/errand/ci/values.yaml`](charts/errand/ci/values.yaml) is a complete example.

## Usage

Run `make help` for the targets. `make tools` downloads the pinned helm, kubeconform and
helm-unittest into `bin/`; `make check` lints the chart, validates the rendered manifests
(ARC's CRDs included), runs the unit tests in `charts/errand/tests/`, and runs `make drift`,
which diffs one runner against upstream `gha-runner-scale-set` at the chart's appVersion.
CI runs the same thing.
`make doctor` reports anything missing and how to fix it.

## Releasing

1. Bump `version` in `charts/errand/Chart.yaml` and merge it to main.
2. Tag the merge commit `vX.Y.Z` matching that version and push the tag.

The release workflow checks that the tag matches Chart.yaml, then packages the chart and
pushes it to `oci://ghcr.io/autobutler-org/charts`.
