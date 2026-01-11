---
name: makepad-init
description: Initialize new Makepad application projects with proper structure and boilerplate. Use when creating a new Makepad app, setting up project structure, or scaffolding a cross-platform Rust UI application.
---

# Makepad Project Initialization

This skill enables Claude Code to scaffold new Makepad application projects with proper structure, dependencies, and boilerplate code.

## Overview

When the user asks to create a new Makepad project, generate the appropriate files based on project complexity:
- **Simple app**: Minimal structure for learning/prototyping
- **Production app**: Full structure with modules, shared components, and cross-platform support

## Simple App Template

### Directory Structure

```
my_app/
├── Cargo.toml
├── src/
│   ├── main.rs
│   ├── lib.rs
│   └── app.rs
├── resources/           # Optional: images, fonts
├── .gitignore
└── rust-toolchain.toml
```

### Cargo.toml

```toml
[package]
name = "my-app"
version = "0.1.0"
edition = "2021"
description = "A Makepad application"
license = "MIT"

[dependencies]
makepad-widgets = { git = "https://github.com/makepad/makepad", branch = "rik" }
```

### src/main.rs

```rust
fn main() {
    my_app::app::app_main()
}
```

### src/lib.rs

```rust
pub use makepad_widgets;
pub mod app;
```

### src/app.rs

```rust
use makepad_widgets::*;

live_design! {
    use link::theme::*;
    use link::shaders::*;
    use link::widgets::*;

    App = {{App}} {
        ui: <Root> {
            main_window = <Window> {
                window: { title: "My App" }
                body = <View> {
                    flow: Down,
                    spacing: 20,
                    align: { x: 0.5, y: 0.5 },

                    <Label> {
                        draw_text: {
                            text_style: { font_size: 24.0 }
                        }
                        text: "Hello, Makepad!"
                    }

                    button1 = <Button> {
                        text: "Click me"
                    }

                    counter_label = <Label> {
                        text: "Count: 0"
                    }
                }
            }
        }
    }
}

app_main!(App);

#[derive(Live, LiveHook)]
pub struct App {
    #[live] ui: WidgetRef,
    #[rust] counter: usize,
}

impl LiveRegister for App {
    fn live_register(cx: &mut Cx) {
        crate::makepad_widgets::live_design(cx);
    }
}

impl MatchEvent for App {
    fn handle_startup(&mut self, _cx: &mut Cx) {
        // Initialize app state here
    }

    fn handle_actions(&mut self, cx: &mut Cx, actions: &Actions) {
        if self.ui.button(ids!(button1)).clicked(&actions) {
            self.counter += 1;
            self.ui.label(ids!(counter_label))
                .set_text(cx, &format!("Count: {}", self.counter));
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

### .gitignore

```
/target
.DS_Store
*.swp
*.swo
.idea/
.vscode/
```

### rust-toolchain.toml

```toml
[toolchain]
channel = "stable"
```

## Production App Template

### Directory Structure

```
my_app/
├── Cargo.toml
├── src/
│   ├── main.rs
│   ├── lib.rs
│   ├── app.rs
│   ├── home/
│   │   ├── mod.rs
│   │   └── home_screen.rs
│   └── shared/
│       ├── mod.rs
│       ├── styles.rs
│       └── widgets.rs
├── resources/
│   └── icons/
├── .gitignore
├── rust-toolchain.toml
└── rustfmt.toml
```

### Cargo.toml (Production)

```toml
[package]
name = "my-app"
version = "0.1.0"
edition = "2021"
description = "A cross-platform Makepad application"
license = "MIT"
authors = ["Your Name <your@email.com>"]
repository = "https://github.com/yourusername/my-app"

[dependencies]
makepad-widgets = { git = "https://github.com/makepad/makepad", branch = "rik" }

# Cross-platform utilities (optional)
# robius-use-makepad = "0.1.1"
# robius-directories = { git = "https://github.com/project-robius/robius" }

# Common dependencies
anyhow = "1.0"
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"

[features]
default = []

[profile.release]
opt-level = 3

