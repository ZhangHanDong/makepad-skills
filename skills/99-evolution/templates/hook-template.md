---
name: [hook-name]
author: [your-github-handle]
date: [YYYY-MM-DD]
trigger: [PreToolUse|PostToolUse|Stop]
matcher: [tool matcher pattern]
---

# [Hook Name]

Brief description of what this hook does.

## Purpose

Why this hook is useful. What problem does it solve?

## Prerequisites

```bash
# List any required tools
# e.g., brew install jq
```

## Setup

Add to `.claude/settings.json`:

```json
{
  "hooks": {
    "[Trigger]": [
      {
        "matcher": "[Matcher]",
        "hooks": [
          {
            "type": "command",
            "command": "bash ${SKILLS_DIR}/hooks/[hook-name].sh"
          }
        ]
      }
    ]
  }
}
```

## Script

```bash
#!/bin/bash
# [hook-name].sh

# Your hook implementation
```

## Testing

Tested with:
- `claude --with-hooks`
- Trigger scenario: [describe what triggers this hook]
- Expected behavior: [describe what should happen]

## Platform Support

- [x] macOS
- [x] Linux
- [ ] Windows (note any limitations)
