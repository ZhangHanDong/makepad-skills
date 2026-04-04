# Makepad 1.x to 2.0 Migration Guide

## Overview

Makepad 2.0 replaces the compile-time `live_design!` macro system with the runtime `script_mod!` macro and the Splash scripting language. This guide covers every syntax change, struct migration, and common pitfall.

---

## Complete Syntax Mapping Table

| Old (live_design!) | New (script_mod!) | Notes |
|---|---|---|
| `live_design!{}` | `script_mod!{}` | Macro name change |
| `<BaseWidget>` | `Widget{}` or `mod.widgets.Widget{}` | Angle brackets removed |
| `{{StructName}}` | `#(Struct::register_widget(vm))` | Registration syntax |
| `(THEME_COLOR_X)` | `theme.color_x` | Theme access via dot notation |
| `<THEME_FONT>` | `theme.font_regular` | Font theme access |
| `Key = Value` | `Key: value` | Colon instead of equals |
| `name = <Type>{}` | `name := Type{}` | Named instance uses `:=` |
| `instance hover: 0.0` | `hover: instance(0.0)` | Function call syntax |
| `uniform color: #fff` | `color: uniform(#fff)` | Function call syntax |
| `draw_bg: {}` (replace) | `draw_bg +: {}` (merge) | Merge operator preserves parent props |
| `default: off` | `default: @off` | `@` prefix for state references |
| `fn pixel(self) -> vec4` | `pixel: fn()` | Shader function declaration |
| `Sdf2d::viewport()` | `Sdf2d.viewport()` | Dot instead of double-colon |
| `mix(a, b, t)` | `a.mix(b, t)` | Method chaining style |
| `item.apply_over(cx, live!{...})` | `script_apply_eval!(cx, item, {...})` | Runtime property updates |
| `#[derive(Live, LiveHook)]` | `#[derive(Script, ScriptHook)]` | Derive macro rename |
| `DrawList2d::new(cx)` | `DrawList2d::script_new(vm)` | Constructor rename |
| `before_apply` / `after_apply` | `on_before_apply` / `on_after_apply` | Hook method rename |
| `dep("crate://self/path")` | `crate_resource("self://path")` | Resource path syntax |
| `tex: texture2d` | `tex: texture_2d(float)` | Texture declaration syntax |
| `#[derive(DefaultNone)]` | `#[derive(Default)]` + `#[default]` | Standard Rust default |
| `live!{...}` (inline) | `script_apply_eval!(cx, widget, {...})` | No more `live!` macro |

---

## Struct Changes

### Widget Struct Migration

```rust
// OLD (Makepad 1.x)
#[derive(Live, LiveHook, Widget)]
pub struct MyWidget {
    #[walk] walk: Walk,
    #[layout] layout: Layout,
    #[live] draw_bg: DrawQuad,
    #[live] draw_text: DrawText,
}

// NEW (Makepad 2.0)
#[derive(Script, ScriptHook, Widget)]
pub struct MyWidget {
    #[source] source: ScriptObjectRef,  // NEW - REQUIRED for all Script structs!
    #[walk] walk: Walk,
    #[layout] layout: Layout,
    #[redraw] #[live] draw_bg: DrawQuad,  // #[redraw] added for draw fields
    #[live] draw_text: DrawText,
}
```

### Animated Widget Struct

```rust
// OLD
#[derive(Live, LiveHook, Widget)]
pub struct AnimatedWidget {
    #[animator] animator: Animator,
    #[walk] walk: Walk,
    #[live] draw_bg: DrawQuad,
}

// NEW
#[derive(Script, ScriptHook, Widget, Animator)]
pub struct AnimatedWidget {
    #[source] source: ScriptObjectRef,
    #[apply_default] animator: Animator,  // #[apply_default] instead of #[animator]
    #[walk] walk: Walk,
    #[redraw] #[live] draw_bg: DrawQuad,
}
```

### Custom Draw Shader Struct

```rust
// OLD
#[derive(Live, LiveHook)]
#[repr(C)]
struct DrawMyShader {
    #[deref] draw_super: DrawQuad,
    #[live] my_param: f32,
}

// NEW
#[derive(Script, ScriptHook)]
#[repr(C)]
pub struct DrawMyShader {
    #[live] pub svg: Option<ScriptHandleRef>,  // non-instance fields BEFORE deref
    #[rust] my_state: bool,                     // non-instance fields BEFORE deref
    #[deref] pub draw_super: DrawQuad,          // deref field
    #[live] pub my_param: f32,                  // instance fields AFTER deref
}
```

CRITICAL: In `#[repr(C)]` draw shader structs, non-instance data (`#[rust]`, resource handles, booleans) must go BEFORE the `#[deref]` field. Only `#[live]` instance fields (shader inputs) go AFTER. The system uses an unsafe pointer trick that reads contiguously past `DrawVars`.

### Enum Default Migration

