---
name: makepad-2.0-troubleshooting
description: |
  CRITICAL: Use for Makepad 2.0 troubleshooting and common mistakes. Triggers on:
  makepad error, makepad bug, makepad problem, makepad issue, makepad not working,
  text invisible, widget not showing, click not working, height zero,
  makepad pitfall, makepad gotcha, makepad FAQ, makepad help,
  script_mod error, compile error, widget not found, render not updating,
  hot reload not working, wasm build error, port conflict, server lock,
  IME popup, selection handle, popup window crash,
  canvas splash, POST splash loop, 100% CPU, set_visible not working,
  on_render empty, event bridge unreliable, float time display,
  fn tick not called, on_audio not called, button click through,
  常见错误, 问题排查, 故障排除, 不显示, 不工作, 看不见, 热重载, 编译错误
---

# Makepad 2.0 Common Pitfalls & Troubleshooting Guide

This skill covers common mistakes when building with Makepad 2.0 and the Splash scripting language. Each pitfall includes:
- What the user sees (symptom)
- Why it happens (root cause)
- How to fix it (correct code)

Reference documents: `AGENTS.md`, `splash.md`

---

## Pitfall #1: Container height is 0px -- UI is invisible

**Symptom:** Your entire UI or a section of it does not appear. The container renders with zero height, making all children invisible.

**Root Cause:** All View-based containers (`View`, `SolidView`, `RoundedView`, etc.) default to `height: Fill`. When a `Fill` container is placed inside a `Fit` parent (or any context where the available height is determined by children), the height resolves to 0px due to circular dependency: the parent asks the child how tall it is, the child says "as tall as my parent", and the result is zero.

**Fix:** Always set `height: Fit` on containers that should shrink-wrap their content.

```
// WRONG -- height defaults to Fill, resolves to 0px in a Fit context
View{
    flow: Down
    Label{text: "Hello"}
}

// CORRECT -- height: Fit makes the container wrap its children
View{
    height: Fit
    flow: Down
    Label{text: "Hello"}
}
```

**Rule of thumb:** Write `height: Fit` immediately after the opening brace of every container unless you have a fixed-height parent or you explicitly want `height: Fill` inside a known fixed-size ancestor.

**Exception:** Inside a fixed-height parent, `height: Fill` is valid:
```
View{
    height: 300
    View{
        height: Fill
        Label{text: "I fill the 300px"}
    }
}
```

---

## Pitfall #2: Text invisible on colored background -- missing new_batch

**Symptom:** You add a `Label` inside a `RoundedView` or `SolidView` with a background color, but the text is invisible. The container appears correctly colored but the text cannot be seen, even though `draw_text.color` is set to a contrasting color.

**Root Cause:** Makepad batches draw calls by shader type for GPU performance. All `Label` widgets using the same text shader get batched into one draw call, and all backgrounds into another. Without `new_batch: true`, the text draw call may execute *before* the background draw call, placing the text geometrically behind the opaque background.

**Fix:** Add `new_batch: true` to any View-based container that has a visible background (`show_bg: true` or pre-styled views like `SolidView`, `RoundedView`) and contains text children.

```
// WRONG -- text is drawn behind the background due to batching
RoundedView{
    height: Fit
    draw_bg.color: #333
    Label{text: "Can't see me"}
}

// CORRECT -- new_batch forces background to draw before children's text
RoundedView{
    height: Fit
    new_batch: true
    draw_bg.color: #333
    Label{text: "Now visible" draw_text.color: #fff}
}
```

**When you MUST use `new_batch: true`:**
- Any container with `show_bg: true` (or pre-styled like `SolidView`, `RoundedView`) that contains text
- Hoverable items with background animator -- text disappears on hover without it
- Parent containers of repeated items that each have their own background

---

## Pitfall #3: Named child override does not work -- used `:` instead of `:=`

**Symptom:** You define a template with `let` and try to override a child property per-instance, but the override is silently ignored. The default text always shows.

**Root Cause:** In Splash, `:` creates a **static** property, while `:=` creates a **named/dynamic** child that is addressable and overridable. If you declare `label: Label{...}` (with `:`), the child has no addressable name and the override path `label.text:` cannot find it.

**Fix:** Use `:=` for any child you want to reference or override later.

```
// WRONG -- static child, override fails silently
let Card = View{
    height: Fit
    title: Label{text: "default"}
}
Card{title.text: "new text"}  // Fails! title is not addressable

// CORRECT -- named child with :=, override works
let Card = View{
    height: Fit
    title := Label{text: "default"}
}
Card{title.text: "new text"}  // Works! title is a named child
```

**Additional rule:** Named children inside anonymous containers are UNREACHABLE. Every container in the path from root to child must also be named:

```
// WRONG -- label is inside an anonymous View, unreachable
let Item = View{
    height: Fit
    View{
        flow: Down
        label := Label{text: "default"}
    }
}
Item{label.text: "new"}  // Fails! No path to label through anonymous View

// CORRECT -- full named path
let Item = View{
    height: Fit
    texts := View{
        flow: Down
        label := Label{text: "default"}
    }
}
Item{texts.label.text: "new"}  // Works! Full dot-path through named containers
```

---

## Pitfall #4: Hex color with letter 'e' renders wrong or causes parse error

**Symptom:** A hex color like `#2ecc71` causes a cryptic parse error such as `expected at least one digit in exponent`, or the color renders incorrectly.

**Root Cause:** The Rust tokenizer inside `script_mod!{}` interprets a digit followed by `e` as the start of a scientific notation number (e.g., `2e` looks like `2 * 10^...`). This breaks parsing of hex colors that contain the letter `e` adjacent to digits.

**Fix:** Use the `#x` prefix for any hex color containing the letter `e` or `E`.

```
// WRONG -- parser reads '2e' as scientific notation exponent
draw_bg.color: #2ecc71
draw_bg.color: #1e1e2e
draw_bg.color: #4466ee

// CORRECT -- #x prefix escapes the hex literal
draw_bg.color: #x2ecc71
draw_bg.color: #x1e1e2e
draw_bg.color: #x4466ee
```

**When is `#x` NOT needed?** Colors without the letter `e` work fine with plain `#`:
```
draw_bg.color: #ff4444    // OK -- no 'e'
draw_bg.color: #44cc44    // OK -- no 'e'
draw_bg.color: #333       // OK -- no 'e'
```

---

## Pitfall #5: border_radius takes wrong type -- must be float, not Inset

**Symptom:** Attempting to set per-corner border radii with `Inset` causes a parse error or silently breaks the layout. The rounded corners do not appear.

**Root Cause:** Border radius is a single `f32` uniform value applied uniformly to all corners. It is NOT an Inset-like struct with per-corner values. Passing an `Inset` or object silently breaks the entire layout.

**CRITICAL:** The property name differs by context:
- **In Canvas Splash (POST /splash):** Use `draw_bg.radius` with trailing-dot float
- **In script_mod! macro:** Use `draw_bg.border_radius`

**Fix:** Use a plain float value with the correct property name.

