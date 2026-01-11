---
name: makepad-events
description: Makepad event handling, hit testing, action system, and ids! macro patterns.
---

# Event Handling

## App-Level Event Routing

```rust
impl MatchEvent for App {
    fn handle_startup(&mut self, cx: &mut Cx) {
        // Initialize on app start
    }

    fn handle_actions(&mut self, cx: &mut Cx, actions: &Actions) {
        // Handle button click
        if self.ui.button(ids!(my_button)).clicked(&actions) {
            self.counter += 1;
            self.ui.label(ids!(counter_label))
                .set_text(cx, &format!("{}", self.counter));
        }

        // Handle custom action
        for action in actions {
            if let MyWidgetAction::ValueChanged(val) = action.cast() {
                self.handle_value_change(cx, val);
            }
        }
    }

    fn handle_network_responses(&mut self, cx: &mut Cx, responses: &NetworkResponsesEvent) {
        for event in responses {
            match &event.response {
                NetworkResponse::HttpResponse(res) if res.status_code == 200 => {
                    let data: MyData = res.get_json_body().unwrap();
                    self.process_data(cx, data);
                }
                _ => {}
            }
        }
    }
}

impl AppMain for App {
    fn handle_event(&mut self, cx: &mut Cx, event: &Event) {
        self.match_event(cx, event);
        self.ui.handle_event(cx, event, &mut Scope::empty());
    }
}

app_main!(App);
```

## ids! Macro Patterns

```rust
// Single widget
self.ui.button(ids!(my_button))

// Nested path
self.ui.label(ids!(container.header.title))

// Multiple widgets (radio button set)
self.ui.radio_button_set(ids!(tab1, tab2, tab3))
```

## Hit Testing

```rust
match event.hits(cx, self.draw_bg.area()) {
    Hit::FingerDown(fe) => { /* mouse/touch down */ }
    Hit::FingerUp(fe) => { /* mouse/touch up */ }
    Hit::FingerMove(fe) => { /* drag */ }
    Hit::FingerHoverIn(_) => { /* hover enter */ }
    Hit::FingerHoverOut(_) => { /* hover leave */ }
    Hit::KeyDown(ke) => { /* key press */ }
    Hit::KeyUp(ke) => { /* key release */ }
    Hit::KeyFocus(_) => { /* gained keyboard focus */ }
    Hit::KeyFocusLost(_) => { /* lost keyboard focus */ }
    _ => {}
}
```

## Widget Event Handling

```rust
impl Widget for MyWidget {
    fn handle_event(&mut self, cx: &mut Cx, event: &Event, scope: &mut Scope) {
        // First delegate to child widgets
        self.view.handle_event(cx, event, scope);

        // Then handle widget-specific events
        self.widget_match_event(cx, event, scope);
    }
}

impl WidgetMatchEvent for MyWidget {
    fn handle_actions(&mut self, cx: &mut Cx, actions: &Actions, scope: &mut Scope) {
        // Handle actions from child widgets
        if self.view.button(ids!(action_button)).clicked(&actions) {
            log!("Button clicked!");
            // Emit action to parent
            cx.widget_action(self.widget_uid(), &scope.path,
                MyWidgetAction::Clicked);
        }
    }
}
```

## Custom Actions

### Define Action Type

```rust
#[derive(Clone, Debug, DefaultNone)]
pub enum MyWidgetAction {
    None,
    Clicked,
    ValueChanged(f64),
    ItemSelected { id: usize, name: String },
}
```

### Emit Actions

```rust
// From widget event handler
cx.widget_action(
    self.widget_uid(),
    &scope.path,
    MyWidgetAction::Clicked
);

// With data
cx.widget_action(
    self.widget_uid(),
    &scope.path,
    MyWidgetAction::ValueChanged(42.0)
);
```

### Handle Actions

```rust
impl MatchEvent for App {
    fn handle_actions(&mut self, cx: &mut Cx, actions: &Actions) {
        // Method 1: cast from widget action
        for action in actions {
            if let MyWidgetAction::Clicked = action.cast() {
                self.handle_click(cx);
            }
        }

        // Method 2: check specific widget
        if let Some(action) = self.ui.widget(id!(my_widget)).actions(actions) {
            match action.cast() {
                MyWidgetAction::ValueChanged(val) => {
                    self.value = val;
                }
                _ => {}
            }
        }
    }
}
```

