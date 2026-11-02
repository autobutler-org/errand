# errand

The autobutler-org self-hosted GitHub Actions runner stack: a Helm chart built on
GitHub's [Actions Runner Controller](https://github.com/actions/actions-runner-controller)
(chart 0.15.1). The chart is a placeholder for now; templates come later.

## Usage

Run `make help` for the targets. `make tools` downloads the pinned helm and kubeconform
into `bin/`; `make check` lints and validates the chart, and CI runs the same thing.
`make doctor` reports anything missing and how to fix it.

## Releasing

1. Bump `version` in `charts/errand/Chart.yaml` and merge it to main.
2. Tag the merge commit `vX.Y.Z` matching that version and push the tag.

The release workflow checks that the tag matches Chart.yaml, then packages the chart and
pushes it to `oci://ghcr.io/autobutler-org/charts`.
