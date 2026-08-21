#!/usr/bin/env bash
# Build and install "kvantum-dialog-alpha-fix" -- a tiny LD_PRELOAD shim that
# lets Kvantum give Dolphin's own dialogs (Properties, Rename, "Open With",
# ...) the SAME real per-pixel background alpha as Dolphin's main window,
# instead of falling back to a whole-window KWin compositor opacity rule.
#
# Background: Kvantum makes a top-level window translucent (background
# painted semi-transparent, text/icons stay fully opaque) by setting
# Qt::WA_TranslucentBackground on it BEFORE its native surface is created --
# see style/polishing.cpp in the Kvantum source (local clone:
# ~/whitesur-build/Kvantum/Kvantum/). If the native surface already exists by
# the time Kvantum's polish() runs (widget->testAttribute(WA_WState_Created)),
# Kvantum permanently gives up on that window: `window->format()
# .alphaBufferSize() != 8`. That's exactly what happens for Dolphin's KIO
# dialogs (confirmed with a standalone Qt6 test program, see
# source/kvantum-dialog-alpha-fix/winid-alpha-hook.cpp comment): they call
# QWidget::winId() during construction -- before Kvantum ever sees them -- to
# set up the transient-for parent relationship, which forces early native
# window creation. QMenu popups don't do this, which is why menus already
# rendered correctly (background-only translucency) and dialogs didn't: their
# background was forced fully to a whole-window compositor opacity rule
# instead, which -- unlike per-pixel alpha -- has no way to spare icons/text,
# leaving them visibly blurry/see-through.
#
# Fix: interpose QWidget::winId() (source in
# source/kvantum-dialog-alpha-fix/winid-alpha-hook.cpp) so that any QDialog
# not yet created gets WA_TranslucentBackground/WA_NoSystemBackground set
# first -- exactly what Kvantum's own polish() would do anyway, just early
# enough to matter. Verified end to end (pixel comparison of the same dialog
# over two different desktop backgrounds): icon/text pixels now stay
# constant regardless of backdrop, only the background pixels track it.
#
# This alone is not sufficient -- also required, done by this script/other
# tools in this repo:
#   1. `dialog-normal`/`dialog-normal-inactive` in Kvantum/MacTahoe/MacTahoe.svg
#      need real alpha (opacity="0.75", matching window-normal) -- otherwise
#      the now-translucency-capable surface still paints a fully opaque fill.
#   2. Dolphin must be excluded from the KWin Window Rule that forces
#      compositor-level opacity on every other window (see
#      install-kwin-window-rules.sh, NATIVE_ALPHA_FULL_CLASSES) -- otherwise
#      the compositor rule's opacity multiplies with Kvantum's own native
#      alpha a second time (0.75*0.75=0.5625), the same double-multiplication
#      bug already fixed once for Dolphin's main window (see
#      notes/CURRENT_STATE.md, "Баг: двойное умножение alpha").
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/source/kvantum-dialog-alpha-fix/winid-alpha-hook.cpp"
LIB_DIR="$HOME/.local/lib"
LIB="$LIB_DIR/kvantum-dialog-alpha-fix.so"

DESKTOP_SRC="/usr/share/applications/org.kde.dolphin.desktop"
DESKTOP_DIR="$HOME/.local/share/applications"
DESKTOP_DST="$DESKTOP_DIR/org.kde.dolphin.desktop"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}
require_command g++
require_command pkg-config
require_command qdbus6

pkg-config --exists Qt6Widgets Qt6Gui Qt6Core || {
  echo "Missing Qt6 dev packages (qt6-base-dev or similar)" >&2
  exit 1
}

# --- 1. Build ----------------------------------------------------------
mkdir -p "$LIB_DIR"
g++ -O2 -fPIC -shared \
  $(pkg-config --cflags Qt6Widgets Qt6Gui Qt6Core) \
  "$SRC" -o "$LIB" \
  $(pkg-config --libs Qt6Widgets Qt6Gui Qt6Core) -ldl
echo "Built: $LIB"

# --- 2. Wire it into Dolphin's launch via a user-level .desktop override --
if [[ ! -f "$DESKTOP_SRC" ]]; then
  echo "Missing $DESKTOP_SRC -- is Dolphin installed?" >&2
  exit 1
fi

mkdir -p "$DESKTOP_DIR"
if [[ -f "$DESKTOP_DST" ]]; then
  cp -a "$DESKTOP_DST" "$DESKTOP_DST.bak-$(date +%Y%m%d-%H%M%S)"
fi

sed -E "s#^Exec=dolphin #Exec=env LD_PRELOAD=$LIB dolphin #" \
  "$DESKTOP_SRC" > "$DESKTOP_DST"

if ! grep -q "^Exec=env LD_PRELOAD=$LIB dolphin " "$DESKTOP_DST"; then
  echo "Failed to patch Exec= line in $DESKTOP_DST -- check $DESKTOP_SRC's Exec= syntax by hand" >&2
  exit 1
fi
echo "Installed: $DESKTOP_DST"

echo
echo "Also required (not done by this script -- see other tools/notes):"
echo "  - MacTahoe.svg dialog-normal/-inactive opacity=0.75 (Kvantum SVG)"
echo "  - dolphin listed in NATIVE_ALPHA_FULL_CLASSES when running"
echo "    install-kwin-window-rules.sh"
echo
echo "Existing Dolphin windows do NOT pick this up (they're already running"
echo "without the preload, and Dolphin is a D-Bus single-instance app, so a"
echo "plain relaunch just messages the old process). Apply now with:"
echo "  pkill -9 -x dolphin && setsid -f dolphin &"