```
// WRONG -- border_radius is not an Inset
draw_bg.border_radius: Inset{top_left: 10 top_right: 10}

// WRONG -- not an object
draw_bg.border_radius: {top: 10 bottom: 0}

// CORRECT (Canvas Splash context) -- use draw_bg.radius with trailing dot
draw_bg.radius: 10.

// CORRECT (script_mod! context) -- use draw_bg.border_radius
draw_bg.border_radius: 10.0

// For per-corner radii, use RoundedAllView with a vec4
// (top-left, top-right, right-bottom, left-bottom)
RoundedAllView{
    height: Fit
    draw_bg.border_radius: vec4(10.0 10.0 0.0 0.0)
}
```

---

## Pitfall #6: Widget not found from Rust -- registration order wrong

**Symptom:** At runtime, a widget type is not found or a script error occurs saying a widget is not registered. The app may panic or display nothing.

**Root Cause:** In Makepad 2.0, widget modules must be registered via `script_mod(vm)` calls in the correct order. Base widgets must be registered before custom widgets, and custom widgets before the UI that uses them. If the order is wrong, a module tries to use a widget type that has not been registered yet.

**Fix:** Follow the correct registration order in `App::run()`.

```rust
impl App {
    fn run(vm: &mut ScriptVm) -> Self {
        // 1. Register base widget library (theme + all standard widgets)
        crate::makepad_widgets::script_mod(vm);

        // 2. Register your custom widget modules (if any)
        crate::my_custom_widgets::script_mod(vm);

        // 3. Register your app UI module (uses widgets from steps 1 and 2)
        crate::app_ui::script_mod(vm);

        // 4. Create the app from its own script_mod
        App::from_script_mod(vm, self::script_mod)
    }
}
```

**Key rule:** Widget modules must be registered BEFORE UI modules that use them. Always call `lib.rs::script_mod` before `app_ui::script_mod`.

---

## Pitfall #7: Filler clips text -- used alongside width: Fill sibling

**Symptom:** Text in a horizontal layout is cut off halfway. The text label appears to have only half the available width.

**Root Cause:** `Filler{}` is defined as `View{width: Fill height: Fill}`. When placed next to a sibling that also has `width: Fill`, both compete for the remaining horizontal space and split it 50/50. The text label only gets half the width and text is clipped.

**Fix:** Remove `Filler{}` when a sibling already uses `width: Fill`. The `Fill` sibling naturally takes all remaining space, pushing `Fit`-sized siblings to the edge.

```
// WRONG -- Filler splits space with Fill sibling, text is clipped
View{
    flow: Right height: Fit
    Label{width: Fill text: "Long text that gets clipped"}
    Filler{}
    Button{text: "OK"}
}

// CORRECT -- width: Fill on label pushes button to the right edge
View{
    flow: Right height: Fit
    Label{width: Fill text: "Long text now has full space"}
    Button{text: "OK"}
}

// CORRECT use of Filler -- between Fit-sized siblings
View{
    flow: Right height: Fit
    Label{text: "left"}
    Filler{}
    Label{text: "right"}
}
```

---

## Pitfall #8: Text disappears on hover -- animated View without new_batch

**Symptom:** A list item or button has hover effects. When you hover over it, the background color changes but the text vanishes completely. Moving the cursor away brings the text back.

**Root Cause:** The hover animator changes the View's background from transparent (`#0000`) to an opaque or semi-opaque color. Without `new_batch: true`, the background and text are in the same draw batch. When the background becomes opaque, it covers the text that was drawn in the same batch order.

**Fix:** Add `new_batch: true` to any View with `show_bg: true` that has a hover animator and contains text.

```
// WRONG -- text disappears when hover activates the background
View{
    width: Fill height: Fit
    show_bg: true
    draw_bg +: {
        color: uniform(#0000)
        color_hover: uniform(#fff2)
        hover: instance(0.0)
        pixel: fn(){
            return Pal.premul(self.color.mix(self.color_hover, self.hover))
        }
    }
    animator: Animator{
        hover: {
            default: @off
            off: AnimatorState{
                from: {all: Forward {duration: 0.15}}
                apply: {draw_bg: {hover: 0.0}}
            }
            on: AnimatorState{
                from: {all: Forward {duration: 0.15}}
                apply: {draw_bg: {hover: 1.0}}
            }
        }
    }
    Label{text: "Vanishes on hover!" draw_text.color: #fff}
}

// CORRECT -- add new_batch: true
View{
    width: Fill height: Fit
    new_batch: true
    show_bg: true
    draw_bg +: {
        color: uniform(#0000)
        color_hover: uniform(#fff2)
        hover: instance(0.0)
        pixel: fn(){
            return Pal.premul(self.color.mix(self.color_hover, self.hover))
        }
    }
    animator: Animator{
        hover: {
            default: @off
            off: AnimatorState{
                from: {all: Forward {duration: 0.15}}
                apply: {draw_bg: {hover: 0.0}}
            }
            on: AnimatorState{
                from: {all: Forward {duration: 0.15}}
                apply: {draw_bg: {hover: 1.0}}
            }
        }
    }
    Label{text: "Stays visible on hover!" draw_text.color: #fff}
}
```

---

## Pitfall #9: Commas in Splash -- tolerated but not required

**Symptom:** Confusion about whether commas are allowed between properties in `script_mod!` blocks.

**Root Cause:** Splash is primarily whitespace-delimited. However, the Splash tokenizer **treats commas as whitespace** — they are silently consumed and do not cause parse errors. Many Makepad projects (including Robrix) use commas extensively in `script_mod!` blocks, inherited from Makepad 1.x `live_design!` syntax which required commas.

**Guidance:** Both styles are valid. Match the surrounding code style:

```
// Style A: with commas (common in codebases migrated from 1.x)
View{
    flow: Down,
    height: Fit,
    spacing: 10,
    padding: Inset{top: 5, bottom: 5, left: 10, right: 10}
}

// Style B: without commas (pure Splash style)
View{
    flow: Down
    height: Fit
    spacing: 10
    padding: Inset{top: 5 bottom: 5 left: 10 right: 10}
}
```

**Note:** Both compile and run identically. The tokenizer discards commas. Do NOT waste time removing commas from existing code — it creates noisy diffs with no functional change.

---

## Pitfall #10: Using semicolons -- not valid in Splash

**Symptom:** Parse errors or unexpected behavior. The semicolons are treated as part of property values or cause tokenizer failures.

**Root Cause:** Splash does not use semicolons to terminate statements. This is a common mistake for developers coming from CSS, JavaScript, or Rust backgrounds.

**Fix:** Remove all semicolons.

```
// WRONG -- semicolons are not valid
View{
    flow: Down;
    height: Fit;
    Label{text: "Hello";};
}

// CORRECT -- no semicolons needed
View{
    flow: Down
    height: Fit
    Label{text: "Hello"}
}
```

---

## Pitfall #11: Root container without width: Fill -- narrow or broken layout

**Symptom:** The UI appears as a narrow sliver on one side of the window, or the layout is entirely broken. Content does not fill the available window width.

