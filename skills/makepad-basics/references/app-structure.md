# Makepad App Structure Reference

## Complete App Template

```rust
use makepad_widgets::*;

live_design! {
    use link::theme::*;
    use link::shaders::*;
    use link::widgets::*;

    App = {{App}} {
        ui: <Root> {
            main_window = <Window> {
                window: { title: "My Makepad App" }
                body = <View> {
                    width: Fill
                    height: Fill
                    flow: Down
                    align: { x: 0.5, y: 0.5 }

                    // Your widgets here
                }
            }
        }
    }
}

app_main!(App);

#[derive(Live, LiveHook)]
pub struct App {
    #[live] ui: WidgetRef,
}

impl LiveRegister for App {
    fn live_register(cx: &mut Cx) {
        crate::makepad_widgets::live_design(cx);
    }
}

impl AppMain for App {
    fn handle_event(&mut self, cx: &mut Cx, event: &Event) {
        self.ui.handle_event(cx, event, &mut Scope::empty());
    }
}
```

## Key Components

### live_design! Macro

The `live_design!` macro defines your UI using Makepad's DSL. It's compiled at runtime, enabling live editing.

```rust
live_design! {
    // Import theme, shaders, and widgets
    use link::theme::*;
    use link::shaders::*;
    use link::widgets::*;

    // Define your app structure
    App = {{App}} {
        ui: <Root> {
            // Window and content
        }
    }
}
```

### App Struct

```rust
#[derive(Live, LiveHook)]
pub struct App {
    #[live] ui: WidgetRef,
    // Add custom state fields
    #[rust] counter: i32,
}
```

- `#[derive(Live)]` - Makes struct live-editable
- `#[derive(LiveHook)]` - Provides lifecycle hooks
- `#[live]` - Field synced with DSL
- `#[rust]` - Rust-only field, not in DSL

### LiveRegister Trait

```rust
impl LiveRegister for App {
    fn live_register(cx: &mut Cx) {
        // Register your crate's live design
        crate::makepad_widgets::live_design(cx);
        // Register custom widgets
        // crate::my_widget::live_design(cx);
    }
}
```

### AppMain Trait

```rust
impl AppMain for App {
    fn handle_event(&mut self, cx: &mut Cx, event: &Event) {
        // Process events and get actions
        let actions = self.ui.handle_event(cx, event, &mut Scope::empty());

        // Handle specific widget actions
        // ...
    }
}
```

## Project Structure

```
my_makepad_app/
├── Cargo.toml
├── src/
│   ├── main.rs          # App entry point
│   └── lib.rs           # (optional) Library code
└── resources/           # Assets
    ├── icons/
    └── images/
```

## Cargo.toml

```toml
[package]
name = "my_makepad_app"
version = "0.1.0"
edition = "2024"

[dependencies]
makepad-widgets = "0.7"

# For mobile/web builds
[target.'cfg(target_os = "android")'.dependencies]
makepad-widgets = { version = "0.7", features = ["android"] }

[target.'cfg(target_arch = "wasm32")'.dependencies]
makepad-widgets = { version = "0.7", features = ["wasm"] }
```

## Running Your App

```bash
# Desktop
cargo run

# Web (requires wasm-pack)
cargo makepad wasm run -p my_makepad_app

# Android
cargo makepad android run -p my_makepad_app

# iOS
cargo makepad ios run -p my_makepad_app
```
