#!/bin/bash
# Post-Bash hook for makepad-evolution
# Triggers: Self-correction on compilation errors

TOOL_OUTPUT="$1"
EXIT_CODE="$2"

# Only process if command failed
if [ "$EXIT_CODE" = "0" ]; then
    exit 0
fi

# Check for common Makepad errors in output
check_makepad_errors() {
    local output="$1"

    # Apply error: no matching field
    if echo "$output" | grep -q "Apply error: no matching field"; then
        echo "[makepad-evolution:self-correction] Detected 'Apply error: no matching field'."
        echo "[makepad-evolution:self-correction] Check makepad-troubleshooting skill for correct property names."
        echo "[makepad-evolution:self-correction] If this is a new error pattern, consider adding it to makepad-troubleshooting."
    fi

    # Font-related errors
    if echo "$output" | grep -q "no matching field: font"; then
        echo "[makepad-evolution:self-correction] Detected font field error."
        echo "[makepad-evolution:self-correction] Use 'text_style: { font_size: X }' instead of 'font:'."
        echo "[makepad-evolution:self-correction] See makepad-troubleshooting for correct font syntax."
    fi

    # Color parse error (hex ending with 'e')
    if echo "$output" | grep -q "expected at least one digit in exponent"; then
        echo "[makepad-evolution:self-correction] Detected color parse error (hex ending with 'e')."
        echo "[makepad-evolution:self-correction] Change the last digit of the hex color to avoid 'e'."
    fi

    # Borrow checker errors
    if echo "$output" | grep -q "cannot borrow.*as mutable because it is also borrowed as immutable"; then
        echo "[makepad-evolution:self-correction] Detected borrow checker conflict."
        echo "[makepad-evolution:self-correction] Use the 'borrow scope pattern' from makepad-rust skill."
        echo "[makepad-evolution:self-correction] Separate read and write phases with explicit scope blocks."
    fi

    # Method not found
    if echo "$output" | grep -q "no method named.*found"; then
        echo "[makepad-evolution:self-correction] Detected method not found error."
        echo "[makepad-evolution:self-correction] Check makepad-troubleshooting for API changes."
        echo "[makepad-evolution:self-correction] If skill-suggested code caused this, update the skill."
    fi

    # Missing cx parameter
    if echo "$output" | grep -q 'argument.*of type.*&mut Cx.*is missing'; then
        echo "[makepad-evolution:self-correction] Detected missing cx parameter."
        echo "[makepad-evolution:self-correction] Most Makepad methods require cx as first argument."
    fi
}

# Only check if this looks like a cargo command output
if echo "$TOOL_OUTPUT" | grep -qE "(error\[E|warning:|Compiling|Building)"; then
    check_makepad_errors "$TOOL_OUTPUT"
fi
