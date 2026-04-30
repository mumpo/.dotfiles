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

OUT="[$MODEL] $BAR $PCT%"

if [ "$(echo "$COST > 0" | bc -l 2>/dev/null)" = "1" ]; then
  COST_FMT=$(printf '$%.4f' "$COST")
  OUT="$OUT | $COST_FMT"
fi

if [ "$DURATION_MS" -gt 0 ] 2>/dev/null; then
  SECS=$(( DURATION_MS / 1000 ))
  MINS=$(( SECS / 60 ))
  SECS=$(( SECS % 60 ))
  OUT="$OUT | ${MINS}m ${SECS}s"
fi

echo "$OUT"

