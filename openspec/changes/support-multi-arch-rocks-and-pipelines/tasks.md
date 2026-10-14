# Tasks: Multi-Architecture Binary and Container Rock Support

## 1. Multi-Architecture Binary Builds (`Makefile`)

- [x] 1.1 Update [Makefile](Makefile) to resolve `GOOS`, `GOARCH` (from environment, `CRAFT_ARCH_BUILD_FOR`, or `go env GOARCH`), and verify with `GOARCH=amd64 make build`, `GOARCH=arm64 make build`, and `GOARCH=riscv64 make build`.
- [x] 1.2 Add a `build-all` target to [Makefile](Makefile) that compiles `bin/app-linux-amd64`, `bin/app-linux-arm64`, and `bin/app-linux-riscv64`, and verify by running `make build-all`.

## 2. Supported-Architecture Container and Rock Packaging (`rockcraft.yaml`, `build.sh`, `skaffold.yaml`, `Dockerfile`)

- [x] 2.1 Update [rockcraft.yaml](rockcraft.yaml) to declare `amd64: null` and `arm64: null` under `platforms` and export `GOARCH="${CRAFT_ARCH_BUILD_FOR}"` in `parts.go-build.override-build`, and verify `.platforms | keys` with `yq`.
- [x] 2.2 Update [build.sh](build.sh) to detect the host architecture (`ARCH`) for `amd64` and `arm64` instead of hardcoding `amd64`, and verify syntax with `sh -n build.sh`.
- [x] 2.3 Update [skaffold.yaml](skaffold.yaml) to set `platforms: ["linux/amd64", "linux/arm64"]` and update [Dockerfile](Dockerfile) to accept `TARGETOS` and `TARGETARCH` build arguments, and verify YAML syntax with `yq`.

## 3. Continuous Integration and Release Pipelines (`.github/workflows/`)

- [x] 3.1 Update [.github/workflows/unittest.yaml](.github/workflows/unittest.yaml) to run `make build-all` so CI builds the binary for `amd64`, `arm64`, and `riscv64`, and verify the step locally.
- [x] 3.2 Update [.github/workflows/ci.yaml](.github/workflows/ci.yaml) to add the `get-architectures` job, run `build` across `strategy.matrix.architecture` (`amd64` and `arm64`), and remove the single-file `rock:` input from `gh-publish-branch` and `gh-publish-candidate`.
- [x] 3.3 Document and prepare the upstream `canonical/identity-team` change for `_rock-promote.yaml` to pass `--all` to `skopeo copy` during candidate promotion.

## 4. Verification Suite

- [x] 4.1 Run `go test -short -race ./...` and confirm zero test or race detector failures.
- [x] 4.2 Run `make build-all` and confirm `file bin/app-linux-amd64 bin/app-linux-arm64 bin/app-linux-riscv64` outputs `x86-64`, `ARM aarch64`, and `UCB RISC-V` ELF binaries.
- [x] 4.3 Run `openspec validate --all` and confirm all specifications and changes pass validation.

## 5. Documentation & Rollout

- [x] 5.1 Update [README.md](README.md) to document `make build-all` (`amd64`, `arm64`, `riscv64` binaries) and `amd64`/`arm64` Rock builds.
- [x] 5.2 Confirm backward compatibility for existing image tags (`latest`, `stable`, `<version>`) across `k8s/` manifests before rollout.

## Implementation Notes

- Local workflows in `.github/workflows/ci.yaml` delegate Rock building (`_rock-build.yaml`), multi-architecture manifest publishing (`_rock-gh-publish.yaml`), vulnerability scanning (`_rock-scan.yaml`), and candidate promotion (`_rock-promote.yaml`) to `canonical/identity-team` without duplicating centralized steps locally.
- Removing `with.rock` from `gh-publish-branch` and `gh-publish-candidate` enables `_rock-gh-publish.yaml`'s built-in multi-architecture mode (`*.rock` artifact download, `<tag>-amd64` and `<tag>-arm64` push, and `docker manifest create --amend` + `docker manifest push`).
- Upstream `canonical/identity-team/.github/workflows/_rock-promote.yaml` requires `--all` on `rockcraft.skopeo --insecure-policy copy --all` so multi-architecture manifest lists preserve all architectures (`amd64` and `arm64`) during promotion to `<release-tag>` and `stable`.
