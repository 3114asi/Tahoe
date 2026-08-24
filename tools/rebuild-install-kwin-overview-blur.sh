#!/usr/bin/env bash
# Rebuild the installed Neon KWin version with Tahoe Overview backdrop blur.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PATCH_FILE="$ROOT_DIR/patches/kwin-6.7.4-overview-backdrop-blur.patch"
KWIN_DEB_VERSION="$(dpkg-query -W -f='${Version}' kwin-wayland)"
KWIN_UPSTREAM_VERSION="$(dpkg-query -W -f='${source:Upstream-Version}' kwin-wayland)"
BACKUP_DIR="/var/backups/tahoe-kwin"
BACKUP_FILE="$BACKUP_DIR/kwin_wayland-${KWIN_UPSTREAM_VERSION}-stock"
QML_FILE="/usr/lib/x86_64-linux-gnu/qt6/qml/org/kde/kwin/private/effects/WindowHeapDelegate.qml"
QML_BACKUP_FILE="$BACKUP_DIR/WindowHeapDelegate-${KWIN_UPSTREAM_VERSION}-stock.qml"
QML_PLUGIN_FILE="/usr/lib/x86_64-linux-gnu/qt6/qml/org/kde/kwin/private/effects/libeffectsplugin.so"
QML_PLUGIN_BACKUP_FILE="$BACKUP_DIR/libeffectsplugin-${KWIN_UPSTREAM_VERSION}-stock.so"
BUILD_TMP_BASE="${TAHOE_BUILD_TMPDIR:-$ROOT_DIR/tmp}"
BUILD_JOBS="${TAHOE_BUILD_JOBS:-4}"
mkdir -p "$BUILD_TMP_BASE"
export TMPDIR="$BUILD_TMP_BASE"
WORK_DIR="$(mktemp -d -p "$BUILD_TMP_BASE" kwin-overview.XXXXXX)"

cleanup() {
    rm -rf -- "$WORK_DIR"
}
trap cleanup EXIT

if [[ "$KWIN_UPSTREAM_VERSION" != "6.7.4" ]]; then
    echo "Unsupported KWin version: $KWIN_UPSTREAM_VERSION" >&2
    echo "Port and dry-run $PATCH_FILE before installing it on a newer KWin." >&2
    exit 1
fi

sudo apt-get build-dep -y "kwin=$KWIN_DEB_VERSION"
sudo apt-get install -y --no-install-recommends patchelf

(
    cd "$WORK_DIR"
    apt-get source "kwin=$KWIN_DEB_VERSION"
)

SOURCE_DIR="$(find "$WORK_DIR" -mindepth 1 -maxdepth 1 -type d -name 'kwin-*' -print -quit)"
if [[ -z "$SOURCE_DIR" ]]; then
    echo "KWin source directory was not created" >&2
    exit 1
fi

patch --dry-run -p1 -d "$SOURCE_DIR" < "$PATCH_FILE"
patch -p1 -d "$SOURCE_DIR" < "$PATCH_FILE"

CC=gcc-14 CXX=g++-14 cmake -S "$SOURCE_DIR" -B "$WORK_DIR/build" \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DBUILD_TESTING=OFF \
    -DKWIN_BUILD_KCMS=OFF \
    -DKWIN_BUILD_RUNNERS=OFF \
    -DKWIN_BUILD_NOTIFICATIONS=OFF
cmake --build "$WORK_DIR/build" --target kwin_wayland effectsplugin -j"$BUILD_JOBS"

QML_PLUGIN_BUILD="$(find "$WORK_DIR/build" -type f -name libeffectsplugin.so -print -quit)"
if [[ -z "$QML_PLUGIN_BUILD" ]]; then
    echo "The rebuilt private effects QML plugin was not found" >&2
    exit 1
fi

install -m 0755 "$WORK_DIR/build/bin/kwin_wayland" "$WORK_DIR/kwin_wayland"
strip --strip-unneeded "$WORK_DIR/kwin_wayland"
patchelf --remove-rpath "$WORK_DIR/kwin_wayland"

if ldd "$WORK_DIR/kwin_wayland" | grep -q 'not found'; then
    echo "The rebuilt binary has unresolved libraries" >&2
    ldd "$WORK_DIR/kwin_wayland" >&2
    exit 1
fi
if [[ "$("$WORK_DIR/kwin_wayland" --version)" != "kwin $KWIN_UPSTREAM_VERSION" ]]; then
    echo "The rebuilt binary version does not match the installed package" >&2
    exit 1
fi
if [[ "$("$WORK_DIR/kwin_wayland" --no-lockscreen --version)" != "kwin $KWIN_UPSTREAM_VERSION" ]]; then
    echo "The rebuilt binary does not accept plasmalogin's --no-lockscreen argument" >&2
    exit 1
fi

sudo install -d -m 0755 "$BACKUP_DIR"
if [[ ! -e "$BACKUP_FILE" ]]; then
    sudo install -m 0755 /usr/bin/kwin_wayland "$BACKUP_FILE"
fi
if [[ ! -e "$QML_BACKUP_FILE" ]]; then
    sudo install -m 0644 "$QML_FILE" "$QML_BACKUP_FILE"
fi
if [[ ! -e "$QML_PLUGIN_BACKUP_FILE" ]]; then
    sudo install -m 0644 "$QML_PLUGIN_FILE" "$QML_PLUGIN_BACKUP_FILE"
fi
sudo install -m 0755 "$WORK_DIR/kwin_wayland" /usr/bin/kwin_wayland
sudo install -m 0644 \
    "$SOURCE_DIR/src/plugins/private/qml/WindowHeapDelegate.qml" \
    "$QML_FILE"
sudo install -m 0644 "$QML_PLUGIN_BUILD" "$QML_PLUGIN_FILE"

echo "Installed Tahoe Overview blur for KWin $KWIN_UPSTREAM_VERSION."
echo "Stock backup: $BACKUP_FILE"
echo "Stock QML backup: $QML_BACKUP_FILE"
echo "Stock QML plugin backup: $QML_PLUGIN_BACKUP_FILE"
echo "Log out and back in (or reboot) to start the new kwin_wayland."
