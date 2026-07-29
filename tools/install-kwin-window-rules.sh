#!/usr/bin/env bash
# Force Dolphin-style translucency (0.75 opacity, blurred behind by forceblur)
# onto every window via a KWin Window Rule, with explicit exceptions for apps
# where see-through content hurts readability (browser, video, image viewer,
# IDEs, screenshot tool by default).
#
# Background: Kvantum can only make a window translucent if the app itself
# requests an alpha-channel surface before Kvantum gets to polish it (works
# for Dolphin/Alacritty, fails for System Settings/KCM/most non-Qt apps that
# create their native surface first). KWin Window Rules operate at the
# compositor level instead, forcing a window's composited alpha regardless of
# toolkit (Qt/GTK/Electron) or when its surface was created — see
# docs/KWIN_FORCEBLUR_DECORATION.md and notes/CURRENT_STATE.md ("Прозрачность+
# блюр Dolphin распространена глобально") for the full investigation.
#
# Rule precedence in KWin: when several rules match the same window, the
# FIRST rule in `rules=` that sets a given property wins; later rules for the
# same property are ignored. So exclusion rules (DontAffect) MUST be listed
# before the catch-all rule in [General] rules=, not after.
set -euo pipefail

RULES_FILE="$HOME/.config/kwinrulesrc"

# Comma-separated list of substrings to match against WM_CLASS and exclude
# from the global translucency (kept fully opaque, as they are today).
# Override to customize, e.g.:
#   TRANSLUCENCY_EXCLUDE_CLASSES="chrome,vlc,firefox" tools/install-kwin-window-rules.sh
#
# NB: KWin's substring match (Rules::matchWMClass, rules.cpp) is
# case-SENSITIVE (QString::contains, no CaseInsensitive flag). KDE apps
# register a lowercase resourceClass ("dolphin"), but Alacritty's Wayland
# app_id is "Alacritty" (capital A, its winit default) -- so it must be
# spelled with the matching case here or this entry silently never matches.
TRANSLUCENCY_EXCLUDE_CLASSES="${TRANSLUCENCY_EXCLUDE_CLASSES:-chrome,vlc,gwenview,jetbrains,dolphin,Alacritty,spectacle}"
TRANSLUCENCY_OPACITY="${TRANSLUCENCY_OPACITY:-75}"

# NET::WindowTypeMask bitmask (netwm_def.h): NormalMask=1 | DialogMask=32 |
# UtilityMask=256 = 289. Covers main windows and preference/utility dialogs
# (e.g. "Настройка — Dolphin") without also grabbing tooltips/menus/popups,
# which would be unreadable blurred.
TRANSLUCENCY_TYPES_MASK="${TRANSLUCENCY_TYPES_MASK:-289}"

# Classes excluded ONLY because their main (top-level) surface already gets
# native Kvantum alpha (see comment above) -- their exclusion must stay
# scoped to windows WITHOUT a transient parent, otherwise it also shadows the
# catch-all rule for their child dialogs (Preferences, Properties, Rename,
# "Open With", ...), which have no native alpha of their own and need the
# forced KWin rule same as anything else. Every other excluded class
# (chrome/vlc/gwenview/jetbrains/spectacle) is excluded for readability, not
# surface capability, so ALL its windows (main + dialogs) should stay opaque
# -- those get no such carve-out.
#
# Why scope by "has a transient parent" rather than by window title or by
# NET::WindowType (Normal/Dialog/Utility): confirmed via a KWin scripting
# query (workspace.windowList(), see notes/CURRENT_STATE.md) that Dolphin's
# child windows do NOT reliably report NET::WindowType=Dialog -- e.g. the
# "Properties" window (Свойства) reports normalWindow=true, dialog=false,
# exactly like the main window, and neither sets a windowRole. The ONE
# property that's true for every child window and false only for the real
# main window is `transient` (has a transient parent). That property IS
# exposed as a matchable rule field: `hastransientparent` (see
# /usr/include/kwin/rulesettings.kcfg, matched in rules.cpp:479-480 as
# `bool(transientParent) == hastransientparent`). Scoping the exclusion to
# hastransientparent=false (ExactBoolMatch) means: exclude only the one true
# main window; ANY other window of that class -- Preferences, Properties,
# Rename, "Open With", future dialogs not seen yet, in any locale -- has a
# transient parent, therefore never matches this exclusion, and falls
# through to the catch-all rule automatically. No per-dialog title
# allowlist needed, and it generalizes to any future NATIVE_ALPHA_CLASSES
# entry for free.
NATIVE_ALPHA_CLASSES="${NATIVE_ALPHA_CLASSES:-dolphin,Alacritty}"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}
require_command qdbus6

if [[ -f "$RULES_FILE" ]]; then
  BACKUP="$RULES_FILE.bak-$(date +%Y%m%d-%H%M%S)"
  cp -a "$RULES_FILE" "$BACKUP"
  echo "Backed up existing rules: $BACKUP"
fi

IFS=',' read -ra EXCLUDES <<< "$TRANSLUCENCY_EXCLUDE_CLASSES"
IFS=',' read -ra NATIVE_ALPHA <<< "$NATIVE_ALPHA_CLASSES"

is_native_alpha_class() {
  local needle="$1" hay
  for hay in "${NATIVE_ALPHA[@]}"; do
    [[ "$(echo -n "$hay" | xargs)" == "$needle" ]] && return 0
  done
  return 1
}

{
  id=1
  ids=()

  for cls in "${EXCLUDES[@]}"; do
    cls="$(echo -n "$cls" | xargs)" # trim whitespace
    [[ -z "$cls" ]] && continue
    transient_clause=""
    if is_native_alpha_class "$cls"; then
      # ExactBoolMatch=1 (Rules::BoolMatch, rules.h): only exclude windows
      # WITHOUT a transient parent, i.e. the real main window -- see comment
      # on NATIVE_ALPHA_CLASSES above.
      transient_clause=$'hastransientparent=false\nhastransientparentmatch=1\n'
    fi
    cat <<EOF
[$id]
Description=Exclude from global translucency: $cls
wmclass=$cls
wmclassmatch=2
wmclasscomplete=false
types=$TRANSLUCENCY_TYPES_MASK
${transient_clause}opacityactiverule=1
opacityinactiverule=1

EOF
    ids+=("$id")
    id=$((id + 1))
  done

  cat <<EOF
[$id]
Description=Translucency: Dolphin-style glass for ALL other windows
wmclass=
wmclassmatch=0
wmclasscomplete=false
types=$TRANSLUCENCY_TYPES_MASK
opacityactive=$TRANSLUCENCY_OPACITY
opacityactiverule=2
opacityinactive=$TRANSLUCENCY_OPACITY
opacityinactiverule=2

EOF
  ids+=("$id")

  # count= is a legacy field KWin's RuleBookSettingsBase still reads on
  # reconfigure; if it disagrees with rules=, KWin treats the book as empty
  # and WIPES every rule's keys on next save. Must match rules= exactly.
  echo "[General]"
  echo "count=${#ids[@]}"
  IFS=,; echo "rules=${ids[*]}"; unset IFS
} > "$RULES_FILE"

qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true

echo "Installed: $RULES_FILE"
echo "  excluded classes: ${TRANSLUCENCY_EXCLUDE_CLASSES}"
echo "  window types mask: ${TRANSLUCENCY_TYPES_MASK} (Normal|Dialog|Utility)"
echo "  opacity for everything else: ${TRANSLUCENCY_OPACITY}%"
echo "Verify: kcmshell6 kwinrules  (should list $(( ${#EXCLUDES[@]} + 1 )) rules, not \"none configured\")"
