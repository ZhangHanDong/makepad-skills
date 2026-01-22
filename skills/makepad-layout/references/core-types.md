# Makepad Layout Core Types Reference

## Walk

The `Walk` type controls how a widget positions itself within its parent.

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `width` | Size | Desired width |
| `height` | Size | Desired height |
| `margin` | Margin | Space around the widget |

### Usage in DSL

```rust
<View> {
    // Walk properties are flattened onto widgets
    width: 200.0
    height: 100.0
    margin: { top: 10.0, right: 10.0, bottom: 10.0, left: 10.0 }
}
```

### Common Walk Patterns

```rust
// Widget type overrides
body_walk: {
    width: Fill
    height: Fill
    margin: 0.0
}

icon_walk: {
    width: 24.0
    height: 24.0
    margin: { right: 8.0 }
}

label_walk: {
    width: Fit
    height: Fit
    margin: 0.0
}
```

## Layout

The `Layout` type controls how a container arranges its children.

### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `flow` | Flow | Down | Direction of child layout |
| `spacing` | f64 | 0.0 | Gap between children |
| `align` | Align | {0,0} | Child alignment |
| `padding` | Padding | 0 | Inner spacing |
| `clip_x` | bool | false | Clip horizontal overflow |
| `clip_y` | bool | false | Clip vertical overflow |

### Usage

```rust
<View> {
    // Layout properties on container
    flow: Right
    spacing: 10.0
    align: { x: 0.5, y: 0.5 }
    padding: { top: 16.0, right: 16.0, bottom: 16.0, left: 16.0 }
}
```

## Size

The `Size` enum determines how dimensions are calculated.

### Variants

| Variant | Description |
|---------|-------------|
| `Fit` | Size to fit children/content |
| `Fill` | Fill available space |
| `Fixed(f64)` | Fixed pixel size |
| `All` | Fill in both passes (special) |

### Direct Values

In DSL, numeric values are converted to `Fixed`:

```rust
width: 100.0    // Same as Fixed(100.0)
height: Fit
```

## Align

Controls how children are positioned within container's inner rectangle.

### Structure

```rust
align: { x: 0.0, y: 0.0 }  // Top-left
align: { x: 0.5, y: 0.5 }  // Center
align: { x: 1.0, y: 1.0 }  // Bottom-right
```

### Value Meanings

- `x: 0.0` - Left edge
- `x: 0.5` - Horizontal center
- `x: 1.0` - Right edge
- `y: 0.0` - Top edge
- `y: 0.5` - Vertical center
- `y: 1.0` - Bottom edge

### Common Presets

```rust
// Center
align: { x: 0.5, y: 0.5 }

// Top-center
align: { x: 0.5, y: 0.0 }

// Vertical center, left
align: { x: 0.0, y: 0.5 }
```

## Margin

Space outside the widget's rectangle.

### Structure

```rust
// Individual sides
margin: { top: 10.0, right: 15.0, bottom: 10.0, left: 15.0 }

// Uniform all sides
margin: 10.0

// Partial (others default to 0)
margin: { top: 20.0, bottom: 20.0 }
```

## Padding

Space inside the widget's rectangle, between rectangle and inner content.

### Structure

```rust
// Individual sides
padding: { top: 16.0, right: 24.0, bottom: 16.0, left: 24.0 }

// Uniform all sides
padding: 16.0

// Partial
padding: { left: 10.0, right: 10.0 }
```

## Flow

Determines the direction children are laid out.

### Variants

| Variant | Description |
|---------|-------------|
| `Down` | Vertical, top to bottom |
| `Right` | Horizontal, left to right |
| `Overlay` | Stack on top of each other |

```rust
// Vertical list
<View> {
    flow: Down
    <Label> { text: "A" }
    <Label> { text: "B" }
}

// Horizontal row
<View> {
    flow: Right
    <Button> { text: "1" }
    <Button> { text: "2" }
}

// Layered/stacked
<View> {
    flow: Overlay
    <Image> { ... }    // Bottom layer
    <Label> { ... }    // Top layer
}
```

## Combining Types

### Complete Layout Example

```rust
<View> {
    // Walk (positioning self)
    width: Fill
    height: Fill
    margin: 0.0

    // Layout (positioning children)
    flow: Down
    spacing: 16.0
    padding: { top: 24.0, right: 24.0, bottom: 24.0, left: 24.0 }
    align: { x: 0.0, y: 0.0 }
    clip_y: true

    // Children
    <Label> {
        width: Fit
        height: Fit
        text: "Title"
    }

    <View> {
        width: Fill
        height: Fill
        // Nested layout...
    }
}
```