**Root Cause:** Using a fixed pixel width (e.g., `width: 400`) on the outermost container means it does not adapt to the available window space. If the window is wider, the content is a small strip. If narrower, content is clipped.

**Fix:** Always use `width: Fill` on the root container. Fixed pixel widths are fine for inner elements.

```
// WRONG -- fixed width on root, does not adapt to window
RoundedView{
    width: 400
    height: Fit
    flow: Down
    Label{text: "Narrow!"}
}

// CORRECT -- root fills available width
RoundedView{
    width: Fill
    height: Fit
    flow: Down
    Label{text: "Full width!"}
}
```

---

## Pitfall #12: Label does not support Animator -- silently ignored

**Symptom:** You add `animator: Animator{...}` and `cursor: MouseCursor.Hand` to a Label, but nothing happens on hover. No error, no effect.

**Root Cause:** `Label` (and `H1`-`H4`, `P`, `TextBox`, `Image`, `Icon`, `Markdown`, `Html`, `Slider`, `DropDown`, `Splitter`, `Hr`, `Filler`) do NOT have an `animator` field. Adding one is silently ignored.

**Fix:** Wrap the Label in a `View` that does support animator.

```
// WRONG -- animator on Label is silently ignored
Label{
    animator: Animator{
        hover: {
            default: @off
            off: AnimatorState{ from: {all: Forward{duration: 0.15}} apply: {draw_text: {hover: 0.0}} }
            on: AnimatorState{ from: {all: Forward{duration: 0.15}} apply: {draw_text: {hover: 1.0}} }
        }
    }
    text: "Hover me"
}

// CORRECT -- animate the wrapping View
View{
    width: Fill height: Fit
    new_batch: true
    cursor: MouseCursor.Hand
    show_bg: true
    draw_bg +: {
        color: uniform(#0000)
        color_hover: uniform(#fff2)
        hover: instance(0.0)
        pixel: fn(){ return Pal.premul(self.color.mix(self.color_hover, self.hover)) }
    }
    animator: Animator{
        hover: {
            default: @off
            off: AnimatorState{ from: {all: Forward{duration: 0.15}} apply: {draw_bg: {hover: 0.0}} }
            on: AnimatorState{ from: {all: Forward{duration: 0.15}} apply: {draw_bg: {hover: 1.0}} }
        }
    }
    Label{text: "Hover me" draw_text.color: #fff}
}
```

**Widgets that SUPPORT animator:** `View`, `SolidView`, `RoundedView`, `ScrollXView`, `ScrollYView`, `ScrollXYView`, `Button`, `ButtonFlat`, `ButtonFlatter`, `CheckBox`, `Toggle`, `RadioButton`, `LinkLabel`, `TextInput`

---

## Pitfall #13: Default text color is white -- invisible on light backgrounds

**Symptom:** Text is present in the widget tree but invisible. On white or light-colored backgrounds, the text simply cannot be seen. It may appear if you select the text or change the background to a dark color.

**Root Cause:** All text widgets (`Label`, `H1`-`H4`, `P`, `Button` text, etc.) default to white (`#fff`) text color. On a light background, white text is invisible.

**Fix:** Explicitly set `draw_text.color` to a dark color for every text element on light backgrounds.

```
// WRONG -- white text on white background
View{
    height: Fit
    show_bg: true
    draw_bg.color: #fff
    Label{text: "Can't see this"}
}

// CORRECT -- explicit dark text color
View{
    height: Fit
    new_batch: true
    show_bg: true
    draw_bg.color: #fff
    Label{text: "Visible!" draw_text.color: #333}
}
```

---

## Pitfall #14: Shader pixel function missing Pal.premul() -- colors render wrong

**Symptom:** Semi-transparent colors render as bright, fully opaque, or washed out. A subtle tint like `#ffffff08` appears as bright white instead of nearly transparent.

**Root Cause:** Makepad uses premultiplied alpha for GPU rendering. When you return a color from a `pixel: fn()` without premultiplying the alpha, the alpha blending produces incorrect results.

**Fix:** Always wrap your final color return in `Pal.premul()` -- unless returning `sdf.result`, which is already premultiplied by `sdf.fill()` / `sdf.stroke()`.

```
// WRONG -- alpha not premultiplied, renders incorrectly
draw_bg +: {
    pixel: fn() {
        return vec4(1.0 0.0 0.0 0.5)
    }
}

// CORRECT -- premultiply alpha
draw_bg +: {
    pixel: fn() {
        return Pal.premul(vec4(1.0 0.0 0.0 0.5))
    }
}

// ALSO CORRECT -- sdf.result is already premultiplied
draw_bg +: {
    pixel: fn() {
        let sdf = Sdf2d.viewport(self.pos * self.rect_size)
        sdf.box(0.0 0.0 self.rect_size.x self.rect_size.y 4.0)
        sdf.fill(#f00)
        return sdf.result
    }
}

// CORRECT -- color mixing with premultiply
draw_bg +: {
    pixel: fn() {
        return Pal.premul(self.color.mix(self.color_hover, self.hover))
    }
}
```

---

## Pitfall #15: Using CSS property names -- not valid in Splash

**Symptom:** Properties are not recognized, causing parse errors or the property being silently ignored.

**Root Cause:** Splash is not CSS. Property names use Makepad's own naming convention with dot-path access to nested struct fields.

**Fix:** Use Makepad property names.

| CSS Name | Splash Name |
|----------|-------------|
| `background-color` | `draw_bg.color` |
| `color` | `draw_text.color` |
| `font-size` | `draw_text.text_style.font_size` |
| `border-radius` | `draw_bg.border_radius` |
| `border-color` | `draw_bg.border_color` |
| `border-width` | `draw_bg.border_size` |
| `padding` | `padding` (same) |
| `margin` | `margin` (same) |
| `gap` | `spacing` |
| `display: flex` | `flow: Right` or `flow: Down` |
| `flex-direction: column` | `flow: Down` |
| `flex-direction: row` | `flow: Right` |
| `justify-content: center` | `align: Center` |
| `width: 100%` | `width: Fill` |
| `width: auto` | `width: Fit` |

```
// WRONG -- CSS property names
View{
    background-color: #333
    font-size: 14
    border-radius: 8px
    gap: 10
}

// CORRECT -- Splash property names
RoundedView{
    height: Fit
    draw_bg.color: #333
    draw_bg.border_radius: 8.0
    spacing: 10
    Label{text: "Hello" draw_text.text_style.font_size: 14}
}
```

---

## Pitfall #16: Inventing non-existent properties -- silent failures

**Symptom:** A property you wrote has no effect. No error is raised, but the widget does not behave as expected.

**Root Cause:** Splash silently ignores unknown properties. If you guess at a property name (e.g., `background:`, `font_size:`, `text_color:`, `border:`, `opacity:`), it is simply discarded.

**Fix:** Only use documented properties. If unsure, check `splash.md` or grep for usage in `widgets/src/`.

**Common invented properties and their correct equivalents:**

