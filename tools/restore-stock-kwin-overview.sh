#!/usr/bin/env bash
# Restore the stock KWin binary saved before the Tahoe Overview patch.
set -euo pipefail

KWIN_UPSTREAM_VERSION="$(dpkg-query -W -f='${source:Upstream-Version}' kwin-wayland)"
BACKUP_FILE="/var/backups/tahoe-kwin/kwin_wayland-${KWIN_UPSTREAM_VERSION}-stock"
QML_FILE="/usr/lib/x86_64-linux-gnu/qt6/qml/org/kde/kwin/private/effects/WindowHeapDelegate.qml"
QML_BACKUP_FILE="/var/backups/tahoe-kwin/WindowHeapDelegate-${KWIN_UPSTREAM_VERSION}-stock.qml"
QML_PLUGIN_FILE="/usr/lib/x86_64-linux-gnu/qt6/qml/org/kde/kwin/private/effects/libeffectsplugin.so"
QML_PLUGIN_BACKUP_FILE="/var/backups/tahoe-kwin/libeffectsplugin-${KWIN_UPSTREAM_VERSION}-stock.so"

if [[ ! -f "$BACKUP_FILE" ]]; then
    echo "Backup not found: $BACKUP_FILE" >&2
    echo "Reinstall instead: sudo apt-get install --reinstall kwin-wayland" >&2
    exit 1
fi

sudo install -m 0755 "$BACKUP_FILE" /usr/bin/kwin_wayland
if [[ -f "$QML_BACKUP_FILE" ]]; then
    sudo install -m 0644 "$QML_BACKUP_FILE" "$QML_FILE"
else
    echo "QML backup not found: $QML_BACKUP_FILE" >&2
    echo "Reinstall kwin-common to restore the stock QML file." >&2
    exit 1
fi
if [[ -f "$QML_PLUGIN_BACKUP_FILE" ]]; then
    sudo install -m 0644 "$QML_PLUGIN_BACKUP_FILE" "$QML_PLUGIN_FILE"
else
    echo "QML plugin backup not found: $QML_PLUGIN_BACKUP_FILE" >&2
    echo "Reinstall kwin-common to restore the stock QML plugin." >&2
    exit 1
fi
echo "Restored stock KWin $KWIN_UPSTREAM_VERSION."
echo "Log out and back in (or reboot) to start it."
