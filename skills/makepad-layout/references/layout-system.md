# Makepad Layout System Reference

## The Turtle Model

Makepad's layout is based on a "turtle" metaphor:
- A turtle walks across the screen, placing elements
- The direction the turtle walks is determined by `flow`
- Each element reserves space based on its size
- The turtle adds `spacing` between each element

## Box Model

Every element has three conceptual rectangles:

```
Outer Rectangle (margin)
+----------------------------------+
|           margin.top             |
|  +----------------------------+  |
|  |       Rectangle            |  |
|  |  +----------------------+  |  |
|  |  |    padding.top       |  |  |
|  |  |  +----------------+  |  |  |
|  |  |  | Inner Rectangle|  |  |  |
|  |  |  | (content area) |  |  |  |
|  |  |  +----------------+  |  |  |
|  |  |    padding.bottom    |  |  |
|  |  +----------------------+  |  |
|  +----------------------------+  |
|           margin.bottom          |
+----------------------------------+
```

## Size Calculation

### Width/Height Values

```rust
// Fit: Size to content
width: Fit
height: Fit

// Fill: Take available space
width: Fill
height: Fill

// Fixed: Explicit pixel size
width: 200.0
height: 100.0

// Fixed with explicit enum
width: Fixed(200.0)
```

### Size Resolution

1. Fixed sizes are used directly
2. `Fit` calculates from children's sizes
3. `Fill` takes remaining space after fixed/fit elements

```rust
<View> {
    width: Fill    // Takes all horizontal space
    height: 300.0  // Fixed 300 pixels
    flow: Down

    // Fixed header
    <View> { width: Fill, height: 50.0 }

    // Flexible content takes remaining 250px
    <View> { width: Fill, height: Fill }
}
```

## Flow Directions

### Down (Default)

```rust
<View> {
    flow: Down  // or omit, it's default

    <Label> { text: "First" }   // Top
    <Label> { text: "Second" }  // Below first
    <Label> { text: "Third" }   // Below second
}
```

### Right

```rust
<View> {
    flow: Right

    <Label> { text: "First" }   // Left
    <Label> { text: "Second" }  // Right of first
    <Label> { text: "Third" }   // Right of second
}
```

### Overlay

```rust
<View> {
    flow: Overlay

    <Image> { ... }  // Background
    <Label> { ... }  // On top of image
}
```

## Spacing and Alignment

### Spacing

```rust
<View> {
    flow: Down
    spacing: 16.0  // 16px gap between each child

    <Label> { text: "A" }
    // 16px gap
    <Label> { text: "B" }
    // 16px gap
    <Label> { text: "C" }
}
```

### Alignment

Alignment positions children within the container's inner rectangle:

```rust
<View> {
    width: Fill
    height: 200.0
    align: { x: 0.5, y: 0.5 }  // Center

    <Label> { text: "Centered" }  // Appears at center
}
```

## Common Layout Patterns

### Header + Content + Footer

```rust
<View> {
    width: Fill
    height: Fill
    flow: Down

    // Header
    header = <View> {
        width: Fill
        height: 60.0
        show_bg: true
        draw_bg: { color: #333333 }
    }

    // Content (flexible)
    content = <View> {
        width: Fill
        height: Fill
    }

    // Footer
    footer = <View> {
        width: Fill
        height: 50.0
        show_bg: true
        draw_bg: { color: #333333 }
    }
}
```

### Sidebar Layout

```rust
<View> {
    width: Fill
    height: Fill
    flow: Right

    // Fixed sidebar
    sidebar = <View> {
        width: 250.0
        height: Fill
    }

    // Flexible main content
    main = <View> {
        width: Fill
        height: Fill
    }
}
```

### Grid-like Layout

```rust
<View> {
    width: Fill
    height: Fit
    flow: Right
    padding: 16.0
    spacing: 16.0

    <View> { width: 100.0, height: 100.0 }
    <View> { width: 100.0, height: 100.0 }
    <View> { width: 100.0, height: 100.0 }
    // Items wrap based on container width
}
```

### Spacer Pattern

```rust
<View> {
    width: Fill
    flow: Right
    padding: 16.0

    <Button> { text: "Left" }

    // Spacer pushes next element to right
    <View> { width: Fill }

    <Button> { text: "Right" }
}
```

## Scrolling

```rust
// Vertical scroll
<ScrollYView> {
    width: Fill
    height: Fill

    <View> {
        width: Fill
        height: Fit  // Important: Fit for scrollable content
        flow: Down

        // Many items...
    }
}

// Horizontal scroll
<ScrollXView> {
    // ...
}

// Both directions
<ScrollXYView> {
    // ...
}
```

## Clipping

```rust
<View> {
    width: 200.0
    height: 100.0
    clip_x: true  // Clip horizontal overflow
    clip_y: true  // Clip vertical overflow

    // Large content will be clipped
    <View> { width: 500.0, height: 300.0 }
}
```
