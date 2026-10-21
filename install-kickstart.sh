#!/bin/bash
# install-kickstart.sh -- ensure the neovim config exists and carries our
# overrides on top of upstream kickstart.nvim.
#
# Exists so this capability can run standalone, without re-running the whole
# init.sh. init.sh calls it too; see the README capability map.
#
#   ./install-kickstart.sh            ensure installed, apply overrides, verify
#   ./install-kickstart.sh --update   also reset to upstream master first
#
# Idempotent: safe to re-run at any time. The default form never moves the
# checkout, so it will not surprise you mid-edit. --update discards local
# changes to the config by design -- our personalizations do not live in the
# tracked tree, they live in nvim/ in this repo and are re-applied on top.
#
# Architecture (mirrors sync-backup.sh: generic engine, data separate):
#   install-kickstart.sh                  this engine
#   nvim/lua/custom/plugins/*.lua         our plugins (copied into the config)
#   nvim/nvim-pack-lock.json              pinned plugin versions
#
# Overridable: NVIM_CONFIG, KICKSTART_URL, TREE_SITTER_VERSION.

set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NVIM_CONFIG="${NVIM_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/nvim}"
KICKSTART_URL="${KICKSTART_URL:-https://github.com/nvim-lua/kickstart.nvim.git}"

UPDATE=0
[ "${1:-}" = "--update" ] && UPDATE=1

echo "==> Installing neovim config ($NVIM_CONFIG)"

# tree-sitter CLI: kickstart.nvim installs parsers with it, so it is a
# config dependency rather than a general-purpose tool here. Pinned because
# releases >=0.26.x need GLIBC 2.39 (Debian trixie) while bookworm ships
# 2.36. Bump when trixie becomes the base image.
TREE_SITTER_VERSION="${TREE_SITTER_VERSION:-0.25.10}"
TREE_SITTER_BIN="/usr/local/bin/tree-sitter"
if ! command -v tree-sitter >/dev/null 2>&1 || ! tree-sitter --version >/dev/null 2>&1; then
    echo "==> Installing tree-sitter CLI v${TREE_SITTER_VERSION}"
    curl -fsSL "https://github.com/tree-sitter/tree-sitter/releases/download/v${TREE_SITTER_VERSION}/tree-sitter-linux-x64.gz" \
        | gunzip > /tmp/tree-sitter
    chmod +x /tmp/tree-sitter
    sudo mv /tmp/tree-sitter "$TREE_SITTER_BIN"
fi

# Full clone (no --depth) so --update can reset to upstream.
if [ -d "$NVIM_CONFIG/.git" ]; then
    echo "==> Config already present at $NVIM_CONFIG"
else
    echo "==> Cloning $KICKSTART_URL"
    git clone "$KICKSTART_URL" "$NVIM_CONFIG"
fi

if [ "$UPDATE" = "1" ]; then
    # Track upstream's default branch rather than hardcoding master.
    DEFAULT="$(git -C "$NVIM_CONFIG" symbolic-ref --quiet --short "refs/remotes/origin/HEAD" 2>/dev/null || true)"
    DEFAULT="${DEFAULT#origin/}"
    [ -n "$DEFAULT" ] || DEFAULT=master
    echo "==> Updating config to origin/$DEFAULT"
    git -C "$NVIM_CONFIG" fetch origin
    git -C "$NVIM_CONFIG" reset --hard "origin/$DEFAULT"
fi

# 1. Enable the loader. Upstream ships lua/custom/plugins/init.lua but leaves
#    `require 'custom.plugins'` commented out in init.lua; that one line is
#    the only edit we make to a tracked upstream file. Idempotent, and falls
#    back to appending if upstream ever reformats the line.
INIT_LUA="$NVIM_CONFIG/init.lua"
if grep -q "^[^--]*require 'custom\.plugins'" "$INIT_LUA"; then
    echo "==> custom plugin loader already enabled"
elif grep -q "^[[:space:]]*--[[:space:]]*require 'custom\.plugins'" "$INIT_LUA"; then
    sed -i "s|^[[:space:]]*--[[:space:]]*require 'custom\.plugins'|  require 'custom.plugins'|" "$INIT_LUA"
    echo "==> Enabled custom plugin loader"
else
    printf "\n-- chuboe: enable the custom plugin loader (see install-kickstart.sh)\nrequire 'custom.plugins'\n" >> "$INIT_LUA"
    echo "==> Appended custom plugin loader (upstream line format changed)" >&2
fi

# 2. Copy our plugins. Upstream ships lua/custom/plugins/init.lua -- the
#    loader itself -- so skip our init.lua and let theirs stand.
mkdir -p "$NVIM_CONFIG/lua/custom/plugins"
for plugin in "$SRC"/nvim/lua/custom/plugins/*.lua; do
    [ -e "$plugin" ] || continue
    [ "$(basename "$plugin")" = "init.lua" ] && continue
    cp "$plugin" "$NVIM_CONFIG/lua/custom/plugins/$(basename "$plugin")"
    echo "==> Overrode $(basename "$plugin")"
done

# 3. Pin plugin versions. Upstream gitignores nvim-pack-lock.json precisely so
#    forks do not conflict over it -- which is what we want here, since ours
#    is tracked in this repo and copied in.
cp "$SRC/nvim/nvim-pack-lock.json" "$NVIM_CONFIG/nvim-pack-lock.json"
echo "==> Pinned plugin versions from nvim/nvim-pack-lock.json"

# 4. Verify. A broken config fails here at install time rather than silently
#    on the operator's first keystroke.
if ! command -v nvim >/dev/null 2>&1; then
    echo "Warning: nvim is not on PATH yet -- run install-neovim.sh to verify the load" >&2
    exit 0
fi
echo "==> Verifying config loads"
XDG_CONFIG_HOME="$(dirname "$NVIM_CONFIG")" nvim --headless \
    -c 'lua print("chuboe-check: " .. #vim.pack.get() .. " plugins loaded")' \
    -c 'qa'
echo "==> neovim config ready"