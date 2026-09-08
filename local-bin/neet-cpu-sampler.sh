#!/usr/bin/env bash

CACHE="$HOME/.cache/neet/cpu"

while true; do
    read -r _ u n s i w _ < /proc/stat
    idle1=$((i + w))
    total1=$((u + n + s + i + w))

    sleep 1

    read -r _ u n s i w _ < /proc/stat
    idle2=$((i + w))
    total2=$((u + n + s + i + w))

    total=$((total2 - total1))
    idle=$((idle2 - idle1))

    if (( total > 0 )); then
        cpu=$((100 * (total - idle) / total))
    else
        cpu=0
    fi

    printf '%s\n' "$cpu" > "${CACHE}.tmp"
    mv "${CACHE}.tmp" "$CACHE"
done
