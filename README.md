# mirror-kubectx

OCX mirrors for the [kubectx project](https://github.com/ahmetb/kubectx) —
`kubectx` and `kubens`, the two kubectl power tools. One repository, one spec
directory per package.

| Package | Spec | Publishes to | Announced as | Upstream SPDX |
|---|---|---|---|---|
| [kubectx](https://github.com/ahmetb/kubectx) | [`kubectx/mirror.yml`](kubectx/mirror.yml) | `ghcr.io/ocx-contrib/kubectx/kubectx` | `ocx.sh/kubectx/kubectx` | `Apache-2.0` |
| [kubens](https://github.com/ahmetb/kubectx) | [`kubens/mirror.yml`](kubens/mirror.yml) | `ghcr.io/ocx-contrib/kubectx/kubens` | `ocx.sh/kubectx/kubens` | `Apache-2.0` |

Each upstream release is discovered, re-bundled, smoke-tested per
`(version, platform)` and only then pushed with cascade tags, after which the
result is announced into the OCX index.

## One upstream repository, two packages

`ahmetb/kubectx` is a single repository that ships **two** tools, and every
release tag publishes **both** asset families side by side:

```
kubectx_v0.11.0_linux_x86_64.tar.gz     kubens_v0.11.0_linux_x86_64.tar.gz
kubectx_v0.11.0_windows_arm64.zip       kubens_v0.11.0_windows_arm64.zip
…                                       …
```

So the two specs here point at the *same* `source:` with the *same*
`tag_pattern` and the *same* version floor, and are separated **only** by their
asset patterns. Every pattern is anchored at both ends and carries the tool's
literal name plus a `_v<semver>_<os>_<arch>` body, so neither spec can reach
the other's family.

That anchoring also handles a trap: every release additionally uploads two
bare, unversioned, unplatformed files named literally **`kubectx`** (6 KB) and
**`kubens`** (6 KB). They are the project's original standalone *bash scripts*,
attached by goreleaser's `release.extra_files` glob — not platform binaries. A
loose substring match on the tool name pulls one in and mirrors a shell script
as if it were a compiled artifact.

The namespace is `kubectx` for both packages. A namespace carries identity, not
provenance — `ahmetb` is a personal handle that would age badly — and the
upstream coordinate is recorded verifiably in each index claim's `upstream`
block instead.

## Layout

```
mirror-base.yml         repo-wide policy every spec inherits via `extends:`
kubectx/                one directory per package — same five files each
kubens/
├── mirror.yml          the spec — never at the repo root
├── metadata.json       bundle interface
├── CATALOG.md          → ocx package describe
├── logo.svg / logo.png describe assets, 512px PNG
└── tests/smoke.star    Starlark smoke test
```

`LICENSE` and `NOTICE.md` are shared at the root. Logos are **not** — each
package carries its own, because a repo-root `logo.*` sits in no workflow's
`paths:` filter, so replacing it would publish nothing until some unrelated
edit happened to fire.

⚠️ `extends:` is a **shallow** merge of top-level keys. A spec that restates
`platforms:` to change one runner drops every `containers:` entry with it, and
nothing reds — the legs simply stop existing, and every `os.features` claim
goes back to being asserted rather than verified. Restate a block in full or
not at all. `mirror-base.yml` here deliberately declares **no** `platforms:`
block: each package stages its own rollout, so each spec restates the matrix in
full and carries its own libc measurement above it.

## Platforms

Upstream builds both tools for six declarable platform keys — linux, darwin and
windows on amd64 and arm64 — rolled out in three staged passes (linux, then
darwin, then windows), each its own commit and CI run.

Both tools are pure-Go builds with `CGO_ENABLED=0`, so there is one Linux build
per arch and it is **fully static**: no `PT_INTERP`, no `DT_NEEDED`, and no
musl/glibc variants to choose between (measured per package on the real assets
— a sibling's result is not evidence). `os.features` states what an artifact
requires *of the host*, so both Linux keys are **bare**; tagging them
`+libc.musl` would be a false requirement that hid them from every glibc host.
The `alpine:3.20` container leg is what turns that claim into evidence.

Staging only the `assets:` keys does **not** save runner minutes: the generated
test matrix is static, so a platform declared with no matching asset still
boots its `macos-14` / `windows-11-arm` runner, skips every version and reports
**success** having tested nothing. The `platforms:` entry has to be commented
out too, and uncommented in the same edit as its assets.

The other arches upstream builds — `armhf`, `armv7`, `ppc64le`, `s390x`, on
Linux and (for the two ARM ones) Windows — are not carried, and that is not a
policy call: OCX's architecture enum has only `amd64` and `arm64`, so they
cannot be expressed as platform keys at all. The armhf-vs-armv7 ABI question
(`goarm: [6, 7]` upstream) therefore never has to be answered.

The version floor is `0.10.0`. Below it lies a ~2.7-year publishing gap
(v0.9.5 in July 2023, v0.10.0 in March 2026) — upstream dormancy followed by a
revival that landed three releases in one week, not a discovery fault.

## Editing

| File | Edit | Regenerate after |
|------|------|------------------|
| `mirror-base.yml`, `<pkg>/mirror.yml` | hand | yes — see below |
| `<pkg>/{metadata.json,CATALOG.md,logo.*}` | hand | — |
| `<pkg>/tests/smoke.star` | hand | — |
| `.github/workflows/*.yml` | **generated — never hand-edit** | re-run when a spec changes |

```bash
ocx-mirror package pipeline generate ci \
  --spec kubectx/mirror.yml \
  --spec kubens/mirror.yml
```

**Name every spec.** `--spec` *appends* rather than replaces, so a command
naming a subset silently stops rendering the rest while staying green — and the
drift guard reds on a generated workflow the current spec set no longer
produces.

`verify-generated.yml` exits 65 on drift. If a generated workflow is wrong, the
spec or the renderer template is wrong — fix it there and regenerate.

Run `direnv allow` once to put the pinned toolchain on `PATH`, and invoke
`ocx-mirror` directly — never `ocx run -- ocx-mirror`, which pins
`OCX_BINARY_PIN` to the bootstrap `ocx` and false-reds the nested push.

## The binaries claim

Every upstream archive is **flat**: `LICENSE` and the single executable at the
archive root, no wrapper directory and no `bin/`. With `strip_components: 0`
they land at the content root, so the bundle's only PATH entry is a bare
`${installPath}`. `bin_scan` only looks *below* an `${installPath}/<dir>`
entry, so `auto`/`verify` is rejected at spec load with exit 65;
`mirror-base.yml` sets `bin_scan: off` and each `metadata.json` hand-lists its
one binary — the blessed shape for this layout.

## The smoke tests are hermetic

Both tools read and rewrite a kubeconfig, and `kubens`' namespace *listing*
talks to a live cluster API. The smoke tests therefore write their own
kubeconfig into the test scratch directory, pass it via `KUBECONFIG`, and
assert on operations that never leave the process: the context/namespace the
binary reports back, the count of entries it lists, and the value it persisted
to the file. `HOME` is pointed at scratch too — both tools write a
previous-selection state file under `${XDG_CACHE_HOME:-$HOME/.kube}` and exit 1
if `HOME` is unset or unwritable, which a bare container image can easily be.

## Required secrets

| Secret | Use |
|--------|-----|
| `OCX_ANNOUNCE_TOKEN` | opens the index pull request from the `ocx-contrib/index` fork |
| `OCX_MIRROR_DISCORD_HOOK` | notify-stage Discord webhook URL |

(Inherited from the `ocx-contrib` org with visibility ALL. GHCR pushes use the
run's own `GITHUB_TOKEN` — no registry secret needed.)

## License

Apache-2.0 — see [`LICENSE`](LICENSE). Upstream assets are out of scope; each
package's redistribution license is recorded in [`NOTICE.md`](NOTICE.md).
