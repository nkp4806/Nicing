#!/usr/bin/env bash

LIGHT="#EBAA82"
MEDIUM="#D86050"
DARK="#A73732"

rgb() {
    local c="${1#\#}"
    printf '\033[38;2;%d;%d;%dm' \
        "$((16#${c:0:2}))" \
        "$((16#${c:2:2}))" \
        "$((16#${c:4:2}))"
}

RESET=$'\033[0m'

color_for() {
    local pct="$1"
    local type="$2"

    if [[ "$type" == "battery" ]]; then
        if (( pct <= 30 )); then
            printf '%s' "$DARK"
        elif (( pct <= 70 )); then
            printf '%s' "$MEDIUM"
        else
            printf '%s' "$LIGHT"
        fi
    else
        if (( pct <= 30 )); then
            printf '%s' "$LIGHT"
        elif (( pct <= 70 )); then
            printf '%s' "$MEDIUM"
        else
            printf '%s' "$DARK"
        fi
    fi
}

make_bar() {
    local pct="$1"
    local type="$2"
    local width=20
    local filled=$((pct * width / 100))
    local empty=$((width - filled))
    local bar=""

    local fill_color
    fill_color=$(color_for "$pct" "$type")

    for ((i=0; i<filled; i++)); do
        bar+="$(rgb "$fill_color")█"
    done

    for ((i=0; i<empty; i++)); do
        bar+="$(rgb "#100C0D")░"
    done

    printf '%s%s' "$bar" "$RESET"
}

case "$1" in

    cpu)
        # Use the 1-second sampler for stable CPU usage.
        PCT=$(cat "$HOME/.cache/neet/cpu" 2>/dev/null || echo 0)

        # Keep the value sane.
        (( PCT < 0 )) && PCT=0
        (( PCT > 100 )) && PCT=100

        COLOR=$(color_for "$PCT" resource)
        BAR=$(make_bar "$PCT" resource)

        printf '[%s%s%s] %s%d%%%s\n' \
            "$(rgb "$COLOR")" "$BAR" "$RESET" \
            "$(rgb "$COLOR")" "$PCT" "$RESET"
        ;;

    memory)
        read -r TOTAL AVAILABLE < <(
            awk '
                /^MemTotal:/     { total=$2 }
                /^MemAvailable:/ { available=$2 }
                END { print total, available }
            ' /proc/meminfo
        )

        USED=$((TOTAL - AVAILABLE))
        PCT=$((100 * USED / TOTAL))

        COLOR=$(color_for "$PCT" resource)
        BAR=$(make_bar "$PCT" resource)

        USED_G=$(awk -v x="$USED" 'BEGIN { printf "%.2f", x/1024/1024 }')
        TOTAL_G=$(awk -v x="$TOTAL" 'BEGIN { printf "%.2f", x/1024/1024 }')

        printf '[%s%s%s] %.2f GiB / %.2f GiB (%s%d%%%s)\n' \
            "$(rgb "$COLOR")" "$BAR" "$RESET" \
            "$USED_G" "$TOTAL_G" "$(rgb "$COLOR")" "$PCT" "$RESET"
        ;;

    disk)
        read -r USED TOTAL PCT < <(
            df -P / | awk 'NR==2 {
                gsub("%","",$5)
                print $3, $2, $5
            }'
        )

        COLOR=$(color_for "$PCT" resource)
        BAR=$(make_bar "$PCT" resource)

        USED_G=$(awk -v x="$USED" 'BEGIN { printf "%.2f", x/1024/1024 }')
        TOTAL_G=$(awk -v x="$TOTAL" 'BEGIN { printf "%.2f", x/1024/1024 }')

        printf '[%s%s%s] %.2f GiB / %.2f GiB (%s%d%%%s)\n' \
            "$(rgb "$COLOR")" "$BAR" "$RESET" \
            "$USED_G" "$TOTAL_G" "$(rgb "$COLOR")" "$PCT" "$RESET"
        ;;

    battery)
        BATTERY_DIR=""

        for d in /sys/class/power_supply/BAT*; do
            if [[ -d "$d" ]]; then
                BATTERY_DIR="$d"
                break
            fi
        done

        if [[ -n "$BATTERY_DIR" ]]; then
            PCT=$(cat "$BATTERY_DIR/capacity")
            BAT_STATUS=$(cat "$BATTERY_DIR/status")

            AC_ONLINE=0

            for ac in /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; do
                if [[ -f "$ac" && "$(cat "$ac")" == "1" ]]; then
                    AC_ONLINE=1
                    break
                fi
            done

            if [[ "$BAT_STATUS" == "Charging" ]]; then
                STATUS="Charging"
            elif [[ "$AC_ONLINE" == "1" && "$BAT_STATUS" == "Full" ]]; then
                STATUS="AC Connected"
            elif [[ "$BAT_STATUS" == "Discharging" ]]; then
                STATUS="Discharging"
            else
                STATUS="$BAT_STATUS"
            fi
        else
            PCT=100
            STATUS="Unknown"
        fi

        COLOR=$(color_for "$PCT" battery)
        BAR=$(make_bar "$PCT" battery)

        printf '[%s%s%s] %s%d%%%s [%s]\n' \
            "$(rgb "$COLOR")" "$BAR" "$RESET" \
            "$(rgb "$COLOR")" "$PCT" "$RESET" "$STATUS"
        ;;

    *)
        echo "Usage: $0 {cpu|memory|disk|battery}"
        exit 1
        ;;
esac
