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
- Скругление углов блюра (`cutRoundedCorner()` в `blur.cpp`) и скругление
  внешнего контура тени `decoration.svg` (`path1019`/`rect6520-3-2-6`,
  коммит `03237226`) — после перелогина/перезагрузки сессии пользователь
  подтвердил вживую: блюр рамки Dolphin отображается как нужно, без резкой
  тёмной полосы в углах. Расследование закрыто, подробности —
  `docs/KWIN_FORCEBLUR_DECORATION.md`.

## Alacritty: фон под рамку — 2026-07-28

`~/.config/alacritty/alacritty.toml`, `[colors.primary]`: `background`
изменён с `#f5f5f5` на `#ffffff`, чтобы совпадать с активной заливкой рамки
Dolphin (`decoration.svg`, `opacity=0.75`) — раньше между тайтлбаром и
содержимым терминала был лёгкий цветовой шов. `opacity=0.75`/`blur=true` не
менялись. Файл не отслеживается в git-репозитории проекта (личный конфиг в
`~/.config`), подтверждено визуально.

## Dolphin: полная унификация прозрачности (сайдбар/список файлов/панель адреса) — 2026-07-28

Цель: сайдбар, список файлов и панель адреса (breadcrumb) должны выглядеть
одинаково полупрозрачными/размытыми — и одинаково в активном и неактивном
состоянии окна. Раньше только сайдбар был по-настоящему размыт; список
файлов и панель адреса оставались практически непрозрачными независимо от
альфы в конфиге, а неактивное состояние отличалось от активного в разных
местах по-разному. Подтверждено строгой численной проверкой: несколько точек
экрана с разным фоном позади окна, сравнение факта с формулой
`результат = 0.75×белый + 0.25×фон` (не полагаться на один скриншот на
удобном фоне — см. [[project-kwin-corner-investigation]] и урок про строгую
визуальную проверку).

Правки (все три файла ниже синхронизированы между `~/.config`/`~/.local/share`
и `source/MacTahoe-kde/`):

1. **`Kvantum/MacTahoe/MacTahoe.kvconfig`, `[GeneralColors]`** — активные и
   неактивные варианты `window.color`/`base.color`/`alt.base.color` сведены
   к ОДНОМУ и тому же полупрозрачному белому значению (`#ffffffbf` /
   `#fafafabf`, альфа 0.75, та же, что у рамки и Alacritty) — раньше
   активное было полностью непрозрачным (`#ffffff`), а неактивное — с
   альфой (`#ffffff74`), из-за чего разница была видна при потере фокуса.
2. **`Kvantum/MacTahoe/MacTahoe.kvconfig`, `[%General]`, `no_inactiveness`** —
   `false` → `true`. Это отдельный переключатель Kvantum, который добавляет
   собственное затемнение неактивных окон ПОВЕРХ значений из `GeneralColors`
   — даже после унификации цветов выше, неактивное окно всё ещё отличалось
   от активного, пока не выключили именно этот флаг.
3. **`Kvantum/MacTahoe/MacTahoe.kvconfig`, `[Hacks]`, `transparent_dolphin_view`** —
   `false` → `true`. **Ключевая находка.** Это официальный, документированный
   хак самого Kvantum (см. исходники стиля,
   `~/whitesur-build/Kvantum/Kvantum/style/polishing.cpp:452-468` и
   `Kvantum.cpp:3331`/`:5214`) специально для `KItemListContainer` viewport
   Dolphin: без этого флага Kvantum принудительно нужен для рисования
   рамки/заливки поверх области списка файлов (`PE_Frame` не пропускается),
   что визуально давало почти непрозрачный слой поверх и так уже
   полупрозрачного `base.color` — список файлов совсем не реагировал на
   фон рабочего стола (менялся на 1 единицу при изменении фона на 17).
   Установка флага в `true` разблокировала настоящий блюр для списка
   файлов, идентично сайдбару.
