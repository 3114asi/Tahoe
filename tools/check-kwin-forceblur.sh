#!/usr/bin/env bash
# Verify the patched "Force Blur (6.7)" KWin effect (content + decoration) is
# installed, configured and active.
set -euo pipefail

PLUGIN_BASE="$(qtpaths6 --query QT_INSTALL_PLUGINS 2>/dev/null || echo "/usr/lib/$(gcc -dumpmachine 2>/dev/null)/qt6/plugins")"
SO="$PLUGIN_BASE/kwin/effects/plugins/forceblur.so"

if [[ -e "$SO" ]]; then echo "ok: $SO"; else echo "missing: $SO"; fi

if command -v kreadconfig6 >/dev/null 2>&1; then KREAD=kreadconfig6; else KREAD=kreadconfig5; fi
echo "kwin Plugins.blurEnabled=$("$KREAD" --file kwinrc --group Plugins --key blurEnabled)"
echo "kwin Plugins.forceblurEnabled=$("$KREAD" --file kwinrc --group Plugins --key forceblurEnabled)"
echo "kwin Effect-blur.WindowClasses=$("$KREAD" --file kwinrc --group Effect-blur --key WindowClasses)"
echo "kwin Effect-blur.BlurStrength=$("$KREAD" --file kwinrc --group Effect-blur --key BlurStrength)"
echo "kwin org.kde.kdecoration2.theme=$("$KREAD" --file kwinrc --group org.kde.kdecoration2 --key theme)"

if command -v qdbus6 >/dev/null 2>&1; then
  echo "runtime forceblur loaded=$(qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.isEffectLoaded forceblur 2>/dev/null)"
  echo "runtime blur loaded=$(qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.isEffectLoaded blur 2>/dev/null)"
fi

echo
echo "If forceblur shows loaded=false but the .so and kwinrc keys above look"
echo "fine, KWin/KF6 was very likely updated and the private ABI this plugin"
echo "links against changed again (this has happened twice on this exact repo"
echo "family already, see ../MacOS/docs/KWIN_FORCEBLUR.md). Fix: rerun"
echo "tools/install-kwin-forceblur.sh to rebuild without touching the code."
