# Tahoe Component Map

## Что за что отвечает

| Компонент | Исходник | Устанавливается install-скриптом исходника в |
| --- | --- | --- |
| Kvantum | `source/MacTahoe-kde/Kvantum/MacTahoe` | `~/.config/Kvantum/MacTahoe` |
| Aurorae (декорации окон) | `source/MacTahoe-kde/aurorae` | `~/.local/share/aurorae/themes/` |
| Color schemes | `source/MacTahoe-kde/color-schemes` | `~/.local/share/color-schemes/` |
| Plasma desktoptheme/look-and-feel | `source/MacTahoe-kde/plasma` | `~/.local/share/plasma/` |
| SDDM (экран входа) | `source/MacTahoe-kde/sddm` | системный, ставится отдельным `sddm/install.sh` (нужен root) |
| GTK-тема | `source/MacTahoe-gtk-theme/src` | `~/.themes/MacTahoe*` |
| Иконки | `source/MacTahoe-icon-theme/src` | `~/.local/share/icons/MacTahoe*` |
| Курсоры | `source/MacTahoe-icon-theme/cursors` | `~/.local/share/icons/MacTahoe-cursors` (собираются отдельным `cursors/build.sh` + `cursors/install.sh`) |

## Отличия от WhiteSur (`../MacOS/`), важные для переноса привычек

- Курсоры **не отдельный репозиторий**, а подкаталог `MacTahoe-icon-theme/cursors`
  со своим build.sh (нужен `python3` для `add-shadows.py`) — в WhiteSur были
  готовые исходники без сборки.
- В комплекте есть **SDDM-тема** — у WhiteSur-проекта её не было. Установка
  требует root и трогает системный `/usr/share/sddm/themes/`, что выходит за
  рамки пользовательского `~/.local/share/` — самое рискованное отдельное
  действие, делать по явному запросу.
- GTK-тема Tahoe умеет несколько акцентных цветов и alt-стиль кнопок окна
  (`-t`, `-a` в `install.sh` gtk-theme) — в WhiteSur такого выбора не было,
  нужно явно зафиксировать выбранный вариант в `notes/CURRENT_STATE.md` после
  установки, иначе при пересборке параметры потеряются.
- Опция `-b/--blur` у gtk-theme — под GNOME Shell (Blur My Shell), на KDE
  неприменима, не использовать.

## Что делать после изменений (KDE)

Как и в WhiteSur-проекте:

```bash
kquitapp6 plasmashell && kstart6 plasmashell   # после Plasma/Look-and-Feel
qdbus6 org.kde.KWin /KWin reconfigure           # после Kvantum/KWin-конфига
```

Aurorae `decoration.svg`/QML правки не подхватываются одним `reconfigure` —
нужен сброс кэша и переключение темы туда-обратно, см. соответствующий раздел
в `../MacOS/docs/AURORAE_FROSTED_TITLEBAR.md` (сам механизм общий для Aurorae,
не специфичен для WhiteSur).

## Проверено: собственного KWin-эффекта нет

В отличие от `../MacOS/`, у MacTahoe-kde **нет** своего C++/CMake KWin-плагина
(проверено — в `source/MacTahoe-kde` нет ни одного `.cpp`/`CMakeLists.txt`).
Blur — только штатный Kvantum/KWin `blurEnabled`, никакого форс-blur по классу
окна из коробки. Значит, инцидент «плагин перестал грузиться после апдейта
KWin/KF6» (см. `../MacOS/docs/KWIN_FORCEBLUR.md`) для этого проекта
**неприменим** — нечему ломаться на уровне приватного ABI. Если понадобится
Alacritty-blur как в WhiteSur-проекте, придётся переносить тот же
`kwin-forceblur-6.7` эффект отдельно — он не завязан на конкретную тему.

## TODO после первой установки

- [ ] Снять снимок в `installed/` по факту установки.
- [ ] Зафиксировать выбранные опции (цвет, акцент, alt-кнопки) в
  `notes/CURRENT_STATE.md`.
