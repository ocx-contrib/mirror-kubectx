# kubens/tests/smoke.star — stable across upstream releases.
#
# kubens is KUBECONFIG-dependent, and its DEFAULT operation (listing the
# namespaces of the current context) talks to a live Kubernetes API server —
# unreachable from a test leg, and a network call besides. So the listing path
# is deliberately not exercised; every assertion below drives a code path that
# is answered entirely from the kubeconfig this script writes into scratch.
#
# Concretely: `kubens -c` reads the active namespace, `kubens <ns> --force`
# sets it without the existence check that would hit the API, and `kubens -u`
# resets it to "default". `kubens -` (previous namespace) is NOT used — it
# re-validates the target against the API and exits 1 with a connection error.
#
# DIALECT: Bazel .bzl — no top-level `if`/`for` STATEMENTS. Ternaries and list
# comprehensions are expressions and are legal at module scope.

KUBENS = "kubens.exe" if ocx.target_platform.os == ocx.os.Windows else "kubens"

# kubens records a "previous namespace" state file under
# ${XDG_CACHE_HOME:-$HOME/.kube} on a successful switch. Pointing HOME at
# scratch keeps that write inside the sandbox instead of the container image's
# real HOME, and makes the behaviour identical on every leg. Upstream resolves
# HOME first and USERPROFILE only as a Windows fallback
# (internal/cmdutil/util.go: HomeDir()), so HOME alone covers all three
# platforms.
ocx.mkdir("home")
ENV = {
    "HOME": ocx.scratch_root + "/home",
    "KUBECONFIG": ocx.scratch_root + "/kubeconfig.yaml",
}

# One context whose active namespace is an invented name — nothing here can
# come from the host's real kubeconfig, and the server is a loopback port that
# no command below ever contacts.
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

# A second kubeconfig that is not valid YAML at all — the negative control.
ocx.write_file("broken.yaml", "this: is: not: valid: [\n")

# ── Tier 1 + 2: liveness and version SHAPE (never the digits, never prose) ───
r_version = ocx.run(KUBENS, "--version")
expect.ok(r_version)
expect.matches(r_version.stdout, r"\d+\.\d+\.\d+")

# ── Tier 3a: read back the namespace THIS script invented ───────────────────
# Output is a single bare token and uncolorized when stdout is a pipe, so an
# exact compare is the right assertion — colorized output would red here rather
# than slip past a loose substring match.
r_current = ocx.run(KUBENS, "-c", env = ENV)
expect.ok(r_current)
expect.eq(r_current.stdout.strip(), "alpha-ns")

# ── Tier 3b: switch round-trip — proves kubens REWROTE the kubeconfig ────────
# --force skips the "does this namespace exist?" query against the cluster API,
# which is the only thing on this path that would need the network. Reading the
# result back through the binary's own `-c` is what separates "parsed my input"
# from "performed the operation".
expect.ok(ocx.run(KUBENS, "bravo-ns", "--force", env = ENV))
expect.eq(ocx.run(KUBENS, "-c", env = ENV).stdout.strip(), "bravo-ns")

# ── Tier 3c: a second write path — `-u` resets the choice to "default" ──────
expect.ok(ocx.run(KUBENS, "-u", env = ENV))
expect.eq(ocx.run(KUBENS, "-c", env = ENV).stdout.strip(), "default")

# ── Negative control ────────────────────────────────────────────────────────
# A tool that merely echoed its kubeconfig back would pass everything above.
# A kubeconfig that is not parseable YAML must fail — hermetically, with no
# network involved. The message differs across the in-range versions
# ("failed to decode" vs "failed to decode file 0"), so only the exit code is
# asserted.
r_broken = ocx.run(KUBENS, "-c", env = {
    "HOME": ocx.scratch_root + "/home",
    "KUBECONFIG": ocx.scratch_root + "/broken.yaml",
})
expect.ne(r_broken.exit_code, 0)