4. **`Kvantum/MacTahoe/MacTahoe.svg`, элементы `toolbar-normal*`
   (6 путей, активные+неактивные)** — были добавлены как отдельная
   непрозрачная (`#ffffff`/`#f2f2f2`, без альфы) заливка панели адреса;
   сначала унифицированы по цвету и получили `opacity=0.75`, но это
   создавало ВТОРОЙ полупрозрачный слой поверх уже полупрозрачного
   `window.color` (комбинированная альфа ≈0.94, отсюда пересвет). Итоговое
   решение — `opacity=0`, элементы полностью прозрачны, панель адреса
   показывает исключительно нижний слой `window.color`, точно так же как
   сайдбар (у которого нет отдельного Kvantum-элемента поверх).

**Проверка:** несколько точек на реальных обоях (Mountain), с фоном за
окном известным заранее (скриншот с минимизированным окном в тех же
координатах) — факт совпадает с формулой в пределах 2-6 единиц RGB во всех
трёх зонах, в обоих состояниях окна (активное/неактивное). Подтверждено на
живой системе, перелогин не потребовался (это чисто Kvantum/Qt-конфиг,
без пересборки KWin-плагина).

## Блюр рамки — распространён на ВСЕ окна, не только Dolphin/Alacritty — 2026-07-28

`source/kwin-forceblur-6.7/src/blur.cpp`, `shouldForceBlur()` — добавлена
поддержка `*` как значения класса окна: если список `WindowClasses`
содержит `*`, форс-блюр (и рамки, и контента) включается для любого окна,
без сравнения класса. `~/.config/kwinrc`, `[Effect-blur] WindowClasses`
изменён с `alacritty,dolphin` на `*`. Дефолт в
`tools/install-kwin-forceblur.sh` (`FORCEBLUR_CLASSES`) тоже изменён на
`*` — при последующих переустановках/пересборках (например, после
обновления KWin/KF6) поведение сохранится без дополнительных переменных
окружения.

Пересобрано и переустановлено (`FORCEBLUR_CLASSES="*"
tools/install-kwin-forceblur.sh`), проверено вживую БЕЗ перелогина: рамка
System Settings (Kirigami/QtQuick-приложение, отдельно от Dolphin/Kvantum)
теперь тоже размыта — численно совпадает с формулой
`0.75×белый + 0.25×фон` в нескольких точках с разным фоном (та же строгая
методика, что и для Dolphin). Dolphin/Alacritty проверены на регрессию —
работают как прежде.

**Важно (см. [[feedback_kwin_plugin_reload_caching]]):** в этот раз живая
проверка через `unloadEffect`+`loadEffect` сработала и показала верный
результат сразу, но это НЕ гарантия на будущее — по прошлому опыту такая
проверка может молча тестировать старую версию `.so`. Если после
следующего перелогина рамка каких-то окон вдруг снова резкая — пересобрать
и переустановить заново, не полагаться на то, что D-Bus reload одного
раза достаточно навсегда.

## System Settings: содержимое окна оставалось полностью непрозрачным — 2026-07-28

Пользователь прислал скриншот с пометкой «сделай фон как в Dolphin» — стрелки
указывали на заголовок, сайдбар и общую область окна «Быстрая настройка»
(System Settings), не только на рамку. Раздел выше («Блюр рамки — распространён
на ВСЕ окна») был ошибочно принят за полное решение: на самом деле он касается
только Aurorae-рамки (KWin-декорация, отдельный буфер), которую forceblur
размывает независимо от содержимого клиента. Строгая проверка по пикселям
(`convert img.png -crop WxH+X+Y txt:-`, сравнение с эталонным `#FFFFFFFF`)
показала: и в оригинальном скриншоте, и после моих первых попыток область
СОДЕРЖИМОГО (сайдбар/список категорий/страница KCM) оставалась чистым
`#FFFFFFFF` — 0% прозрачности, несмотря на то что видимая «дымка» в районе
заголовка (декорация) создавала обманчивое впечатление, что всё окно
затронуто.

