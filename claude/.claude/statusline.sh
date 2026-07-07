#!/bin/bash
# Read JSON data that Claude Code sends to stdin
input=$(cat)

# Extract fields using jq
MODEL=$(echo "$input" | jq -r '.model.display_name')
DIR=$(echo "$input" | jq -r '.workspace.current_dir')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
# The "// 0" provides a fallback if the field is null
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)

# Build progress bar: printf -v creates a run of spaces, then
# ${var// /▓} replaces each space with a block character
BAR_WIDTH=10
FILLED=$((PCT * BAR_WIDTH / 100))
EMPTY=$((BAR_WIDTH - FILLED))
BAR=""
[ "$FILLED" -gt 0 ] && printf -v FILL "%${FILLED}s" && BAR="${FILL// /▓}"
[ "$EMPTY" -gt 0 ] && printf -v PAD "%${EMPTY}s" && BAR="${BAR}${PAD// /░}"

# MONTHLY / EXTRA USAGE via OAuth API
USAGE_CACHE="/tmp/claude-statusline-usage.json"
USAGE_CACHE_AGE=1800

fetch_usage() {
  local token
  if [ "$(uname)" = "Darwin" ]; then
    token=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null | jq -r '.claudeAiOauth.accessToken // empty')
  else
    token=$(jq -r '.claudeAiOauth.accessToken // empty' ~/.claude/.credentials.json 2>/dev/null)
  fi
  [ -z "$token" ] && return 1
  curl -s --max-time 3 "https://api.anthropic.com/api/oauth/usage" \
    -H "Authorization: Bearer $token" \
    -H "anthropic-beta: oauth-2025-04-20" \
    -H "Content-Type: application/json" > "$USAGE_CACHE" 2>/dev/null
}

# Refresh cache if missing or stale
cache_age=9999
if [ -f "$USAGE_CACHE" ]; then
  if [ "$(uname)" = "Darwin" ]; then
    cache_age=$(( $(date +%s) - $(stat -f %m "$USAGE_CACHE") ))
  else
    cache_age=$(( $(date +%s) - $(stat -c %Y "$USAGE_CACHE") ))
  fi
fi
[ "$cache_age" -gt "$USAGE_CACHE_AGE" ] && fetch_usage

# Read from cache
monthly_limit=$(jq -r '.extra_usage.monthly_limit // empty' "$USAGE_CACHE" 2>/dev/null)
monthly_used=$(jq -r '.extra_usage.used_credits // empty' "$USAGE_CACHE" 2>/dev/null)

OUT="[$MODEL] $BAR $PCT%"

if [ "$(echo "$COST > 0" | bc -l 2>/dev/null)" = "1" ]; then
  COST_FMT=$(printf '$%.4f' "$COST")
  OUT="$OUT | $COST_FMT"
fi

if [ -n "$monthly_used" ] && [ -n "$monthly_limit" ]; then
  OUT="$OUT [\$$(awk "BEGIN {printf \"%.2f\", $monthly_used/100}")/\$$(awk "BEGIN {printf \"%.0f\", $monthly_limit/100}")]"
fi

if [ "$DURATION_MS" -gt 0 ] 2>/dev/null; then
  SECS=$(( DURATION_MS / 1000 ))
  MINS=$(( SECS / 60 ))
  SECS=$(( SECS % 60 ))
  OUT="$OUT | ${MINS}m ${SECS}s"
fi

echo "$OUT"

