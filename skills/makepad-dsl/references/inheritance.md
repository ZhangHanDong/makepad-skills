# Makepad DSL Inheritance Reference

## Inheritance Model

Makepad uses **eager copy inheritance**, similar to prototypal inheritance in JavaScript but with immediate property copying.

### Key Principles

1. **Eager Copy**: When inheriting, all properties are immediately copied
2. **Override**: Any inherited property can be overridden
3. **Extend**: New properties can be added
4. **Partial Override**: Nested objects can be partially overridden

## Basic Inheritance

```rust
// Define a prototype
Base = {
    a: 1
    b: 2
    c: 3
}

// Inherit and override
Derived = <Base> {
    b: 20      // Override b
    d: 4       // Add new property d
}

// Result: Derived = { a: 1, b: 20, c: 3, d: 4 }
```

## Nested Object Inheritance

When overriding nested objects, only specified properties are overridden:

```rust
Parent = {
    style: {
        color: #FF0000
        size: 10.0
        weight: bold
    }
}

Child = <Parent> {
    style: {
        color: #00FF00  // Override only color
    }
}

// Result: Child.style = { color: #00FF00, size: 10.0, weight: bold }
```

## Widget Inheritance

### Inheriting Built-in Widgets

```rust
// Create custom button from Button
MyButton = <Button> {
    width: Fit
    height: 40.0
    text: "Default"

    draw_bg: {
        color: #444444
        border_radius: 8.0
    }
}

// Use it
<View> {
    <MyButton> { text: "OK" }
    <MyButton> { text: "Cancel" }
}
```

### Multi-level Inheritance

```rust
// Level 1: Base style
BaseCard = {
    width: Fill
    padding: 16.0
    margin: 8.0
}

// Level 2: Add background
ColoredCard = <BaseCard> {
    show_bg: true
    draw_bg: {
        color: #FFFFFF
        border_radius: 12.0
    }
}

// Level 3: Add shadow
ShadowCard = <ColoredCard> {
    draw_bg: {
        // Inherits color and border_radius
        shadow_color: #00000033
        shadow_offset: { x: 0.0, y: 2.0 }
    }
}
```

## Inheritance with Rust Linking

```rust
// Define widget prototype linked to Rust struct
CustomWidget = {{CustomWidget}} {
    width: 200.0
    height: 100.0
    custom_prop: 42.0
}

// Inherit in DSL
MyCustomWidget = <CustomWidget> {
    width: 300.0  // Override width
    // height and custom_prop inherited
}

// In Rust
#[derive(Live, LiveHook, Widget)]
pub struct CustomWidget {
    #[deref] view: View,
    #[live] custom_prop: f64,
}
```

## Composition vs Inheritance

### Inheritance (for styling/configuration)

```rust
// Inherit to modify appearance
StyledButton = <Button> {
    draw_bg: { color: #0066CC }
}
```

### Composition (for structure)

```rust
// Compose for layout
Card = <View> {
    flow: Down
    padding: 16.0

    header = <View> {
        <Label> { text: "Title" }
    }

    content = <View> {
        // Content goes here
    }
}
```

## Best Practices

1. **Create reusable prototypes** for consistent styling
2. **Use meaningful names** that describe the purpose
3. **Avoid deep inheritance chains** (max 3-4 levels)
4. **Override minimally** - only change what's needed
5. **Document inheritance chains** in comments when complex

```rust
// Good: Clear, purposeful prototypes
PrimaryButton = <Button> { draw_bg: { color: #0066CC } }
SecondaryButton = <Button> { draw_bg: { color: #666666 } }
DangerButton = <Button> { draw_bg: { color: #CC0000 } }

// Bad: Vague, overly generic
Button1 = <Button> { ... }
Button2 = <Button1> { ... }
Button3 = <Button2> { ... }
```
