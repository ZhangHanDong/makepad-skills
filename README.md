# Claude Skills for Makepad

[English](./README.md) | [中文](./README.zh-CN.md) | [日本語](./README.ja.md)

[![Version](https://img.shields.io/badge/version-2.1.0-blue.svg)](./skills/.claude-plugin/plugin.json)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](./LICENSE)

Claude Code skills for building cross-platform UI applications with the [Makepad](https://github.com/makepad/makepad) framework in Rust.

## About Makepad

[Makepad](https://github.com/makepad/makepad) is a next-generation UI framework written in Rust that enables building high-performance, cross-platform applications. Key features include:

- **Cross-Platform**: Single codebase for Desktop (macOS, Windows, Linux), Mobile (Android, iOS), and Web (WebAssembly)
- **GPU-Accelerated**: Custom shader-based rendering with SDF (Signed Distance Field) drawing
- **Live Design**: Hot-reloadable `live_design!` DSL for rapid UI development
- **High Performance**: Native compilation, no virtual DOM, minimal runtime overhead

## About Robius

[Project Robius](https://github.com/project-robius) is an open-source initiative to build a full-featured application development framework in Rust. Production applications built with Makepad include:

- **[Robrix](https://github.com/project-robius/robrix)** - A Matrix chat client showcasing real-time messaging, E2E encryption, and complex UI patterns
- **[Moly](https://github.com/moxin-org/moly)** - An AI model manager demonstrating data-heavy interfaces and async operations

These skills are extracted from patterns used in Robrix and Moly.

## Installation

### Quick Install (Recommended)

Use the install script for one-command setup:

```bash
# Install to current project
curl -fsSL https://raw.githubusercontent.com/project-robius/makepad-skills/main/install.sh | bash

# Install with hooks enabled
curl -fsSL https://raw.githubusercontent.com/project-robius/makepad-skills/main/install.sh | bash -s -- --with-hooks

# Install to specific project
curl -fsSL https://raw.githubusercontent.com/project-robius/makepad-skills/main/install.sh | bash -s -- --target /path/to/project
```

**Script features:**
- Auto-detects Rust/Makepad projects (checks for Cargo.toml)
- Backs up existing skills before installation
- `--with-hooks` copies and configures self-evolution hooks
- `--target` allows installing to any project directory
- Colored output with clear progress indicators

**Available options:**

| Option | Description |
|--------|-------------|
| `--target DIR` | Install to specific directory (default: current) |
| `--with-hooks` | Enable self-evolution hooks |
| `--branch NAME` | Use specific branch (default: main) |
| `--help` | Show help message |

### Manual Install

```bash
# Clone this repo
git clone https://github.com/project-robius/makepad-skills.git

# Copy to your project
cp -r makepad-skills/skills your-project/.claude/skills
```

Your project structure should look like:

```
your-project/
├── .claude/
│   └── skills/
│       ├── .claude-plugin/
│       │   └── plugin.json
│       ├── 00-getting-started/
│       ├── 01-core/
│       ├── 02-components/
│       ├── 03-graphics/
│       │   ├── _base/          # Official skills (atomic)
│       │   └── community/      # Community contributions
│       ├── 04-patterns/
│       │   ├── _base/          # Official patterns (atomic)
│       │   └── community/      # Community contributions
│       ├── 05-deployment/
│       ├── 06-reference/
│       ├── 99-evolution/
│       │   └── templates/      # Contribution templates
│       └── CONTRIBUTING.md
├── src/
└── Cargo.toml
```

See [Claude Code Skills documentation](https://docs.anthropic.com/en/docs/claude-code/skills) for more details.

## Architecture: Atomic Skills for Collaboration

### Why Atomic Structure?

v2.1 introduces an **atomic skill structure** designed for collaborative development:

```
04-patterns/
├── SKILL.md              # Index file
├── _base/                # Official patterns (numbered, atomic)
│   ├── 01-widget-extension.md
│   ├── 02-modal-overlay.md
│   ├── ...
│   └── 14-callout-tooltip.md
└── community/            # Your contributions
    ├── README.md
    └── {github-handle}-{pattern-name}.md
```

**Benefits:**
- **No merge conflicts**: Your `community/` files never conflict with official `_base/` updates
- **Parallel development**: Multiple users can contribute simultaneously
- **Clear attribution**: Your GitHub handle in filename provides credit
- **Progressive disclosure**: SKILL.md index → individual pattern details

### Self-Evolution: Enriching Skills from Your Development

The self-evolution feature allows you to capture patterns discovered during your development and add them to the skills.

#### How It Works

1. **During Development**: You discover a useful pattern, shader, or error solution while building with Makepad

2. **Capture the Pattern**: Ask Claude to save it:
   ```
   User: This tooltip positioning logic is useful. Save it as a community pattern.
   Claude: [Creates community/{handle}-tooltip-positioning.md using template]
   ```

3. **Auto-Detection** (with hooks enabled): When you encounter and fix errors, the system can automatically capture solutions to troubleshooting

#### Enable Self-Evolution Hooks (Optional)

```bash
# Copy hooks from 99-evolution to your project
cp -r your-project/.claude/skills/99-evolution/hooks your-project/.claude/skills/hooks

# Make hooks executable
chmod +x your-project/.claude/skills/hooks/*.sh

# Add hooks config to your .claude/settings.json
# See skills/99-evolution/hooks/settings.example.json for the configuration
```

#### Manual Pattern Creation

Ask Claude directly:
```
User: Create a community pattern for the drag-drop reordering I just implemented
Claude: I'll create a pattern using the template...
```

Claude will:
1. Use the template from `99-evolution/templates/pattern-template.md`
2. Create file at `04-patterns/community/{your-handle}-drag-drop-reorder.md`
3. Fill in the frontmatter and content

### Community Contribution Guide

#### Contributing Patterns

1. **Create your pattern file**:
   ```
   04-patterns/community/{github-handle}-{pattern-name}.md
   ```

2. **Use the template**: Copy from `99-evolution/templates/pattern-template.md`

3. **Required frontmatter**:
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

4. **Submit PR** to the main repository

#### Contributing Shaders/Effects

1. **Create your effect file**:
   ```
   03-graphics/community/{github-handle}-{effect-name}.md
   ```

2. **Use the template**: Copy from `99-evolution/templates/shader-template.md`

#### Contributing Error Solutions

1. **Create troubleshooting entry**:
   ```
   06-reference/troubleshooting/{error-name}.md
   ```

2. **Use the template**: Copy from `99-evolution/templates/troubleshooting-template.md`

#### Syncing with Upstream

Keep your local skills updated while preserving your contributions:

```bash
# If you've forked the repo
git fetch upstream
git merge upstream/main --no-edit
# Your community/ files won't conflict with _base/ changes
```

#### Promotion Path

High-quality community contributions may be promoted to `_base/`:
- Pattern is widely useful and well-tested
- Documentation is complete
- Community feedback is positive
- Credit preserved via `author` field

## Skills Overview (v2.1 Atomic Structure)

### [00-getting-started](./skills/00-getting-started/SKILL.md) - Project Setup

| File | Description | When to Use |
|------|-------------|-------------|
| [init.md](./skills/00-getting-started/init.md) | Project scaffolding | "Create a new Makepad app" |
| [project-structure.md](./skills/00-getting-started/project-structure.md) | Directory organization | "How should I organize my project?" |

### [01-core](./skills/01-core/SKILL.md) - Core Development

| File | Description | When to Use |
|------|-------------|-------------|
| [layout.md](./skills/01-core/layout.md) | Flow, sizing, spacing, alignment | "Arrange UI elements" |
| [widgets.md](./skills/01-core/widgets.md) | Common widgets, custom widgets | "How do I create a button?" |
| [events.md](./skills/01-core/events.md) | Event handling, hit testing | "Handle click events" |
| [styling.md](./skills/01-core/styling.md) | Fonts, text styles, SVG icons | "Change font size", "Add icons" |

### [02-components](./skills/02-components/SKILL.md) - Widget Gallery

All built-in widgets reference (from ui_zoo): Buttons, TextInput, Sliders, Checkboxes, Labels, Images, ScrollView, PortalList, PageFlip, and more.

### [03-graphics](./skills/03-graphics/SKILL.md) - Graphics & Animation (Atomic)

14 individual skills in `_base/`:

| Category | Skills |
|----------|--------|
| Shader Basics | `01-shader-structure`, `02-shader-math` |
| SDF Drawing | `03-sdf-shapes`, `04-sdf-drawing`, `05-progress-track` |
| Animation | `06-animator-basics`, `07-easing-functions`, `08-keyframe-animation`, `09-loading-spinner` |
| Visual Effects | `10-hover-effect`, `11-gradient-effects`, `12-shadow-glow`, `13-disabled-state`, `14-toggle-checkbox` |

Plus `community/` for your custom effects.

### [04-patterns](./skills/04-patterns/SKILL.md) - Production Patterns (Atomic)

14 individual patterns in `_base/`:

| Category | Patterns |
|----------|----------|
| Widget Patterns | `01-widget-extension`, `02-modal-overlay`, `03-collapsible`, `04-list-template`, `05-lru-view-cache`, `06-global-registry`, `07-radio-navigation` |
| Data Patterns | `08-async-loading`, `09-streaming-results`, `10-state-machine`, `11-theme-switching`, `12-local-persistence` |
| Advanced | `13-tokio-integration`, `14-callout-tooltip` |

Plus `community/` for your custom patterns.

### [05-deployment](./skills/05-deployment/SKILL.md) - Build & Package

Build for desktop (Linux, Windows, macOS), mobile (Android, iOS), and web (WebAssembly).

### [06-reference](./skills/06-reference/SKILL.md) - Reference Materials

| File | Description | When to Use |
|------|-------------|-------------|
| [troubleshooting.md](./skills/06-reference/troubleshooting.md) | Common errors and fixes | "Apply error: no matching field" |
| [code-quality.md](./skills/06-reference/code-quality.md) | Makepad-aware refactoring | "Simplify this code" |
| [adaptive-layout.md](./skills/06-reference/adaptive-layout.md) | Desktop/mobile responsive | "Support both desktop and mobile" |

### [99-evolution](./skills/99-evolution/SKILL.md) - Self-Improvement

| Component | Description |
|-----------|-------------|
| `templates/` | Pattern, shader, and troubleshooting templates |
| `hooks/` | Auto-detection and validation hooks |

## Usage Examples

### Create a New Project
```
User: Create a new Makepad app called "my-app" with a counter button
Claude: [Uses 00-getting-started for scaffolding, 01-core for button/counter]
```

### Add a Tooltip
```
User: Add a tooltip that shows user info on hover
Claude: [Uses 04-patterns/_base/14-callout-tooltip.md for complete implementation]
```

### Save a Custom Pattern
```
User: Save this infinite scroll implementation as a community pattern
Claude: [Creates 04-patterns/community/yourhandle-infinite-scroll.md]
```

### Fix Compilation Error
```
User: Getting "no matching field: font" error
Claude: [Uses 06-reference/troubleshooting.md to identify correct text_style syntax]
```

## What You Can Build

With these skills, Claude can help you:

- Initialize new Makepad projects with proper structure
- Create custom widgets with `live_design!` DSL
- Handle events and user interactions
- Write GPU shaders for visual effects
- Implement smooth animations
- Manage application state with async/tokio
- Build responsive desktop/mobile layouts
- Package apps for all platforms
- **Capture and share patterns** you discover during development

## Projects Built with These Skills

Real-world projects created using makepad-skills and Claude Code:

| Project | Description | Time |
|---------|-------------|------|
| [makepad-skills-demo](https://github.com/ZhangHanDong/makepad-skills-demo) | Currency converter app demo | ~20 min |
| [makepad-component](https://github.com/ZhangHanDong/makepad-component) | Reusable Makepad component library | - |

### makepad-skills-demo Screenshot

<p align="center">
  <img src="./assets/skill-app-demo.jpg" width="60%" alt="Currency Converter App" />
</p>

### makepad-component Screenshots

<p align="center">
  <img src="./assets/mc1.png" width="45%" alt="Component 1" />
  <img src="./assets/mc2.png" width="45%" alt="Component 2" />
</p>
<p align="center">
  <img src="./assets/mc3.png" width="45%" alt="Component 3" />
  <img src="./assets/mc4.png" width="45%" alt="Component 4" />
</p>

## Resources

- [Makepad Repository](https://github.com/makepad/makepad)
- [Makepad Examples](https://github.com/makepad/makepad/tree/main/examples)
- [Project Robius](https://github.com/project-robius)
- [Robrix](https://github.com/project-robius/robrix)
- [Moly](https://github.com/moxin-org/moly)

## License

MIT
