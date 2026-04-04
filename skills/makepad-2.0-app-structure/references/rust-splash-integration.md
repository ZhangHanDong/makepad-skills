### Rust -> Splash Communication:

1. `script_eval!(cx, {...})` - Execute Splash code from Rust:
```rust
script_eval!(cx, {
    mod.state.counter += 1
    ui.main_view.render()
});
```

2. `script_apply_eval!(cx, item, {...})` - Apply properties to widget at runtime:
```rust
script_apply_eval!(cx, item, {
    height: #(height)
    draw_bg: {is_even: #(if is_even {1.0} else {0.0})}
});
```
Use `#(expr)` for Rust expression interpolation.

### Splash -> Rust Communication:

Script callbacks drive widget behavior:
```
// In Splash
todo_input := TextInput{
    on_return: || ui.add_button.on_click()
}
add_button := Button{
    on_click: ||{
        let text = ui.todo_input.text()
        if text != "" {
            add_todo(text, "")
            ui.todo_input.set_text("")
        }
    }
}
```

Rust side reads actions:
```rust
impl MatchEvent for App {
    fn handle_actions(&mut self, cx: &mut Cx, actions: &Actions) {
        if self.ui.button(cx, ids!(my_button)).clicked(actions) {
            // Business logic
        }
    }
}
```

### Multi-Module Pattern:

```rust
// lib.rs - aggregate all widget modules
pub fn script_mod(vm: &mut ScriptVm) {
    crate::module_a::script_mod(vm);
    crate::module_b::script_mod(vm);
}

// app.rs - register in correct order
impl App {
    fn run(vm: &mut ScriptVm) -> Self {
        crate::makepad_widgets::script_mod(vm);  // 1. Base
        crate::script_mod(vm);                    // 2. Custom widgets
        crate::app_ui::script_mod(vm);            // 3. UI
        App::from_script_mod(vm, self::script_mod)
    }
}
```

### Custom Widget Registration:
```rust
#[derive(Script, ScriptHook, Widget)]
pub struct MyWidget {
    #[source] source: ScriptObjectRef,  // REQUIRED
    #[walk] walk: Walk,
    #[layout] layout: Layout,
    #[redraw] #[live] draw_bg: DrawQuad,
    #[live] draw_text: DrawText,
    #[rust] my_state: i32,  // Runtime-only field
}

// With animations:
#[derive(Script, ScriptHook, Widget, Animator)]
pub struct AnimatedWidget {
    #[source] source: ScriptObjectRef,
    #[apply_default] animator: Animator,
    // ...
}
```

### State Management Pattern:
- Splash state: `mod.state = {...}` for UI state
- Rust state: `#[rust] field: Type` for business logic
- Update flow: Rust event -> script_eval! update mod.state -> ui.view.render()

### GC Best Practices:
- Large static templates: `mod.gc.set_static(template)` then `mod.gc.run()`
- Reduces GC pressure for long-lived UI templates
- Manual GC: `mod.gc.run()` / `mod.gc.run_status()`

### main.rs:
```rust
fn main() {
    makepad_widgets::app_main!(App);
}
```
Or typically combined with app.rs in single file.
