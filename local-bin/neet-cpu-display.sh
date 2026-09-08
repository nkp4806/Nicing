#!/usr/bin/env bash

cpu=$(cat "$HOME/.cache/neet/cpu" 2>/dev/null || echo 0)

(( cpu < 0 )) && cpu=0
(( cpu > 100 )) && cpu=100

width=20
filled=$((cpu * width / 100))
empty=$((width - filled))

if (( cpu < 30 )); then
    color='235;170;130'
elif (( cpu <= 70 )); then
    color='216;96;80'
else
    color='167;55;50'
fi

printf '['

if (( filled > 0 )); then
    printf '\033[38;2;%sm' "$color"

    for ((i=0; i<filled; i++)); do
        printf '█'
    done

    printf '\033[0m'
fi

printf '%*s' "$empty" ''
printf '] '

printf '\033[38;2;%sm%s%%\033[0m\n' "$color" "$cpu"
