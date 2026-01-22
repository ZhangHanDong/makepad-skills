# Makepad Skills

Comprehensive skills for building cross-platform UI applications with [Makepad](https://github.com/makepad/makepad), [Robius](https://github.com/project-robius), and [MolyKit](https://github.com/moxin-org/moly).

## Overview

This skill collection covers:

- **Makepad Framework**: Cross-platform UI framework with live design DSL
- **Robius**: App architecture patterns from real-world Makepad apps (Robrix, Moly)
- **MolyKit**: AI chat interface toolkit built on Makepad

## Skills

### Makepad Core (10 skills)

| Skill | Description |
|-------|-------------|
| `makepad-basics` | Getting started, app structure, `live_design!`, `app_main!` |
| `makepad-dsl` | DSL syntax, inheritance, prototypes, properties |
| `makepad-layout` | Layout system, Flow, Walk, Size, Padding, Alignment |
| `makepad-widgets` | Built-in widgets (View, Button, Label, TextInput, etc.) |
| `makepad-event-action` | Event handling, Actions, Hit testing |
| `makepad-animation` | Animator, state transitions, hover/pressed effects |
| `makepad-shaders` | Shader system, draw_bg, Sdf2d, GPU rendering |
| `makepad-platform` | Cross-platform support (macOS, Windows, Linux, iOS, Android, Web) |
| `makepad-font` | Font rendering, text layout, typography |
| `makepad-splash` | Splash scripting language for dynamic UI |

### Robius Patterns (5 skills)

| Skill | Description |
|-------|-------------|
| `robius-app-architecture` | App structure, sync/async patterns, Tokio integration |
| `robius-widget-patterns` | Widget design, reusable components, apply_over |
| `robius-event-action` | Custom actions, centralized handling, MatchEvent |
| `robius-state-management` | AppState, Scope propagation, persistence |
| `robius-matrix-integration` | Matrix SDK integration patterns |

### MolyKit (1 skill)

| Skill | Description |
|-------|-------------|
| `molykit` | AI chat interfaces, BotClient, SSE streaming, cross-platform async |

## Installation

### Option 1: Add as Working Directory

```bash
# In Claude Code settings or .claude/settings.json
{
  "additionalWorkingDirectories": [
    "/path/to/makepad-skills"
  ]
}
```

### Option 2: Symlink to Skills Directory

```bash
# Symlink skills to ~/.claude/skills/
for skill in skills/*; do
    ln -sf "$(pwd)/$skill" ~/.claude/skills/
done
```

### Option 3: Copy Skills

```bash
cp -r skills/* ~/.claude/skills/
```

## Usage

Skills are automatically triggered by keywords:

```
User: "How do I create a Makepad app?"
-> makepad-basics loaded

User: "How do I handle button clicks in Makepad?"
-> makepad-event-action loaded

User: "How does Robrix handle Matrix room subscriptions?"
-> robius-matrix-integration loaded

User: "How do I implement SSE streaming in a Makepad AI chat?"
-> molykit loaded
```

## Trigger Keywords

### Makepad
- `makepad`, `live_design!`, `app_main!`, `Widget`, `View`, `Button`
- `draw_bg`, `Sdf2d`, `shader`, `animator`, `Flow`, `Walk`
- DSL syntax: `<Widget>`, `Foo = { }`, prototype, inheritance

### Robius
- `robius`, `robrix`, `AppState`, `Scope::with_data`
- `MatrixRequest`, `TimelineUpdate`, `submit_async_request`
- `MatchEvent`, `handle_actions`, `cx.widget_action`

### MolyKit
- `molykit`, `moly-kit`, `BotClient`, `BotContext`
- `PlatformSend`, `BoxPlatformSendFuture`, `ThreadToken`
- SSE streaming, AI chat, OpenAI Makepad

## Directory Structure

```
makepad-skills/
├── README.md
├── CLAUDE.md           # Claude instructions
├── metadata.json       # Skill metadata
├── skills/
│   ├── makepad-basics/
│   │   ├── SKILL.md
│   │   └── llms.txt
│   ├── makepad-dsl/
│   ├── makepad-layout/
│   ├── makepad-widgets/
│   ├── makepad-event-action/
│   ├── makepad-animation/
│   ├── makepad-shaders/
│   ├── makepad-platform/
│   ├── makepad-font/
│   ├── makepad-splash/
│   ├── robius-app-architecture/
│   ├── robius-widget-patterns/
│   ├── robius-event-action/
│   ├── robius-state-management/
│   ├── robius-matrix-integration/
│   └── molykit/
├── docs/               # Additional documentation
└── references/         # Reference materials
```

## Source Projects

These skills were extracted from:

- **Makepad**: https://github.com/makepad/makepad
- **Robrix**: https://github.com/project-robius/robrix (Matrix client)
- **Moly**: https://github.com/moxin-org/moly (AI chat app)
- **MolyKit**: https://github.com/moxin-org/moly/moly-kit

## License

MIT
