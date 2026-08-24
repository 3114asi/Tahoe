#!/usr/bin/env bash
# Keep an empty Dolphin 26.08 launch from opening Home when another Dolphin
# GUI process exists. Dolphin only restores the saved session in its first
# process. For subsequent launches, explicitly open the URL saved by the last
# closed/auto-saved window. Do this even when no process is visible: process
# exit and D-Bus service removal are not atomic, and a rapid Meta+E after
# closing a window can otherwise make Dolphin skip restoration and open Home.
# Other arguments are passed through unchanged.
set -euo pipefail

if (( $# == 0 )); then
    session_file="$HOME/.config/session/dolphin_dolphin_dolphin"
    if [[ -r "$session_file" ]]; then
        active_index="$(
            sed -n 's/^Active Tab Index=//p' "$session_file" |
                head -n 1
        )"
        [[ "$active_index" =~ ^[0-9]+$ ]] || active_index=0
        saved_url="$(
            grep -m1 "^Tab Data $active_index=" "$session_file" |
                grep -o 'file://[^\\]*' |
                head -n 1 || true
        )"
        if [[ -n "$saved_url" ]]; then
            set -- --new-window "$saved_url"
        fi
    fi
fi

export LANG=ru_RU.UTF-8
export LANGUAGE=ru
export LC_ALL=ru_RU.UTF-8
export LD_PRELOAD="$HOME/.local/lib/kvantum-dialog-alpha-fix.so"
exec /usr/bin/dolphin "$@"
