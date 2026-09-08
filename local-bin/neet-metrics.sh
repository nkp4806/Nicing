#!/usr/bin/env bash

cpu=$(cat "$HOME/.cache/neet/cpu" 2>/dev/null || echo 0)

read -r total available < <(free -b | awk '/Mem:/ {print $2, $7}')
ram=$(( (total - available) * 100 / total ))

gpu=$(nvidia-smi --query-gpu=utilization.gpu \
  --format=csv,noheader,nounits 2>/dev/null | head -1 | xargs)

printf 'CPU %s%%  ·  RAM %s%%  ·  GPU %s%%\n' "$cpu" "$ram" "$gpu"
