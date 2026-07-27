# Текущее состояние MacTahoe

Дата фиксации: 2026-07-28  
Сеанс: KDE Plasma 6.7.3, Wayland  
Проект: `/home/ediskrad/Documents/Theme/Tahoe`

## Активные настройки

| Компонент | Активное значение |
| --- | --- |
| Look-and-Feel | `com.github.vinceliuice.MacTahoe-Light` |
| Widget style | `kvantum` |
| Kvantum | `MacTahoe` |
| Color scheme | `MacTahoeLight` |
| Иконки KDE/GTK | `MacTahoe-light` |
| Курсор KDE/GTK | `MacTahoe-cursors` |
| GTK-тема | `MacTahoe-Light` |
| SDDM | `MacTahoe-Light` |

## Установленные пути

- `~/.config/Kvantum/MacTahoe/`
- `~/.local/share/aurorae/themes/MacTahoe-Light/`
- `~/.local/share/aurorae/themes/MacTahoe-Dark/`
- `~/.local/share/color-schemes/MacTahoeLight.colors`
- `~/.local/share/color-schemes/MacTahoeDark.colors`
- `~/.local/share/plasma/desktoptheme/MacTahoe-Light/`
- `~/.local/share/plasma/desktoptheme/MacTahoe-Dark/`
- `~/.local/share/plasma/look-and-feel/com.github.vinceliuice.MacTahoe-Light/`
- `~/.local/share/plasma/look-and-feel/com.github.vinceliuice.MacTahoe-Dark/`
- `~/.local/share/icons/MacTahoe-light/` и другие цветовые варианты
- `~/.local/share/icons/MacTahoe-cursors/`
- `~/.local/share/icons/MacTahoe-dark-cursors/`
- `~/.themes/MacTahoe-Light/` и `~/.themes/MacTahoe-Dark/`
- `/usr/share/sddm/themes/MacTahoe-Light/`
- `/usr/share/sddm/themes/MacTahoe-Dark/`
- `/etc/sddm.conf.d/theme.conf` с `Current=MacTahoe-Light`

## Что было выполнено

1. Запущен корневой `./install.sh`: KDE, GTK и все цветовые варианты иконок.
2. Запущен `source/MacTahoe-icon-theme/cursors/install.sh`.
3. Запущен `sudo source/MacTahoe-kde/sddm/install.sh`.
4. Применён `plasma-apply-lookandfeel -a com.github.vinceliuice.MacTahoe-Light`.
5. Настройки KDE, Kvantum и GTK зафиксированы напрямую.
6. Перезапущен `plasma-plasmashell.service`; `plasma-kwin_wayland.service`
   повторно проверен.

## Проверки

- `tools/check-theme-state.sh`: KDE, Kvantum и Aurorae показывают MacTahoe.
- Проверено 10 обязательных файлов компонентов: `10/10`, ошибок `0`.
- Plasma Shell: `active`.
- KWin Wayland: `active`.
- Рабочее дерево Git: чистое после документирования.

## Важный нюанс курсоров

Look-and-Feel апстрима выставляет имя `MacTahoe-light`, но штатный скрипт
курсоров создаёт каталоги `MacTahoe-cursors` и `MacTahoe-dark-cursors`.
Поэтому после применения имя курсора исправлено на реально установленное
`MacTahoe-cursors` в `kcminputrc` и GSettings.
