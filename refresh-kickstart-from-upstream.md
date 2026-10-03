# Refresh Kickstart From Upstream

The purpose of this document is to guide the recurring refresh of a personal `nvim-lua/kickstart.nvim` fork against upstream `master`, so the local dotfile stays current with the upstream changes we have consciously chosen to track.

This document is important because the kickstart fork drifts out of date whenever upstream advances, and a few recurring edits must be re-applied on every sync. Catching up only after a long lag makes the rebase harder. Both `[YOUR_USER]/kickstart.nvim` and `[YOUR_USER]/chuboe-system-configurator` ship from the same host: `init.sh` is what installs and upgrades nvim itself, so a kickstart refresh often needs a matching `init.sh` refresh.

## TOC

- [When to Refresh](#when-to-refresh)
- [Prerequisites](#prerequisites)
- [Procedure](#procedure)
- [What Gets Wiped on Rebase](#what-gets-wiped-on-rebase)
- [Validate on a Disposable Container](#validate-on-a-disposable-container)
- [Tags](#tags)

## When to Refresh

Refresh when any of the following are true:

- `git log --oneline upstream/master..HEAD` is non-empty inside `~/.config/nvim/` — the local fork has fallen behind upstream.
- The user upgraded nvim and upstream kickstart dropped compatibility with the previous version.
- A clean install shows treesitter breakage — a common signal that upstream has moved on while a frozen local branch stayed pinned.

## Prerequisites

- `~/.config/nvim/` cloned from `[YOUR_USER]/kickstart.nvim` with `origin` pointing at the fork and `upstream` pointing at `https://github.com/nvim-lua/kickstart.nvim.git`.
- nvim at `v0.12+` installed by `[YOUR_USER]/chuboe-system-configurator/init.sh`.
- An Incus client, used to validate the refresh before pushing.

> 💡 **Tip** — The `upstream` remote is a read-only convenience added during the first sync. Re-add it at any time with `git -C ~/.config/nvim remote add upstream https://github.com/nvim-lua/kickstart.nvim.git`.

## Procedure

- [ ] Fetch upstream and see how far behind the local fork is:

    ```bash
    git -C ~/.config/nvim fetch upstream
    git -C ~/.config/nvim log --oneline upstream/master..HEAD
    ```

- [ ] Read the diff scope. A handful of commits is usually a fast-forward; dozens of commits spanning a `vim.pack` migration or a `init.lua` restructure usually means a clean reset is faster than cherry-picking.
- [ ] If the diff is large enough to warrant a reset, snapshot the current HEAD as a tag first:

    ```bash
    git -C ~/.config/nvim tag backup/pre-rebase-$(date +%Y-%m-%d)
    ```

- [ ] Reset local `master` to upstream:

    ```bash
    git -C ~/.config/nvim reset --hard upstream/master
    ```

- [ ] Re-apply the recurring edits — see [What Gets Wiped on Rebase](#what-gets-wiped-on-rebase).
- [ ] Re-apply the personal custom plugins in `lua/custom/plugins/`, translated to the current `vim.pack.add` style.
- [ ] Update `.gitignore` so the lockfile `nvim-pack-lock.json` is tracked on this personal fork (per the kickstart README guidance for personal forks).
- [ ] Verify the local config loads cleanly:

    ```bash
    nvim --headless -c 'lua print("blink-emoji:", pcall(require, "blink-emoji"))' -c 'qa'
    ```

- [ ] Commit and force-push to the personal fork:

    ```bash
    git -C ~/.config/nvim add -A
    git -C ~/.config/nvim commit -m "Sync to upstream/master and migrate custom plugins to vim.pack"
    git -C ~/.config/nvim push --force-with-lease origin master
    ```

> ⚠️ **Warning** — `--force-with-lease` overwrites the personal fork's history. Only safe when `origin/master` has not moved since the last fetch. Confirm with `git -C ~/.config/nvim fetch origin && git -C ~/.config/nvim status` before pushing.

- [ ] If `chuboe-system-configurator/init.sh` also needs changes (e.g., the `tree-sitter-cli` pin moved, or the neovim version it tracks bumped), commit and push them too.

## What Gets Wiped on Rebase

The upstream kickstart keeps these user customization points commented out so users opt in explicitly:

- The `require 'custom.plugins'` line in `init.lua` — the convenience loader for `lua/custom/plugins/*.lua`. Uncomment it; re-apply on every upstream sync.
- Any `kickstart.plugins.*` require that was previously enabled (debug, lint, indent_line, autopairs, neo-tree).

The upstream `.gitignore` keeps `nvim-pack-lock.json` uncommented; in a personal fork, comment it so the lockfile is committed. The upstream README recommends this.

The new `vim.pack` plugin manager does not auto-import from `lua/custom/plugins/`. The convenience loader uncommented above is the documented replacement for the lazy.nvim `{ import = 'custom.plugins' }` setup-table entry — that line simply does not exist anymore.

## Validate on a Disposable Container

Pushing the local fork without validating on a fresh install risks shipping a broken tree. The pattern that has worked:

- [ ] `incus launch images:debian/13/cloud delme-nvim-test-01`
- [ ] Inside the container, install `git`, clone `[YOUR_USER]/chuboe-system-configurator`, and run `./init.sh` end-to-end.
- [ ] Verify nvim, tree-sitter, and both custom plugins load. Verify tree-sitter parsers install and a Lua buffer is parsed — `vim.treesitter.get_parser(0, "lua")` returns a parser whose root is `chunk`.
- [ ] `incus delete delme-nvim-test-01 --force`.

Only after the container install succeeds should the personal fork be force-pushed.

> 📝 **Note** — The disposable container tests the *bootstrap* path. It does not test the *refresh* path. A refresh that compiles and passes locally but fails on a fresh bootstrap is a `chuboe-system-configurator/init.sh` regression, not a kickstart regression.

## Tags

#workflow #refactor #neovim