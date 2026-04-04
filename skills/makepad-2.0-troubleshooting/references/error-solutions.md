# Makepad 2.0 Error Solutions Reference

This reference maps error messages, visual symptoms, and migration issues to their solutions.
Use alongside the main SKILL.md pitfalls guide.

---

## 1. Compile-Time Error Solutions

### Error: `cannot find derive macro 'Live'`

**Full message:**
```
error: cannot find derive macro `Live` in this scope
  --> src/app.rs:12:10
   |
12 | #[derive(Live, LiveHook)]
   |          ^^^^
```

**Cause:** Makepad 2.0 renamed derive macros.

**Solution:** Replace `Live` with `Script` and `LiveHook` with `ScriptHook`.
```rust
// Before
#[derive(Live, LiveHook)]
// After
#[derive(Script, ScriptHook)]
```

---

### Error: `cannot find macro 'live_design'`

**Full message:**
```
error: cannot find macro `live_design` in this scope
```

**Cause:** `live_design!` was replaced by `script_mod!` in Makepad 2.0.

**Solution:** Rewrite the macro block using `script_mod!` syntax.
```rust
// Before
live_design!{
    import makepad_widgets::base::*;
    App = {{App}}{
        ui: <Root>{ ... }
    }
}

// After
script_mod!{
    use mod.prelude.widgets.*
    load_all_resources() do #(App::script_component(vm)){
        ui: Root{
            main_window := Window{
                body +: { /* content */ }
            }
        }
    }
}
```

---

### Error: `cannot find macro 'live'`

**Full message:**
```
error: cannot find macro `live` in this scope
   |
42 |     item.apply_over(cx, live!{ height: (h) });
   |                         ^^^^
```

**Cause:** `live!` macro was replaced by `script_apply_eval!` in Makepad 2.0.

**Solution:**
```rust
// Before
item.apply_over(cx, live!{ height: (h) });

// After
script_apply_eval!(cx, item, { height: #(h) });
```

---

### Error: `cannot find derive macro 'DefaultNone'`

**Full message:**
```
error: cannot find derive macro `DefaultNone` in this scope
```

**Cause:** `DefaultNone` derive was removed. Use standard Rust `Default`.

**Solution:**
```rust
// Before
#[derive(DefaultNone)]
pub enum MyAction { Clicked, None }

// After
#[derive(Clone, Default)]
pub enum MyAction {
    Clicked,
    #[default]
    None,
}
```

---

### Error: `expected at least one digit in exponent`

**Full message:**
```
error: expected at least one digit in exponent
  --> src/app.rs:15:25
   |
15 |     draw_bg.color: #2ecc71
   |                     ^^
```

**Cause:** Rust tokenizer reads `2e` as start of scientific notation.

**Solution:** Use `#x` prefix for hex colors containing `e` or `E`.
```
// Before
draw_bg.color: #2ecc71
draw_bg.color: #1e1e2e

// After
draw_bg.color: #x2ecc71
draw_bg.color: #x1e1e2e
```

---

### Error: `cannot find value 'THEME_COLOR_*'` or `expected expression, found '('`

**Cause:** Old theme constant syntax `(THEME_COLOR_X)` was replaced.

**Solution:** Use `theme.` prefix.
```
// Before
draw_bg.color: (THEME_COLOR_BG_APP)

// After
draw_bg.color: theme.color_bg_app
```

---

### Error: `cannot find function 'dep'`

**Full message:**
```
error: cannot find function `dep` in this scope
   |
   |    svg: dep("crate://self/resources/icon.svg")
   |         ^^^
```

**Cause:** Resource path syntax changed in 2.0.

**Solution:**
```
// Before
svg: dep("crate://self/resources/icon.svg")

// After
svg: crate_resource("self://resources/icon.svg")
```

---

### Error: `use crate.module.* -- not found`

**Full message:** Script evaluation error referencing `crate.module` path.

**Cause:** `crate.` prefix does not exist in `script_mod`. Cross-module sharing uses the `mod` object.

**Solution:** Store shared definitions in `mod.widgets.*`:
```rust
// In module_a.rs
script_mod!{
    mod.widgets.MyWidget = View{ height: Fit }
}

// In module_b.rs -- access via mod.widgets
script_mod!{
    use mod.prelude.widgets.*
    // MyWidget is now available if module_a's script_mod was called first
}
```

