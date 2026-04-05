# Makepad 2.0 Skills

Skills for building cross-platform UI applications with [Makepad 2.0](https://github.com/makepad/makepad).

## Skills (14)

| Skill | Description |
|-------|-------------|
| `makepad-2.0-design-judgment` | **Entry point.** Design judgment anchors (Elm Architecture, Presentational/Container, GPU rendering mental model). Load this first, then co-load specific skills below. |
| `makepad-2.0-app-structure` | App structure, `app_main!`, ScriptVm, Cargo setup, hot reload |
| `makepad-2.0-dsl` | DSL syntax, `script_mod!`, colon syntax, `mod.widgets`, let bindings |
| `makepad-2.0-layout` | Layout system, Flow, Fill, Fit, Inset, spacing, alignment |
| `makepad-2.0-widgets` | Widget catalog (View, Button, Label, TextInput, PortalList, Dock, etc.) |
| `makepad-2.0-events` | Event/action handling, `on_click`, `on_render`, Hit, `ids!` |
| `makepad-2.0-animation` | Animator, states, Forward/Snap/Loop, ease functions |
| `makepad-2.0-shaders` | Shader system, `draw_bg`, Sdf2d, pixel/vertex fn, DrawQuad |
| `makepad-2.0-splash` | Splash scripting language, streaming evaluation, hot reload |
| `makepad-2.0-theme` | Theme system, `mod.themes`, colors, fonts, dark/light mode |
| `makepad-2.0-vector` | Vector graphics, SVG paths, gradients, tweens, DropShadow |
| `makepad-2.0-performance` | Performance optimization, GC, draw batching, ViewOptimize |
| `makepad-2.0-troubleshooting` | Common mistakes, FAQ, debugging tips |
| `makepad-2.0-migration` | Migration guide from Makepad 1.x to 2.0 |

## Installation

### Option 1: Add as Working Directory

```json
// .claude/settings.json
{
  "additionalWorkingDirectories": [
    "/path/to/makepad-skills"
  ]
}
```

### Option 2: Symlink to Skills Directory

```bash
for skill in skills/*; do
    ln -sf "$(pwd)/$skill" ~/.claude/skills/
done
```

### Option 3: Copy Skills

```bash
cp -r skills/* ~/.claude/skills/
```

## Legacy

Makepad 1.x skills (including Robius and MolyKit patterns) are archived on the [`v1/makepad-1.0`](../../tree/v1/makepad-1.0) branch.

## Source

- **Makepad**: https://github.com/makepad/makepad

## License

MIT
