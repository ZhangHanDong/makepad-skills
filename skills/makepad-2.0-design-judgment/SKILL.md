---
name: makepad-2.0-design-judgment
description: |
  CRITICAL: Entry-level skill for Makepad 2.0 GUI development.
  This is the FIRST skill to load for any Makepad task — it provides design
  judgment anchors ABOVE the other 13 Makepad 2.0 skills.
  Triggers on: makepad, makepad app, makepad project, makepad design,
  live_design!, app_main!, script_mod!, Cx, WidgetRef, Widget,
  makepad-widgets, makepad architecture, makepad how to,
  "how should I", "should I use", "what's the best way",
  makepad 架构, makepad 设计, makepad 怎么做, makepad 最佳实践,
  组件拆分, 状态管理, 数据流, 渲染思维
---

# Makepad 2.0 Design Judgment Skill

> **Role:** Entry-level routing + design judgment anchors for Makepad 2.0 development.
> **Relationship to other skills:** This skill is the **liberation layer** (释放层).
> The other 13 Makepad 2.0 skills are the **compliance layer** (服从层) — they provide
> DSL syntax, API patterns, widget catalogs. Don't argue with them. Obey them.
> This skill provides **conceptual anchors** for design decisions that have no single
> correct answer.

## How This Skill Works

This skill operates as a **quality valve** (质量阀门), simultaneously performing two functions:

- **Constraint** (约束): Route to the correct compliance-layer skill for syntax/API questions
- **Liberation** (释放): Activate the right conceptual anchors for design judgment questions

**Key principle:** Conceptual anchors set **boundary conditions** for emergence.
They don't instruct the model what to output — they shape the space in which
good output emerges. Rules tell you "don't do X". Anchors tell you "think like Y".

---

## Step 1: Route to Compliance Layer

For any Makepad question, FIRST identify which compliance skill(s) to co-load:

| Question Domain | Co-load Skill |
|----------------|---------------|
| App setup, Cargo.toml, hot reload, `app_main!` | makepad-2.0-app-structure |
| DSL syntax, `script_mod!`, property system | makepad-2.0-dsl |
| Width, height, Flow, Fill, Fit, spacing | makepad-2.0-layout |
| Widget catalog, View, Button, Label, PortalList | makepad-2.0-widgets |
| Events, actions, `on_click`, `handle_event` | makepad-2.0-events |
| Animator, hover, pressed, state transitions | makepad-2.0-animation |
| `draw_bg`, Sdf2d, pixel fn, GPU shaders | makepad-2.0-shaders |
| Splash scripting, `script_mod!`, hot reload | makepad-2.0-splash |
| Theme colors, fonts, dark/light mode | makepad-2.0-theme |
| Vector graphics, SVG, gradients, tweens | makepad-2.0-vector |
| Performance, GC, draw batching, profiling | makepad-2.0-performance |
| Errors, bugs, widget not showing, FAQ | makepad-2.0-troubleshooting |
| Migrating from 1.x to 2.0 | makepad-2.0-migration |

**Always co-load at least one compliance skill.** This skill alone is not enough —
it provides judgment, not syntax.

---

## Step 2: Apply Design Judgment Anchors

When the question involves HOW to organize, structure, or design (not just WHAT syntax to use),
apply these conceptual anchors. Each anchor activates a region of subsidiary awareness
in the model — let the integration happen, don't force chain-of-thought on judgment tasks.

### Anchor 1: Data Flow — Elm Architecture (Evan Czaplicki)

- State is centralized. UI is a projection of state. Events trigger updates.
- Makepad's `MatchEvent::handle_actions` IS Elm's `update` function.
- **Decision heuristic:** If you find state scattered across multiple components
  that need to be aware of each other — STOP. Lift state to a common ancestor.
- **Popup corollary:** Menus, tooltips, and language pickers that must escape a local
  widget's bounds should be owned by a common ancestor or overlay owner, not buried
  as ordinary children inside the triggering widget.
- **External reality to obey:** Makepad's event system is the arbiter.
  `Cx::post_action` + `SignalToUI` is the canonical async→UI bridge.
  Don't invent alternatives.

### Anchor 2: Component Split — Dan Abramov (Presentational vs Container)

- **Presentational components:** Only receive live properties. No state. No side effects.
  In Makepad: widgets with `#[live]` fields and `#[deref] view: View` delegation.
- **Container components:** Own state, handle events, coordinate children.
  In Makepad: widgets with `#[rust]` fields that hold business state.
- **Decision heuristic:** If a widget both renders complex UI AND manages business logic,
  split it. The `#[deref]` delegation pattern exists precisely for this.

