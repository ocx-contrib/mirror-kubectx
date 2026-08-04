# NOTICE

This repository packages and redistributes upstream software published by the
[kubectx project](https://github.com/ahmetb/kubectx). The Apache-2.0 license in
[`LICENSE`](LICENSE) covers the OCX pipeline files authored here. It does
**not** cover any upstream-derived asset — each package's redistributed bytes
carry their own license, recorded below.

Both packages in this repository are built from the **same upstream
repository**, `ahmetb/kubectx`, under the same single Apache-2.0 license.

Each package's logo is an original mark authored for this catalog — upstream
publishes no logo of its own — and is used for catalog identification only. The
kubectx and kubens names remain the property of their owners and no endorsement
is implied.

| Package | GHCR path | Upstream SPDX |
|---|---|---|
| `kubectx` | `ghcr.io/ocx-contrib/kubectx/kubectx` | `Apache-2.0` |
| `kubens` | `ghcr.io/ocx-contrib/kubectx/kubens` | `Apache-2.0` |

---

## `kubectx`

Upstream: <https://github.com/ahmetb/kubectx>
Published to `ghcr.io/ocx-contrib/kubectx/kubectx`.

| Component | SPDX | Holder |
|---|---|---|
| kubectx (`kubectx`) | **Apache-2.0** | Copyright Google LLC |

Permissive; redistribution of the compiled binary is granted under the terms of
<https://github.com/ahmetb/kubectx/blob/master/LICENSE>. Verified via
`gh api repos/ahmetb/kubectx/license --jq '.license.spdx_id'` → `Apache-2.0`.

The repository's `LICENSE` is the stock Apache-2.0 text with the boilerplate
copyright placeholder left unfilled; the copyright holder is taken from the
per-file headers, which read `Copyright 2021 Google LLC` across the Go sources
(`cmd/kubectx/main.go`, `cmd/kubens/main.go`, `internal/**`) and the release
configuration. The project is maintained by Ahmet Alp Balkan at the personal
GitHub account `ahmetb`.

Upstream ships the `LICENSE` file **inside** every release archive
(goreleaser's `files: ["LICENSE"]`), so the terms travel with the redistributed
bytes as well as being referenced here.

The binary is a pure-Go static build (`CGO_ENABLED=0`) that links third-party
Go modules under permissive licenses, enumerated in upstream's `go.mod`.

No modifications are made to any upstream artifact in this repository; they are
republished byte-for-byte inside an OCX bundle.

---

## `kubens`

Upstream: <https://github.com/ahmetb/kubectx>
Published to `ghcr.io/ocx-contrib/kubectx/kubens`.

| Component | SPDX | Holder |
|---|---|---|
| kubens (`kubens`) | **Apache-2.0** | Copyright Google LLC |

Same repository, same release tags and the same single Apache-2.0 license as
`kubectx` above — `ahmetb/kubectx` builds and publishes both tools from every
release. The attribution, the in-archive `LICENSE` file and the pure-Go static
build all apply identically.

No modifications are made to any upstream artifact in this repository; they are
republished byte-for-byte inside an OCX bundle.
