#!/bin/bash
# Pre-UI-Edit Hook for makepad-evolution
# Author: TigerInYourDream
# Date: 2026-01-12
# Purpose: Check UI code completeness and remind to add missing properties
# Related: 04-patterns/community/ui-complete-specification.md
#
# IMPORTANT: Claude Code passes data via stdin as JSON, not command line args!
# Data format: {"tool_name": "Edit", "tool_input": {"file_path": "...", "new_string": "..."}}

# Read JSON from stdin
INPUT=$(cat)

# Extract tool_name and content using jq
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
NEW_STRING=$(echo "$INPUT" | jq -r '.tool_input.new_string // empty' 2>/dev/null)
CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // empty' 2>/dev/null)

# Use new_string for Edit, content for Write
TOOL_INPUT="$NEW_STRING"
[ -z "$TOOL_INPUT" ] && TOOL_INPUT="$CONTENT"

# Only check Write/Edit/Update operations
if [[ "$TOOL_NAME" != "Write" && "$TOOL_NAME" != "Edit" && "$TOOL_NAME" != "Update" ]]; then
    exit 0
fi

# Check if this is UI-related code
if ! echo "$TOOL_INPUT" | grep -qE "<(Button|Label|TextInput|RoundedView)>"; then
    exit 0
fi

# Count completeness indicators (ensure numeric values)
count_pattern() {
    local result=$(echo "$TOOL_INPUT" | grep -cE "$1" 2>/dev/null || true)
    result=${result:-0}
    echo "$result" | tr -d '[:space:]'
}

HAS_WIDTH=$(count_pattern "width:[[:space:]]*(Fit|Fill|[0-9]+)")
HAS_HEIGHT=$(count_pattern "height:[[:space:]]*(Fit|Fill|[0-9]+)")
HAS_PADDING=$(count_pattern "padding:[[:space:]]*\{|padding:[[:space:]]*[0-9]+")
HAS_TEXT_STYLE=$(count_pattern "draw_text:[[:space:]]*\{|text_style:")
HAS_WRAP=$(count_pattern "wrap:")

[ -z "$HAS_WIDTH" ] && HAS_WIDTH=0
[ -z "$HAS_HEIGHT" ] && HAS_HEIGHT=0
[ -z "$HAS_PADDING" ] && HAS_PADDING=0
[ -z "$HAS_TEXT_STYLE" ] && HAS_TEXT_STYLE=0
[ -z "$HAS_WRAP" ] && HAS_WRAP=0

COMPLETENESS=$((HAS_WIDTH + HAS_HEIGHT + HAS_PADDING + HAS_TEXT_STYLE + HAS_WRAP))

# Only warn if missing 3+ critical properties
if [ "$COMPLETENESS" -ge 3 ]; then
    exit 0
fi

# Build warning message
MESSAGE="\n"
MESSAGE+="  ╭─────────────────────────────────────────╮\n"
MESSAGE+="  │  📐 UI Specification Check ($COMPLETENESS/5)          │\n"
MESSAGE+="  ╰─────────────────────────────────────────╯\n"
MESSAGE+="\n"
MESSAGE+="  Missing properties:\n"
MESSAGE+="\n"

[ "$HAS_WIDTH" -eq 0 ] && MESSAGE+="    • width      Fit | Fill | number\n"
[ "$HAS_HEIGHT" -eq 0 ] && MESSAGE+="    • height     Fit | Fill | number\n"
[ "$HAS_PADDING" -eq 0 ] && MESSAGE+="    • padding    { left, right, top, bottom }\n"
[ "$HAS_TEXT_STYLE" -eq 0 ] && MESSAGE+="    • draw_text  { text_style, color }\n"
[ "$HAS_WRAP" -eq 0 ] && MESSAGE+="    • wrap       Word | Line | Ellipsis\n"

MESSAGE+="\n"
MESSAGE+="  💡 Add these to prevent text overlap.\n"
MESSAGE+="\n"

# Output to stderr and exit 2 to block tool execution
echo -e "$MESSAGE" >&2
exit 2
