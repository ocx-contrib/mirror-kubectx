---
title: kubectx
description: Switch between kubectl contexts (clusters) fast, rename and delete them, or open a shell scoped to one
keywords: kubectx,kubectl,kubernetes,k8s,context,cluster,kubeconfig,cli,devops
---

# kubectx

`kubectx` is a small CLI for the part of `kubectl` that gets typed the most:
choosing which cluster the next command talks to. It lists the contexts in your
kubeconfig, switches between them, jumps back to the previous one, renames and
deletes them, and can open a shell — optionally read-only — scoped to a single
context so an experiment cannot leak into another cluster.

It edits the kubeconfig `kubectl` already reads, so nothing else has to be
configured and every other Kubernetes tool follows along.

## What's included

- **kubectx** — the context manager: `kubectx` to list, `kubectx <name>` to
  switch, `kubectx -` for the previous context, `kubectx -c` for the current
  one, `kubectx <new>=<old>` to rename, `kubectx -d <name>` to delete,
  `kubectx -s <name>` / `-r <name>` for a scoped or read-only shell.

A single static binary with no runtime dependencies. Its sibling tool for
namespaces is [`ocx.sh/kubectx/kubens`](https://index.ocx.sh/kubectx/kubens),
published from the same upstream releases.

## Links

- [kubectx + kubens on GitHub](https://github.com/ahmetb/kubectx)
- [Installation and usage](https://github.com/ahmetb/kubectx#usage)
- [Shell completion scripts](https://github.com/ahmetb/kubectx/tree/master/completion)
