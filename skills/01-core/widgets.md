---
name: makepad-widgets
description: Common Makepad widgets (Label, Button, TextInput, etc.) and custom widget creation patterns.
---

# Widgets

## Common Widgets

### Label

```rust
my_label = <Label> {
    width: Fit
    draw_text: {
        text_style: <THEME_FONT_REGULAR>{ font_size: 16.0 }
        color: #ffffff
    }
    text: "Hello World"
}
```

### Button

```rust
my_btn = <Button> {
    width: Fit
    height: 40
    padding: {left: 16, right: 16}
    text: "Submit"

    draw_bg: {
        color: #2196F3
        color_hover: #1976D2
        border_radius: 4.0
    }

    draw_text: {
        text_style: <THEME_FONT_BOLD>{ font_size: 14.0 }
        color: #ffffff
    }
}
```

### TextInput

```rust
my_input = <TextInput> {
    width: Fill
    height: Fit
    padding: {top: 12, bottom: 12, left: 10, right: 10}

    text: "Default value"

    draw_bg: {
        color: #1a1a1a
        border_radius: 4.0
    }

    draw_text: {
        text_style: <THEME_FONT_REGULAR>{ font_size: 18.0 }
        color: #00ff88
    }

    draw_cursor: {
        color: #00ff88
    }
}

// Handle input changes
if let Some(text) = self.ui.text_input(id!(my_input)).changed(&actions) {
    if let Ok(value) = text.parse::<f64>() {
        self.amount = value;
    }
}
```

### ScrollYView

```rust
<ScrollYView> {
    width: Fill
    height: Fill
    flow: Down
    spacing: 10

    // Scrollable content
    <View> { height: 100, show_bg: true, draw_bg: { color: #333 } }
    <View> { height: 100, show_bg: true, draw_bg: { color: #444 } }
    <View> { height: 100, show_bg: true, draw_bg: { color: #555 } }
}
```

### RoundedView

```rust
<RoundedView> {
    width: Fill
    height: Fit
    padding: 16

    draw_bg: {
        color: #1a1a26
        border_radius: 8.0
    }

    <Label> { text: "Card content" }
}
```

### Window

```rust
ui: <Window> {
    window: {
        title: "My App"
        inner_size: vec2(400, 600)
    }

    show_bg: true
    draw_bg: { color: #1a1a1a }

    body = <View> {
        // Window content
    }
}
```

## Widget Creation

### Basic Widget Pattern

```rust
#[derive(Live, LiveHook, Widget)]
pub struct MyWidget {
    #[deref] view: View,          // Delegate to parent
    #[live] some_prop: f64,       // DSL-configurable
    #[rust] internal_state: i32,  // Rust-only state
}

impl Widget for MyWidget {
    fn handle_event(&mut self, cx: &mut Cx, event: &Event, scope: &mut Scope) {
        self.view.handle_event(cx, event, scope);
    }

    fn draw_walk(&mut self, cx: &mut Cx2d, scope: &mut Scope, walk: Walk) -> DrawStep {
        self.view.draw_walk(cx, scope, walk)
    }
}
```

### Field Attributes

| Attribute | Purpose |
|-----------|---------|
| `#[live]` | DSL-configurable property |
| `#[rust]` | Rust-only state (not in DSL) |
| `#[deref]` | Delegate to inner widget |
| `#[animator]` | Animation state machine |
| `#[redraw]` | Triggers redraw on change |
| `#[walk]` | Layout positioning |
| `#[layout]` | Layout rules |

### Widget with Custom Actions

```rust
#[derive(Clone, Debug, DefaultNone)]
pub enum MyWidgetAction {
    Clicked,
    ValueChanged(f64),
    None,
}

impl Widget for MyWidget {
    fn handle_event(&mut self, cx: &mut Cx, event: &Event, scope: &mut Scope) {
        self.view.handle_event(cx, event, scope);

        match event.hits(cx, self.view.area()) {
            Hit::FingerDown(_) => {
                cx.widget_action(self.widget_uid(), &scope.path,
                    MyWidgetAction::Clicked);
            }
            Hit::FingerUp(fe) => {
                if fe.is_over {
                    cx.widget_action(self.widget_uid(), &scope.path,
                        MyWidgetAction::ValueChanged(1.0));
                }
            }
            _ => {}
        }
    }
}
```

