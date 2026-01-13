# Makepad Skills Hooks

This folder contains Claude Code hooks to enable automatic triggering of makepad-evolution features.

## Setup

Copy the hooks configuration to your project's `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash|Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "bash ${SKILLS_DIR}/hooks/pre-tool.sh \"$TOOL_NAME\" \"$TOOL_INPUT\""
          }
        ]
      },
      {
        "matcher": "Write|Edit|Update",
        "hooks": [
          {
            "type": "command",
            "command": "bash ${SKILLS_DIR}/hooks/pre-ui-edit.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash ${SKILLS_DIR}/hooks/post-bash.sh \"$TOOL_OUTPUT\" \"$EXIT_CODE\""
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash ${SKILLS_DIR}/hooks/session-end.sh"
          }
        ]
      }
    ]
  }
}
```

Replace `${SKILLS_DIR}` with the actual path to your `.claude/skills` directory.

## Hooks Overview

| Hook | Trigger | Purpose |
|------|---------|---------|
| `pre-tool.sh` | Before Bash/Write/Edit | Detect Makepad version, check project style |
| `post-bash.sh` | After Bash command | Detect compilation errors for self-correction |
| `session-end.sh` | Session ends | Prompt for evolution review |
| `pre-ui-edit.sh` | Before Write/Edit/Update | Check UI code completeness (Optional) |

## How It Works

1. **Version Detection** (`pre-tool.sh`): On first tool use, detects Makepad branch from Cargo.toml
2. **Error Detection** (`post-bash.sh`): Monitors `cargo build/run` output for errors
3. **Evolution Prompt** (`session-end.sh`): Reminds to capture learnings at session end

---

## UI Specification Checker (Optional)

The `pre-ui-edit.sh` hook checks UI code completeness to prevent text overlap issues.

### Prerequisites

```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt install jq
```

### Setup

Add to your `.claude/settings.json` (can coexist with other hooks):

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit|Update",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/skills/hooks/pre-ui-edit.sh"
          }
        ]
      }
    ]
  }
}
```

**Note**: Claude Code passes data via stdin as JSON, not command line arguments.

### What It Checks

When writing UI code (Button, Label, TextInput, RoundedView), checks for 5 properties:
- `width` - Fit / Fill / number
- `height` - Fit / Fill / number
- `padding` - { left, right, top, bottom } or number
- `draw_text` - { text_style, color }
- `wrap` - Word / Line / Ellipsis

If fewer than 3 properties are present, blocks and shows reminder.

### Technical Details

- Input: JSON via stdin `{"tool_name": "Edit", "tool_input": {...}}`
- Output: stderr for display
- Exit code: `0` = allow, `2` = block

See [ui-complete-specification.md](../../04-patterns/community/ui-complete-specification.md) for the full pattern.
