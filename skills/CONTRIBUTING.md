# Contributing to Makepad Skills

Thank you for contributing to the Makepad skills ecosystem! This guide explains how to contribute patterns, shaders, hooks, and troubleshooting entries.

## Directory Structure

```
skills/
├── 03-graphics/
│   ├── _base/           # Official skills (numbered) - DO NOT modify
│   └── community/       # Community contributions
├── 04-patterns/
│   ├── _base/           # Official patterns (numbered) - DO NOT modify
│   └── community/       # Community contributions
├── 06-reference/
│   └── troubleshooting/ # Error/solution documentation
└── 99-evolution/
    ├── hooks/           # Hook scripts
    ├── references/      # Detailed guides
    └── templates/       # Contribution templates
```

## Contribution Types

### 1. Community Patterns

Add your pattern to `04-patterns/community/`:

**File naming**: `{descriptive-pattern-name}.md` (NO GitHub handle in filename)

Examples:
- `drag-drop-list.md`
- `infinite-scroll.md`
- `theme-persistence.md`

**Template**: Copy from `99-evolution/templates/pattern-template.md`

### 2. Community Shaders/Effects

Add your shader to `03-graphics/community/`:

**File naming**: `{descriptive-effect-name}.md` (NO GitHub handle in filename)

Examples:
- `glassmorphism.md`
- `neon-glow.md`
- `particle-trail.md`

**Template**: Copy from `99-evolution/templates/shader-template.md`

### 3. Troubleshooting Entries

Add error solutions to `06-reference/troubleshooting/`:

**File naming**: `{error-short-name}.md`

Examples:
- `widget-not-found.md`
- `animator-not-playing.md`
- `shader-compile-error.md`

**Template**: Copy from `99-evolution/templates/troubleshooting-template.md`

### 4. Hooks

Add hooks to `99-evolution/hooks/`:

**File naming**: `{hook-purpose}.sh`

**Template**: Copy from `99-evolution/templates/hook-template.md`

**Additional requirements**: See [Hook Testing Requirements](#hook-testing-requirements) below.

## Frontmatter Format

Every contribution must include YAML frontmatter:

```yaml
---
name: my-pattern-name
author: your-github-handle          # Your ID goes here, NOT in filename
source: project-where-you-discovered-this
date: 2024-01-15
tags: [tag1, tag2, tag3]
level: beginner|intermediate|advanced
makepad-branch: main|dev            # Required: specify which branch this works with
---
```

## Naming Conflict Resolution

Since filenames don't include GitHub handles, conflicts may occur:

1. **First come, first served** - Merged PR owns the name
2. **Use descriptive suffix** for different approaches:
   - ✓ `drag-drop-native.md` vs `drag-drop-gesture.md`
   - ✗ `drag-drop.md` vs `drag-drop-v2.md`
3. **Maintainer decides** - May merge or replace if new version is clearly better

## Testing Requirements

### All Contributions Must Be Tested

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

### Hook Testing Requirements

Hooks require additional verification:

- [ ] Tested with `claude --with-hooks` flag
- [ ] Provided `settings.example.json` snippet in PR
- [ ] Documented prerequisites (e.g., `jq`, `bash 4+`)
- [ ] Works on macOS and Linux (note Windows limitations if any)

**Required in PR for hooks:**

1. **settings.example.json snippet** showing exact configuration
2. **Test evidence** describing trigger scenario and behavior

## Quality Guidelines

### Patterns Should:
- Solve a real, reusable problem
- Include working code examples
- Explain when to use (and when not to)
- Be tested in a real project

### Shaders Should:
- Produce a visible, useful effect
- Be performant (avoid heavy loops)
- Include inline comments explaining the math
- Document all customizable parameters

### Troubleshooting Should:
- Include exact error message
- Explain why the error occurs
- Show wrong vs. correct code
- Provide copy-pasteable solutions

### Hooks Should:
- Solve a specific automation need
- Be tested with `claude --with-hooks`
- Include ready-to-use settings.example.json
- Document all prerequisites

## Workflow

### Using Self-Evolution Skill

If you have the makepad-skills installed, use the self-evolution skill to add your contribution:

```
# In your Claude Code session
/evolve add pattern my-new-pattern

# Claude will guide you through creating the pattern
```

### Manual Contribution

1. Fork the repository
2. Create your file in the appropriate `community/` directory
3. Test your contribution thoroughly
4. Fill in the template with your content
5. Submit a Pull Request with testing evidence

### Syncing Upstream

To sync your fork with new official content while keeping your contributions:

```bash
git fetch upstream
git merge upstream/main --no-edit
```

Your `community/` files won't conflict with `_base/` changes.

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

## Testing Evidence
- Tested with: [project name]
- Makepad branch: [main/dev]
- Platform: [macOS/Linux/Windows]

## For Hooks Only
- [ ] Tested with `claude --with-hooks`
- [ ] Included settings.example.json snippet
- [ ] Documented prerequisites
```

## Promotion Path

High-quality community contributions may be promoted to `_base/`:

1. Pattern is widely useful
2. Code is well-tested
3. Documentation is complete
4. Community feedback is positive

Promoted patterns:
- Get a numbered prefix (e.g., `15-community-pattern.md`)
- Move to `_base/` directory
- Credit preserved via `author` field

## File Organization Principles

### Why `_base/` + `community/`?

1. **No merge conflicts**: Your community files never conflict with official updates
2. **Attribution**: Your GitHub handle in frontmatter provides clear credit
3. **Discoverability**: SKILL.md indexes both directories
4. **Quality tiers**: Official vs community is clear

### Why One Pattern Per File?

1. **Atomic updates**: Change one pattern without affecting others
2. **Parallel contributions**: Multiple people can add patterns simultaneously
3. **Easy linking**: Direct links to specific patterns
4. **Progressive disclosure**: Users see index first, dive into details

## Code Style

### Rust Code

```rust
// Include necessary imports
use makepad_widgets::*;

// Add comments for non-obvious code
live_design! {
    // Explain what this widget does
    MyWidget = {{MyWidget}} {
        // ...
    }
}
```

### DSL Code

```rust
live_design! {
    // Use consistent indentation (4 spaces)
    MyView = <View> {
        width: Fill
        height: Fit

        // Group related properties
        flow: Down
        spacing: 10
        padding: 20
    }
}
```

## Detailed Guidelines

For more details, see [Collaboration Guidelines](99-evolution/references/collaboration.md).

## Questions?

- Open an issue on GitHub
- Tag `@robius` in discussions
- Check existing patterns for examples

Happy contributing!
