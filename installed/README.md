# Снимок установленного состояния

Полная копия `~/.config`, `~/.local/share`, `~/.themes` и системного каталога
SDDM не включается в Git-репозиторий: это машинные каталоги с кэшем, симлинками
и правами доступа. Вместо этого здесь зафиксирован манифест установки, а
подробные значения находятся в [CURRENT_STATE.md](../notes/CURRENT_STATE.md).

Установка выполнена 2026-07-28 на KDE Plasma 6.7.3 Wayland. Активный профиль:
`com.github.vinceliuice.MacTahoe-Light`.

Для повторной установки пользовательских компонентов:

```bash
./install.sh
./source/MacTahoe-icon-theme/cursors/install.sh
```

Для SDDM требуется отдельная команда с root:

```bash
sudo ./source/MacTahoe-kde/sddm/install.sh
```

Проверка состояния:

```bash
./tools/check-theme-state.sh
```
