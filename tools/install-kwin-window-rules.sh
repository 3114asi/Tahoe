#!/usr/bin/env bash
# Force Dolphin-style translucency (0.75 opacity, blurred behind by forceblur)
# onto every window via a KWin Window Rule, with explicit exceptions for apps
# where see-through content hurts readability (browser, video, image viewer,
# IDEs by default).
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
TRANSLUCENCY_EXCLUDE_CLASSES="${TRANSLUCENCY_EXCLUDE_CLASSES:-chrome,vlc,gwenview,jetbrains}"
TRANSLUCENCY_OPACITY="${TRANSLUCENCY_OPACITY:-75}"

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

{
  id=1
  ids=()
  for cls in "${EXCLUDES[@]}"; do
    cls="$(echo -n "$cls" | xargs)" # trim whitespace
    [[ -z "$cls" ]] && continue
    cat <<EOF
[$id]
Description=Exclude from global translucency: $cls
wmclass=$cls
wmclassmatch=2
wmclasscomplete=false
types=1
opacityactiverule=1
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
types=1
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
echo "  opacity for everything else: ${TRANSLUCENCY_OPACITY}%"
echo "Verify: kcmshell6 kwinrules  (should list $(( ${#EXCLUDES[@]} + 1 )) rules, not \"none configured\")"
