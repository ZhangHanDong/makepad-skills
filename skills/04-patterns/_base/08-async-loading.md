---
name: async-loading
author: robius
source: robrix
date: 2024-01-01
tags: [async, loading, spinner, data-fetch]
level: intermediate
---

# Pattern 8: Async Data Loading

Show loading state while fetching data asynchronously.

## Problem

You need to fetch data from an API or database without blocking the UI, showing a loading spinner while waiting.

## Solution

Show loading UI, spawn async task, update UI when data arrives via `Cx::post_action`.

## Implementation

```rust
#[derive(Debug)]
pub enum DataAction {
    Loading,
    Loaded(Vec<Item>),
    Error(String),
}

#[derive(Live)]
pub struct App {
    #[live] ui: WidgetRef,
    #[rust] store: Option<Store>,
    #[rust] loading: bool,
}

impl MatchEvent for App {
    fn handle_startup(&mut self, cx: &mut Cx) {
        // Show loading state
        self.ui.view(ids!(main_content)).set_visible(cx, false);
        self.ui.view(ids!(loading_spinner)).set_visible(cx, true);
        self.loading = true;

        // Spawn async task
        spawn(async move {
            match fetch_data().await {
                Ok(data) => Cx::post_action(DataAction::Loaded(data)),
                Err(e) => Cx::post_action(DataAction::Error(e.to_string())),
            }
        });
    }

    fn handle_actions(&mut self, cx: &mut Cx, actions: &Actions) {
        for action in actions {
            if let Some(data_action) = action.downcast_ref::<DataAction>() {
                match data_action {
                    DataAction::Loaded(data) => {
                        self.store = Some(Store::new(data.clone()));
                        self.loading = false;

                        self.ui.view(ids!(main_content)).set_visible(cx, true);
                        self.ui.view(ids!(loading_spinner)).set_visible(cx, false);
                        self.ui.redraw(cx);
                    }
                    DataAction::Error(err) => {
                        self.loading = false;
                        self.ui.view(ids!(loading_spinner)).set_visible(cx, false);
                        self.ui.view(ids!(error_view)).set_visible(cx, true);
                        self.ui.label(ids!(error_message)).set_text(cx, err);
                        self.ui.redraw(cx);
                    }
                    _ => {}
                }
            }
        }
    }
}
```

## live_design!

```rust
live_design! {
    App = {{App}} {
        ui: <Root> {
            <Window> {
                body = <View> {
                    flow: Overlay

                    main_content = <View> {
                        visible: false
                        // Your main content...
                    }

                    loading_spinner = <View> {
                        align: { x: 0.5, y: 0.5 }
                        <Spinner> { width: 48, height: 48 }
                        <Label> { text: "Loading..." }
                    }

                    error_view = <View> {
                        visible: false
                        align: { x: 0.5, y: 0.5 }
                        flow: Down

                        <Label> { text: "Error" }
                        error_message = <Label> { text: "" }
                        <Button> { text: "Retry" }
                    }
                }
            }
        }
    }
}
```

## When to Use

- Initial app data loading
- API requests
- Database queries
- File loading
