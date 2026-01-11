---
name: global-registry
author: robius
source: robrix
date: 2024-01-01
tags: [global, registry, singleton, toast, notification]
level: intermediate
---

# Pattern 6: Global Widget Registry

Access widgets from anywhere in the app using `Cx::set_global`.

## Problem

You have app-wide widgets like toast notifications or tooltips that need to be triggered from deep in the widget tree.

## Solution

Use `Cx::set_global()` to register a widget reference, then access it from anywhere.

## Implementation

```rust
// In shared/popup.rs
pub fn set_global_popup(cx: &mut Cx, popup: PopupRef) {
    Cx::set_global(cx, popup);
}

pub fn get_global_popup(cx: &mut Cx) -> &mut PopupRef {
    cx.get_global::<PopupRef>()
}

pub fn show_notification(cx: &mut Cx, message: &str) {
    get_global_popup(cx).show(cx, message);
}

pub fn show_error(cx: &mut Cx, error: &str) {
    get_global_popup(cx).show_error(cx, error);
}
```

## Setup in App

```rust
impl MatchEvent for App {
    fn handle_startup(&mut self, cx: &mut Cx) {
        // Register global widgets
        set_global_popup(cx, self.ui.popup(ids!(global_popup)));
        set_global_tooltip(cx, self.ui.tooltip(ids!(global_tooltip)));
    }
}
```

## live_design!

```rust
live_design! {
    App = {{App}} {
        ui: <Root> {
            main_window = <Window> {
                body = <View> {
                    // Your app content...

                    // Global popup (rendered on top)
                    global_popup = <ToastPopup> {}
                    global_tooltip = <Tooltip> {}
                }
            }
        }
    }
}
```

## Usage from Anywhere

```rust
// In any widget, any depth
impl Widget for DeepNestedWidget {
    fn handle_event(&mut self, cx: &mut Cx, event: &Event, scope: &mut Scope) {
        if some_error_occurred {
            // Call global helper
            show_error(cx, "Something went wrong!");
        }

        if operation_succeeded {
            show_notification(cx, "Saved successfully!");
        }
    }
}
```

## When to Use

- Toast notifications
- Global tooltips
- Loading overlays
- Error displays
- Any UI that can be triggered from multiple places

## Caution

- Don't overuse - only for truly global UI elements
- Register in `handle_startup` before any usage
- Widget must exist in the view hierarchy
