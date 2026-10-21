# Refresh Neovim Config and Binary

The purpose of this document is to be short: refreshing neovim and its config
is now a script you run, not a procedure you follow by hand.

## Refresh

```bash
~/chuboe-system-configurator/install-kickstart.sh --update   # config -> upstream master
~/chuboe-system-configurator/install-neovim.sh               # binary -> latest stable
```

Both are idempotent. `install-kickstart.sh` without `--update` re-applies the
overrides in `nvim/` without moving the checkout, which is the right call if you
have local edits to look at. `install-neovim.sh` skips the rebuild when the
`stable` tag has not moved, so it costs nothing to run.

## Where Things Live

- **Personalizations** — `nvim/lua/custom/plugins/*.lua` and
  `nvim/nvim-pack-lock.json` in this repo. These are the source of truth.
- **The config** — `~/.config/nvim`, a clone of
  [nvim-lua/kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim).
  Only `init.lua` is modified (one line, to enable kickstart's own
  `lua/custom/plugins` loader); everything else is upstream's.
- **The binary** — built from source at neovim's `stable` tag into
  `/usr/local/bin/nvim`. The last built commit is recorded in
  `~/.local/state/neovim-built-sha` so no-op reruns are free.

Editing a file under `~/.config/nvim` directly is wasted work — the next
`--update` resets it. Edit it in this repo and re-run the script.

## Editing a Personalization

1. Edit the file in `nvim/lua/custom/plugins/`.
2. Run `~/chuboe-system-configurator/install-kickstart.sh`.
3. Commit the change here so the next machine gets it too.

Do not add a file named `init.lua` there. Kickstart ships its own
`lua/custom/plugins/init.lua` (the loader that reads the directory); the script
skips our copy of that name on purpose so upstream's loader stays in place.

## Migrating a Host Still on the Old Fork

Hosts configured before this change cloned
`https://github.com/cboecking/kickstart.nvim.git`. The script leaves an existing
checkout alone, so re-point it once:

```bash
git -C ~/.config/nvim remote set-url origin https://github.com/nvim-lua/kickstart.nvim.git
git -C ~/.config/nvim fetch origin
git -C ~/.config/nvim reset --hard origin/master
~/chuboe-system-configurator/install-kickstart.sh
```

## Troubleshooting

- **Config fails to load.** `install-kickstart.sh` verifies the config headless
  at the end and fails loudly. Run it directly to see the error.
- **nvim missing after install.** Check `nvim --version`; then
  `~/.local/state/neovim-built-sha` against
  `git -C ~/.local/src/neovim rev-parse 'refs/tags/stable^{}'`.
- **Force a neovim rebuild.** `NEOVIM_FORCE=1 ~/chuboe-system-configurator/install-neovim.sh`.

#workflow #neovim