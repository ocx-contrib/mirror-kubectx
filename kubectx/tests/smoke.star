# kubectx/tests/smoke.star — stable across upstream releases.
#
# kubectx is KUBECONFIG-dependent: run bare with no kubeconfig it prints
# "warning: kubeconfig file not found" and exits 0 with an empty list. So exit 0
# proves nothing on its own here — every assertion below pins a COUNT or an
# exact computed value.
#
# Everything is hermetic: the kubeconfig is written into scratch by this script
# and no cluster is ever contacted. The one upstream operation that does reach
# the network (`kubectx -s/--shell`, and kubens' namespace listing) is not
# exercised.
#
# DIALECT: Bazel .bzl — no top-level `if`/`for` STATEMENTS. Ternaries and list
# comprehensions are expressions and are legal at module scope.

KUBECTX = "kubectx.exe" if ocx.target_platform.os == ocx.os.Windows else "kubectx"

# kubectx writes a "previous context" state file under
# ${XDG_CACHE_HOME:-$HOME/.kube} on EVERY successful switch, and hard-fails
# (exit 1, "failed to save previous context name" / "HOME or USERPROFILE
# environment variable not set") when HOME is unset or unwritable. Measured
# locally against the real v0.11.0 binary. Pointing HOME at scratch makes the
# switch below deterministic on a bare container image instead of dependent on
# what the image sets. Upstream resolves HOME first and USERPROFILE only as a
# Windows fallback (internal/cmdutil/util.go: HomeDir()), so HOME alone covers
# all three platforms.
ocx.mkdir("home")
ENV = {
    "HOME": ocx.scratch_root + "/home",
    "KUBECONFIG": ocx.scratch_root + "/kubeconfig.yaml",
}

# Two contexts with distinct, invented names — nothing here can come from the
# host's real kubeconfig, and the server is a loopback port that is never
# contacted by any command this script runs.
ocx.write_file("kubeconfig.yaml", """apiVersion: v1
kind: Config
current-context: ocx-alpha
clusters:
- name: ocx-cluster
  cluster:
    server: https://127.0.0.1:1
contexts:
- name: ocx-alpha
  context:
    cluster: ocx-cluster
    user: ocx-user
    namespace: alpha-ns
- name: ocx-bravo
  context:
    cluster: ocx-cluster
    user: ocx-user
    namespace: bravo-ns
users:
- name: ocx-user
  user:
    token: not-a-real-token
""")

# ── Tier 1 + 2: liveness and version SHAPE (never the digits, never prose) ───
r_version = ocx.run(KUBECTX, "--version")
expect.ok(r_version)
expect.matches(r_version.stdout, r"\d+\.\d+\.\d+")

# ── Tier 3a: list the contexts — assert the COUNT and both names ─────────────
# Output is one context per line and uncolorized when stdout is a pipe (kubectx
# only emits SGR to a tty), so each line is a single bare token. Comparing bare
# tokens is deliberate: colorized output would red here rather than pass on a
# loose substring.
r_list = ocx.run(KUBECTX, env = ENV)
expect.ok(r_list)
CONTEXTS = [line.strip() for line in r_list.stdout.split("\n") if line.strip() != ""]
expect.eq(len(CONTEXTS), 2)
expect.contains(CONTEXTS, "ocx-alpha")
expect.contains(CONTEXTS, "ocx-bravo")

# ── Tier 3b: switch round-trip — proves kubectx REWROTE the kubeconfig ───────
# Reading the file back through the binary's own `-c` is what separates "parsed
# my input" from "performed the operation": the second `-c` can only answer
# ocx-bravo if the switch was persisted to disk.
expect.eq(ocx.run(KUBECTX, "-c", env = ENV).stdout.strip(), "ocx-alpha")
expect.ok(ocx.run(KUBECTX, "ocx-bravo", env = ENV))
expect.eq(ocx.run(KUBECTX, "-c", env = ENV).stdout.strip(), "ocx-bravo")

# ── Negative control ────────────────────────────────────────────────────────
# A tool that merely echoed its kubeconfig back would pass everything above.
# An unknown context name must fail (upstream exits 1 with "no context exists
# with the name"), and must leave current-context untouched.
r_bad = ocx.run(KUBECTX, "ocx-no-such-context", env = ENV)
expect.ne(r_bad.exit_code, 0)
expect.eq(ocx.run(KUBECTX, "-c", env = ENV).stdout.strip(), "ocx-bravo")
