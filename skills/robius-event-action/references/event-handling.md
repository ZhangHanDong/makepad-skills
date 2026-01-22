# Event Handling Reference

Detailed event handling patterns.

## Event Types

### System Events

```rust
fn handle_event(&mut self, cx: &mut Cx, event: &Event, scope: &mut Scope) {
    match event {
        Event::Startup => {
            // App just started
        }
        Event::Shutdown => {
            // App is closing, save state
        }
        Event::Signal => {
            // Background task signaled UI
            self.poll_updates(cx);
        }
        Event::WindowGeomChange(geom) => {
            // Window size/position changed
        }
        Event::WindowCloseRequested(_) => {
            // User clicked close button
        }
        _ => {}
    }
}
```

### Input Events

```rust
fn handle_event(&mut self, cx: &mut Cx, event: &Event, scope: &mut Scope) {
    match event {
        Event::KeyDown(ke) => {
            // Key pressed
            if ke.key_code == KeyCode::Return {
                // Enter key
            }
        }
        Event::KeyUp(ke) => {
            // Key released
        }
        Event::TextInput(ti) => {
            // Text was typed
            let text = &ti.input;
        }
        Event::TextCopy(tc) => {
            // Copy requested
            tc.response = Some(self.get_selected_text());
        }
        _ => {}
    }
}
```

### Hit Events

```rust
fn handle_event(&mut self, cx: &mut Cx, event: &Event, scope: &mut Scope) {
    let area = self.view.area();

    match event.hits(cx, area) {
        Hit::FingerDown(fe) => {
            // Touch/click started
            cx.set_key_focus(area);
            self.drag_start = Some(fe.abs);
        }
        Hit::FingerUp(fe) => {
            // Touch/click ended
            if fe.is_over && fe.is_primary_hit() {
                if fe.was_tap() {
                    // Quick tap
                }
                if fe.was_long_press() {
                    // Long press (context menu)
                }
            }
            self.drag_start = None;
        }
        Hit::FingerMove(fe) => {
            // Drag
            if let Some(start) = self.drag_start {
                let delta = fe.abs - start;
                self.handle_drag(cx, delta);
            }
        }
        Hit::FingerHoverIn(_) => {
            self.is_hovered = true;
            self.animator_play(cx, id!(hover.on));
        }
        Hit::FingerHoverOut(_) => {
            self.is_hovered = false;
            self.animator_play(cx, id!(hover.off));
        }
        Hit::FingerHoverOver(fe) => {
            // Continuous hover position
            self.hover_pos = fe.abs;
        }
        Hit::FingerScroll(se) => {
            // Scroll wheel
            self.scroll_offset += se.scroll;
        }
        Hit::FingerLongPress(lpe) => {
            // Long press detected (before finger up)
            self.show_context_menu(cx, lpe.abs);
        }
        Hit::Nothing => {
            // Event didn't hit this widget
        }
    }
}
```

## Focus Management

```rust
impl Widget for MyInput {
    fn handle_event(&mut self, cx: &mut Cx, event: &Event, scope: &mut Scope) {
        let area = self.view.area();

        match event.hits(cx, area) {
            Hit::FingerDown(_) => {
                // Take keyboard focus
                cx.set_key_focus(area);
            }
            _ => {}
        }

        // Check if we have focus
        if cx.has_key_focus(area) {
            if let Event::KeyDown(ke) = event {
                // Handle keyboard input
            }
        }
    }
}
```

## Event Bubbling Control

```rust
impl Widget for MyWidget {
    fn handle_event(&mut self, cx: &mut Cx, event: &Event, scope: &mut Scope) {
        // Forward to children first
        self.view.handle_event(cx, event, scope);

        // Then handle at this level
        // If you want to stop propagation, simply don't forward

        // For hit events, use captures
        let area = self.view.area();
        match event.hits(cx, area) {
            Hit::FingerDown(_) => {
                cx.set_key_focus(area);
                // Capture all future events until finger up
                cx.set_finger_capture(area);
            }
            _ => {}
        }
    }
}
```

## Timer Events

```rust
live_design! {
    MyWidget = {{MyWidget}} {
        animator: {
            tick = {
                default: on
                on = {
                    from: { all: Loop { duration: 1.0 } }
                    apply: { }  // Empty, just triggers redraw
                }
            }
        }
    }
}

impl Widget for MyWidget {
    fn handle_event(&mut self, cx: &mut Cx, event: &Event, scope: &mut Scope) {
        if self.animator_handle_event(cx, event).is_animating() {
            // Animation is running, update state
            self.update_animation(cx);
        }
    }
}
```

## Window Events

```rust
impl MatchEvent for App {
    fn handle_window_close_requested(&mut self, cx: &mut Cx, _ce: &WindowCloseRequestedEvent) {
        // Can prevent close
        // cx.prevent_default();

        // Or allow it
        // (do nothing)
    }

    fn handle_window_focus_change(&mut self, cx: &mut Cx, event: &WindowFocusChangeEvent) {
        if event.is_focused {
            // Window gained focus
        } else {
            // Window lost focus
        }
    }
}
```

## Drag and Drop

```rust
fn handle_event(&mut self, cx: &mut Cx, event: &Event, scope: &mut Scope) {
    match event {
        Event::DragEnter(de) => {
            self.show_drop_indicator(cx);
        }
        Event::DragLeave(_) => {
            self.hide_drop_indicator(cx);
        }
        Event::DragOver(de) => {
            self.update_drop_position(cx, de.abs);
        }
        Event::Drop(de) => {
            self.handle_drop(cx, &de.items);
        }
        _ => {}
    }
}
```