**Причина:** System Settings/kcmshell6 создают нативную поверхность окна до
того, как Kvantum успевает выставить `WA_TranslucentBackground` с alpha-каналом
в surface format — Kvantum сам не может задним числом сделать окно
прозрачным (see `~/whitesur-build/Kvantum/Kvantum/style/polishing.cpp:362-390`,
комментарий про «old Spectacle»). Это ограничение самого приложения/Qt, не
лечится правкой kvconfig ни для WhiteSur, ни здесь.

**Рабочее решение — компоузер-уровня, а не Kvantum:** KWin Window Rules
(«Особые параметры окон», `~/.config/kwinrulesrc`), опция **Opacity**, forced
(`Force`) на 75% активное/неактивное — совпадает с формулой Dolphin
`0.75×белый + 0.25×фон`. Это форсирует альфу всего окна на уровне компоновки
независимо от того, что рисует само приложение, а поскольку `forceblur`
уже настроен на `WindowClasses=*`, фон под получившейся альфой ещё и
по-настоящему блюрится (проверено увеличенным (400%) кропом — фон под текстом
гладкий/смазанный, без деталей гор, то есть это блюр, а не просто чёткая
подложенная картинка).

Правила (два — под сайдбар/главный шелл и под отдельные kcmshell-окна KCM):

```ini
[1]
Description=Translucency: System Settings (main shell)
wmclass=systemsettings
wmclassmatch=1
wmclasscomplete=false
types=1
opacityactive=75
opacityactiverule=2
opacityinactive=75
opacityinactiverule=2

[2]
Description=Translucency: standalone KCM windows (kcmshell)
wmclass=kcm_
wmclassmatch=2
wmclasscomplete=false
types=1
opacityactive=75
opacityactiverule=2
opacityinactive=75
opacityinactiverule=2

[General]
count=2
rules=1,2
```

**Важная ловушка (полдня отладки):** `[General]` в `kwinrulesrc` имеет ДВА
поля — легаси `count=N` и актуальный список `rules=id1,id2,...`. Если
записать только `rules=1,2` без `count=2` — `RuleBookSettings::usrRead()`
при следующем `qdbus6 org.kde.KWin /KWin reconfigure` читает `count=0` по
умолчанию, считает книгу правил пустой и **при сохранении затирает и
`rules=`, и все ключи с `wmclass`/`types` в группах** — визуально кажется,
что konfig «сам стёрся». Признак: после `reconfigure` в файле остаются
только те ключи, которые правились kwriteconfig6 последними (например
`opacityactiverule`), а `wmclass`/`Description`/`types` пропадают, и
`[General] rules=` становится пустым. Диагностировано разбором заголовков
`/usr/include/kwin/rules.h` и `rulebooksettingsbase.kcfg`
(`invent.kde.org/plasma/kwin`) — `RuleBookSettingsBase` хранит `count`
(legacy) параллельно с `rules` (StringList); GUI «Особые параметры окон»
(`kcmshell6 kwinrules`) — надёжный способ проверить, действительно ли
правило подхвачено (показывает список активных правил или «не заданы»),
не полагаться только на то, что файл на диске выглядит правильно.

Также уточнены числовые enum'ы `Rules::SetRule`/`ForceRule` (из того же
`rules.h`): `Unused=0, DontAffect=1, Force=2, Apply=3, Remember=4,
ApplyNow=5, ForceTemporarily=6` — для реальной принудительной прозрачности
нужно **2** (`Force`), не 3 (это было ошибочно принято за «force» в первой
попытке и не давало эффекта).

Проверено вживую на `systemsettings` (главный шелл) и на отдельном
`kcmshell6 kcm_mouse` — оба теперь показывают то же смешение с фоном, что и
Dolphin, без пересборки и без перелогина (обычный `reconfigure` через D-Bus
подхватывает kwinrulesrc сразу, в отличие от forceblur.so).