---

### Error: `pub keyword invalid in script_mod`

**Cause:** Splash does not use `pub` for visibility.

**Solution:** Remove `pub`:
```
// Before
pub mod.widgets.MyWidget = View{ ... }

// After
mod.widgets.MyWidget = View{ ... }
```

---

### Error: Field ordering in `#[repr(C)]` draw shader structs

**Symptom:** GPU rendering artifacts, corrupted colors, or crashes in draw shaders.

**Cause:** `DrawVars::as_slice()` uses unsafe pointer arithmetic. Non-instance data between `DrawVars` and instance fields corrupts the GPU buffer.

**Solution:** Put `#[rust]` and non-instance `#[live]` fields BEFORE `#[deref]`, and only instance fields AFTER:
```rust
// CORRECT
#[derive(Script, ScriptHook)]
#[repr(C)]
pub struct MyDrawShader {
    #[live] pub svg: Option<ScriptHandleRef>,  // BEFORE deref
    #[rust] my_state: bool,                     // BEFORE deref
    #[deref] pub draw_super: DrawQuad,          // deref in middle
    #[live] pub tint: Vec4f,                    // instance field AFTER deref -- OK
}

// WRONG -- #[rust] field after instance fields corrupts memory
#[derive(Script, ScriptHook)]
#[repr(C)]
pub struct MyDrawShader {
    #[deref] pub draw_super: DrawQuad,
    #[live] pub tint: Vec4f,
    #[rust] my_state: bool,  // BAD: corrupts GPU instance buffer
}
```

---

### Error: `texture2d` not found

**Cause:** Texture declaration syntax changed.

**Solution:**
```
// Before
tex: texture2d

// After
tex: texture_2d(float)
```

---

## 2. Runtime Error Solutions

### Error: Widget type not found / script evaluation error

**Symptom:** App starts but widgets fail to render. Console shows script evaluation errors about unresolved widget types.

**Cause:** Widget modules not registered in the correct order.

**Solution:** Register in order: base widgets -> custom widgets -> app UI:
```rust
impl App {
    fn run(vm: &mut ScriptVm) -> Self {
        crate::makepad_widgets::script_mod(vm);     // 1. Base
        crate::my_widgets::script_mod(vm);           // 2. Custom
        App::from_script_mod(vm, self::script_mod)   // 3. App
    }
}
```

---

### Error: `MatchEvent::handle_actions` never called

**Symptom:** Button clicks and widget interactions produce no response.

**Cause:** Missing `self.match_event(cx, event)` call.

**Solution:**
```rust
impl AppMain for App {
    fn handle_event(&mut self, cx: &mut Cx, event: &Event) {
        self.match_event(cx, event);  // REQUIRED
        self.ui.handle_event(cx, event, &mut Scope::empty());
    }
}
```

---

### Error: Modal defined but never appears

**Symptom:** Modal widget exists in the script tree but is invisible.

**Cause:** Modals are hidden by default and require `.open(cx)`.

**Solution:**
```rust
// Open from event handler
self.ui.modal(ids!(my_modal)).open(cx);

// Close
self.ui.modal(ids!(my_modal)).close(cx);
```

---

### Error: Enum variant not found in script

**Symptom:** Script evaluation error when using an enum like `PopupMenuPosition::BelowInput`.

**Cause:** Some Rust enums are not exposed to the script system.

**Solution:** Remove the property and rely on the default value. If an enum variant causes "not found" errors, the enum is not exposed to script.

---

### Error: `mod(a, b)` causes shader compilation failure

**Cause:** Makepad shader language uses `modf(a, b)` not `mod(a, b)`. Similarly, use `atan2(y, x)` not `atan(y, x)` for two-argument arctangent.

**Solution:**
```
// Before
let v = mod(x, y)
let angle = atan(y, x)

// After
let v = modf(x, y)
let angle = atan2(y, x)
```

---

## 3. Visual Debugging Guide

### What You See -> What Is Wrong

