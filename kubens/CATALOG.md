---
title: kubens
description: Switch the active Kubernetes namespace of the current kubectl context, and jump back to the previous one
keywords: kubens,kubectl,kubernetes,k8s,namespace,context,kubeconfig,cli,devops
---

# kubens

`kubens` sets the namespace that `kubectl` uses by default, so the `-n` flag
stops appearing on every command. It lists the namespaces of the current
context, switches to one, jumps back to the previous choice, prints the active
one, and can reset it to `default`.

It edits the kubeconfig `kubectl` already reads, so the change applies to every
other Kubernetes tool on the machine too — no shell wrapper and no extra
configuration.

## What's included

- **kubens** — the namespace switcher: `kubens` to list, `kubens <name>` to
  switch, `kubens -` for the previous namespace, `kubens -c` for the current
  one, `kubens -u` to reset to `default`, and `--force` to select a namespace
  without checking that it exists.

A single static binary with no runtime dependencies. Listing namespaces queries
the cluster API; every other operation is answered from the kubeconfig alone.
Its sibling tool for contexts is
[`ocx.sh/kubectx/kubectx`](https://index.ocx.sh/kubectx/kubectx), published
from the same upstream releases.

## Links

- [kubectx + kubens on GitHub](https://github.com/ahmetb/kubectx)
- [Installation and usage](https://github.com/ahmetb/kubectx#usage)
- [Shell completion scripts](https://github.com/ahmetb/kubectx/tree/master/completion)