## Прозрачность+блюр Dolphin распространена глобально на ВСЕ окна, кроме исключений — 2026-07-29

Пользователь попросил не настраивать каждое приложение отдельно, а включить
вид как у Dolphin (`0.75×цвет + 0.25×фон`, блюр фона через `forceblur`)
глобально для всех окон системы, с исключением конкретных категорий, где
просвечивание мешает: браузер, видео/медиаплееры, редакторы кода/IDE,
просмотр изображений. Механизм — тот же, что уже был найден для System
Settings (раздел выше): KWin Window Rules работают на уровне компоузера,
поверх содержимого окна любого тулкита (Qt/GTK/Electron), не только Qt/Kvantum.

Старые два точечных правила (`systemsettings`, `kcm_`) заменены одним
универсальным правилом с `wmclassmatch=0` (Unimportant — совпадает с любым
классом окна) + четырьмя правилами-исключениями с `opacityactiverule`/
`opacityinactiverule=1` (`DontAffect`), которые должны идти **раньше**
универсального правила в списке `rules=` — по опыту работы KWin с
несколькими совпавшими правилами для одного окна побеждает **первое**
совпавшее правило для данного свойства (`Force`/`DontAffect` от более ранней
записи блокирует переопределение более поздними записями для того же
свойства). Итоговый `~/.config/kwinrulesrc` (синхронно не хранится в Git —
личный конфиг, как и `alacritty.toml`):

```ini
[1]
Description=Exclude from global translucency: Chrome
wmclass=chrome
wmclassmatch=2
wmclasscomplete=false
types=1
opacityactiverule=1
opacityinactiverule=1

[2]
Description=Exclude from global translucency: VLC
wmclass=vlc
wmclassmatch=2
wmclasscomplete=false
types=1
opacityactiverule=1
opacityinactiverule=1

[3]
Description=Exclude from global translucency: Gwenview (image viewer)
wmclass=gwenview
wmclassmatch=2
wmclasscomplete=false
types=1
opacityactiverule=1
opacityinactiverule=1

[4]
Description=Exclude from global translucency: JetBrains IDEs (Android Studio etc.)
wmclass=jetbrains
wmclassmatch=2
wmclasscomplete=false
types=1
opacityactiverule=1
opacityinactiverule=1

[5]
Description=Translucency: Dolphin-style glass for ALL other windows
wmclass=
wmclassmatch=0
wmclasscomplete=false
types=1
opacityactive=75
opacityactiverule=2
opacityinactive=75
opacityinactiverule=2

[General]
count=5
rules=1,2,3,4,5
```

Реально установленные на системе приложения по категориям (проверено
`ls /usr/share/applications` + `~/.local/share/applications`):
браузер — `google-chrome-stable` (класс `chrome`, substring); видео —
`vlc` (класс `vlc`); просмотр изображений — `gwenview` (класс `gwenview`);
IDE — Android Studio, `StartupWMClass=jetbrains-studio` (класс-паттерн
`jetbrains`, substring — заодно покроет любые другие JetBrains IDE, если
появятся). Если пользователь позже поставит другой браузер/плеер/редактор —
по этой же схеме добавить ещё одно правило-исключение с нужным `wmclass`
**перед** правилом `[5]`, не забыть `count=`/`rules=` в `[General]`.

**Проверено численно (не только на глаз)**, как и во всех прошлых пунктах
этого раздела — `convert img.png -crop 1x1+X+Y txt:-` в нескольких точках,
сравнение окна с открытым приложением против чистого снимка тех же
координат без окон:

- Chrome (`about:blank`) поверх фона `(214,231,234)` — пиксель `(255,255,255)`,
  то есть 0% примеси фона — исключение действует, окно осталось полностью
  непрозрачным.
