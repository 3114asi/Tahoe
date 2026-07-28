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

## Инцидент 2026-07-28: невидимый курсор мыши (Wayland)

**Симптом:** после установки указатель мыши на рабочем столе либо не виден,
либо отображается мелким искажённым артефактом вместо стрелки MacTahoe.

**Причина:** баг в апстримном `source/MacTahoe-icon-theme/cursors/install.sh`.
Функция `install_cursors()` вызывалась в цикле по каждому из 46 имён курсоров
в `src/cursorSVG`, и на **каждой** итерации делала `rm -rf` + пересборку всего
каталога `cursors_scalable` из шаблона, копируя внутрь только один текущий
`.svg`. В итоге после цикла в финальной установке оставался SVG только от
**последнего** имени по алфавиту в индексе (`openhand`) плюс `progress*`/
`wait*` (эти два `cp` не зависели от `svgid` и выполнялись на каждой
итерации). Все остальные `cursors_scalable/<имя>/`, включая критичный
`default`, содержали только `metadata.json` без самой картинки.

Plasma 6 на Wayland при отрисовке курсора предпочитает именно эти SVG
(`cursors_scalable/`) для чёткости при масштабировании; при их отсутствии
`kwin_wayland` пишет в лог на каждую смену формы курсора:

```
Cannot open file '~/.icons/MacTahoe-cursors/cursors_scalable/default/default.svg', because: Файл или каталог не существует
Failed to render ".../cursors_scalable/default/default.svg"
```

и рисует битую замену вместо стрелки. Растровые Xcursor-файлы
(`cursors/default` и т.п.) при этом оставались полностью исправны — баг
затрагивал только SVG-путь отрисовки.

**Исправление:** `install_cursors()` разбита на `init_theme_dir()`
(разовые `rm -rf`/пересборка каталога на цвет — вызывается один раз до
цикла) и `install_cursor_svg()` (только копирование одного `.svg` —
вызывается внутри цикла по `svgid`, каталог больше не сносится). Копирование
`progress*`/`wait*` вынесено после цикла. Правка — только в этом проекте
(`source/MacTahoe-icon-theme/cursors/install.sh`), апстрим не менялся.

После правки `bash source/MacTahoe-icon-theme/cursors/install.sh` запущен
повторно: во всех 46 каталогах `cursors_scalable/*` (обоих вариантов —
`MacTahoe-cursors` и `MacTahoe-dark-cursors`) появились свои `.svg`
(итого 93 файла на цвет, совпадает с `source/.../src/svg/*.svg`).
`plasma-plasmashell.service` перезапущен; после этого новых ошибок
`Cannot open file .../cursors_scalable/` в логе `kwin_wayland` не
появлялось (до правки — на каждую смену формы курсора).

**Статус:** причина устранена и переустановка подтверждена файлово (все 46
`cursors_scalable/<имя>/*.svg` на месте в обоих цветах) и по логам KWin
(ошибки `Cannot open file .../cursors_scalable/...` перестали появляться при
смене формы курсора). `plasma-plasmashell.service` перезапущен,
`qdbus6 org.kde.KWin /KWin reconfigure` выполнен.

Визуальное подтверждение через `spectacle -b -p` оказалось ненадёжным:
объект, изначально принятый за искажённый курсор на скриншотах, оказался
звёздочкой на обоях `Mountain` (тот же артефакт на тех же координатах
присутствует и на скриншоте без `-p`, где курсор заведомо не рисуется) —
`kdotool getmouselocation` под чистым Wayland отдаёт неактуальные координаты
(синхронизируется через XWayland и не отслеживает нативный указатель без
взаимодействия), поэтому найти реальный спрайt указателя через скриншот из
CLI не удалось. Нужна ручная проверка глазами/движением мыши на живом
экране. Если после проверки курсор всё ещё не виден — следующий шаг:
перелогин сессии (полный перезапуск `kwin_wayland`, который кэширует
декодированные спрайты в памяти процесса и мог не подхватить обновлённые
файлы без полного перезапуска).

## Матовое стекло Dolphin (боковая панель / рамка окна) — 2026-07-28

Подробности и обоснование — `AI_HANDOFF.md` (раздел «Матовое стекло Dolphin»)
и `docs/KWIN_FORCEBLUR_DECORATION.md`. Кратко, активное состояние:

- `~/.config/Kvantum/MacTahoe/MacTahoe.kvconfig`: `window.color=#ffffff`,
  `inactive.window.color=#ffffff74` (было `#f5f5f5`/`#f5f5f574`).
- `~/.local/share/aurorae/themes/MacTahoe-Light/decoration.svg`: 12 плоских
  заливок рамки (6 активных `#ffffff`, 6 неактивных `#f2f2f2`) получили
  `opacity="0.75"`.
- Собран и установлен патченный `forceblur.so`
  (`source/kwin-forceblur-6.7/`, патч — `forceDecorationBlurRegion()` в
  `blur.cpp`/`blur.h`) — форсирует настоящий блюр рамки для окон из
  `[Effect-blur] WindowClasses` в `~/.config/kwinrc` (сейчас
  `alacritty,dolphin` — общий список с `../MacOS/`, не терять `alacritty`
  при правках отсюда). `Plugins.blurEnabled=false`,
  `Plugins.forceblurEnabled=true`.
- Статус-бар Dolphin остаётся без тонирования — `DolphinStatusBar` кастомный
  `QWidget`, Kvantum `[StatusBar]` на него не действует (подтверждено
  экспериментально, не переоткрывать).
- Синхронизация источника: `source/MacTahoe-kde/Kvantum/MacTahoe/MacTahoe.kvconfig`
  и `source/MacTahoe-kde/aurorae/MacTahoe-Light/decoration.svg` обновлены в
  ногу с `~/.config`/`~/.local/share`. Варианты масштаба `MacTahoe-Light-1.25x`/
  `-1.5x` и тёмная тема (`MacTahoe-Dark*`) **не патчились** — правка сделана
  только для активного `MacTahoe-Light` при 1x.
- Проверка: `tools/check-kwin-forceblur.sh` (плагин загружен) и численный
  тест рамки поверх силуэта горы на обоях (2026-07-28, подробности —
  `docs/KWIN_FORCEBLUR_DECORATION.md`, раздел «Статус проверки») — подтверждено,
  что рамка Dolphin реально размыта (gaussian, не просто alpha-прозрачность).