## State Management

### Thread-Local State (UI Thread Only)

```rust
thread_local! {
    static APP_DATA: Rc<RefCell<AppData>> = Rc::new(RefCell::new(AppData::default()));
}

pub fn get_app_data(_cx: &mut Cx) -> Rc<RefCell<AppData>> {
    APP_DATA.with(Rc::clone)
}
```

### Scope-Based Data Passing

```rust
// Parent passes data
let mut scope = Scope::with_data(&mut self.store);
self.view.handle_event(cx, event, &mut scope);

// Child accesses data
fn handle_event(&mut self, cx: &mut Cx, event: &Event, scope: &mut Scope) {
    if let Some(store) = scope.data.get_mut::<Store>() {
        store.update_something();
    }
}
```

## Dynamic UI Updates

### Using apply_over

Update widget properties at runtime:

```rust
// Update text color
self.ui.label(id!(my_label)).apply_over(cx, live!{
    draw_text: { color: #ff0000 }
});

// Update background
self.ui.view(id!(my_view)).apply_over(cx, live!{
    show_bg: true
    draw_bg: { color: #ffffff }
});

// Update multiple properties
self.ui.button(id!(theme_btn)).apply_over(cx, live!{
    draw_text: { color: (accent_color) }
    draw_bg: { color: (bg_color) }
});

// Always redraw after updates
self.ui.redraw(cx);
```

### Using Variables in live!

```rust
let colors = self.current_theme.colors();

self.ui.label(id!(title)).apply_over(cx, live!{
    draw_text: { color: (colors.accent) }  // Use parentheses for variables
});

self.ui.view(id!(card)).apply_over(cx, live!{
    draw_bg: { color: (colors.bg_card) }
});
```

### Updating Text

```rust
// Always pass cx as first argument
label.set_text(cx, "New text");
label.redraw(cx);

// Update input text
input.set_text(cx, "1000");
```

## Timer

### Setup Timer

```rust
#[derive(Live, LiveHook)]
pub struct App {
    #[live] ui: WidgetRef,
    #[rust] refresh_timer: Timer,
    #[rust] countdown: i32,
}

impl MatchEvent for App {
    fn handle_startup(&mut self, cx: &mut Cx) {
        self.countdown = 30;
        self.refresh_timer = cx.start_interval(1.0);  // 1 second interval
    }

    fn handle_timer(&mut self, cx: &mut Cx, _event: &TimerEvent) {
        self.countdown -= 1;
        self.update_countdown_display(cx);

        if self.countdown <= 0 {
            self.countdown = 30;
            self.refresh_data(cx);
        }
    }
}
```

## Network Operations

### HTTP Requests

```rust
fn send_request(&self, cx: &mut Cx) {
    let request_id = live_id!(FetchData);
    let mut request = HttpRequest::new(url, HttpMethod::POST);
    request.set_header("Content-Type".to_string(), "application/json".to_string());
    request.set_json_body(&data);
    cx.http_request(request_id, request);
}
```

### Background Thread Communication

```rust
use makepad_widgets::SignalToUI;

// In background thread
std::thread::spawn(move || {
    let result = expensive_computation();
    cx.action(MyAction::ComputationDone(result));
    SignalToUI::set_ui_signal();  // Wake UI thread
});

// In UI thread (handle_actions)
for action in actions {
    if let Some(MyAction::ComputationDone(result)) = action.downcast_ref() {
        self.update_ui_with_result(cx, result);
    }
}
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Forgetting `live_design(cx)` call | Register in `LiveRegister::live_register` |
| Missing `#[deref]` on View | Add `#[deref] view: View` for delegation |
| Not calling `redraw(cx)` after state change | Always call `self.redraw(cx)` or `widget.redraw(cx)` |
| Using `action.cast()` for non-widget actions | Use `action.downcast_ref()` for background thread actions |
| Blocking UI thread with async | Use `SignalToUI::set_ui_signal()` from background threads |
