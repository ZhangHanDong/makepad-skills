---
name: makepad-core
description: Entry point for Makepad core concepts including layout, widgets, events, and styling. Start here to learn UI fundamentals.
---

# Makepad Core Concepts

This category covers the fundamental building blocks of Makepad UI development.

## Quick Navigation

| Topic | File | Use When |
|-------|------|----------|
| [Layout System](./layout.md) | Flow, sizing, spacing, alignment | Arranging UI elements |
| [Widgets](./widgets.md) | Common widgets, custom widgets | Building UI components |
| [Events](./events.md) | Event handling, hit testing, actions | Handling user interaction |
| [Styling](./styling.md) | Fonts, text styles, SVG icons | Styling text and graphics |

## Overview

Makepad is a Rust-based cross-platform UI framework using:
- `live_design!` macro for declarative UI layout
- Widget composition with `#[derive(Live, Widget)]`
- Event-driven architecture with typed Actions
- GPU-accelerated rendering

## Project Structure

```
my_app/
├── src/
│   ├── app.rs              # Main app entry, event routing
│   ├── lib.rs              # Module declarations, live_register
│   ├── home/               # Feature modules
│   │   ├── mod.rs
│   │   └── home_screen.rs
│   └── shared/             # Reusable widgets
│       ├── mod.rs
│       ├── styles.rs       # Theme, colors
│       └── widgets.rs
└── resources/              # Images, fonts
```

## live_design! Macro

The core of Makepad UI definition:

```rust
live_design! {
    use link::theme::*;
    use link::shaders::*;
    use link::widgets::*;

    App = {{App}} {
        ui: <Root> {
            main_window = <Window> {
                body = <View> {
                    flow: Down,
                    spacing: 10,
                    padding: 20,

                    my_button = <Button> {
                        text: "Click me"
                        draw_bg: { color: #4A90D9 }
                    }

                    <Label> { text: "Hello Makepad" }
                }
            }
        }
    }
}
```

### DSL Syntax Reference

| Syntax | Purpose | Example |
|--------|---------|---------|
| `<Widget>` | Instantiate widget | `<Button> { text: "OK" }` |
| `name = <Widget>` | Named reference | `my_btn = <Button> {}` |
| `{{StructName}}` | Link to Rust struct | `App = {{App}} {}` |
| `flow: Down/Right` | Layout direction | `flow: Down` |
| `width/height` | Sizing | `width: Fill, height: Fit` |
| `padding/margin` | Spacing | `padding: {left: 10, top: 5}` |
| `dep("crate://...")` | Resource path | `dep("crate://self/logo.png")` |

### Size Values

| Value | Meaning |
|-------|---------|
| `Fill` | Fill available space |
| `Fit` | Fit to content |
| `Fixed(100.0)` | Fixed size in pixels |
| `All` | Fill in all directions |

## Module Registration

```rust
// In lib.rs
impl LiveRegister for App {
    fn live_register(cx: &mut Cx) {
        makepad_widgets::live_design(cx);

        // Register your modules
        crate::shared::live_design(cx);
        crate::home::live_design(cx);

        // Link theme
        cx.link(live_id!(theme), live_id!(theme_desktop_dark));
    }
}

// In each module's mod.rs
pub fn live_design(cx: &mut Cx) {
    self::home_screen::live_design(cx);
    self::sidebar::live_design(cx);
}
```

## Next Steps

- [Layout System](./layout.md) - Learn how to arrange UI elements
- [Widgets](./widgets.md) - Build custom components
- [Events](./events.md) - Handle user interactions
- [Styling](./styling.md) - Style your UI with fonts and icons

## References

- [Makepad Repository](https://github.com/makepad/makepad)
- [Makepad Examples](https://github.com/makepad/makepad/tree/main/examples)
- [ui_zoo example](https://github.com/makepad/makepad/tree/main/examples/ui_zoo)
