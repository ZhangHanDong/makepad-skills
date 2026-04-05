# Makepad 2.0 Design Philosophy Reference

## Theoretical Foundation

This skill is built on the **quality valve** model from Polanyi's *The Tacit Dimension*,
applied to AI-assisted GUI development.

### The Three Layers

```
释放层 (Liberation)  — Conceptual anchors that activate judgment
                       "Think like Elm Architecture for data flow"
                       "Think like Casey Muratori for rendering"

服从层 (Compliance)   — External reality that must be obeyed
                       Makepad API, DSL syntax, widget behavior
                       The other 13 skills provide this

约束层 (Constraint)   — Zero-ambiguity configuration
                       cargo clippy, cargo fmt, edition = "2024"
                       Linters handle this, not prompts
```

### Why Conceptual Anchors, Not Rule Lists

**Rule list approach (bad for design):**
```
- Keep widgets under 200 lines
- Don't nest Views more than 3 levels deep
- Always use #[deref] for composition
- Separate state from rendering
```

Each rule is mechanically correct but isolated. They don't produce coherent architecture.

**Conceptual anchor approach (good for design):**
```
Data flow follows Elm Architecture (Evan Czaplicki).
Component structure follows Dan Abramov's Presentational vs Container distinction.
Rendering is Casey Muratori's immediate-mode GPU thinking.
```

Three names activate entire regions of training knowledge. The model integrates
them into a coherent design that no individual rule list could specify.

### Key Insight: Rules Set Floor, Anchors Set Ceiling

- Rules prevent obviously bad output (the floor)
- Anchors enable surprisingly good output (the ceiling)
- When rules try to do both jobs, the floor itself collapses —
  because "correct by rules" ≠ "correct by engineering"

### Anti-Sycophancy: Obey External Reality

The strongest structural tool against sycophancy: anchor to external reality.

- **Don't write:** "Please evaluate objectively" (self-defeating instruction)
- **Do write:** "Evaluate against Makepad's actual API behavior as documented in skill X"

When both the user and the AI serve the same external reality (the Makepad API),
sycophancy has nowhere to hide — because "serve the user" and "serve the API"
are clearly separated, and you explicitly require the latter.

## Makepad-Specific Design Patterns

### Pattern: Centralized State with Event Projection

```
Elm Architecture → Makepad mapping:

  Model       →  App struct with #[rust] fields
  View        →  script_mod! DSL template
  Update      →  handle_actions() match on widget actions
  Msg/Cmd     →  Cx::post_action() + SignalToUI
```

When to apply: Any app with more than one screen or shared state across components.

### Pattern: Presentational / Container Split

```
Presentational Widget:
  - #[live] fields only (configured from DSL)
  - #[deref] view: View (delegates rendering)
  - No #[rust] business state
  - Emits generic actions (clicked, changed)

Container Widget:
  - #[rust] fields for business state
  - Handles actions from presentational children
  - Calls redraw(cx) when state changes
  - May use Cx::post_action for cross-component communication
```

When to apply: Any widget that's doing both "look pretty" and "manage data."

### Pattern: GPU-First Rendering

```
Wrong mental model (DOM):
  "I need to update this label's text"
  → find node → modify property → trigger re-render

Correct mental model (GPU):
  "Next frame, this region should show different text"
  → set_text() → redraw(cx) → GPU paints new frame
```

When to apply: Always. This is not optional — it's how Makepad works.

### Pattern: Self-Contained Styles via Themes

```
Wrong (trying to cascade):
  "Set a global font that all labels inherit"

Correct (using themes):
  mod.themes defines theme variables
  Each widget references theme.font_xxx, theme.color_xxx
  No cascade — explicit reference to shared tokens
```

When to apply: Any project that needs consistent visual design across components.
