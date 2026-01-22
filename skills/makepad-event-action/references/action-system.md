# Makepad Action System Reference

## Overview

Actions are Makepad's mechanism for child-to-parent communication. While events flow DOWN from parent to child, actions flow UP from child to parent.

## ActionTrait

```rust
/// Type-erased action trait
pub trait ActionTrait: 'static {
    fn debug_fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result;
}

/// Send-able action for cross-thread communication
pub type ActionSend = Box<dyn ActionTrait + Send>;

/// Local action (same thread)
pub type Action = Box<dyn ActionTrait>;
```

## Defining Actions

```rust
use makepad_widgets::*;

/// DefaultNone auto-derives Default returning None variant
#[derive(Clone, Debug, DefaultNone)]
pub enum ButtonAction {
    None,      // Must have None variant for DefaultNone
    Clicked,
    Pressed,
    Released,
}

/// Actions with data
#[derive(Clone, Debug, DefaultNone)]
pub enum TextInputAction {
    None,
    Changed(String),
    Returned(String),
    Escape,
    KeyFocus,
    KeyFocusLost,
}

/// Complex action example
#[derive(Clone, Debug, DefaultNone)]
pub enum ListAction {
    None,
    ItemSelected { index: usize, id: LiveId },
    ItemClicked { index: usize },
    ScrollChanged { offset: f64 },
}
```

## Emitting Actions

### From Main Thread

```rust
impl Widget for MyButton {
    fn handle_event(&mut self, cx: &mut Cx, event: &Event, scope: &mut Scope) {
        match event.hits(cx, self.area()) {
            Hit::FingerDown(_) => {
                // Emit action on main thread
                cx.action(ButtonAction::Pressed);
            }
            Hit::FingerUp(fe) => {
                if fe.is_over {
                    cx.action(ButtonAction::Clicked);
                }
                cx.action(ButtonAction::Released);
            }
            _ => {}
        }
    }
}
```

### From Any Thread (Thread-Safe)

```rust
// For async operations, network requests, etc.
std::thread::spawn(move || {
    let data = fetch_data();
    // Post action from background thread
    Cx::post_action(MyAction::DataLoaded(data));
});
```

## Capturing Actions

### Using capture_actions

```rust
fn handle_event(&mut self, cx: &mut Cx, event: &Event, scope: &mut Scope) {
    // Capture actions from child widgets
    let actions = cx.capture_actions(|cx| {
        self.view.handle_event(cx, event, scope);
    });

    // Process captured actions
    for action in actions.iter() {
        // Check action type
        if let Some(btn_action) = action.downcast_ref::<ButtonAction>() {
            match btn_action {
                ButtonAction::Clicked => {
                    // Handle click
                }
                _ => {}
            }
        }
    }
}
```

### Using Widget Ref Helpers

```rust
fn handle_event(&mut self, cx: &mut Cx, event: &Event, scope: &mut Scope) {
    let actions = cx.capture_actions(|cx| {
        self.view.handle_event(cx, event, scope);
    });

    // Convenient helper methods
    if self.button(id!(submit_btn)).clicked(&actions) {
        // Submit button was clicked
    }

    if let Some(text) = self.text_input(id!(name_input)).changed(&actions) {
        // Text changed to `text`
    }

    if let Some(text) = self.text_input(id!(name_input)).returned(&actions) {
        // Enter pressed, text is `text`
    }
}
```

## ActionsBuf

```rust
pub struct ActionsBuf {
    actions: Vec<(WidgetUid, Action)>,
}

impl ActionsBuf {
    /// Iterate over all actions
    pub fn iter(&self) -> impl Iterator<Item = &Action>;

    /// Find actions by widget UID
    pub fn find(&self, uid: WidgetUid) -> impl Iterator<Item = &Action>;

    /// Check if any action matches
    pub fn contains<T: ActionTrait>(&self) -> bool;
}
```

## Common Widget Action Helpers

### Button

```rust
impl ButtonRef {
    pub fn clicked(&self, actions: &ActionsBuf) -> bool;
    pub fn pressed(&self, actions: &ActionsBuf) -> bool;
    pub fn released(&self, actions: &ActionsBuf) -> bool;
}
```

### TextInput

```rust
impl TextInputRef {
    pub fn changed(&self, actions: &ActionsBuf) -> Option<String>;
    pub fn returned(&self, actions: &ActionsBuf) -> Option<String>;
    pub fn escaped(&self, actions: &ActionsBuf) -> bool;
}
```

### CheckBox

```rust
impl CheckBoxRef {
    pub fn changed(&self, actions: &ActionsBuf) -> Option<bool>;
}
```

### Slider

```rust
impl SliderRef {
    pub fn changed(&self, actions: &ActionsBuf) -> Option<f64>;
    pub fn released(&self, actions: &ActionsBuf) -> Option<f64>;
}
```

### DropDown

```rust
impl DropDownRef {
    pub fn selected(&self, actions: &ActionsBuf) -> Option<usize>;
}
```

## Patterns

### Action with Scope Data

```rust
fn handle_event(&mut self, cx: &mut Cx, event: &Event, scope: &mut Scope) {
    // Pass data down via scope
    scope.with(|scope| {
        scope.data = Some(&mut self.my_data);
        self.child.handle_event(cx, event, scope);
    });

    // Child can access scope.data
}
```

### Forwarding Actions

```rust
fn handle_event(&mut self, cx: &mut Cx, event: &Event, scope: &mut Scope) {
    // Forward events to children
    self.child.handle_event(cx, event, scope);

    // Don't capture - let actions bubble up
}
```

### Stopping Action Propagation

```rust
fn handle_event(&mut self, cx: &mut Cx, event: &Event, scope: &mut Scope) {
    // Capture and handle - don't let actions bubble up
    let actions = cx.capture_actions(|cx| {
        self.child.handle_event(cx, event, scope);
    });

    // Actions are consumed here, not propagated to parent
    self.process_actions(&actions);
}
```
