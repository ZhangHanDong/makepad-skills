---
name: makepad-getting-started
description: Entry point for Makepad development with Claude. Start here to learn about available skills and how to begin building Makepad applications.
---

# Getting Started with Makepad Skills

Welcome! These skills help Claude assist you in building cross-platform UI applications with the Makepad framework.

## Quick Start

1. **New Project?** → See [init.md](./init.md) for project scaffolding
2. **Project Organization?** → See [project-structure.md](./project-structure.md)
3. **Learning Basics?** → Go to [01-core](../01-core/SKILL.md)

## Skills Overview

| Category | Description | Use When |
|----------|-------------|----------|
| [00-getting-started](./SKILL.md) | Project setup and structure | Starting a new project |
| [01-core](../01-core/SKILL.md) | Layout, widgets, events, styling | Learning fundamentals |
| [02-components](../02-components/SKILL.md) | Built-in widget reference | Need specific components |
| [03-graphics](../03-graphics/SKILL.md) | Shaders, SDF, animations | Visual effects |
| [04-patterns](../04-patterns/SKILL.md) | State, async, responsive design | Advanced patterns |
| [05-deployment](../05-deployment/SKILL.md) | Build for all platforms | Packaging apps |
| [06-reference](../06-reference/SKILL.md) | Troubleshooting, code quality | Debugging, refactoring |
| [99-evolution](../99-evolution/SKILL.md) | Self-improving skills | Auto-learning |

## First Steps

```bash
# Create new Makepad project
cargo new my_app
cd my_app

# Add Makepad dependencies to Cargo.toml
[dependencies]
makepad-widgets = { git = "https://github.com/makepad/makepad", branch = "rik" }

# Run
cargo run
```

## Resources

- [Makepad Repository](https://github.com/makepad/makepad)
- [Project Robius](https://github.com/project-robius)
- [Robrix](https://github.com/project-robius/robrix) - Reference app
