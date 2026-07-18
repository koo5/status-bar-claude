#!/usr/bin/env bash
input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
model=$(echo "$input" | jq -r '.model.display_name')
ctx_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
hour_pct=$(echo "$input" | jq -r '(.rate_limits["5h"] // .rate_limits.five_hour // .rate_limits.hour).used_percentage // empty')
week_pct=$(echo "$input" | jq -r '(.rate_limits["7d"] // .rate_limits.seven_day // .rate_limits.week).used_percentage // empty')
hour_reset=$(echo "$input" | jq -r '(.rate_limits["5h"] // .rate_limits.five_hour // .rate_limits.hour).resets_at // empty')
week_reset=$(echo "$input" | jq -r '(.rate_limits["7d"] // .rate_limits.seven_day // .rate_limits.week).resets_at // empty')

dir=$(basename "$cwd")

RESET=$'\033[0m'
DIM=$'\033[2;37m'
WHITE=$'\033[0;37m'
BOLD_WHITE=$'\033[1;37m'
GREEN=$'\033[0;32m'
CYAN=$'\033[0;36m'
YELLOW=$'\033[0;33m'
RED=$'\033[0;31m'
BOLD_RED=$'\033[1;31m'

branch=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git -C "$cwd" -c core.hooksPath=/dev/null symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
fi

pct_color() {
  local pct=$1
  if   [ "$pct" -ge 90 ]; then printf '%s' "$BOLD_RED"
  elif [ "$pct" -ge 75 ]; then printf '%s' "$RED"
  elif [ "$pct" -ge 50 ]; then printf '%s' "$YELLOW"
  else                          printf '%s' "$WHITE"
  fi
}

format_reset_time() {
  local epoch=$1 fmt=$2
  LC_ALL=C date -r "$epoch" "+$fmt" 2>/dev/null || LC_ALL=C date -d "@$epoch" "+$fmt" 2>/dev/null
}

out="${BOLD_WHITE}${dir}${RESET}"
[ -n "$branch" ] && out="${out}  ${GREEN}${branch}${RESET}"
if [ -n "$model" ]; then
  out="${out}  ${WHITE}${model}${RESET}"
else
  out="${out}  ${DIM}claude${RESET}"
fi

if [ -n "$ctx_pct" ]; then
  pct=$(LC_ALL=C printf "%.0f" "$ctx_pct")
  out="${out}  ${DIM}ctx${RESET} $(pct_color "$pct")${pct}%${RESET}"
fi

if [ -n "$hour_pct" ]; then
  pct=$(LC_ALL=C printf "%.0f" "$hour_pct")
  out="${out}  ${DIM}5h${RESET} $(pct_color "$pct")${pct}%${RESET}"
  if [ -n "$hour_reset" ]; then
    reset_str=$(format_reset_time "$hour_reset" "%H:%M")
    [ -n "$reset_str" ] && out="${out} ${DIM}↻${RESET}${WHITE}${reset_str}${RESET}"
  fi
fi

if [ -n "$week_pct" ]; then
  pct=$(LC_ALL=C printf "%.0f" "$week_pct")
  out="${out}  ${DIM}7d${RESET} $(pct_color "$pct")${pct}%${RESET}"
  if [ -n "$week_reset" ]; then
    reset_str=$(format_reset_time "$week_reset" "%a %H:%M")
    [ -n "$reset_str" ] && out="${out} ${DIM}↻${RESET}${WHITE}${reset_str}${RESET}"
  fi
fi

printf '%s' "$out"
