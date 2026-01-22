# Makepad Event Handling Reference

## Basic Event Handling Pattern

```rust
impl AppMain for App {
    fn handle_event(&mut self, cx: &mut Cx, event: &Event) {
        let actions = self.ui.handle_event(cx, event, &mut Scope::empty());

        // Handle button clicks
        if self.ui.button(id!(submit_btn)).clicked(&actions) {
            self.on_submit(cx);
        }

        // Handle text input changes
        if let Some(text) = self.ui.text_input(id!(name_input)).changed(&actions) {
            self.name = text;
        }

        // Handle checkbox toggle
        if self.ui.check_box(id!(agree_checkbox)).changed(&actions).is_some() {
            self.agreed = self.ui.check_box(id!(agree_checkbox)).selected(cx);
        }
    }
}
```

## Widget Action Methods

### Button

```rust
// Check if clicked
if self.ui.button(id!(my_btn)).clicked(&actions) {
    // Handle click
}

// Check if pressed (held down)
if self.ui.button(id!(my_btn)).pressed(&actions) {
    // Handle press
}

// Check if released
if self.ui.button(id!(my_btn)).released(&actions) {
    // Handle release
}
```

### TextInput

```rust
// Get changed text
if let Some(new_text) = self.ui.text_input(id!(input)).changed(&actions) {
    println!("Text changed to: {}", new_text);
}

// Get text programmatically
let current_text = self.ui.text_input(id!(input)).text();

// Set text programmatically
self.ui.text_input(id!(input)).set_text("New value");
```

### CheckBox / RadioButton

```rust
// Check if toggled
if self.ui.check_box(id!(checkbox)).changed(&actions).is_some() {
    let is_selected = self.ui.check_box(id!(checkbox)).selected(cx);
}
```

### Slider

```rust
// Get slider value change
if let Some(value) = self.ui.slider(id!(volume)).changed(&actions) {
    println!("Volume: {}", value);
}
```

### DropDown

```rust
// Check selection change
if let Some(index) = self.ui.drop_down(id!(dropdown)).selected(&actions) {
    println!("Selected index: {}", index);
}
```

## Accessing Widgets

### By ID

```rust
// Direct access
let label = self.ui.label(id!(my_label));
label.set_text("Hello");

// Nested access
let nested_btn = self.ui.view(id!(container)).button(id!(nested_btn));
```

### Widget Reference Types

| Widget | Access Method | Common Operations |
|--------|---------------|-------------------|
| `Label` | `.label(id!(...))` | `.set_text()` |
| `Button` | `.button(id!(...))` | `.clicked()`, `.pressed()` |
| `TextInput` | `.text_input(id!(...))` | `.text()`, `.set_text()`, `.changed()` |
| `CheckBox` | `.check_box(id!(...))` | `.selected()`, `.changed()` |
| `Slider` | `.slider(id!(...))` | `.changed()` |
| `DropDown` | `.drop_down(id!(...))` | `.selected()` |
| `View` | `.view(id!(...))` | `.redraw()` |
| `Image` | `.image(id!(...))` | `.set_texture()` |

## Triggering Redraws

```rust
// Redraw specific widget
self.ui.view(id!(my_view)).redraw(cx);

// Redraw entire UI
self.ui.redraw(cx);
```

## Custom Actions

```rust
// Define custom action
#[derive(Clone, Debug, DefaultNone)]
pub enum MyAction {
    None,
    DataLoaded(Vec<String>),
    Error(String),
}

// Dispatch action
cx.action(MyAction::DataLoaded(data));

// Handle in event loop
if let MyAction::DataLoaded(data) = event.action::<MyAction>() {
    self.data = data;
}
```
