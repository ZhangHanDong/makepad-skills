# Makepad DSL Syntax Reference

## Basic Syntax Elements

### Objects

Objects are the fundamental building blocks of the DSL.

```rust
// Anonymous object
{
    property1: value1
    property2: value2
}

// Named object (becomes a prototype)
MyObject = {
    property1: value1
    property2: value2
}
```

### Property Assignment

```rust
{
    // Numeric values
    width: 100.0
    height: 50
    opacity: 0.5

    // Colors (RGBA hex)
    color: #FF0000        // Red (RGB)
    color: #FF0000FF      // Red with alpha
    color: #F00           // Short form

    // Strings
    text: "Hello World"
    font: "Roboto"

    // Enums
    flow: Down
    align: Center
    fit: Contain

    // Size enum
    width: Fit            // Size to content
    width: Fill           // Fill available space
    width: 100.0          // Fixed size

    // Boolean-like (as float)
    show_bg: true         // Actually 1.0
    visible: false        // Actually 0.0

    // Nested objects
    padding: {
        top: 10.0
        right: 15.0
        bottom: 10.0
        left: 15.0
    }

    // Shorthand for uniform values
    margin: 10.0          // All sides

    // Arrays
    labels: ["Option 1", "Option 2", "Option 3"]
}
```

### Widget Instantiation

```rust
// Instantiate a widget
<Button> {
    text: "Click Me"
}

// Named widget instance (for reference in Rust)
my_button = <Button> {
    text: "Click Me"
}

// Nested widgets
<View> {
    <Label> { text: "Title" }
    <Button> { text: "OK" }
}
```

### Inheritance

```rust
// Define a prototype
BaseButton = {
    width: Fit
    height: 40.0
    padding: 10.0
    draw_bg: {
        color: #333333
        border_radius: 4.0
    }
}

// Inherit and override
PrimaryButton = <BaseButton> {
    draw_bg: {
        color: #0066CC  // Override color
        // border_radius is inherited as 4.0
    }
}

// Use in widget tree
<View> {
    <PrimaryButton> { text: "Submit" }
}
```

### Linking to Rust

```rust
// In live_design!
MyWidget = {{MyWidget}} {
    // DSL-editable properties
    width: 100.0
    custom_value: 42.0
}

// In Rust code
#[derive(Live, LiveHook, Widget)]
pub struct MyWidget {
    #[deref] view: View,           // Inherit from View
    #[live] width: f64,            // Synced with DSL
    #[live] custom_value: f64,     // Synced with DSL
    #[rust] internal_state: i32,   // Rust-only, not in DSL
}
```

### Resource Dependencies

```rust
{
    // Image from crate resources
    source: dep("crate://self/resources/image.png")

    // Icon SVG
    svg_file: dep("crate://self/icons/menu.svg")

    // Font
    font: dep("crate://self/fonts/Roboto.ttf")
}
```

### Comments

```rust
{
    // Single line comment
    width: 100.0

    /* Multi-line
       comment */
    height: 50.0
}
```

## Import Statements

```rust
live_design! {
    // Import theme definitions
    use link::theme::*;

    // Import shaders
    use link::shaders::*;

    // Import widget definitions
    use link::widgets::*;

    // Import from another module
    use crate::my_module::*;
}
```

## Special Syntax

### Draw Shaders

```rust
{
    draw_bg: {
        // Shader uniforms
        color: #FF0000
        border_radius: 4.0
        border_size: 1.0
        border_color: #000000

        // Shader code (optional override)
        fn pixel(self) -> vec4 {
            return self.color;
        }
    }
}
```

### Animator States

```rust
{
    animator: {
        hover = {
            default: off

            off = {
                from: { all: Forward { duration: 0.15 } }
                apply: { draw_bg: { color: #333333 } }
            }

            on = {
                from: { all: Forward { duration: 0.15 } }
                apply: { draw_bg: { color: #555555 } }
            }
        }
    }
}
```
