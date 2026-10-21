#!/bin/bash
# install-neovim.sh -- build neovim from source at its moving `stable` tag.
#
# Exists so this capability can run standalone, without re-running the whole
# init.sh. init.sh calls it too; see the README capability map.
#
# Idempotent: the commit that was last built is recorded in $NEOVIM_STATE.
# Re-running when `stable` has not moved prints a notice and exits without
# rebuilding -- a full clean rebuild is minutes of CPU. Move the state file
# (or set NEOVIM_FORCE=1) to force one.
#
# Overridable: NEOVIM_SRC, NEOVIM_STATE, NEOVIM_REF, NEOVIM_FORCE.
#
# Why the tag and not a branch: neovim publishes `stable` as a TAG that the
# release process force-moves, and has no `stable` branch. A plain
# `git fetch --tags` refuses to update an existing tag ("would clobber
# existing tag"), so the fetch needs --force or the tag -- and therefore the
# version we build -- stays frozen at whatever the first clone saw.

set -euo pipefail

NEOVIM_SRC="${NEOVIM_SRC:-$HOME/.local/src/neovim}"
NEOVIM_STATE="${NEOVIM_STATE:-$HOME/.local/state/neovim-built-sha}"
NEOVIM_REF="${NEOVIM_REF:-stable}"
NEOVIM_FORCE="${NEOVIM_FORCE:-0}"

# --force is load-bearing: see the note above. Do not drop it.
fetch_tags() {
    git -C "$NEOVIM_SRC" fetch --tags --prune --force origin
}

echo "==> Installing neovim ($NEOVIM_REF)"

sudo apt install -y ninja-build gettext cmake unzip curl git # neovim dependencies

mkdir -p "$(dirname "$NEOVIM_SRC")" "$(dirname "$NEOVIM_STATE")"

if [ -d "$NEOVIM_SRC/.git" ]; then
    fetch_tags
else
    git clone https://github.com/neovim/neovim "$NEOVIM_SRC"
    fetch_tags
fi

# Peel the annotated tag to the commit it points at -- that, not the tag
# object, is what identifies a build.
TARGET="$(git -C "$NEOVIM_SRC" rev-parse "refs/tags/$NEOVIM_REF^{}")"
BUILT="$(cat "$NEOVIM_STATE" 2>/dev/null || true)"

if [ "$NEOVIM_FORCE" != "1" ] && [ "$BUILT" = "$TARGET" ] && command -v nvim >/dev/null 2>&1; then
    echo "==> neovim already built at $NEOVIM_REF ($TARGET) -- skipping rebuild"
    nvim --version | head -1
    exit 0
fi

git -C "$NEOVIM_SRC" checkout --detach "$TARGET"

# Drop the previous build dir so a toolchain change actually rebuilds;
# incremental cmake otherwise keeps stale caches.
rm -rf "$NEOVIM_SRC/build"
make -C "$NEOVIM_SRC" CMAKE_BUILD_TYPE=Release -j"$(nproc)"
sudo make -C "$NEOVIM_SRC" install

# Record only after a successful install, so a failed build is retried.
printf '%s\n' "$TARGET" > "$NEOVIM_STATE"

if ! command -v nvim >/dev/null 2>&1; then
    echo "Error: nvim is not on PATH after install" >&2
    exit 1
fi
nvim --version | head -1
echo "==> neovim ready at $NEOVIM_REF ($TARGET)"