```rust
// OLD
#[derive(Clone, Copy, Debug, PartialEq, DefaultNone)]
pub enum MyAction {
    SomeAction,
    None,
}

// NEW
#[derive(Clone, Copy, Debug, PartialEq, Default)]
pub enum MyAction {
    SomeAction,
    AnotherAction,
    #[default]
    None,
}
```

---

## App Initialization

### OLD Pattern
```rust
use makepad_widgets::*;

app_main!(App);

live_design!{
    import makepad_widgets::base::*;
    import makepad_widgets::theme_desktop_dark::*;

    App = {{App}} {
        ui: <Root> {
            main_window = <Window> {
                body = <View> {
                    // UI here
                }
            }
        }
    }
}

#[derive(Live, LiveHook)]
pub struct App {
    #[live] ui: WidgetRef,
}

impl LiveHook for App {
    fn after_new_from_doc(&mut self, cx: &mut Cx) {
        // initialization
    }
}

impl AppMain for App {
    fn handle_event(&mut self, cx: &mut Cx, event: &Event) {
        self.match_event(cx, event);
        self.ui.handle_event(cx, event, &mut Scope::empty());
    }
}
```

### NEW Pattern
```rust
use makepad_widgets::*;

app_main!(App);

script_mod!{
    use mod.prelude.widgets.*

    load_all_resources() do #(App::script_component(vm)){
        ui: Root{
            main_window := Window{
                window.inner_size: vec2(800, 600)
                body +: {
                    // UI here
                }
            }
        }
    }
}

impl App {
    fn run(vm: &mut ScriptVm) -> Self {
        crate::makepad_widgets::script_mod(vm);  // Register all widgets FIRST
        // Platform-specific init: vm.cx().start_stdin_service() for macos
        App::from_script_mod(vm, self::script_mod)
    }
}

#[derive(Script, ScriptHook)]
pub struct App {
    #[live] ui: WidgetRef,
}

impl MatchEvent for App {
    fn handle_actions(&mut self, cx: &mut Cx, actions: &Actions) {
        // Handle widget actions
    }
}

impl AppMain for App {
    fn handle_event(&mut self, cx: &mut Cx, event: &Event) {
        self.match_event(cx, event);
        self.ui.handle_event(cx, event, &mut Scope::empty());
    }
}
```

---

## Script Module Registration

### Widget Registration (OLD vs NEW)

```rust
// OLD: live_design! with {{StructName}}
live_design!{
    MyWidget = {{MyWidget}} {
        width: Fill
        draw_bg: { color: #f00 }
    }
}

// NEW: script_mod! with #() registration
script_mod!{
    use mod.prelude.widgets_internal.*
    use mod.widgets.*

    // Register the base widget (connects Rust struct to script)
    mod.widgets.MyWidgetBase = #(MyWidget::register_widget(vm))

    // Create styled variant with defaults
    mod.widgets.MyWidget = set_type_default() do mod.widgets.MyWidgetBase{
        width: Fill
        draw_bg +: {
            color: theme.color_bg_app
        }
    }
}
```

### Multi-Module Registration Order

```rust
// In App::run - order matters!
impl App {
    fn run(vm: &mut ScriptVm) -> Self {
        crate::makepad_widgets::script_mod(vm);  // 1. Base widgets first
        crate::script_mod(vm);                    // 2. Your custom widget modules
        crate::app_ui::script_mod(vm);            // 3. UI that uses the widgets
        App::from_script_mod(vm, self::script_mod)
    }
}
```

### Cross-Module Sharing

IMPORTANT: `use crate.module.*` does NOT work. Use `mod` object:

```rust
// In app_ui.rs - export to mod.widgets namespace
script_mod! {
    use mod.prelude.widgets.*
    mod.widgets.AppUI = Window{ /* ... */ }
}

// In app.rs - import via mod.widgets
script_mod! {
    use mod.prelude.widgets.*
    use mod.widgets.*  // Now AppUI is in scope
    load_all_resources() do #(App::script_component(vm)){
        ui: Root{ AppUI{} }
    }
}
```

---

## Runtime Property Updates

```rust
// OLD: apply_over with live! macro
item.apply_over(cx, live!{
    height: (height)
    draw_bg: {is_even: (if is_even {1.0} else {0.0})}
});

// NEW: script_apply_eval! macro with #() interpolation
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

Note: Use `#(expr)` for Rust expression interpolation instead of the old `(expr)`.

---

## Shader Syntax Changes

