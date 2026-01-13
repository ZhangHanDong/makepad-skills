# Makepad Skills Hooks (Optional)

Hooks are **optional** Claude Code extensions that automatically check your Makepad UI code quality.

## Why Use Hooks?

Makepad UI components often have text overlap issues when missing critical properties. The hook automatically reminds you to add:
- `width` / `height` - Prevent layout collapse
- `padding` - Ensure proper spacing
- `draw_text` - Control text rendering
- `wrap` - Handle text overflow

**Without hooks**: You write incomplete UI code → compile → see visual bugs → fix manually

**With hooks**: Claude reminds you before writing incomplete code

## Quick Setup

### 1. Prerequisites

```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt install jq
```

### 2. Copy hooks to your project

```bash
cp -r .claude/skills/99-evolution/hooks .claude/skills/hooks
chmod +x .claude/skills/hooks/*.sh
```

### 3. Add to `.claude/settings.json`

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

If you already have a `settings.json`, merge the `hooks` section.

## Available Hooks

| Hook | Trigger | Purpose |
|------|---------|---------|
| `pre-ui-edit.sh` | Before Write/Edit/Update | Check UI completeness (5 properties) |

## How It Works

When you ask Claude to write UI code like `<Button>`, the hook checks for 5 critical properties. If fewer than 3 are present, it blocks and shows a reminder:

```
┌─────────────────────────────────────────────────┐
│  📐 UI Specification Check (1/5)                │
└─────────────────────────────────────────────────┘

UI component missing critical properties:

  • width: Fit / Fill / number
  • height: Fit / Fill / number
  • padding: { left, right, top, bottom }
  • draw_text: { text_style, color }

💡 Complete specs prevent text overlap issues.
```

Claude will then rewrite the code with complete properties.

## Technical Details

- Claude Code passes data via **stdin as JSON**, not command line arguments
- Output must go to **stderr** for display
- Exit code `0` = allow, `2` = block with message

Input format:
```json
{
  "tool_name": "Edit",
  "tool_input": {
    "file_path": "src/app.rs",
    "new_string": "<Button> { text: \"Click\" }"
  }
}
```
