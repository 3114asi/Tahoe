# Снимок установленного состояния

Полная копия `~/.config`, `~/.local/share`, `~/.themes` и системного каталога
SDDM не включается в Git-репозиторий: это машинные каталоги с кэшем, симлинками
и правами доступа. Вместо этого здесь зафиксирован манифест установки, а
подробные значения находятся в [CURRENT_STATE.md](../notes/CURRENT_STATE.md).

Установка выполнена 2026-07-28 на KDE Plasma 6.7.3 Wayland, дополнена
2026-07-29 глобальной прозрачностью+блюром в стиле Dolphin. Активный профиль:
`com.github.vinceliuice.MacTahoe-Light`.

## Полная последовательность воспроизведения текущего визуального состояния

Каждый шаг идемпотентен (безопасно перезапускать). Шаги 5-6 требуют root
(сборка/установка системного KWin-плагина и SDDM); всё остальное —
пользовательское, без root.

```bash
# 1. Kvantum/Aurorae/Plasma (свет+тёмная) + GTK-тема + иконки (все цвета)
./install.sh

# 2. Курсоры (SVG+растровые, свет+тёмная) — отдельный скрипт, апстримный баг
#    цикла исправлен локально, см. notes/CURRENT_STATE.md
./source/MacTahoe-icon-theme/cursors/install.sh

# 3. Применить выбор темы к текущей сессии
kwriteconfig6 --file kdeglobals   --group KDE     --key widgetStyle kvantum
kwriteconfig6 --file kdeglobals   --group Icons   --key Theme MacTahoe-light
kwriteconfig6 --file kdeglobals   --group General --key ColorScheme MacTahoeLight
# Апстримный Look-and-Feel называет курсор "MacTahoe-light", а реально
# устанавливается "MacTahoe-cursors" (cursors/install.sh) — без этой правки
# после apply-lookandfeel курсор останется от предыдущего профиля.
kwriteconfig6 --file kcminputrc   --group Mouse   --key cursorTheme MacTahoe-cursors
gsettings set org.gnome.desktop.interface cursor-theme 'MacTahoe-cursors'
plasma-apply-lookandfeel -a com.github.vinceliuice.MacTahoe-Light

# 3b. GTK/GNOME-приложения читают тему из отдельных файлов (gtk-3.0/4.0
#     settings.ini, xsettingsd.conf, легаси ~/.gtkrc-2.0), которые install.sh
#     не трогает — без этого шага GTK-приложения остаются на предыдущей теме
#     (было замечено: WhiteSur-Light, наследие ../MacOS/), даже когда
#     kdeglobals/gsettings уже показывают MacTahoe:
tools/apply-gtk-theme.sh

# 4. Матовое стекло рамки (Aurorae opacity 0.75) уже внутри source/ (шаг 1),
#    но настоящий блюр рамки+содержимого требует патченного forceblur.so:
tools/install-kwin-forceblur.sh

# 5. Глобальная прозрачность+блюр в стиле Dolphin для ВСЕХ окон (KWin Window
#    Rules) — Chrome/VLC/Gwenview/JetBrains IDE/Dolphin/Alacritty/Spectacle
#    исключены по умолчанию (Dolphin/Alacritty уже имеют свою нативную альфу,
#    Spectacle не должен искажаться при съёмке скриншотов), см. AI_HANDOFF.md
#    и notes/CURRENT_STATE.md, раздел «Прозрачность+блюр Dolphin распространена
#    глобально»:
tools/install-kwin-window-rules.sh

# 6. SDDM (экран входа) — системный путь, требует root, необязателен для
#    визуального состояния текущей сессии:
sudo ./source/MacTahoe-kde/sddm/install.sh

# 7. Перезапустить Plasma Shell, чтобы гарантированно подхватить
#    Aurorae/panel-background SVG (кэш ksvg) и live-конфиги:
kquitapp6 plasmashell && kstart6 plasmashell
```

## Проверка состояния

```bash
./tools/check-theme-state.sh
./tools/check-kwin-forceblur.sh
./tools/check-kwin-window-rules.sh
grep theme-name ~/.config/gtk-3.0/settings.ini ~/.config/gtk-4.0/settings.ini
```
