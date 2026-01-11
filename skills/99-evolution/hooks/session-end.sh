#!/bin/bash
# Session-end hook for makepad-evolution
# Triggers: Evolution review prompt

# Check if any Makepad-related work was done (by checking state file)
STATE_FILE="/tmp/makepad-skills-session-$$"

if [ -f "$STATE_FILE" ]; then
    echo "[makepad-evolution:review] Session ending."
    echo "[makepad-evolution:review] Consider if any learnings should be captured:"
    echo "  - New widget patterns discovered?"
    echo "  - Errors solved that others might encounter?"
    echo "  - Shader techniques worth documenting?"
    echo "[makepad-evolution:review] Use 'evolve makepad-skills' to add valuable patterns."

    # Clean up state file
    rm -f "$STATE_FILE"
fi