### Anchor 3: Rendering Mental Model — Casey Muratori (Handmade Hero)

- This is NOT a DOM. It's a GPU surface redrawn every frame.
- Don't think "modify a node." Think "what do I paint next frame."
- `redraw(cx)` doesn't "mark a node dirty" — it tells the GPU to repaint this region.
- **Decision heuristic:** If you're reaching for patterns from React/DOM mental models
  (virtual diff, reconciliation, component lifecycle), stop and reframe.
  The question is always: "what does the next frame look like?"

### Anchor 4: Layout — CSS Flexbox (but simpler and self-contained)

- `Flow.Down` = flex-direction: column. `Flow.Right` = flex-direction: row.
- `align`, `spacing`, `padding`, `margin` — semantics match CSS.
- **Critical difference:** Makepad has NO cascade, NO inheritance of styles.
  Each component's style is self-contained. This is a **strength**, not a limitation.
- **Decision heuristic:** If you're trying to build a "global style system" that
  cascades down — you're fighting the framework. Use themes (`mod.themes`) instead.

### Anchor 5: Shaders and Animation — Shadertoy community ("everything is math")

- `draw_bg` / `draw_text` are real GPU shaders, not CSS properties.
- `Sdf2d` is signed distance fields — describe shapes with math, not bitmaps.
- Animation = shader uniforms changing over time, not CSS transitions.
- **Decision heuristic:** "How do I make a rounded button?" → Answer is an SDF function,
  not `border-radius`. "How do I animate opacity?" → Answer is a uniform interpolating
  between 0.0 and 1.0 in the shader, not a CSS animation.

### Anchor 6: Cross-Platform — Flutter ("own every pixel")

- Makepad draws everything itself. No platform native controls.
- Benefit: pixel-perfect cross-platform consistency.
- Cost: accessibility is a known weakness.
- **Decision heuristic:** Don't try to mimic native control appearance.
  Embrace Makepad's own design language. If accessibility is a hard requirement,
  acknowledge this gap honestly rather than pretending it doesn't exist.

---

## Step 3: The Compliance-Liberation Workflow

```
1. READ the user's question
2. ROUTE to compliance skill(s) — confirm DSL syntax and API patterns
3. APPLY judgment anchors — for architecture and design decisions
4. WHEN WRITING CODE: obey compliance skills for syntax, use anchors for structure
5. WHEN ANCHORS CONFLICT WITH API: compliance wins — the API is external reality
```

**The compliance layer is what Polanyi calls "external reality" (外部实在).**
You serve it, not the user's preferences. If the user asks for something that
contradicts Makepad's actual API behavior, say so. Don't be sycophantic.

---

## Anti-Sycophancy Protocol

When answering Makepad design questions:

- **Don't write** "that's a great approach!" before pointing out problems.
- **Don't soften** "this won't work in Makepad" into "this might have some challenges."
- **Do anchor to external reality:** "Makepad's event system requires X, so your
  approach of Y won't work. Here's what works instead, verified against the API."
- **Do acknowledge gaps honestly:** "Makepad 2.0 doesn't have a built-in solution
  for this. Here are workarounds, with their trade-offs."

---

## Quality Check: Unpredictable Depth

After generating a response, self-check:

> "Could the user have predicted exactly this output from the question alone?"

- If **yes** → you over-constrained. You're being a find-and-replace tool.
  The anchors should have activated subsidiary awareness that produces
  design decisions the user didn't explicitly ask for.
- If **no, but the user can judge whether it's good** → correct balance.
  Emergence happened within well-shaped boundary conditions.

---

## Reference: Skill Ecosystem

This skill sits at the top of a 14-skill stack:

```
┌─────────────────────────────────────────┐
│  makepad-2.0-design-judgment (this)     │  ← Liberation layer: WHY & HOW to design
├─────────────────────────────────────────┤
│  makepad-2.0-app-structure              │
│  makepad-2.0-dsl                        │
│  makepad-2.0-layout                     │
│  makepad-2.0-widgets                    │
│  makepad-2.0-events                     │  ← Compliance layer: WHAT syntax to use
│  makepad-2.0-animation                  │
│  makepad-2.0-shaders                    │
│  makepad-2.0-splash                     │
│  makepad-2.0-theme                      │
│  makepad-2.0-vector                     │
│  makepad-2.0-performance                │
│  makepad-2.0-troubleshooting            │
│  makepad-2.0-migration                  │
└─────────────────────────────────────────┘
```

When in doubt: **compliance skills answer "what does the API do?"
This skill answers "what should I build with it?"**
