#!/usr/bin/env bash
set -euo pipefail

read_config() {
  local file="$1"
  local group="$2"
  local key="$3"
  if command -v kreadconfig6 >/dev/null 2>&1; then
    kreadconfig6 --file "$file" --group "$group" --key "$key" || true
  elif command -v kreadconfig5 >/dev/null 2>&1; then
    kreadconfig5 --file "$file" --group "$group" --key "$key" || true
  else
    echo "kreadconfig not found"
  fi
}

echo "KDE widget style: $(read_config kdeglobals KDE widgetStyle)"
echo "KDE color scheme: $(read_config kdeglobals General ColorScheme)"
echo "KDE icons: $(read_config kdeglobals Icons Theme)"
echo "KDE look and feel: $(read_config kdeglobals KDE LookAndFeelPackage)"
echo "Cursor theme: $(read_config kcminputrc Mouse cursorTheme)"

echo
echo "Kvantum selected theme:"
if [[ -f "$HOME/.config/Kvantum/kvantum.kvconfig" ]]; then
  awk '
    /^\[General\]/ { in_general=1; next }
    /^\[/ { in_general=0 }
    in_general && /^theme=/ { print }
  ' "$HOME/.config/Kvantum/kvantum.kvconfig" || true
else
  echo "missing ~/.config/Kvantum/kvantum.kvconfig"
fi

echo
echo "Important MacTahoe files:"
for f in \
  "$HOME/.config/Kvantum/MacTahoe/MacTahoe.kvconfig" \
  "$HOME/.local/share/icons/MacTahoe/index.theme" \
  "$HOME/.local/share/aurorae/themes/MacTahoe-Light" \
  "$HOME/.local/share/aurorae/themes/MacTahoe-Dark" \
  "$HOME/.themes/MacTahoe"; do
  [[ -e "$f" ]] && echo "ok: $f" || echo "missing: $f"
done