[profile.release-lto]
inherits = "release"
lto = "thin"

[lints.clippy]
too_many_arguments = "allow"
```

### src/lib.rs (Production)

```rust
pub use makepad_widgets;

pub mod app;
pub mod home;
pub mod shared;
```

### src/app.rs (Production)

```rust
use makepad_widgets::*;

use crate::shared::styles::*;

live_design! {
    use link::theme::*;
    use link::shaders::*;
    use link::widgets::*;

    use crate::shared::styles::*;
    use crate::home::home_screen::HomeScreen;

    App = {{App}} {
        ui: <Root> {
            main_window = <Window> {
                window: { title: "My App" }
                body = <View> {
                    width: Fill, height: Fill
                    show_bg: true
                    draw_bg: { color: (COLOR_BG) }

                    <HomeScreen> {}
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
        crate::shared::live_design(cx);
        crate::home::live_design(cx);
    }
}

impl MatchEvent for App {
    fn handle_startup(&mut self, _cx: &mut Cx) {
        // Initialize app state
    }

    fn handle_actions(&mut self, cx: &mut Cx, actions: &Actions) {
        // Handle global actions
        let _ = (cx, actions);
    }
}

impl AppMain for App {
    fn handle_event(&mut self, cx: &mut Cx, event: &Event) {
        self.match_event(cx, event);
        self.ui.handle_event(cx, event, &mut Scope::empty());
    }
}
```

### src/shared/mod.rs

```rust
use makepad_widgets::Cx;

pub mod styles;
pub mod widgets;

pub fn live_design(cx: &mut Cx) {
    self::styles::live_design(cx);
    self::widgets::live_design(cx);
}
```

### src/shared/styles.rs

```rust
use makepad_widgets::*;

live_design! {
    // Color palette
    pub COLOR_BG = #1a1a2e
    pub COLOR_BG_LIGHT = #16213e
    pub COLOR_PRIMARY = #0f3460
    pub COLOR_ACCENT = #e94560
    pub COLOR_TEXT = #eaeaea
    pub COLOR_TEXT_DIM = #888888

    // Spacing
    pub SPACING_SM = 8.0
    pub SPACING_MD = 16.0
    pub SPACING_LG = 24.0

    // Border radius
    pub RADIUS_SM = 4.0
    pub RADIUS_MD = 8.0
    pub RADIUS_LG = 16.0

    // Common text styles
    pub TextRegular = <Label> {
        draw_text: {
            text_style: { font_size: 14.0 }
            color: (COLOR_TEXT)
        }
    }

    pub TextTitle = <Label> {
        draw_text: {
            text_style: { font_size: 24.0, font: {path: dep("crate://makepad-widgets/resources/IBMPlexSans-SemiBold.ttf")} }
            color: (COLOR_TEXT)
        }
    }

    pub TextSubtitle = <Label> {
        draw_text: {
            text_style: { font_size: 18.0 }
            color: (COLOR_TEXT_DIM)
        }
    }

    // Common button style
    pub PrimaryButton = <Button> {
        draw_bg: {
            color: (COLOR_ACCENT)
            radius: (RADIUS_SM)
        }
        draw_text: {
            color: #ffffff
        }
    }
}
```

### src/shared/widgets.rs

```rust
use makepad_widgets::*;

live_design! {
    use link::theme::*;
    use link::widgets::*;
    use crate::shared::styles::*;

    // Card container
    pub Card = <RoundedView> {
        width: Fill, height: Fit
        padding: (SPACING_MD)
        show_bg: true
        draw_bg: {
            color: (COLOR_BG_LIGHT)
            radius: (RADIUS_MD)
        }
    }

    // Horizontal divider
    pub Divider = <View> {
        width: Fill, height: 1
        show_bg: true
        draw_bg: { color: (COLOR_TEXT_DIM) }
    }

    // Icon button
    pub IconButton = <Button> {
        width: 40, height: 40
        draw_bg: {
            color: transparent
            radius: 20.0
        }
    }
}
```

### src/home/mod.rs

```rust
use makepad_widgets::Cx;

pub mod home_screen;

pub fn live_design(cx: &mut Cx) {
    self::home_screen::live_design(cx);
}
```

### src/home/home_screen.rs

```rust
use makepad_widgets::*;

live_design! {
    use link::theme::*;
    use link::shaders::*;
    use link::widgets::*;

    use crate::shared::styles::*;
    use crate::shared::widgets::*;

    pub HomeScreen = {{HomeScreen}} {
        width: Fill, height: Fill
        flow: Down
        spacing: (SPACING_LG)
        padding: (SPACING_LG)
        align: { x: 0.5, y: 0.0 }

        <TextTitle> { text: "Welcome" }
        <TextSubtitle> { text: "Your Makepad App" }

        <Card> {
            flow: Down
            spacing: (SPACING_MD)

            <TextRegular> { text: "This is a card component" }

            action_button = <PrimaryButton> {
                text: "Get Started"
            }
        }

        <Divider> {}

        <TextRegular> {
            text: "Built with Makepad"
            draw_text: { color: (COLOR_TEXT_DIM) }
        }
    }
}

#[derive(Live, LiveHook, Widget)]
pub struct HomeScreen {
    #[deref] view: View,
}

impl Widget for HomeScreen {
    fn handle_event(&mut self, cx: &mut Cx, event: &Event, scope: &mut Scope) {
        self.view.handle_event(cx, event, scope);
        self.widget_match_event(cx, event, scope);
    }

    fn draw_walk(&mut self, cx: &mut Cx2d, scope: &mut Scope, walk: Walk) -> DrawStep {
        self.view.draw_walk(cx, scope, walk)
    }
}

impl WidgetMatchEvent for HomeScreen {
    fn handle_actions(&mut self, cx: &mut Cx, actions: &Actions, _scope: &mut Scope) {
        if self.view.button(ids!(action_button)).clicked(&actions) {
            log!("Button clicked!");
            // Handle action
        }
        let _ = cx;
    }
}
```

### rustfmt.toml

```toml
max_width = 100
tab_spaces = 4
edition = "2021"
```

## Running the App

### Desktop

```bash
cargo run --release
```

### Mobile (requires cargo-makepad)

```bash
# Install cargo-makepad
cargo install --force --git https://github.com/makepad/makepad.git --branch rik cargo-makepad

# Android
cargo makepad android run -p my-app --release

# iOS Simulator
cargo makepad apple ios run-sim -p my-app --release
```

## Adding Features

### Adding a New Screen

1. Create `src/screens/new_screen.rs`
2. Add `pub mod new_screen;` to `src/screens/mod.rs`
3. Call `self::new_screen::live_design(cx);` in mod.rs `live_design()`
4. Import and use in parent widget

### Adding Resources

```rust
live_design! {
    // Import image
    IMG_LOGO = dep("crate://self/resources/logo.png")

    // Use in widget
    <Image> {
        source: (IMG_LOGO)
        width: 100, height: 100
    }
}
```

### Adding Custom Fonts

```rust
live_design! {
    FONT_CUSTOM = dep("crate://self/resources/fonts/CustomFont.ttf")

    <Label> {
        draw_text: {
            text_style: {
                font: { path: (FONT_CUSTOM) }
                font_size: 16.0
            }
        }
    }
}
```

## Project Checklist

When initializing a new project, ensure:

- [ ] `Cargo.toml` has correct package metadata
- [ ] `makepad-widgets` dependency uses correct branch (`rik` or `dev`)
- [ ] `lib.rs` re-exports `makepad_widgets`
- [ ] `main.rs` calls `app::app_main()`
- [ ] `LiveRegister` registers all module's `live_design(cx)`
- [ ] `.gitignore` excludes `/target` and IDE files
- [ ] `rust-toolchain.toml` specifies stable channel

## References

- [Makepad Examples](https://github.com/makepad/makepad/tree/main/examples)
- [Robrix](https://github.com/project-robius/robrix) - Production reference
- [Moly](https://github.com/moxin-org/moly) - Production reference