```rust
// OLD
draw_bg: {
    instance hover: 0.0
    uniform base_color: #fff
    fn pixel(self) -> vec4 {
        let sdf = Sdf2d::viewport(self.pos * self.rect_size)
        let color = mix(self.base_color, #f00, self.hover)
        sdf.box(0., 0., self.rect_size.x, self.rect_size.y, 4.0)
        sdf.fill(color)
        return sdf.result
    }
}

// NEW
draw_bg +: {
    hover: instance(0.0)
    base_color: uniform(#fff)
    pixel: fn() {
        let sdf = Sdf2d.viewport(self.pos * self.rect_size)
        let color = self.base_color.mix(#f00, self.hover)
        sdf.box(0.0, 0.0, self.rect_size.x, self.rect_size.y, 4.0)
        sdf.fill(color)
        return sdf.result
    }
}
```

Key changes:
- `instance x: val` becomes `x: instance(val)`
- `uniform x: val` becomes `x: uniform(val)`
- `fn pixel(self) -> vec4` becomes `pixel: fn()`
- `Sdf2d::viewport()` becomes `Sdf2d.viewport()` (dot not double-colon)
- `mix(a, b, t)` becomes `a.mix(b, t)` (method chaining)
- `draw_bg: {}` becomes `draw_bg +: {}` (merge operator)

---

## Common Migration Pitfalls

### 1. Missing `#[source] source: ScriptObjectRef`
Every struct that derives `Script` MUST have this field. Without it, compilation fails.

### 2. Missing `height: Fit` on containers
In 2.0, containers default to zero height. Always set `height: Fit` or a fixed height.

### 3. Using `=` instead of `:`
All property assignments use colon: `width: Fill` not `width = Fill`.

### 4. Using `<Widget>` instead of `Widget{}`
Angle bracket syntax is gone: `Button{}` not `<Button>`.

### 5. Using `THEME_COLOR_X` instead of `theme.color_x`
Theme constants use dot notation: `theme.color_bg_app` not `(THEME_COLOR_BG_APP)`.

### 6. Forgetting `+:` merge operator
Without `+:`, the entire property is replaced. Use `draw_bg +: { color: #f00 }` to override only `color` while keeping other draw_bg properties from the parent.

### 7. Hex colors with 'e' need `#x` prefix
Colors like `#2ecc71` fail because Rust sees `2e` as scientific notation. Use `#x2ecc71`.

### 8. Wrong registration order in App::run()
Widget modules must be registered BEFORE UI modules that use them. Always: base widgets -> custom widgets -> app UI.

### 9. Using `pub` in script_mod
Do not use `pub mod.widgets.X = ...`. Just use `mod.widgets.X = ...`. Visibility is controlled by the Rust module system.

### 10. No comments before first code in script_mod
Comments are stripped by the proc macro and shift span tracking. Always start with real code (like `use mod.std.assert`) immediately after the opening brace.

---

## Additional Syntax Pitfalls

### 11. Inset/Align/Walk constructors
Use constructor syntax: `margin: Inset{left: 10}` not `margin: {left: 10}`.

### 12. Cursor values
Use `cursor: MouseCursor.Hand` not `cursor: Hand` or `cursor: @Hand`.

### 13. Resource paths
Use `crate_resource("self://path")` not `dep("crate://self/path")`.

### 14. Texture declarations
Use `tex: texture_2d(float)` not `tex: texture2d`.

### 15. Shader mod vs modf
Use `modf(a, b)` for float modulo, NOT `mod(a, b)`. Use `atan2(y, x)` for two-argument arctangent.

---

## Migration Checklist

- [ ] All `live_design!` changed to `script_mod!`
- [ ] All `=` property assignments changed to `:`
- [ ] All `<Widget>` changed to `Widget{}`
- [ ] All `(THEME_X)` changed to `theme.x`
- [ ] All shader functions use `pixel: fn()` syntax
- [ ] All `Sdf2d::` calls changed to `Sdf2d.`
- [ ] All `mix(a, b, t)` changed to `a.mix(b, t)`
- [ ] All `instance x: val` changed to `x: instance(val)`
- [ ] All `uniform x: val` changed to `x: uniform(val)`
- [ ] All `draw_bg: {}` uses `draw_bg +: {}` merge operator
- [ ] All `default: off` changed to `default: @off`
- [ ] All `#[derive(Live, LiveHook)]` changed to `#[derive(Script, ScriptHook)]`
- [ ] All Script structs have `#[source] source: ScriptObjectRef`
- [ ] All containers have `height: Fit` or fixed height
- [ ] Widget registration uses `#(Widget::register_widget(vm))`
- [ ] App uses `App::from_script_mod(vm, self::script_mod)`
- [ ] `crate::makepad_widgets::script_mod(vm)` called in `App::run()` before custom modules
- [ ] All `apply_over` + `live!{}` changed to `script_apply_eval!`
- [ ] All `#[derive(DefaultNone)]` changed to `#[derive(Default)]` with `#[default]` attribute
- [ ] Old `live_*` crate dependencies removed from Cargo.toml
- [ ] Hex colors with 'e' use `#x` prefix
- [ ] Resource paths use `crate_resource("self://...")` syntax
- [ ] `#[repr(C)]` draw shaders have correct field ordering (non-instance before deref)
