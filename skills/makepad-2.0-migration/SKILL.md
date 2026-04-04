---
name: makepad-2.0-migration
description: |
  CRITICAL: Use for migrating from Makepad 1.x to 2.0. Triggers on:
  makepad migration, live_design to script_mod, makepad upgrade, makepad 1.x,
  old syntax, new syntax, makepad breaking changes, makepad 迁移, 旧语法,
  LiveHook to ScriptHook, apply_over to script_apply_eval,
  Live to Script, live_design!, angle brackets to curly braces
---

# Makepad 1.x to 2.0 Migration Skill

> **Version:** makepad-widgets (dev branch) | **Last Updated:** 2026-03-03

## Overview

Makepad 2.0 is a **fundamental architecture shift** from compile-time static DSL to runtime scripting. Migration involves syntax changes, derive macro updates, lifecycle method renames, and new patterns for state management.

## Documentation

Refer to the local files for detailed documentation:
- `./references/migration-guide.md` - Complete migration reference with examples

---

## Quick Syntax Mapping Table

| Makepad 1.x | Makepad 2.0 | Notes |
|-------------|-------------|-------|
| `live_design! { ... }` | `script_mod! { ... }` | Core macro change |
| `<Widget> { ... }` | `Widget{ ... }` | No angle brackets |
| `Key = Value` | `Key: value` | Colon, not equals |
| `(THEME_COLOR)` | `theme.color_*` | Theme namespace |
| `live_body: { ... }` | `body +: { ... }` | Merge operator |
| `#[derive(Live)]` | `#[derive(Script)]` | Derive macro |
| `#[derive(LiveHook)]` | `#[derive(ScriptHook)]` | Lifecycle hooks |
| `#[derive(Widget)]` | `#[derive(Widget)]` | Unchanged |
| `before_apply()` | `on_before_apply()` | Method rename |
| `after_apply()` | `on_after_apply()` | Method rename |
| `apply_over!()` | `script_apply_eval!()` | Runtime updates |
| `DefaultNone` | `Default` | Enum default |
| `LiveRegister` | `WidgetRegister` | Widget registration |
| `live_register()` | `register_widget(vm)` | Registration method |
| `LiveId` | `LiveId` | Unchanged |

---

## Step-by-Step Migration

### Step 1: Replace Macro

```rust
// OLD
live_design! {
    import makepad_widgets::base::*;
    import makepad_widgets::theme_desktop_dark::*;

    App = {{App}} {
        ui: <Root> { ... }
    }
}

// NEW
script_mod! {
    use mod.prelude.widgets.*

    startup() do #(App::script_component(vm)){
        ui: Root{
            // ... UI definition
        }
    }
}
```

### Step 2: Update Derives

```rust
// OLD
#[derive(Live, LiveHook, Widget)]
pub struct MyWidget { ... }

// NEW
#[derive(Script, ScriptHook, Widget)]
pub struct MyWidget { ... }
```

### Step 3: Update App::run

```rust
// OLD
impl LiveRegister for App {
    fn live_register(cx: &mut Cx) {
        makepad_widgets::live_design(cx);
    }
}

// NEW
impl App {
    fn run(vm: &mut ScriptVm) -> Self {
        crate::makepad_widgets::script_mod(vm);
        App::from_script_mod(vm, self::script_mod)
    }
}
```

### Step 4: Rename Lifecycle Methods

```rust
// OLD
impl LiveHook for MyWidget {
    fn before_apply(&mut self, cx: &mut Cx, ...) { ... }
    fn after_apply(&mut self, cx: &mut Cx, ...) { ... }
}

// NEW
impl ScriptHook for MyWidget {
    fn on_before_apply(&mut self, cx: &mut Cx, ...) { ... }
    fn on_after_apply(&mut self, cx: &mut Cx, ...) { ... }
}
```

### Step 5: Update DSL Syntax

```
// OLD - angle brackets, equals signs
<View> {
    width: Fill, height: Fill
    show_bg: true
    draw_bg: { color: (THEME_BG) }

    title = <Label> {
        text: "Hello"
        draw_text: { color: #fff }
    }
}

// NEW - curly braces, colons, theme namespace
View{
    width: Fill height: Fill
    show_bg: true
    draw_bg.color: theme.color_bg_app

    title := Label{
        text: "Hello"
        draw_text.color: #fff
    }
}
```

### Step 6: Replace apply_over with script_eval

```rust
// OLD
self.label(id!(title)).apply_over(cx, live! {
    text: "New text"
});

// NEW
script_eval!(cx, {
    ui.title.set_text("New text")
});
// OR
script_apply_eval!(cx, self.ui, {
    title.text: "New text"
});
```

---

## Key Breaking Changes

1. **No commas** between properties (whitespace-delimited)
2. **No semicolons** anywhere in Splash
3. **No angle brackets** for widget types
4. **Theme constants** use `theme.*` prefix, not `(THEME_*)` syntax
5. **Named children** use `:=` operator, not `=`
6. **Merge operator** is `+:` not `:` for extending parent properties
7. **`height: Fit`** is MANDATORY on containers (default is 0px, not auto)
8. **Registration** happens in `App::run`, not `live_register`
9. **Field attribute** `#[source]` links to script object (required on some widgets)
10. **Old `old/` directory** contains archived 1.x code for reference

---

## Common Migration Mistakes

| Mistake | Symptom | Fix |
|---------|---------|-----|
| Still using `live_design!` | Compile error | Replace with `script_mod!` |
| Using `<Widget>` syntax | Parse error | Use `Widget{}` |
| Using `Key = Value` | Property not applied | Use `Key: value` |
| Using `(THEME_COLOR)` | Unknown token | Use `theme.color_*` |
| Missing `height: Fit` | Container invisible (0px) | Add `height: Fit` |
| Using `Live` derive | Compile error | Use `Script` |
| Using `before_apply` | Method not found | Use `on_before_apply` |
| Using commas between props | Parse error | Remove commas |

---

## Best Practices for Migration

1. **Start with examples** - Study `examples/counter` and `examples/todo` for 2.0 patterns
2. **Migrate one widget at a time** - Don't try to convert everything at once
3. **Check the old/ directory** - Compare old vs new widget implementations
4. **Test `height: Fit`** - Most invisible UI is caused by missing height
5. **Use theme variables** - Replace all hardcoded theme colors with `theme.*`
6. **Add `new_batch: true`** - Any View with `show_bg` and text children needs it