| Invented (WRONG) | Correct |
|-------------------|---------|
| `background:` | `draw_bg.color:` |
| `font_size:` | `draw_text.text_style.font_size:` |
| `text_color:` | `draw_text.color:` |
| `border:` | `draw_bg.border_size:` + `draw_bg.border_color:` |
| `opacity:` | Use alpha in color: `#fff8` |
| `on_click:` | Handle in Rust `handle_actions()` |
| `class:` | Use `let` bindings for reusable styles |
| `id:` | Use `:=` for named instances |

---

## Pitfall #17: Adding Root{} or Window{} in script output -- host-level wrappers

**Symptom:** When generating UI for streaming/splash context, the output does not display or causes errors. Duplicate Window wrappers may cause unexpected behavior.

**Root Cause:** `Root{}` and `Window{}` are host-level wrappers that are defined in the app's `script_mod!` block. Script content that renders inside a `body +: {}` block should NOT include these wrappers -- the content goes inside the body.

**Fix:** Your script output should start directly with the UI content, without `Root{}` or `Window{}` wrappers.

```
// WRONG -- do not add host-level wrappers in script output
Root{
    Window{
        body +: {
            View{ height: Fit Label{text: "Hello"} }
        }
    }
}

// CORRECT -- just the content
View{
    height: Fit
    Label{text: "Hello"}
}
```

**In app code** (where `Root` and `Window` ARE correct):
```rust
script_mod!{
    use mod.prelude.widgets.*
    load_all_resources() do #(App::script_component(vm)){
        ui: Root{
            main_window := Window{
                window.inner_size: vec2(800 600)
                body +: {
                    // UI content goes HERE
                    View{ height: Fit Label{text: "Hello"} }
                }
            }
        }
    }
}
```

---

## Pitfall #18: on_render not called -- must call render() explicitly

**Symptom:** You implement `on_render` on a widget but it is never called. The widget's render logic does not execute.

**Root Cause:** Makepad does not automatically call `on_render` in all situations. You must explicitly trigger rendering by calling `ui.widget.render()` or ensuring the widget is part of the active draw tree.

**Fix:** Ensure `render()` is called on the widget, typically from the parent's draw pass. Check that the widget is properly included in the widget hierarchy and that `handle_event` and `draw_walk` are correctly implemented.

```rust
// Make sure your widget is in the draw tree and draw_walk is implemented
impl Widget for MyWidget {
    fn draw_walk(&mut self, cx: &mut Cx2d, scope: &mut Scope, walk: Walk) -> DrawStep {
        cx.begin_turtle(walk, self.layout);
        // ... drawing code ...
        cx.end_turtle_with_area(&mut self.area);
        DrawStep::done()
    }

    fn handle_event(&mut self, cx: &mut Cx, event: &Event, scope: &mut Scope) {
        // ... event handling ...
    }
}
```

---

## Pitfall #19: MapView with height: Fill or Fit -- must use fixed pixel height

**Symptom:** A MapView renders with zero height or behaves erratically. The map area is invisible.

