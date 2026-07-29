#!/usr/bin/env bash
# Verify the global Dolphin-style translucency Window Rule (see
# tools/install-kwin-window-rules.sh) is present and internally consistent.
set -euo pipefail

RULES_FILE="$HOME/.config/kwinrulesrc"

if [[ ! -f "$RULES_FILE" ]]; then
  echo "missing: $RULES_FILE"
  exit 1
fi

if command -v kreadconfig6 >/dev/null 2>&1; then KREAD=kreadconfig6; else KREAD=kreadconfig5; fi

COUNT="$("$KREAD" --file kwinrulesrc --group General --key count)"
RULES="$("$KREAD" --file kwinrulesrc --group General --key rules)"
echo "[General] count=$COUNT rules=$RULES"

# The count=/rules= trap: if these disagree, KWin silently wipes every rule's
# keys on the next reconfigure/save (see notes/CURRENT_STATE.md).
N_RULES_LISTED=$(( $(grep -o ',' <<< "$RULES" | wc -l) + 1 ))
if [[ -z "$RULES" ]]; then N_RULES_LISTED=0; fi
if [[ "$COUNT" != "$N_RULES_LISTED" ]]; then
  echo "MISMATCH: count=$COUNT but rules= lists $N_RULES_LISTED id(s) -- KWin will wipe rules on next reconfigure/save. Rerun tools/install-kwin-window-rules.sh."
fi

echo
echo "Rules found in file:"
grep -E '^\[[0-9]+\]|^Description=|^wmclass=|^opacity.*rule=' "$RULES_FILE"

echo
if grep -q '^wmclassmatch=0$' "$RULES_FILE"; then
  echo "Global catch-all rule (wmclassmatch=0, matches every window class): yes"
else
  echo "Global catch-all rule (wmclassmatch=0, matches every window class): NO -- global translucency will not apply to unlisted apps"
fi

if command -v qdbus6 >/dev/null 2>&1; then
  echo "forceblur loaded=$(qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.isEffectLoaded forceblur 2>/dev/null) (window rules only show blur behind a window if forceblur/blur is also active)"
fi

echo
echo "Full GUI check (most reliable): kcmshell6 kwinrules"
