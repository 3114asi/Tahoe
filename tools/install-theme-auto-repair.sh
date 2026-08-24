#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UNIT_DIR="$HOME/.config/systemd/user"
STATE_DIR="$HOME/.local/state/tahoe"

mkdir -p "$UNIT_DIR" "$STATE_DIR"

sed "s|@ROOT@|$ROOT|g" "$ROOT/tools/systemd/tahoe-theme-auto-repair.service.in" \
    > "$UNIT_DIR/tahoe-theme-auto-repair.service"
install -m 0644 "$ROOT/tools/systemd/tahoe-theme-auto-repair.timer" \
    "$UNIT_DIR/tahoe-theme-auto-repair.timer"

# The current package version is healthy unless a component check says otherwise.
dpkg-query -W -f='${Version}\n' kwin-wayland > "$STATE_DIR/kwin-package-version"

systemctl --user daemon-reload
systemctl --user enable --now tahoe-theme-auto-repair.timer
echo "Installed and enabled Tahoe automatic repair timer."
