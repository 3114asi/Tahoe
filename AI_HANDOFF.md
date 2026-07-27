# AI Handoff

Отвечай пользователю только на русском языке.

Этот проект — новый перенос темы, стиль macOS **Tahoe (26)**, на замену/рядом
с существующим проектом `../MacOS/` (тема WhiteSur, стиль более старых macOS —
Big Sur/Monterey). Оба проекта независимы, живут в соседних директориях.

## Откуда взято

Три отдельных апстрим-репозитория одного автора (vinceliuice, тот же автор,
что и WhiteSur):

| Проект | Локально | Апстрим |
| --- | --- | --- |
| MacTahoe-kde | `source/MacTahoe-kde` | github.com/vinceliuice/MacTahoe-kde |
| MacTahoe-gtk-theme | `source/MacTahoe-gtk-theme` | github.com/vinceliuice/MacTahoe-gtk-theme |
| MacTahoe-icon-theme | `source/MacTahoe-icon-theme` | github.com/vinceliuice/MacTahoe-icon-theme (включает курсоры, отдельного репозитория курсоров нет) |

Точные коммиты снимка — `notes/SOURCE_REVISIONS.md`. Клонировано
2026-07-28, `.git` каждого репозитория удалён (проект хранит плоский снимок
исходников, как и `../MacOS/`).

## Активное состояние системы

Тема установлена и применена 2026-07-28 на Plasma 6.7.3 Wayland. Активны:

- Look-and-Feel: `com.github.vinceliuice.MacTahoe-Light`;
- Kvantum: `MacTahoe`;
- цветовая схема: `MacTahoeLight`;
- иконки: `MacTahoe-light`;
- курсоры: `MacTahoe-cursors`;
- GTK: `MacTahoe-Light`;
- SDDM: `MacTahoe-Light`.

Подробный журнал установки и проверки — `notes/CURRENT_STATE.md`.
Откат к WhiteSur возможен через рабочий `../MacOS/install.sh`.

## Важные особенности install-скриптов исходников

Каждый из трёх содержит собственный `install.sh` с независимыми опциями,
проверять `--help` перед использованием, если нужно что-то нестандартное:

- **MacTahoe-kde**: `-c/--color [light|dark]` (по умолчанию — оба).
- **MacTahoe-gtk-theme**: `-c/--color`, `-t/--theme [default|blue|purple|...|all]`
  (акцентный цвет), `-a/--alt [normal|alt|all]` (стиль кнопок окна), `-o/--opacity
  [normal|solid]`, `-b/--blur` (требует GNOME Shell расширение Blur My Shell —
  **на KDE неприменимо**, не включать), `-s/--scheme [standard|nord]`.
- **MacTahoe-icon-theme**: `-t/--theme [default|blue|purple|...|nord|all]`
  (по умолчанию — только `blue`, если нужны все цвета — `all`), `-b/--bold`
  (более жирные иконки на панели).

`install.sh` в корне этого проекта — обёртка над всеми тремя, вызывает их с
консервативными дефолтами (не `-b/--blur`, поскольку это GNOME-специфичная
опция). Если пользователь просит другой акцент/цвет — редактировать вызовы
внутри обёртки, а не спорить с апстримными скриптами напрямую.

## Что делать после изменений

По аналогии с `../MacOS/`:

1. Обновлять `notes/CURRENT_STATE.md` после изменения активных вариантов.
2. Обновлять `installed/README.md`, если меняются фактические пути установки.
3. Вести раздел инцидентов в этом файле, если что-то ломается при
   обновлении пакетов KWin/KF6 (в `../MacOS/` уже есть похожий повторяющийся
   инцидент с forceblur — возможно, актуален и здесь, если MacTahoe-kde тоже
   использует кастомный KWin blur-эффект — проверить `source/MacTahoe-kde`
   на наличие C++/QML эффектов, не только Aurorae/Kvantum).

## Что не делать без явного запроса

- Не запускать `install.sh` (ни обёртку, ни исходников) без подтверждения —
  это меняет вид живой системы.
- Не удалять и не трогать `../MacOS/` — это отдельный рабочий проект,
  пользователь может захотеть вернуться к WhiteSur.
- Не добавлять внешние GitHub-ссылки, кроме апстрима vinceliuice.
