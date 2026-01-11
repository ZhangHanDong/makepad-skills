# Contributing to Makepad Skills

Thank you for contributing to the Makepad skills ecosystem! This guide explains how to contribute patterns, shaders, and troubleshooting entries.

## Directory Structure

```
skills/
├── 03-graphics/
│   ├── _base/           # Official skills (numbered)
│   └── community/       # Community contributions
├── 04-patterns/
│   ├── _base/           # Official patterns (numbered)
│   └── community/       # Community contributions
├── 06-reference/
│   └── troubleshooting/ # Error/solution documentation
└── 99-evolution/
    └── templates/       # Contribution templates
```

## Contribution Types

### 1. Community Patterns

Add your pattern to `04-patterns/community/`:

**File naming**: `{github-handle}-{pattern-name}.md`

Examples:
- `zhangsan-drag-drop-list.md`
- `lisi-infinite-scroll.md`
- `wangwu-theme-persistence.md`

**Template**: Copy from `99-evolution/templates/pattern-template.md`

### 2. Community Shaders/Effects

Add your shader to `03-graphics/community/`:

**File naming**: `{github-handle}-{effect-name}.md`

Examples:
- `zhangsan-glassmorphism.md`
- `lisi-neon-glow.md`
- `wangwu-particle-trail.md`

**Template**: Copy from `99-evolution/templates/shader-template.md`

### 3. Troubleshooting Entries

Add error solutions to `06-reference/troubleshooting/`:

**File naming**: `{error-short-name}.md`

Examples:
- `widget-not-found.md`
- `animator-not-playing.md`
- `shader-compile-error.md`

**Template**: Copy from `99-evolution/templates/troubleshooting-template.md`

## Frontmatter Format

Every contribution must include YAML frontmatter:

```yaml
---
name: my-pattern-name
author: your-github-handle
source: project-where-you-discovered-this
date: 2024-01-15
tags: [tag1, tag2, tag3]
level: beginner|intermediate|advanced
---
```

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
3. Fill in the template with your content
4. Submit a Pull Request

### Syncing Upstream

To sync your fork with new official content while keeping your contributions:

```bash
git fetch upstream
git merge upstream/main --no-edit
```

Your `community/` files won't conflict with `_base/` changes.

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
2. **Attribution**: Your GitHub handle in filename provides clear credit
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

## Questions?

- Open an issue on GitHub
- Tag `@robius` in discussions
- Check existing patterns for examples

Happy contributing!