| Visual Symptom | Likely Cause | Solution |
|----------------|-------------|----------|
| Completely blank / empty window | Container missing `height: Fit` | Add `height: Fit` to all containers (Pitfall #1) |
| Colored rectangle but no text | Missing `new_batch: true` | Add `new_batch: true` to background container (Pitfall #2) |
| Text disappears on hover | Hover animator without `new_batch` | Add `new_batch: true` (Pitfall #8) |
| White area where text should be | White text on white background | Set `draw_text.color: #333` (Pitfall #13) |
| Template overrides ignored | Used `:` instead of `:=` | Change to `:=` for named children (Pitfall #3) |
| Narrow content strip | Fixed width on root container | Use `width: Fill` on root (Pitfall #11) |
| Text clipped halfway | `Filler{}` next to `width: Fill` | Remove `Filler{}` (Pitfall #7) |
| Semi-transparent color too bright | Missing `Pal.premul()` in shader | Add `Pal.premul()` to return value (Pitfall #14) |
| Map area invisible | `MapView` with `height: Fit` | Use fixed pixel height like `height: 500` (Pitfall #19) |
| Ugly green background | Used `View` with `show_bg: true` | Use `SolidView` or `RoundedView` instead |
| Hover effect does nothing on Label | Label does not support Animator | Wrap in `View` with animator (Pitfall #12) |
| Colors look wrong / unexpected | Hex color with `e` parsed wrong | Use `#x` prefix (Pitfall #4) |
| Border radius does not apply | Used `Inset` for `border_radius` | Use a single float value (Pitfall #5) |
| Dialog never appears | Modal not opened from Rust | Call `.open(cx)` (Pitfall #20) |
| Buttons do nothing | `match_event` not called | Add `self.match_event(cx, event)` (Pitfall #24) |
| Counter resets every frame | Local variable instead of struct field | Use `#[rust]` field on struct (Pitfall #25) |

---

### Visual Flowchart: Nothing Renders

```
Start: Nothing renders on screen
  |
  v
Q: Is the window itself visible (title bar, frame)?
  |
  +--NO--> Check if cargo run compiled successfully
  |        Check for runtime panics in console
  |        Verify App::run() calls makepad_widgets::script_mod(vm)
  |
  +--YES--> Window visible but content area is blank
      |
      v
    Q: Does the console show script evaluation errors?
      |
      +--YES--> Widget type not found: check registration order (Pitfall #6)
      |         Property not found: check property name (Pitfall #15, #16)
      |         Parse error with 'e': use #x prefix (Pitfall #4)
      |
      +--NO--> Silent layout failure
          |
          v
        Q: Add temporary border to debug container sizes:
           RoundedView{ draw_bg.color: #f00 draw_bg.border_size: 2.0 ... }
          |
          +--Containers have zero height--> Add height: Fit (Pitfall #1)
          |
          +--Containers have correct size but text invisible
              |
              v
            Q: Is background colored?
              +--YES--> Add new_batch: true (Pitfall #2)
              +--NO--> Check draw_text.color (Pitfall #13)
```

---

### Visual Flowchart: Text Not Visible

```
Start: Text is not visible
  |
  v
Q: Is the container behind the text colored (non-transparent background)?
  |
  +--YES--> Does the container have new_batch: true?
  |   |
  |   +--NO--> Add new_batch: true (Pitfall #2)
  |   +--YES--> Is draw_text.color same as background? (white on white?)
  |       |
  |       +--YES--> Change draw_text.color to contrasting color (Pitfall #13)
  |       +--NO--> Does text disappear only on hover?
  |           |
  |           +--YES--> Hover animator bg without new_batch (Pitfall #8)
  |           +--NO--> Check if container has height: Fit (Pitfall #1)
  |
  +--NO--> Is the container itself visible (has height > 0)?
      |
      +--NO--> Add height: Fit to the container (Pitfall #1)
      +--YES--> Is the text being clipped?
          |
          +--YES--> Is Filler next to width: Fill? (Pitfall #7)
          +--NO--> Check if text is actually set (text: "...")
```

---

## 4. Migration-Specific Errors (1.x -> 2.0)

### Complete Migration Checklist

| Step | 1.x Syntax | 2.0 Syntax | Notes |
|------|-----------|------------|-------|
| 1 | `live_design!{}` | `script_mod!{}` | Complete rewrite required |
| 2 | `<BaseWidget>` | `BaseWidget{}` or `mod.widgets.BaseWidget{}` | Angle brackets removed |
| 3 | `{{StructName}}` | `#(Struct::register_widget(vm))` | Widget registration syntax |
| 4 | `Key = Value` | `Key: value` | Equals sign replaced with colon |
| 5 | `(THEME_COLOR)` | `theme.color_*` | Parenthesized constants replaced |
| 6 | `<THEME_FONT>` | `theme.font_*` | Angle-bracket theme refs replaced |
| 7 | `instance hover: 0.0` | `hover: instance(0.0)` | Instance declaration is a function |
| 8 | `uniform color: #fff` | `color: uniform(#fff)` | Uniform declaration is a function |
| 9 | `draw_bg: {}` (replace) | `draw_bg +: {}` (merge) | Use `+:` to merge, not replace |
| 10 | `default: off` | `default: @off` | `@` prefix for state references |
| 11 | `fn pixel(self)` | `pixel: fn()` | Shader function syntax |
| 12 | `live!{...}` | `script_apply_eval!` | Runtime property updates |
| 13 | `#[derive(Live)]` | `#[derive(Script)]` | Derive macro rename |
| 14 | `#[derive(LiveHook)]` | `#[derive(ScriptHook)]` | Derive macro rename |
| 15 | `#[derive(DefaultNone)]` | `#[derive(Default)]` + `#[default]` | Standard Rust Default |
| 16 | `dep("crate://self/...")` | `crate_resource("self://...")` | Resource path syntax |
| 17 | `tex: texture2d` | `tex: texture_2d(float)` | Texture declaration |
| 18 | `import makepad_widgets::*` | `use mod.prelude.widgets.*` | Import syntax |
| 19 | `mix(mix(a,b,t),c,t2)` | `a.mix(b,t).mix(c,t2)` | Method chaining preferred |
| 20 | `Key = Value` bindings | `let Key = Value` bindings | Template definitions |

---

### Migration Error: `import` statement not recognized

**1.x code:**
```
live_design!{
    import makepad_widgets::base::*;
    import makepad_widgets::theme_desktop_dark::*;
}
```

**2.0 equivalent:**
```rust
script_mod!{
    use mod.prelude.widgets.*
}
```

---

### Migration Error: Angle bracket widget inheritance

**1.x code:**
```
MyButton = <Button>{
    draw_bg: { color: #f00 }
}
```

**2.0 equivalent:**
```
let MyButton = Button{
    draw_bg +: { color: #f00 }
}
```

Note the `+:` for merging (not replacing) draw_bg properties.

---

### Migration Error: Double-brace struct registration

**1.x code:**
```
App = {{App}}{
    ui: <Root>{ ... }
}
```

**2.0 equivalent:**
```rust
script_mod!{
    use mod.prelude.widgets.*
    load_all_resources() do #(App::script_component(vm)){
        ui: Root{
            main_window := Window{
                body +: { /* content */ }
            }
        }
    }
}
```

---

### Migration Error: Old `live_register` function

**1.x code:**
```rust
fn live_register(cx: &mut Cx) {
    crate::makepad_widgets::live_design(cx);
}
```

**2.0 equivalent:**
```rust
impl App {
    fn run(vm: &mut ScriptVm) -> Self {
        crate::makepad_widgets::script_mod(vm);
        App::from_script_mod(vm, self::script_mod)
    }
}
```

---

### Migration Error: Shader `fn pixel(self)` syntax

**1.x code:**
```
draw_bg: {
    fn pixel(self) -> vec4 {
        return #f00;
    }
}
```

**2.0 equivalent:**
```
draw_bg +: {
    pixel: fn() {
        return Pal.premul(#f00)
    }
}
```

Key differences:
- `pixel: fn()` instead of `fn pixel(self) -> vec4`
- No explicit `self` parameter (implicitly available)
- No explicit return type
- Must use `Pal.premul()` for color returns (unless returning `sdf.result`)
- Use `+:` to merge with inherited draw properties

---

## 5. Quick Diagnostic Commands

### Debug script evaluation

Use the `~` operator to log values during script evaluation:
```rust
script_mod!{
    ~mod.theme           // Logs the entire theme object
    ~mod.prelude.widgets // Logs what is in the prelude
    ~some_variable       // Logs a variable (or "not found" error)
}
```

### Search for correct property usage

When unsure about a property name, grep the widgets source:
```bash
# Find how a property is used in the current codebase
grep -r "border_radius" widgets/src/
grep -r "draw_text.color" widgets/src/
grep -r "new_batch" widgets/src/
```

### Debug container sizes

Temporarily add visible borders to containers to see their actual size:
```
View{
    height: Fit
    show_bg: true
    draw_bg.color: #f002
    draw_bg.border_size: 1.0
    draw_bg.border_color: #f00
    // your content
}
```

### Check widget tree at runtime

Use Studio remote protocol to dump the widget tree:
```json
{"WidgetTreeDump":{"build_id":YOUR_BUILD_ID}}
```

Or query a specific widget:
```json
{"WidgetQuery":{"build_id":YOUR_BUILD_ID,"query":"id:my_button"}}
```

---

## 6. Error Pattern Quick-Lookup Table

| Error Pattern | Pitfall # | One-Line Fix |
|---------------|-----------|--------------|
| Container 0px tall | #1 | Add `height: Fit` |
| Text behind background | #2 | Add `new_batch: true` |
| Override silently ignored | #3 | Use `:=` not `:` |
| `expected digit in exponent` | #4 | Use `#x` prefix for hex |
| `border_radius` no effect | #5 | Use float, not Inset |
| Widget type not found | #6 | Fix registration order |
| Text clipped halfway | #7 | Remove Filler next to Fill |
| Text vanishes on hover | #8 | Add `new_batch: true` |
| Unexpected token (comma) | #9 | Remove all commas |
| Unexpected token (semicolon) | #10 | Remove all semicolons |
| Layout narrow strip | #11 | Root: `width: Fill` |
| Animator does nothing | #12 | Wrap Label in View |
| White text invisible | #13 | Set `draw_text.color` |
| Alpha blending wrong | #14 | Add `Pal.premul()` |
| Property not recognized | #15 | Use Splash names, not CSS |
| Property silently ignored | #16 | Check docs for valid props |
| Duplicate Window wrapper | #17 | Remove Root/Window from output |
| on_render not called | #18 | Ensure widget in draw tree |
| MapView 0px | #19 | Use fixed pixel height |
| Modal invisible | #20 | Call `.open(cx)` |
| `live!` not found | #21 | Use `script_apply_eval!` |
| `Live` derive not found | #22 | Use `Script` derive |
| `THEME_COLOR` not found | #23 | Use `theme.color_*` |
| Actions not handled | #24 | Call `self.match_event()` |
| State resets each frame | #25 | Use `#[rust]` struct field |
| `mod(a,b)` shader error | -- | Use `modf(a, b)` |
| `texture2d` not found | -- | Use `texture_2d(float)` |
| `dep()` not found | -- | Use `crate_resource()` |
| `DefaultNone` not found | -- | Use `#[derive(Default)]` |
| `pub` in script_mod | -- | Remove `pub` keyword |
| `crate.module` not found | -- | Use `mod.widgets.*` |
| Green background on View | -- | Use `SolidView`/`RoundedView` |
| Comments shift error lines | -- | No comments before first code |
| `set_visible()` does nothing | -- | Rust-only API; use `set_text`/`on_render` conditional |
| `on_render` empty on first load | -- | `on_render` needs `.render()` call; put initial content statically |
| Loop-POST splash → 100% CPU | -- | POST once; use `on_click`/`set_text`/`fn tick()` internally |
| Time shows long decimal | -- | `_pos`/`_dur` are floats; truncate with while loop |
| HTTP event bridge unreliable | -- | Use `on_click:` handlers in Splash; don't rely on `GET /event` |
| View-children mode horizontal | -- | Default flow is Right; add `flow: Down` explicitly |
| Button click-through in Splash | -- | Use fixed `width`/`height` on buttons, not `width: Fill` |
| `window.macos.chrome` not found in VM | -- | Set from Rust via `configure_macos_window()` |
