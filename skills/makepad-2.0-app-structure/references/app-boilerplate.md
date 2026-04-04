### Minimal App Template (Cargo.toml):
```toml
[package]
name = "makepad-example-myapp"
version = "0.1.0"
edition = "2021"

[dependencies]
makepad-widgets = { path = "../../widgets" }
```

### Minimal App (app.rs) - Counter Pattern:
```rust
use makepad_widgets::*;

app_main!(App);

script_mod! {
    use mod.prelude.widgets.*

    let state = { counter: 0 }
    mod.state = state

    startup() do #(App::script_component(vm)){
        ui: Root{
            on_startup: ||{
                ui.main_view.render()
            }
            main_window := Window{
                window.inner_size: vec2(420, 220)
                body +: {
                    main_view := View{
                        width: Fill height: Fill
                        flow: Down spacing: 12
                        align: Center
                        on_render: ||{
                            counter_label := Label{
                                text: "Count: " + state.counter
                                draw_text.text_style.font_size: 24
                            }
                        }
                    }
                    increment_button := Button{
                        text: "Increment"
                    }
                }
            }
        }
    }
}

impl App {
    fn run(vm: &mut ScriptVm) -> Self {
        crate::makepad_widgets::script_mod(vm);
        App::from_script_mod(vm, self::script_mod)
    }
}

#[derive(Script, ScriptHook)]
pub struct App {
    #[live] ui: WidgetRef,
}

impl MatchEvent for App {
    fn handle_actions(&mut self, cx: &mut Cx, actions: &Actions) {
        if self.ui.button(cx, ids!(increment_button)).clicked(actions) {
            script_eval!(cx, {
                mod.state.counter += 1
                ui.main_view.render()
            });
        }
    }
}

impl AppMain for App {
    fn handle_event(&mut self, cx: &mut Cx, event: &Event) {
        self.match_event(cx, event);
        self.ui.handle_event(cx, event, &mut Scope::empty());
    }
}
```

### Key Components:
1. `app_main!(App)` - Entry point macro
2. `script_mod!{...}` - UI definition in Splash
3. `App::run(vm)` - Script module registration
4. `App::from_script_mod(vm, self::script_mod)` - Create app from script
5. `#[derive(Script, ScriptHook)]` - App struct derives
6. `#[live] ui: WidgetRef` - UI reference field
7. `MatchEvent` - Action handling trait
8. `AppMain` - Event dispatch trait

### Theme Selection (Light/Dark):
```rust
impl App {
    fn run(vm: &mut ScriptVm) -> Self {
        crate::makepad_widgets::theme_mod(vm);
        script_eval!(vm, {
            mod.theme = mod.themes.light  // or mod.themes.dark
        });
        crate::makepad_widgets::widgets_mod(vm);
        App::from_script_mod(vm, self::script_mod)
    }
}
```

### Widget Reference Pattern:
```rust
// Named widget in Splash
my_button := Button{text: "Click"}
my_input := TextInput{empty_text: "Type here"}

// Access in Rust
self.ui.button(cx, ids!(my_button)).clicked(actions)
self.ui.text_input(ids!(my_input)).text()
```

### Running the app:
```bash
RUST_BACKTRACE=1 cargo run -p makepad-example-myapp --release
```