- Gwenview поверх System Settings (уже прозрачных) — визуально чистый белый
  `#FFFFFF`, никакой дымки/фона сквозь окно — исключение действует.
- KCalc (не в списке исключений) поверх двух разных фонов —
  `(216,233,235)→242,242,242` и `(140,181,185)→238,238,238` — оба заметно
  темнее чистого белого и зависят от фона позади окна (в отличие от
  плоского `255,255,255` у Chrome), то есть глобальное правило `[5]`
  реально форсирует альфу и блюр для приложения, для которого раньше не
  было отдельного правила.

Backup предыдущей версии файла — `~/.config/kwinrulesrc.bak-20260729-102321`.

**Воспроизводимость (2026-07-29, тем же днём позже):** изначально это правило
существовало только как вручную записанный live-файл, нигде не
воспроизводилось скриптом (в отличие от Kvantum/Aurorae/панели, уже
синхронизированных в `source/`). Теперь есть `tools/install-kwin-window-rules.sh`
(генерирует ровно этот INI, список исключений переопределяется
`TRANSLUCENCY_EXCLUDE_CLASSES`) и `tools/check-kwin-window-rules.sh`
(проверка, включая ловушку `count=`/`rules=`). Прогнан вживую — файл
пересоздан скриптом побитово идентичным ручной версии, `reconfigure`
отработал без потери правил. Полная последовательность воспроизведения
текущего визуального состояния с нуля — `installed/README.md`.

## GTK-тема сессии переключена на MacTahoe — 2026-07-29

До этой правки KDE-сторона (`kdeglobals`, `gsettings
org.gnome.desktop.interface gtk-theme`) уже показывала MacTahoe, но файлы,
которые GTK-приложения реально читают при старте, ещё показывали
`WhiteSur-Light` (наследие соседнего `../MacOS/`) — реальная рассинхронизация,
не просто устаревшая запись в этом файле. Исправлено новым
`tools/apply-gtk-theme.sh` (см. `AI_HANDOFF.md`, раздел «GTK/GNOME-приложения
переключены на MacTahoe»). Актуальные значения на всех уровнях:

| Файл/ключ | Было | Стало |
| --- | --- | --- |
| `~/.config/gtk-3.0/settings.ini`, `gtk-theme-name` | `WhiteSur-Light` | `MacTahoe-Light` |
| `~/.config/gtk-4.0/settings.ini`, `gtk-theme-name` | `WhiteSur-Light` | `MacTahoe-Light` |
| `~/.config/xsettingsd/xsettingsd.conf`, `Net/ThemeName` | `"WhiteSur-Light"` | `"MacTahoe-Light"` |
| `~/.gtkrc-2.0`, `gtk-theme-name` | `"WhiteSur-Light"` | `"MacTahoe-Light"` |
| `gsettings org.gnome.desktop.wm.preferences theme` | `Adwaita` | `MacTahoe-Light` |

Иконки/курсор в этих же файлах уже были верными (`MacTahoe-light`/
`MacTahoe-cursors`) и не менялись. `gsettings gtk-theme`/`icon-theme` тоже
уже были верными — рассинхрон был только в файлах, которые правит отдельный
инструмент (`kde-gtk-config`/KCM), а не `plasma-apply-lookandfeel`.

## Диалоги Dolphin: фон не совпадал с рамкой (цвет), исправлено — 2026-07-29

Численно подтверждено (обои временно сделаны белыми для чистоты сравнения,
`spectacle -a`/`-f` + `convert ... txt:-`): на «Настройка — Dolphin» рамка и
сайдбар — `#FFFFFF` при α=0.75, область настроек — `#F6F6F6` при той же
α=0.75. Причина найдена в исходнике Kvantum
(`~/whitesur-build/Kvantum/Kvantum/style/Kvantum.cpp:1855-1927`): для любого
верхнеуровневого окна Kvantum по умолчанию использует SVG-элемент `dialog`
(`[Dialog] interior.element=dialog`), переключаясь на `window` только если
первый child в точке (0,0) — `QMenuBar`/`QToolBar`. `dialog-normal`/
`dialog-normal-inactive` в `MacTahoe.svg` остались с апстримными
`#f6f6f6`/`#f5f5f5` (`fill-opacity:1`) — их не трогали при унификации
прозрачности Dolphin (та работа шла через `[GeneralColors]`,
`decoration.svg`, KWin-правила, не через этот SVG-элемент).

