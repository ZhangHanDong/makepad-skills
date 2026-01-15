# Collaboration Guidelines

Detailed guidelines for contributing to makepad-skills.

## Core Principles

### 1. Incremental Contributions

All community contributions go to `community/` directories, never modify `_base/` files.

```
skills/
├── 03-graphics/
│   ├── _base/           # Official only - DO NOT modify
│   └── community/       # Your contributions here
├── 04-patterns/
│   ├── _base/           # Official only - DO NOT modify
│   └── community/       # Your contributions here
```

This ensures:
- No merge conflicts with upstream updates
- Clear separation of official vs community content
- Easy sync with `git pull`

### 2. File Naming

**DO NOT include your GitHub handle in filename.**

```
✓ drag-drop-list.md
✓ glassmorphism-effect.md
✗ zhangsan-drag-drop-list.md
```

**Put author info in frontmatter:**

```yaml
---
name: drag-drop-list
author: your-github-handle    # Your ID goes here
source: my-project
date: 2024-01-15
tags: [interaction, list]
level: intermediate
makepad-branch: main          # Required: main|dev
---
```

### 3. Naming Conflicts

When filename already exists:

1. **First come, first served** - Merged PR owns the name
2. **Use descriptive suffix** for different approaches:
   - ✓ `drag-drop-native.md` vs `drag-drop-gesture.md`
   - ✗ `drag-drop.md` vs `drag-drop-v2.md`
3. **Maintainer decides** - May merge or replace if new version is clearly better

---

## Testing Requirements

### For Skills (Patterns/Shaders/Troubleshooting)

Before submitting PR, verify:

- [ ] Code compiles with `cargo build`
- [ ] Tested in a real Makepad project
- [ ] All `live_design!` blocks are valid DSL
- [ ] Examples work as documented

**In PR description, include:**
```markdown
## Testing
- Tested with: [project name or "standalone test"]
- Makepad branch: main/dev
- Platform: macOS/Linux/Windows
```

### For Hooks

Hooks require additional verification:

- [ ] Tested with `claude --with-hooks` flag
- [ ] Provided `settings.example.json` snippet
- [ ] Documented prerequisites (e.g., `jq`, `bash 4+`)
- [ ] Works on macOS and Linux (note Windows limitations if any)

**Required in PR:**

1. **settings.example.json snippet** showing exact configuration:
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "YourMatcher",
        "hooks": [
          {
            "type": "command",
            "command": "bash ${SKILLS_DIR}/hooks/your-hook.sh"
          }
        ]
      }
    ]
  }
}
```

2. **Test evidence** in PR description:
```markdown
## Hook Testing
- [ ] Ran `claude --with-hooks` with this configuration
- [ ] Hook triggered correctly on: [describe trigger scenario]
- [ ] Output/behavior: [describe what happened]
```

---

## PR Checklist

Copy this checklist to your PR description:

```markdown
## Contribution Type
- [ ] Pattern
- [ ] Shader/Effect
- [ ] Troubleshooting
- [ ] Hook

## Required Checks
- [ ] File in correct `community/` directory
- [ ] Frontmatter includes `author` and `makepad-branch`
- [ ] Code tested and working
- [ ] No modification to `_base/` files

## For Hooks Only
- [ ] Tested with `claude --with-hooks`
- [ ] Included settings.example.json snippet
- [ ] Documented prerequisites
```

---

## Directory Reference

| Content Type | Location | Template |
|--------------|----------|----------|
| Patterns | `04-patterns/community/` | `templates/pattern-template.md` |
| Shaders | `03-graphics/community/` | `templates/shader-template.md` |
| Troubleshooting | `06-reference/troubleshooting/` | `templates/troubleshooting-template.md` |
| Hooks | `99-evolution/hooks/` | `templates/hook-template.md` |

---

## Promotion Path

High-quality community contributions may be promoted to `_base/`:

1. Widely useful across projects
2. Well-tested and documented
3. Positive community feedback
4. Maintainer approval

Promoted content:
- Moves to `_base/` with numbered prefix
- Original `author` field preserved
