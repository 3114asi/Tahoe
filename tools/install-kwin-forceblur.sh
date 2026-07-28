#!/usr/bin/env bash
# Build, install and configure the "Force Blur (6.7)" KWin effect, patched to
# also blur the window decoration/titlebar for the configured window classes.
#
# Background: KWin's native blur effect only blurs a window's CONTENT region
# if the app registers one itself (Kvantum does this for Dolphin's sidebar via
# KWindowEffects::enableBlurBehind). It can also blur the DECORATION/titlebar,
# but only if the active decoration plugin calls
# KDecoration3::Decoration::setBlurRegion() — the currently active Aurorae
# backend (org.kde.kwin.aurorae.v2) never does this, so the MacTahoe titlebar
# stayed sharp-transparent even with alpha<1 fills in decoration.svg (verified
# empirically: legacy org.kde.kwin.aurorae doesn't do it either).
#
# This build starts from KWin 6.7's own Blur effect source (guaranteed to
# compile against this KWin) and adds ~40 lines:
#   1. force blur by window class (upstreamed from the MacOS/WhiteSur project's
#      kwin-forceblur-6.7, see ../MacOS/docs/KWIN_FORCEBLUR.md) — blurs the
#      whole CONTENT region for windows whose class matches, even if they
#      never request blur themselves;
#   2. forceDecorationBlurRegion() (Tahoe addition) — for the same matched
#      window classes, also blurs the decoration-minus-contents region
#      directly from decoration geometry, bypassing Aurorae's cooperation
#      requirement entirely.
#
# See docs/KWIN_FORCEBLUR_DECORATION.md for the full rationale, the exact
# patch, and verification method (pixel comparison against raw wallpaper).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOME_DIR="${HOME}"
SRC_DIR="$ROOT/source/kwin-forceblur-6.7"
BUILD_DIR="$ROOT/tmp/build-kwin-forceblur"

# Window classes that should be force-blurred, content AND decoration
# (comma-separated for KWin, or "*" to force-blur every window regardless of
# class). Default is "*" so every window's frame gets the same translucent
# look as Dolphin's; set FORCEBLUR_CLASSES to a specific comma-separated list
# to scope it back down to particular apps instead.
FORCEBLUR_CLASSES="${FORCEBLUR_CLASSES:-*}"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

# --- 0. Build dependencies (KDE neon / Kubuntu / Ubuntu) -------------------
BUILD_DEPS=(
  cmake g++ kf6-extra-cmake-modules qt6-base-dev qt6-base-private-dev
  kwin-dev libkf6configwidgets-dev libkf6coreaddons-dev libkf6windowsystem-dev
  libkf6i18n-dev libkdecorations3-dev libepoxy-dev libxcb1-dev
)
if command -v apt-get >/dev/null 2>&1; then
  missing=()
  for pkg in "${BUILD_DEPS[@]}"; do
    dpkg -s "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
  done
  if (( ${#missing[@]} )); then
    echo "Installing build dependencies: ${missing[*]}"
    sudo apt-get update -qq || true
    sudo apt-get install -y --no-install-recommends "${missing[@]}"
  fi
fi

require_command cmake
require_command qdbus6

# --- 1. Build --------------------------------------------------------------
rm -rf "$BUILD_DIR"
cmake -S "$SRC_DIR" -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Release
cmake --build "$BUILD_DIR" --parallel
SO="$BUILD_DIR/src/forceblur.so"
[[ -f "$SO" ]] || { echo "Build failed: $SO not found" >&2; exit 1; }

# --- 2. Install the plugin (system-wide; KWin does not reliably scan ~/) ----
PLUGIN_BASE="$(qtpaths6 --query QT_INSTALL_PLUGINS 2>/dev/null || echo "/usr/lib/$(gcc -dumpmachine)/qt6/plugins")"
DEST="$PLUGIN_BASE/kwin/effects/plugins"
sudo mkdir -p "$DEST"
sudo install -m 0644 "$SO" "$DEST/forceblur.so"
echo "Installed: $DEST/forceblur.so"

# --- 3. Configure KWin -----------------------------------------------------
if command -v kwriteconfig6 >/dev/null 2>&1; then KWRITE=kwriteconfig6; else KWRITE=kwriteconfig5; fi
# Our effect replaces the built-in blur (must be off, or Qt windows double-blur).
"$KWRITE" --file kwinrc --group Plugins     --key blurEnabled false
"$KWRITE" --file kwinrc --group Plugins     --key forceblurEnabled true
"$KWRITE" --file kwinrc --group Effect-blur --key BlurStrength 15
"$KWRITE" --file kwinrc --group Effect-blur --key NoiseStrength 0
"$KWRITE" --file kwinrc --group Effect-blur --key WindowClasses "$FORCEBLUR_CLASSES"

# --- 4. Apply live -----------------------------------------------------------
# Order matters: unload built-in blur FIRST (it owns the Wayland blur
# capability), then load ours, so exactly one effect advertises the capability
# to Qt/Kvantum clients (otherwise Dolphin's own content blur stops working).
# A freshly (re)installed plugin is only auto-discovered at KWin startup, so
# we explicitly unload+load it here to pick up a rebuilt .so; on the next
# login it loads automatically from the config above.
qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.unloadEffect blur      >/dev/null 2>&1 || true
qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.unloadEffect forceblur >/dev/null 2>&1 || true
qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.loadEffect   forceblur >/dev/null 2>&1 || true
qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true

echo "Force Blur (6.7, decoration patch) installed and configured."
echo "  plugin:        $DEST/forceblur.so"
echo "  force classes: $FORCEBLUR_CLASSES"
echo "  loaded now:    $(qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.isEffectLoaded forceblur 2>/dev/null)"