**Правка:** только цвет, `#f6f6f6`→`#ffffff`, `#f5f5f5`→`#f2f2f2` (в тон
`window-normal`/`window-normal-inactive`), альфа не добавлялась — она уже
форсится KWin-правилом (см. следующий раздел), добавление альфы в SVG
повторило бы баг двойного умножения. Синхронно в `~/.config/Kvantum/
MacTahoe/MacTahoe.svg` и `source/MacTahoe-kde/Kvantum/MacTahoe/MacTahoe.svg`.
Бэкап — `backups/dialog-background_20260729-180306/`. Требует полного
перезапуска процесса приложения, не просто закрытия окна.

**Проверка:** после правки — «Настройка — Dolphin»: рамка/сайдбар/контент
все `#FFFFFF`/α0.75. Так как это правка общего файла темы, а не
Dolphin-специфичного кода, фикс системный — проверен без дополнительных
правок на диалоге настроек KCalc (другое приложение), тот же результат.

## Диалоги Dolphin: контент оставался непрозрачным (не только «Настройка») — универсальный фикс через `hastransientparent`, 2026-07-29

После фикса цвета выше проверено окно «Свойства» (Alt+Enter/ПКМ на файле) —
фон полностью непрозрачный (α=1.0) при прозрачной рамке (α=0.75). Прежний
punch-through в `tools/install-kwin-window-rules.sh` матчил только заголовок
`^(Настройка|Configure) `, под «Свойства ...» не подходивший — окно
продолжало ловиться исключением `wmclass=dolphin`.

Через временный KWin-скрипт (`qdbus6 org.kde.KWin /Scripting loadScript` →
`qdbus6 org.kde.KWin /Scripting/Script0 org.kde.kwin.Script.run` →
`journalctl --user -b0 -o cat`, `workspace.windowList()`) подтверждено: окно
«Свойства» отдаёт `normalWindow=true, dialog=false, transient=true`, без
`windowRole` — отличить его от главного окна по NET::WindowType или роли
нельзя, а по заголовку не масштабируется на другие диалоги (Переименовать,
«Открыть с помощью» и т.д.) и локале-зависимо.

**Найденное надёжное поле** — `hastransientparent`
(`/usr/include/kwin/rulesettings.kcfg`, `rules.cpp:479-480`:
`bool(transientParent) == hastransientparent`): истинно для любого
дочернего окна, ложно только для настоящего главного окна.

`tools/install-kwin-window-rules.sh` переписан: punch-through по заголовку
убран целиком; исключение для `NATIVE_ALPHA_CLASSES` (`dolphin,Alacritty`)
теперь скоуплено `hastransientparent=false`+`hastransientparentmatch=1`
(`ExactBoolMatch=1`) вместо `types=1`. Итоговый `~/.config/kwinrulesrc`
(фрагмент, класс `dolphin`):

```ini
[5]
Description=Exclude from global translucency: dolphin
wmclass=dolphin
wmclassmatch=2
wmclasscomplete=false
types=289
hastransientparent=false
hastransientparentmatch=1
opacityactiverule=1
opacityinactiverule=1
```

**Проверка** (полный перезапуск `dolphin`, старые окна не откатывают уже
применённый opacity): «Свойства» — `#FFFFFF`/α0.75; «Настройка» — без
регрессии; главное окно Dolphin — без двойного умножения альфы (нативные
0.75, не 0.5625).