**Root Cause:** MapView has no intrinsic content height. Using `height: Fit` gives 0px (no content to fit). Using `height: Fill` may also resolve to 0px in certain contexts (same circular dependency as Pitfall #1).

**Fix:** Always give MapView a fixed pixel height.

```
// WRONG -- no intrinsic height, resolves to 0px
MapView{
    width: Fill
    height: Fit
}

// WRONG -- may resolve to 0px in a Fit parent
MapView{
    width: Fill
    height: Fill
}

// CORRECT -- fixed pixel height
MapView{
    width: Fill
    height: 500
}
```

---

## Pitfall #20: Modal not showing -- must call .open(cx) from Rust

**Symptom:** A Modal is defined in the script but never appears. There is no visible dialog or overlay.

**Root Cause:** Modals are hidden by default. They must be opened programmatically from Rust code by calling `.open(cx)` on the modal widget reference.

**Fix:** Call `.open(cx)` from your Rust event handler when you want to show the modal.

```
// In script_mod! -- define the modal
my_modal := Modal{
    content +: {
        width: 300 height: Fit
        RoundedView{
            height: Fit
            new_batch: true
            padding: 20 flow: Down spacing: 10
            draw_bg.color: #333
            draw_bg.border_radius: 8.0
            Label{text: "Are you sure?" draw_text.color: #fff}
            confirm_btn := Button{text: "Confirm"}
            cancel_btn := ButtonFlat{text: "Cancel"}
        }
    }
}
```

```rust
// In Rust -- open the modal when a button is clicked
impl MatchEvent for App {
    fn handle_actions(&mut self, cx: &mut Cx, actions: &Actions) {
        if self.ui.button(ids!(open_modal_btn)).clicked(actions) {
            self.ui.modal(ids!(my_modal)).open(cx);
        }
        if self.ui.button(ids!(cancel_btn)).clicked(actions) {
            self.ui.modal(ids!(my_modal)).close(cx);
        }
    }
}
```

---

## Pitfall #21: apply_over vs script_eval -- use script_apply_eval! in 2.0

**Symptom:** `apply_over(cx, live!{...})` does not compile or does not work. The old 1.x runtime property update mechanism is gone.

**Root Cause:** Makepad 2.0 replaced the `live!` macro and `apply_over` with the `script_apply_eval!` macro. The old macros from the `live_design!` system no longer exist.

**Fix:** Use `script_apply_eval!` for runtime property updates. Use `#(expr)` for Rust expression interpolation inside the macro.

```rust
// OLD 1.x way (WRONG in 2.0)
item.apply_over(cx, live!{
    height: (height)
    draw_bg: {is_even: (if is_even {1.0} else {0.0})}
});

// NEW 2.0 way (CORRECT)
script_apply_eval!(cx, item, {
    height: #(height)
    draw_bg: {is_even: #(if is_even {1.0} else {0.0})}
});

// For colors
let color = self.color_focus;
script_apply_eval!(cx, item, {
    draw_bg: {
        color: #(color)
    }
});
```

---

## Pitfall #22: Old derive macros -- Live -> Script, LiveHook -> ScriptHook

**Symptom:** Compilation errors about unknown derive macros `Live`, `LiveHook`, or unresolved traits.

**Root Cause:** Makepad 2.0 renamed the derive macros: `Live` became `Script`, `LiveHook` became `ScriptHook`. The old names no longer exist.

**Fix:** Update all derive macros to the new names.

```rust
// OLD 1.x (WRONG in 2.0)
#[derive(Live, LiveHook)]
pub struct App {
    #[live] ui: WidgetRef,
}

// NEW 2.0 (CORRECT)
#[derive(Script, ScriptHook)]
pub struct App {
    #[live] ui: WidgetRef,
}

// For widgets:
// OLD
#[derive(Live, LiveHook, Widget)]
// NEW
#[derive(Script, ScriptHook, Widget)]

// For animated widgets:
// OLD
#[derive(Live, LiveHook, Widget, Animator)]
// NEW
#[derive(Script, ScriptHook, Widget, Animator)]
```

**Also renamed:** `DefaultNone` derive is gone -- use standard `#[derive(Default)]` with `#[default]` attribute on the `None` variant:

```rust
// OLD (WRONG)
#[derive(DefaultNone)]
pub enum MyAction {
    Clicked,
    None,
}

// NEW (CORRECT)
#[derive(Clone, Default)]
pub enum MyAction {
    Clicked,
    #[default]
    None,
}
```

---

## Pitfall #23: THEME_COLOR vs theme.color -- old syntax replaced

**Symptom:** `(THEME_COLOR_X)` causes a parse error or is not recognized. Theme values are not applied.

**Root Cause:** Makepad 2.0 replaced the parenthesized constant syntax `(THEME_COLOR_X)` with dot-path access via `theme.color_x`. Similarly, `<THEME_FONT>` became `theme.font_regular`, and all theme access now uses the `theme.` prefix.

**Fix:** Replace all old theme references with `theme.` prefix syntax.

```
// OLD 1.x (WRONG in 2.0)
draw_bg.color: (THEME_COLOR_BG_APP)
draw_text.text_style: <THEME_FONT_REGULAR>
padding: (THEME_SPACE_2)

// NEW 2.0 (CORRECT)
draw_bg.color: theme.color_bg_app
draw_text.text_style: theme.font_regular
padding: theme.space_2
```

| Old Syntax | New Syntax |
|------------|------------|
| `(THEME_COLOR_X)` | `theme.color_x` |
| `<THEME_FONT_X>` | `theme.font_x` |
| `(THEME_SPACE_X)` | `theme.space_x` |
| `(THEME_FONT_SIZE_X)` | `theme.font_size_x` |

---

## Pitfall #24: Forgot to call self.match_event(cx, event) -- MatchEvent does not fire

**Symptom:** `handle_actions()` in your `MatchEvent` implementation is never called. Button clicks and other widget actions are not handled.

**Root Cause:** The `MatchEvent` trait's `handle_actions` method is called internally by `match_event()`. If you do not call `self.match_event(cx, event)` in your `AppMain::handle_event`, the trait dispatch never happens.

**Fix:** Always call `self.match_event(cx, event)` in `handle_event`.

```rust
// WRONG -- match_event not called, handle_actions never fires
impl AppMain for App {
    fn handle_event(&mut self, cx: &mut Cx, event: &Event) {
        self.ui.handle_event(cx, event, &mut Scope::empty());
    }
}

// CORRECT -- call match_event before or after ui.handle_event
impl AppMain for App {
    fn handle_event(&mut self, cx: &mut Cx, event: &Event) {
        self.match_event(cx, event);  // THIS IS REQUIRED
        self.ui.handle_event(cx, event, &mut Scope::empty());
    }
}

impl MatchEvent for App {
    fn handle_actions(&mut self, cx: &mut Cx, actions: &Actions) {
        // Now this actually gets called!
        if self.ui.button(ids!(my_button)).clicked(actions) {
            log!("Button clicked!");
        }
    }
}
```

---

## Pitfall #25: State not persisting between renders -- use proper state management

**Symptom:** Variables you set during one render pass are reset on the next frame. Counter values reset to zero, list state is lost, toggled states revert.

**Root Cause:** Local variables inside `draw_walk` or event handlers are re-initialized each call. Splash `let` bindings are template definitions, not mutable runtime state. For persistent state, you need to use `#[rust]` fields on your widget struct or manage state in the app struct.

**Fix:** Use `#[rust]` fields on your widget/app struct for persistent state.

```rust
// WRONG -- local variable resets every frame
impl Widget for Counter {
    fn draw_walk(&mut self, cx: &mut Cx2d, scope: &mut Scope, walk: Walk) -> DrawStep {
        let count = 0;  // Resets to 0 every frame!
        // ...
        DrawStep::done()
    }
}

// CORRECT -- persistent state in the struct
#[derive(Script, ScriptHook, Widget)]
pub struct Counter {
    #[source] source: ScriptObjectRef,
    #[walk] walk: Walk,
    #[layout] layout: Layout,
    #[rust] count: i32,  // Persists between frames
    #[deref] view: View,
}

impl MatchEvent for App {
    fn handle_actions(&mut self, cx: &mut Cx, actions: &Actions) {
        if self.ui.button(ids!(increment)).clicked(actions) {
            // State persists because it lives on the App struct
            self.count += 1;
            let label = self.ui.label(ids!(count_label));
            label.set_text(cx, &format!("{}", self.count));
        }
    }
}
```

---

## Quick Reference: Diagnostic Decision Tree

```
Problem: UI is invisible / blank screen
  |
  +-- Are containers missing height: Fit?              --> Pitfall #1
  +-- Is text on a colored background?                 --> Pitfall #2 (new_batch)
  +-- Is text white on white?                          --> Pitfall #13
  +-- Is root container using width: Fill?             --> Pitfall #11
  +-- Did you add Root{} or Window{} in script output? --> Pitfall #17

Problem: Text disappears
  |
  +-- On hover?                                        --> Pitfall #8 (new_batch)
  +-- On colored background?                           --> Pitfall #2 (new_batch)
  +-- On light background?                             --> Pitfall #13 (text color)

Problem: Override does not work
  |
  +-- Used : instead of :=?                            --> Pitfall #3
  +-- Named child inside anonymous container?          --> Pitfall #3 (path issue)

Problem: Parse error
  |
  +-- Hex color with letter 'e'?                       --> Pitfall #4 (use #x)
  +-- Using commas?                                    --> Pitfall #9
  +-- Using semicolons?                                --> Pitfall #10
  +-- border_radius with Inset?                        --> Pitfall #5

Problem: Widget behavior not working
  |
  +-- Animator on Label?                               --> Pitfall #12
  +-- Modal not showing?                               --> Pitfall #20
  +-- MatchEvent not firing?                           --> Pitfall #24
  +-- State resetting between frames?                  --> Pitfall #25

Problem: Compilation error
  |
  +-- Derive macro not found?                          --> Pitfall #22 (Script/ScriptHook)
  +-- apply_over / live! not found?                    --> Pitfall #21 (script_apply_eval!)
  +-- Theme constant not found?                        --> Pitfall #23 (theme.xxx)
  +-- Widget type not found at runtime?                --> Pitfall #6 (registration order)
```

---

## Additional Notes

### Splash Syntax Quick Rules
1. Commas are optional between properties (tokenizer treats them as whitespace)
2. No semicolons anywhere
3. `:=` for named/addressable children, `:` for static properties
4. `+:` to merge with parent instead of replacing
5. `#x` prefix for hex colors containing the letter `e`
6. `height: Fit` on every container (unless inside fixed-height parent)
7. `width: Fill` on root container
8. `new_batch: true` on any background container with text children

### Registration Order in App::run()
1. `crate::makepad_widgets::script_mod(vm)` -- base widgets
2. Your custom widget modules
3. Your app UI modules
4. `App::from_script_mod(vm, self::script_mod)`

### Widgets That Support Animator
`View`, `SolidView`, `RoundedView`, `ScrollXView`, `ScrollYView`, `ScrollXYView`, `Button`, `ButtonFlat`, `ButtonFlatter`, `CheckBox`, `Toggle`, `RadioButton`, `LinkLabel`, `TextInput`

### Widgets That Do NOT Support Animator
`Label`, `H1`-`H4`, `P`, `TextBox`, `Image`, `Icon`, `Markdown`, `Html`, `Slider`, `DropDown`, `Splitter`, `Hr`, `Filler`

---

## Pitfall #26: Hot reload not working -- missing `--hot` flag or file watcher issues

**Symptom:** You edit `script_mod!` code in a Rust source file but the running app does not update. No hot reload occurs.

**Root Cause:** Hot reload requires the `--hot` flag to start the file watcher. Without it, the app runs normally without watching for file changes. Also, the watcher normalizes paths and deduplicates content -- if your change produces identical extracted script_mod content, no reload triggers.

**Fix:**
```bash
# Run with hot reload enabled
cargo run -p my-app -- --hot
```

**Additional checks:**
- Ensure the `script_mod!` block is well-formed (syntax errors prevent extraction)
- Check that raw strings, byte strings, and comments within `script_mod!` are properly closed
- The watcher tracks `#(...)` Rust placeholder counts -- adding/removing placeholders requires a full rebuild
- File paths are normalized across platforms (handles Windows backslashes, symlinks)

---

## Pitfall #27: WASM server port conflict -- stale lock file

**Symptom:** `cargo makepad wasm run` fails with a port-in-use error or hangs during startup. Multiple WASM servers may conflict.

**Root Cause:** The WASM server manager uses per-workspace lock files tracking PID and port. A stale lock from a crashed process can block new server startup.

**Fix:**
- The server manager automatically detects and cleans stale locks (checks PID alive AND port ownership)
- If auto-detection fails, manually remove the lock file in your workspace
- The startup mutex prevents concurrent `wasm run` startups with configurable timeouts

**Diagnostics:** The server manager reports detailed port occupant info using `lsof` (Unix) or `netstat` (Windows).

---

## Pitfall #28: IME popup appears without TextInput focus

**Symptom:** The IME (Input Method Editor) popup window appears when no TextInput has focus, or appears at the wrong position.

**Root Cause:** On Linux X11, IME events could be dispatched without proper focus tracking. This was fixed to only show IME popups when a TextInput widget has keyboard focus.

**Fix:** Ensure your TextInput calls `cx.set_key_focus(area)` on `FingerDown`. The platform layer now correctly gates IME popup visibility on focus state.

---

## Pitfall #29: Wayland context menu crash -- repeated open/close

**Symptom:** On Wayland, rapidly opening and closing context menus (popup windows) causes a crash or protocol error.

**Root Cause:** The `xdg_popup` protocol requires proper grab semantics. Repeated popup open/close without waiting for compositor acknowledgment triggered protocol violations.

**Fix:** This is fixed in the platform layer. Popup windows now use `xdg_popup` with compositor-driven grab and emit `PopupDismissed` events. Apps must handle `PopupDismissed` for explicit-close semantics (don't re-open immediately in the dismiss handler).

---

## Updated Quick Reference: Diagnostic Decision Tree

```
Problem: Hot reload not working
  |
  +-- Missing --hot flag?                               --> Pitfall #26
  +-- script_mod! has syntax errors?                    --> Pitfall #26
  +-- Content unchanged (same extracted script)?        --> Pitfall #26

Problem: WASM build/server issues
  |
  +-- Port conflict?                                    --> Pitfall #27
  +-- Server hangs on startup?                          --> Pitfall #27
  +-- Binary too large?                                 --> Use --wasm-opt, --split-functions

Problem: Platform-specific issues
  |
  +-- IME popup at wrong time?                          --> Pitfall #28
  +-- Wayland popup crash?                              --> Pitfall #29
  +-- Selection handles not showing (mobile)?           --> Check iOS 16+ / Android JNI bridge

Problem: Splash eval issues (POST /splash, set_text)
  |
  +-- ScrollYView renders blank in eval?                --> Pitfall #30
  +-- Code block has no syntax highlighting?            --> Pitfall #31
  +-- CJK characters overlap in CodeView?              --> Pitfall #32
  +-- Type default properties not inherited?            --> Pitfall #33
  +-- on_after_apply not called for eval widgets?      --> Pitfall #33
```

---

## Pitfall #30: ScrollYView renders blank in Splash eval

**Symptom:** Sending `ScrollYView{...}` via POST /splash renders a blank/empty panel. The same code works fine in compiled `script_mod!`.

**Root Cause:** `ScrollYView` requires internal initialization that doesn't complete properly during Splash runtime eval. The scroll view creates but its viewport dimensions are not set up correctly in the eval context.

**Fix:** Use plain `View` with `height: Fit` instead. Canvas wraps the splash panel in its own scroll container.

```
// WRONG -- blank in Splash eval
ScrollYView{ width: Fill height: Fill flow: Down
    Label{ text: "content" }
}

// CORRECT -- works in eval
View{ width: Fill height: Fit flow: Down
    Label{ text: "content" }
}
```

---

## Pitfall #31: Markdown code blocks have no syntax highlighting in Splash eval

**Symptom:** `Markdown{body: "...```rust\n...\n```..."}` sent via POST /splash shows code blocks as plain monospace text without syntax coloring. The same Markdown in compiled `script_mod!` has full syntax highlighting via CodeView.

**Root Cause:** Canvas overrides `mod.widgets.Markdown` with `set_type_default()` adding `code_block := View{CodeView{...}}` and `use_code_block_widget: true`. But instances created via Splash eval don't inherit these because: (1) `on_after_apply` is not called in eval path, (2) the type default vec entries (named children) are not fully copied to instances.

**Fix (applied 2026-03-23):** `widgets/src/markdown.rs` now lazily looks up the type default in `draw_walk` via `vm.bx.heap.type_default_for_object()` and registers missing templates. Also auto-enables `use_code_block_widget` when a `code_block` template is found.

---

## Pitfall #32: CJK characters overlap in CodeView / CodeEditor

**Symptom:** Chinese, Japanese, or Korean characters in code blocks overlap with adjacent characters. The monospace grid doesn't account for double-width CJK glyphs.

**Root Cause:** `code_editor/src/char.rs` had `column_count()` returning `1` for ALL characters. CJK characters need 2 columns in a monospace grid.

**Fix (applied 2026-03-23):** `char.rs` now returns `2` for CJK Unified Ideographs, Hiragana, Katakana, Hangul, fullwidth Latin, and related Unicode ranges. Also added `LXGWWenKaiRegular.ttf` as Chinese fallback in `font_code` across all three theme files.

---

## Pitfall #33: Type default overrides not inherited in Splash eval

**Symptom:** When a widget type is overridden via `set_type_default()` (e.g., Canvas overriding Markdown with extra templates), instances created through Splash eval (`POST /splash`) don't pick up the override's properties or named children.

**Root Cause:** The Splash eval path creates widgets by applying only the eval value (e.g., `{body: "..."}`) without triggering `ScriptHook::on_after_apply`. The `#[live]` field defaults are used instead of the type default values. Vec entries (named children like templates) from the type default may also be lost during the proto copy chain.

**Workaround:** Implement lazy initialization in `draw_walk` that checks for missing state and looks up the type default via `vm.bx.heap.type_default_for_object(self.source.as_object())`. This is the pattern used by Markdown for code_block templates.

---

## Pitfall #34: `instance` in `draw_bg +:` crashes — "cannot push to frozen vec"

**Symptom:** Runtime crash: "cannot push to frozen vec" when adding `instance my_var: 0.5` inside `draw_bg +: { }`.

**Root Cause:** Splash `+:` blocks can override `pixel: fn()` and set existing variables, but CANNOT add new instance/uniform fields. GPU layout is compile-time.

**Fix:** Use built-in variables (`self.draw_pass.time`, `self.pos`, `self.rect_size`) or create a custom Rust DrawQuad type.

---

## Pitfall #35: Transparent window still shows opaque background

**Symptom:** Setting `window.transparent: true` but the window still has a gray/dark background.

**Root Cause:** `window.transparent` only tells the OS the window is transparent. The render pass still clears to an opaque color by default.

**Fix:** Must set BOTH:
```
window.transparent: true
pass.clear_color: #x00000000    // CRITICAL: fully transparent clear color
```
And do NOT set `draw_bg.color` on `body +: {}` — it overrides the transparency.

Reference: `tools/canvas/src/app.rs` in Makepad source.

---

## Pitfall #36: `sdf.box()` with large border_radius produces diamond/spiky shape

**Symptom:** Using `border_radius: 28.0` on a 56px-tall `RoundedView` with `width: Fit` produces pointy diamond-shaped ends instead of rounded capsule ends.

**Root Cause:** `sdf.box()` formula `size.xy - vec2(2*r, 2*r)` goes negative when `r >= min(w,h)/2`, breaking the SDF.

**Fix:** Use a custom capsule SDF: `let cx = clamp(px, r, max(r, w-r))` — see makepad-2.0-shaders skill "SDF Capsule Pattern".

---

## Pitfall #37: Child widget bleeds through parent SDF mask

**Symptom:** A `LoadingSpinner` or other child widget renders outside the parent View's custom SDF capsule shape, causing visible artifacts at the edges.

**Root Cause:** Each widget has its own draw call. Child widgets are not clipped by the parent's SDF shader — they draw independently in their own rect.

**Fix:** Embed animation directly in the parent's `pixel: fn()` shader instead of using child widgets. Or use `clip_x: true` + `clip_y: true` (may not fully solve it for rounded shapes).

---

## Pitfall #38: `show_in_dock(false)` hides NSStatusBar items

**Symptom:** Calling `cx.show_in_dock(false)` makes the app invisible in Dock, but also hides any NSStatusBar items (menu bar icons).

**Root Cause:** `show_in_dock(false)` sets `NSApplicationActivationPolicyAccessory`, which prevents the app from owning status bar items.

**Fix:** Don't call `show_in_dock(false)` at runtime. Use `LSUIElement=true` in Info.plist for .app bundles instead. During `cargo run`, accept the Dock icon.

---

## Pitfall #39: Emoji renders as garbage/box character

**Symptom:** Some emoji (✨ ⏳) display as boxes or garbled characters in `Label` text.

**Root Cause:** Makepad's font atlas doesn't include all emoji glyphs. Only a subset of basic emoji is supported.

**Fix:** Test each emoji. Known working: 🎙 🔍 🔄. Known broken: ✨ ⏳. Use ASCII alternatives as fallback.

---

## Pitfall #40: `script_apply_eval!` has no effect on dynamically-created widgets

**Symptom:** You create a widget via `widget_ref_from_live_ptr(cx, Some(ptr))` (or `cx.with_vm(|vm| WidgetRef::script_from_value(vm, value))`), then use `script_apply_eval!(cx, item, { draw_bg.color: #(color) })` to change its properties at runtime. The call executes without error, but the widget's appearance doesn't change.

**Root Cause:** `script_apply_eval!` internally calls `self.script_source()` to get the widget's ScriptObject, then evaluates the script code against it. For widgets created dynamically from LivePtr/ScriptValue templates, `script_source()` returns `ScriptObject::ZERO` (the default). This means the eval scope is empty — property assignments silently fail because there is no valid target object.

This affects ALL of these approaches:
- `script_apply_eval!(cx, item, { draw_bg.color: #(color) })` — no effect
- `script_apply_eval!(cx, item, { draw_bg +: { color: #(color) } })` — no effect
- `script_apply_eval!(cx, item, { show_bg: true })` — no effect
- `ViewRef.set_uniform(cx, live_id!(color), &[r,g,b,a])` — also no effect

**Fix:** Use **Animator states** with **shader instance variables** instead:

1. Define an instance variable and pixel shader in the DSL template:
```
mod.widgets.MyItem = View {
    show_bg: true
    draw_bg +: {
        color: (COLOR_PRIMARY)
        selected: instance(0.0)

        pixel: fn() {
            let sdf = Sdf2d.viewport(self.pos * self.rect_size)
            sdf.box(0. 0. self.rect_size.x self.rect_size.y self.border_radius)
            let highlight = #x1E90FF30
            sdf.fill(Pal.premul(self.color.mix(highlight self.selected)))
            return sdf.result
        }
    }

    animator: Animator {
        highlight: {
            default: @off
            off: AnimatorState {
                from: { all: Forward { duration: 0.12 } }
                apply: { draw_bg: { selected: 0.0 } }
            }
            on: AnimatorState {
                from: { all: Forward { duration: 0.08 } }
                apply: { draw_bg: { selected: 1.0 } }
            }
        }
    }
}
```

2. Toggle the state from Rust:
```rust
let view = item.as_view();
if is_highlighted {
    view.animator_cut(cx, ids!(highlight.on));
} else {
    view.animator_cut(cx, ids!(highlight.off));
}
```

**Key insight:** Animator states work because they operate through Makepad's animation system which directly modifies shader instance variables in the GPU buffer — this bypasses the ScriptObject/eval mechanism entirely.

---

## Pitfall #41: `script_apply_eval!` cannot use DSL constants at runtime

**Symptom:** Runtime errors like `variable Right not found in scope`, `variable Fit not found in scope`, `variable Align not found in scope`, `variable MouseCursor not found in scope` when using `script_apply_eval!`.

**Root Cause:** `script_apply_eval!` evaluates code in a restricted runtime scope that does NOT include DSL constants like `Right`, `Down`, `Fit`, `Fill`, `Align`, `Inset`, `MouseCursor`, etc. These constants are only available during `script_mod!` evaluation (compile/init time), not at runtime.

**Fix:** For layout changes, set properties in the DSL template at definition time. If you must change layout at runtime, use the Rust API directly:

```rust
// WRONG — DSL constants not available at runtime
script_apply_eval!(cx, item, {
    flow: Right
    height: Fit
    align: Align{y: 0.5}
});

// CORRECT — Use Rust values with #(expr) interpolation
let height = 36.0_f64;
script_apply_eval!(cx, item, {
    height: #(height)
});

// CORRECT — For colors (hex literals work)
let color = vec4(0.1, 0.2, 0.3, 1.0);
script_apply_eval!(cx, item, {
    draw_bg +: { color: #(color) }
});

// CORRECT — Bake layout into DSL template instead
mod.widgets.MyItem = View {
    flow: Right
    height: 36
    align: Align{y: 0.5}
}
```

**What DOES work in `script_apply_eval!`:** Numeric values, hex colors (#fff), `#(rust_expr)` interpolation, and property paths (`draw_bg +: { ... }`).

**What does NOT work:** Type constructors (`Align{}`, `Inset{}`), enum variants (`Right`, `Down`, `Fit`, `Fill`), and widget type references (`MouseCursor.Hand`).

---

## Pitfall #42: `Dock.load_state()` corrupts DrawList references — blank rendering

**Symptom:** After restoring a dock layout from persisted state (e.g., on app restart), the entire dock area renders blank/grey. Console shows massive `Drawlist id generation wrong index: N current gen:1 in pointer:0` errors.

**Root Cause:** `Dock.load_state()` calls `self.tab_bars.clear()` during event handling, which drops `TabBarWrap` instances containing `DrawList2d`. This frees the DrawList pool entries (incrementing their generation). However, Makepad's rendering pipeline still holds cached `DrawListId` references from the previous draw frame with generation 0. On the next frame, accessing these stale references causes generation mismatches.

**Fix:** Don't call `dock.load_state()` to restore persisted state. Instead, recreate tabs programmatically:

```rust
// WRONG — corrupts DrawList references
dock.borrow_mut().load_state(cx, saved_dock_items.clone());

// CORRECT — use normal Dock API
self.close_all_tabs(cx);
for room in &saved_room_order {
    self.focus_or_create_tab(cx, room.clone());
}
```

**Trade-off:** This approach doesn't restore custom splitter positions or multi-pane layouts. Those require a fix in Makepad's Dock widget upstream.

---

## Pitfall #43: Named children use `=` in 1.0 but `:=` in 2.0 DSL templates

**Symptom:** When migrating `live_design!` to `script_mod!`, named children defined with `name = Widget { }` cause runtime errors like `variable name not found in scope`. The children exist in the widget tree but are not addressable from Rust via `ids!(name)`.

**Root Cause:** In Makepad 1.0 `live_design!`, both `=` and `:=` create named children. In Makepad 2.0 `script_mod!`, only `:=` creates named, addressable children. Using `=` in 2.0 creates a local variable assignment, not a named child widget.

**Fix:**
```
// 1.0 (live_design!) — both work
avatar = <Avatar> { width: 24, height: 24 }
avatar := <Avatar> { width: 24, height: 24 }

// 2.0 (script_mod!) — ONLY := works for named children
avatar := Avatar { width: 24 height: 24 }  // CORRECT
avatar = Avatar { width: 24 height: 24 }   // WRONG — local variable, not child
```

---

## Pitfall #44: `draw_bg:` replaces, `draw_bg +:` merges in DSL and `script_apply_eval!`

**Symptom:** Setting `draw_bg: { color: #f00 }` in a DSL template or `script_apply_eval!` causes all other draw_bg properties (border_radius, border_color, hover states, shader code) to be lost.

**Root Cause:** The `:` operator REPLACES the entire property value. The `+:` operator MERGES with the existing value, only overriding specified sub-properties.

**Fix:** Always use `+:` when you want to modify a sub-property of draw_bg, draw_text, or any nested struct:

```
// WRONG — replaces ALL of draw_bg, losing border_radius, shader, etc.
draw_bg: { color: #f00 }

// CORRECT — only changes color, keeps everything else
draw_bg +: { color: #f00 }

// In script_apply_eval!, same rule applies:
// WRONG
script_apply_eval!(cx, item, { draw_bg: { color: #(color) } });

// CORRECT
script_apply_eval!(cx, item, { draw_bg +: { color: #(color) } });

// Dot-path shorthand also works (equivalent to +: merge):
draw_bg.color: #f00
draw_bg.border_radius: 8.0
```

---

## Pitfall #45: Popup/menu opens in the wrong place -- treating layout spacing as overlay positioning

**Symptom:** A popup menu or language selector should appear above a button, but it keeps
appearing below it, pinned to the wrong corner, or behaving as if your Y-position math is
being ignored.

**Root Cause:** You built the popup as an ordinary child in a local layout tree and tried to
position it with `margin.top` / `margin.left` or other layout offsets. In Makepad, that is
still layout negotiation, not a true overlay anchor. For real popup behavior, the popup
should usually live in a top-level overlay owner (`Modal`, tooltip layer, popup owner) and
be positioned with `walk.abs_pos`.

**Fix:** Move popup ownership to a common ancestor or overlay owner. Read the trigger button
position with `button.area().clipped_rect(cx)`, compute the popup's absolute position in the
overlay's coordinate space, and write it to `popup.walk.abs_pos`.

```rust
// WRONG -- local child + layout spacing fights the turtle
script_apply_eval!(cx, popup, {
    margin.left: #(x)
    margin.top: #(y)
});

// CORRECT -- top-level overlay popup with explicit absolute anchor
let button_rect = button.area().clipped_rect(cx);
let popup_pos = dvec2(button_rect.pos.x, button_rect.pos.y - 294.0);

if let Some(mut popup) = self.view(cx, ids!(popup)).borrow_mut() {
    popup.walk.abs_pos = Some(popup_pos);
}
```

**Important distinction:**
- `clip_x: false` / `clip_y: false` only let a local child paint outside its parent.
- They do NOT make that child behave like a true overlay.

**Rule of thumb:** If the popup must escape the component that triggered it, lift the popup
state to a common ancestor and let that ancestor own the overlay.

---

## Updated Diagnostic Decision Tree (additions)

```
Problem: script_apply_eval! has no effect on widget
  |
  +-- Widget created via widget_ref_from_live_ptr()?    --> Pitfall #40 (use Animator)
  +-- Using DSL constants (Right, Fit, Align)?          --> Pitfall #41 (use Rust values)
  +-- Using draw_bg: instead of draw_bg +: ?            --> Pitfall #44 (use merge operator)

Problem: Dock renders blank after state restore
  |
  +-- Called Dock.load_state() in event handler?         --> Pitfall #42 (use tab recreation)

Problem: Named child not addressable from Rust
  |
  +-- Used = instead of := in script_mod!?               --> Pitfall #43 (use :=)

Problem: Popup/menu anchored to button but renders in wrong place
  |
  +-- Built as normal child and moved with margin?       --> Pitfall #45 (use top-level overlay + walk.abs_pos)
  +-- Only disabled clip_x/clip_y on local parent?       --> Pitfall #45 (overflow is not a true overlay)
```
