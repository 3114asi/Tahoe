#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Обёртка над тремя независимыми install.sh апстрима (vinceliuice/MacTahoe-*).
# Каждый исходник умеет намного больше опций (акцент, alt-кнопки, bold-иконки
# и т.д.) — см. `docs/COMPONENT_MAP.md` и `--help` каждого скрипта.
# SDDM и сборку курсоров сюда намеренно не включаем: SDDM требует root и
# трогает системные файлы, курсоры требуют предварительной сборки (python3).

echo "==> Kvantum/Aurorae/Plasma (MacTahoe-kde)"
"$ROOT/source/MacTahoe-kde/install.sh" -c light -c dark

echo "==> GTK-тема (MacTahoe-gtk-theme)"
"$ROOT/source/MacTahoe-gtk-theme/install.sh" -c light -c dark -t default -a normal

echo "==> Иконки (MacTahoe-icon-theme)"
"$ROOT/source/MacTahoe-icon-theme/install.sh" -t all

echo
echo "Готово. Курсоры и SDDM не установлены этим скриптом (см. README.md/AI_HANDOFF.md)."
echo "Для применения темы в системе:"
echo "  kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle kvantum"
echo "  kwriteconfig6 --file kdeglobals --group Icons --key Theme MacTahoe"
echo "  kwriteconfig6 --file kdeglobals --group General --key ColorScheme MacTahoeLight"
echo "  plasma-apply-lookandfeel -a <look-and-feel-id-после-установки>"
echo "Перезапустить Plasma Shell / выйти и зайти в сессию заново."
