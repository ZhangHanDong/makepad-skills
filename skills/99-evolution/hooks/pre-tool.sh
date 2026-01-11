#!/bin/bash
# Pre-tool hook for makepad-evolution
# Triggers: Version detection, project style detection

TOOL_NAME="$1"
TOOL_INPUT="$2"

# State file to track if version detection has been done this session
STATE_FILE="/tmp/makepad-skills-session-$$"

# Only run detection once per session
if [ -f "$STATE_FILE" ]; then
    exit 0
fi

# Mark session as initialized
touch "$STATE_FILE"

# Find Cargo.toml in current directory or parents
find_cargo_toml() {
    local dir="$PWD"
    while [ "$dir" != "/" ]; do
        if [ -f "$dir/Cargo.toml" ]; then
            echo "$dir/Cargo.toml"
            return 0
        fi
        dir=$(dirname "$dir")
    done
    return 1
}

CARGO_TOML=$(find_cargo_toml)

if [ -n "$CARGO_TOML" ]; then
    # Detect Makepad branch
    MAKEPAD_BRANCH=$(grep -A5 'makepad-widgets' "$CARGO_TOML" | grep 'branch' | head -1 | sed 's/.*branch *= *"\([^"]*\)".*/\1/')

    if [ -n "$MAKEPAD_BRANCH" ]; then
        echo "[makepad-evolution] Detected Makepad branch: $MAKEPAD_BRANCH"
        echo "[makepad-evolution] Apply version-specific guidance from makepad-rust skill."
    fi

    # Check if this is a Makepad project
    if grep -q 'makepad' "$CARGO_TOML"; then
        echo "[makepad-evolution] This is a Makepad project. Skills available: makepad-fundamentals, makepad-rust, makepad-patterns, makepad-shaders, makepad-troubleshooting"
    fi
fi
