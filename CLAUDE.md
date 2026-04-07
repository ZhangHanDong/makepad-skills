# Makepad 2.0 Skills - Claude Instructions

## Design Judgment Anchors (Liberation Layer)

These concept anchors provide design judgment for Makepad 2.0 architecture questions. Use them when facing "how should I organize state / split components / handle complex interactions" — questions without a single correct answer. The specific DSL, API, and widget patterns come from the compliance-layer skills below; this section is the liberation layer.

### Data Flow
Reference **Elm Architecture** (Evan Czaplicki):

- State is centralized, UI is a projection of state, events trigger updates
- Makepad's event handlers are Elm's `update` function
- If you find state scattered across components that need to observe each other — stop, lift the state to a common ancestor

### Component Decomposition
Reference **Dan Abramov**'s presentational vs container distinction:

- Presentational components: receive props, hold no state, no side effects
- Container components: hold state, handle events, coordinate children
- Use Makepad's delegation patterns to separate Widget rendering from business logic

### Rendering Mindset
Reference **Casey Muratori** (Handmade Hero):

- This is not a DOM, it's a GPU-rendered frame every tick
- Don't think "mutate the node", think "what does the next frame look like"
- `redraw(cx)` is not "mark node dirty" — it's "tell the GPU to repaint this region next frame"

### Layout
Reference **CSS Flexbox** as a mental model (but simpler):

- `Flow.Down` = flex-direction: column
- `Flow.Right` = flex-direction: row
- `align`, `spacing`, `padding`, `margin` — same semantics as CSS
- Difference: Makepad has no CSS cascade or inheritance. Each component's style is self-contained — **this is a feature, not a bug**

### Animation and Shaders
Reference the **Shadertoy** community's "everything is math" mindset:

- Makepad shader fields contain real GPU shader code, not CSS-equivalents
- `Sdf2d` is a signed distance field — describe shapes with math, not bitmaps
- Animation is a shader uniform changing over time, not a CSS transition
- When you want a rounded button, the answer is an SDF function, not `border-radius`

### Cross-Platform Philosophy
Reference **Flutter**'s "own every pixel" philosophy:

- Makepad draws everything itself, does not use native platform controls
- Benefit: pixel-perfect cross-platform consistency
- Cost: accessibility support is a known weakness
- Don't try to mimic native control appearance — embrace Makepad's own design language

### When Anchors Conflict with Compliance-Layer Skills

If a design judgment from these anchors contradicts the actual Makepad 2.0 API documented in a compliance-layer skill, **the compliance-layer skill wins**. Those skills are the external reality. Anchors help you navigate within that reality, not override it.

---

## Entry Point

**For ALL Makepad questions, FIRST load `makepad-2.0-design-judgment`.**
This is the liberation layer — it provides design judgment anchors and routes
to the correct compliance-layer skill. Then co-load the specific skill below.

## Skill Routing

For Makepad 2.0 questions, route based on keywords:

| Keywords | Skill |
|----------|-------|
| architecture, design, "how should I", component split, state management | makepad-2.0-design-judgment |
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
makepad-widgets = { git = "https://github.com/makepad/makepad", branch = "dev" }

[features]
default = []
nightly = ["makepad-widgets/nightly"]
```

## Legacy

Makepad 1.x skills (including Robius and MolyKit patterns) are archived on the `v1/makepad-1.0` branch.

## Source
- **Makepad**: https://github.com/makepad/makepad
