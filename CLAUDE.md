# Makepad 2.0 Skills - Claude Instructions

## Skill Routing

For Makepad 2.0 questions, route based on keywords:

| Keywords | Skill |
|----------|-------|
| getting started, app structure, `app_main!`, `ScriptVm`, Cargo setup | makepad-2.0-app-structure |
| DSL syntax, `script_mod!`, property, colon syntax, `mod.widgets` | makepad-2.0-dsl |
| layout, width, height, Flow, Fill, Fit, Inset, spacing, align | makepad-2.0-layout |
| View, Button, Label, TextInput, PortalList, Dock, Modal, widget | makepad-2.0-widgets |
| event, action, `handle_event`, `on_click`, `on_render`, Hit, ids! | makepad-2.0-events |
| animation, animator, state, transition, Forward, Snap, Loop | makepad-2.0-animation |
| shader, `draw_bg`, Sdf2d, GPU, pixel fn, vertex fn, DrawQuad | makepad-2.0-shaders |
| splash, script, `script_mod!`, hot reload, streaming evaluation | makepad-2.0-splash |
| theme, color, font, dark mode, light mode, `mod.themes` | makepad-2.0-theme |
| vector, SVG, path, gradient, tween, DropShadow, Group transform | makepad-2.0-vector |
| performance, debug, profiling, GC, `new_batch`, ViewOptimize | makepad-2.0-performance |
| troubleshooting, error, bug, widget not showing, text invisible | makepad-2.0-troubleshooting |
| migration, 1.x to 2.0, `live_design` to `script_mod`, upgrade | makepad-2.0-migration |

## Usage Examples

### App Structure
```
User: "How do I create a Makepad 2.0 app?"
-> Load: makepad-2.0-app-structure
-> Answer with app_main!, ScriptVm, from_script_mod, MatchEvent
```

### DSL / Splash
```
User: "How does the new Makepad DSL work?"
-> Load: makepad-2.0-dsl
-> Answer with script_mod!, colon syntax, mod.widgets, let bindings
```

### Layout
```
User: "How do I center a widget in Makepad 2.0?"
-> Load: makepad-2.0-layout
-> Answer with Flow.Down, align, Fill, Fit
```

### Migration
```
User: "How do I migrate from Makepad 1.x to 2.0?"
-> Load: makepad-2.0-migration
-> Answer with live_design→script_mod, LiveHook→ScriptHook changes
```

## Default Project Settings

When creating Makepad 2.0 projects:

```toml
[package]
edition = "2024"

[dependencies]
makepad-widgets = "0.7"

[features]
default = []
nightly = ["makepad-widgets/nightly"]
```

## Legacy

Makepad 1.x skills (including Robius and MolyKit patterns) are archived on the `v1/makepad-1.0` branch.

## Source

- **Makepad**: https://github.com/makepad/makepad
