#!/usr/bin/env bash
# Restore Tahoe components that package updates can overwrite or invalidate.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_DIR="$HOME/.local/state/tahoe"
LOCK_FILE="$STATE_DIR/auto-repair.lock"
VERSION_FILE="$STATE_DIR/kwin-package-version"
LOG_PREFIX="[Tahoe auto-repair]"

mkdir -p "$STATE_DIR"
exec 9>"$LOCK_FILE"
flock -n 9 || exit 0

kwin_version="$(dpkg-query -W -f='${Version}' kwin-wayland 2>/dev/null || true)"
saved_version="$(cat "$VERSION_FILE" 2>/dev/null || true)"

if [[ ! -f "$HOME/.local/lib/kvantum-dialog-alpha-fix.so" ]] ||
   [[ ! -x "$HOME/.local/bin/tahoe-dolphin" ]] ||
   ! grep -q "^Exec=$HOME/.local/bin/tahoe-dolphin " \
      "$HOME/.local/share/applications/org.kde.dolphin.desktop" 2>/dev/null ||
   ! grep -q '^X-KDE-Shortcuts=Meta+E$' \
      "$HOME/.local/share/applications/tahoe-dolphin-shortcut.desktop" 2>/dev/null; then
    echo "$LOG_PREFIX restoring Dolphin dialog alpha hook"
    "$ROOT/tools/install-kvantum-dialog-alpha-fix.sh"
fi

forceblur_plugin="/usr/lib/x86_64-linux-gnu/qt6/plugins/kwin/effects/plugins/forceblur.so"
if [[ ! -f "$forceblur_plugin" ]] ||
   [[ -n "$kwin_version" && "$kwin_version" != "$saved_version" ]]; then
    echo "$LOG_PREFIX KWin changed: ${saved_version:-unknown} -> $kwin_version"
    "$ROOT/tools/install-kwin-forceblur.sh"
elif [[ "$(kreadconfig6 --file kwinrc --group Plugins --key forceblurEnabled 2>/dev/null)" != true ]] ||
     [[ "$(qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.isEffectLoaded forceblur 2>/dev/null || true)" != true ]]; then
    echo "$LOG_PREFIX re-enabling window forceblur"
    kwriteconfig6 --file kwinrc --group Plugins --key blurEnabled false
    kwriteconfig6 --file kwinrc --group Plugins --key forceblurEnabled true
    qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.unloadEffect blur >/dev/null 2>&1 || true
    qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.loadEffect forceblur >/dev/null 2>&1 || true
fi

if ! grep -q 'Description=Translucency: Dolphin-style glass for ALL other windows' \
    "$HOME/.config/kwinrulesrc" 2>/dev/null; then
    echo "$LOG_PREFIX restoring window translucency rules"
    "$ROOT/tools/install-kwin-window-rules.sh"
fi

overview_qml="/usr/lib/x86_64-linux-gnu/qt6/qml/org/kde/kwin/private/effects/WindowHeapDelegate.qml"
if ! grep -q 'property Item backdropSource' "$overview_qml" 2>/dev/null; then
    echo "$LOG_PREFIX restoring Overview backdrop blur"
    "$ROOT/tools/rebuild-install-kwin-overview-blur.sh"
fi

printf '%s\n' "$kwin_version" > "$VERSION_FILE"
echo "$LOG_PREFIX state is current; log out or reboot if KWin files changed"