## Common Button Patterns

```rust
impl MatchEvent for App {
    fn handle_actions(&mut self, cx: &mut Cx, actions: &Actions) {
        // Single button click
        if self.ui.button(id!(submit_btn)).clicked(&actions) {
            self.submit_form(cx);
        }

        // Button pressed state
        if self.ui.button(id!(hold_btn)).pressed(&actions) {
            self.on_hold(cx);
        }

        // Multiple buttons
        for (i, btn_id) in [id!(btn1), id!(btn2), id!(btn3)].iter().enumerate() {
            if self.ui.button(*btn_id).clicked(&actions) {
                self.handle_button(cx, i);
            }
        }
    }
}
```

## Radio Button Navigation

```rust
impl MatchEvent for App {
    fn handle_actions(&mut self, cx: &mut Cx, actions: &Actions) {
        let tabs = self.ui.radio_button_set(ids!(
            sidebar.home_tab,
            sidebar.settings_tab,
            sidebar.profile_tab
        ));

        if let Some(selected) = tabs.selected(cx, actions) {
            // Hide all pages
            self.ui.view(ids!(pages.home)).set_visible(cx, false);
            self.ui.view(ids!(pages.settings)).set_visible(cx, false);
            self.ui.view(ids!(pages.profile)).set_visible(cx, false);

            // Show selected
            match selected {
                0 => self.ui.view(ids!(pages.home)).set_visible(cx, true),
                1 => self.ui.view(ids!(pages.settings)).set_visible(cx, true),
                2 => self.ui.view(ids!(pages.profile)).set_visible(cx, true),
                _ => {}
            }
        }
    }
}
```

## Text Input Events

```rust
impl MatchEvent for App {
    fn handle_actions(&mut self, cx: &mut Cx, actions: &Actions) {
        // Text changed
        if let Some(text) = self.ui.text_input(id!(search_input)).changed(&actions) {
            self.search(cx, &text);
        }

        // Enter pressed
        if self.ui.text_input(id!(search_input)).returned(&actions).is_some() {
            self.execute_search(cx);
        }

        // Focus gained/lost
        if self.ui.text_input(id!(input)).focus(&actions) {
            self.show_keyboard(cx);
        }
        if self.ui.text_input(id!(input)).focus_lost(&actions) {
            self.hide_keyboard(cx);
        }
    }
}
```

## Signal Handling (Background Threads)

```rust
impl MatchEvent for App {
    fn handle_signal(&mut self, cx: &mut Cx) {
        // Called when SignalToUI::set_ui_signal() is triggered
        // Check shared state or receivers for data
        if let Some(receiver) = &self.data_receiver {
            while let Ok(data) = receiver.try_recv() {
                self.process_data(cx, data);
            }
        }
    }
}
```

## Keyboard Shortcuts

```rust
impl Widget for MyWidget {
    fn handle_event(&mut self, cx: &mut Cx, event: &Event, scope: &mut Scope) {
        match event.hits(cx, self.view.area()) {
            Hit::KeyDown(ke) => {
                match ke.key_code {
                    KeyCode::Escape => self.close(cx),
                    KeyCode::Return => self.submit(cx),
                    KeyCode::KeyS if ke.modifiers.control => self.save(cx),
                    KeyCode::KeyZ if ke.modifiers.control => self.undo(cx),
                    _ => {}
                }
            }
            _ => {}
        }
    }
}
```

## Event Propagation

```rust
impl Widget for MyWidget {
    fn handle_event(&mut self, cx: &mut Cx, event: &Event, scope: &mut Scope) {
        // Sweep lock prevents events from reaching widgets underneath
        cx.sweep_lock(self.view.area());

        // Handle events for this widget
        self.view.handle_event(cx, event, scope);

        // Unlock to allow events through
        cx.sweep_unlock(self.view.area());
    }
}
```
