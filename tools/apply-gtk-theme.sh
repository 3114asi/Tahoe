#!/usr/bin/env bash
# Point every GTK/GNOME-settings surface at the installed MacTahoe theme.
#
# `install.sh` (MacTahoe-gtk-theme's own install.sh) only unpacks the theme
# files into ~/.themes/ -- it never selects them as active. KDE's kdeglobals/
# gsettings can independently say "MacTahoe-Light" while the files GTK apps
# actually read at startup (gtk-3.0/settings.ini, gtk-4.0/settings.ini,
# xsettingsd.conf, the legacy ~/.gtkrc-2.0) still say whatever theme was
# active before (e.g. WhiteSur-Light, left over from ../MacOS/). This script
# closes that gap. See notes/CURRENT_STATE.md ("GTK-тема сессии").
set -euo pipefail

THEME="${MACTAHOE_GTK_THEME:-MacTahoe-Light}"
ICON_THEME="${MACTAHOE_ICON_THEME:-MacTahoe-light}"
CURSOR_THEME="${MACTAHOE_CURSOR_THEME:-MacTahoe-cursors}"

set_ini_key() {
  local file="$1" key="$2" value="$3"
  mkdir -p "$(dirname "$file")"
  if [[ ! -f "$file" ]]; then
    printf '[Settings]\n%s=%s\n' "$key" "$value" > "$file"
  elif grep -q "^${key}=" "$file"; then
    sed -i "s|^${key}=.*|${key}=${value}|" "$file"
  else
    # Insert right after [Settings] if present, else just append.
    if grep -q '^\[Settings\]' "$file"; then
      sed -i "/^\[Settings\]/a ${key}=${value}" "$file"
    else
      printf '%s=%s\n' "$key" "$value" >> "$file"
    fi
  fi
}

set_xsettingsd_key() {
  local file="$1" key="$2" value="$3" # value already quoted if needed
  mkdir -p "$(dirname "$file")"
  touch "$file"
  if grep -q "^${key} " "$file"; then
    sed -i "s|^${key} .*|${key} ${value}|" "$file"
  else
    printf '%s %s\n' "$key" "$value" >> "$file"
  fi
}

set_gtkrc2_key() {
  local file="$1" key="$2" value="$3" # value already quoted
  touch "$file"
  if grep -q "^${key}=" "$file"; then
    sed -i "s|^${key}=.*|${key}=${value}|" "$file"
  else
    printf '%s=%s\n' "$key" "$value" >> "$file"
  fi
}

# --- GTK3 / GTK4 settings.ini ------------------------------------------------
for ver in gtk-3.0 gtk-4.0; do
  f="$HOME/.config/$ver/settings.ini"
  set_ini_key "$f" gtk-theme-name "$THEME"
  set_ini_key "$f" gtk-icon-theme-name "$ICON_THEME"
  set_ini_key "$f" gtk-cursor-theme-name "$CURSOR_THEME"
done

# --- xsettingsd (XSETTINGS propagation to already-running/XWayland apps) ----
XS="$HOME/.config/xsettingsd/xsettingsd.conf"
set_xsettingsd_key "$XS" Net/ThemeName "\"$THEME\""
set_xsettingsd_key "$XS" Net/IconThemeName "\"$ICON_THEME\""
set_xsettingsd_key "$XS" Gtk/CursorThemeName "\"$CURSOR_THEME\""

# --- legacy GTK2 apps ---------------------------------------------------------
set_gtkrc2_key "$HOME/.gtkrc-2.0" gtk-theme-name "\"$THEME\""
set_gtkrc2_key "$HOME/.gtkrc-2.0" gtk-icon-theme-name "\"$ICON_THEME\""
set_gtkrc2_key "$HOME/.gtkrc-2.0" gtk-cursor-theme-name "\"$CURSOR_THEME\""

# --- gsettings (GNOME portal / xdg-desktop-portal-gtk / GTK4 fallback) ------
if command -v gsettings >/dev/null 2>&1; then
  gsettings set org.gnome.desktop.interface gtk-theme "$THEME"
  gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME"
  gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_THEME"
  # Metacity/xfwm window-border theme; inert under KWin but kept consistent
  # since MacTahoe-gtk-theme ships a metacity-1 variant.
  if [[ -d "$HOME/.themes/$THEME/metacity-1" ]]; then
    gsettings set org.gnome.desktop.wm.preferences theme "$THEME"
  fi
fi

echo "GTK theme applied: $THEME (icons: $ICON_THEME, cursor: $CURSOR_THEME)"
echo "xsettingsd live-reloads its config file automatically; already-running"
echo "GTK apps still need to be restarted individually to pick up the change."
