---
name: makepad-layout
description: Makepad layout system including flow direction, sizing, spacing, alignment, and common layout patterns.
---

# Layout System

## Flow Direction

Controls how children are arranged:

```rust
live_design! {
    // Vertical stack (default)
    <View> {
        flow: Down
        <Label> { text: "First" }
        <Label> { text: "Second" }
        <Label> { text: "Third" }
    }

    // Horizontal row
    <View> {
        flow: Right
        <Button> { text: "A" }
        <Button> { text: "B" }
        <Button> { text: "C" }
    }

    // Layered/stacked (z-order)
    <View> {
        flow: Overlay
        <Image> {}        // Bottom layer
        <GradientOverlay> {}  // Middle layer
        <Label> { text: "On top" }  // Top layer
    }

    // Horizontal with wrapping
    <View> {
        flow: RightWrap
        // Items wrap to next line when no space
        <Tag> { text: "Tag 1" }
        <Tag> { text: "Tag 2" }
        <Tag> { text: "Tag 3" }
    }
}
```

| Flow | Behavior |
|------|----------|
| `Down` | Vertical, top to bottom (default) |
| `Right` | Horizontal, left to right |
| `Overlay` | Stack children on top of each other |
| `RightWrap` | Horizontal with line wrapping |

## Size System (width/height)

```rust
live_design! {
    // Fill: Take all available space
    <View> { width: Fill, height: Fill }

    // Fit: Size to content
    <Label> { width: Fit, height: Fit, text: "Sized to text" }

    // Fixed: Exact pixels
    <View> { width: 200, height: 100 }

    // All: Fill in both dimensions (shorthand)
    <View> { width: All, height: All }  // Same as Fill, Fill

    // Percentage (relative to parent)
    <View> { width: 50%, height: 100 }

    // Mixed
    <View> {
        width: Fill    // Take remaining horizontal space
        height: Fit    // Size to content vertically
    }
}
```

| Size | Behavior |
|------|----------|
| `Fill` | Expand to fill available space |
| `Fit` | Shrink to fit content |
| `100` | Fixed pixel size |
| `50%` | Percentage of parent |
| `All` | Fill in this dimension |

## Spacing: padding, margin, spacing

```rust
live_design! {
    <View> {
        // padding: Space INSIDE the widget (between border and content)
        padding: 16                                    // All sides
        padding: { left: 10, right: 10 }               // Horizontal only
        padding: { top: 8, bottom: 8 }                 // Vertical only
        padding: { top: 10, bottom: 10, left: 16, right: 16 }  // All sides

        // margin: Space OUTSIDE the widget (between widgets)
        margin: 8
        margin: { top: 20 }
        margin: { left: 10, right: 10 }

        // spacing: Gap between children
        spacing: 10    // 10px between each child

        <Button> { text: "A" }  // 10px gap
        <Button> { text: "B" }  // 10px gap
        <Button> { text: "C" }
    }
}
```

| Property | Affects | Use Case |
|----------|---------|----------|
| `padding` | Inside widget | Content inset from edges |
| `margin` | Outside widget | Space between sibling widgets |
| `spacing` | Between children | Uniform gap in flow layout |

## Alignment

```rust
live_design! {
    // Align children within parent
    <View> {
        width: Fill, height: 100
        align: { x: 0.5, y: 0.5 }  // Center both axes

        <Label> { text: "Centered" }
    }

    // Horizontal alignment
    <View> {
        align: { x: 0.0 }  // Left (default)
        align: { x: 0.5 }  // Center
        align: { x: 1.0 }  // Right
    }

    // Vertical alignment
    <View> {
        align: { y: 0.0 }  // Top (default)
        align: { y: 0.5 }  // Middle
        align: { y: 1.0 }  // Bottom
    }

    // Common patterns
    <View> { align: { x: 0.5, y: 0.5 } }  // Center-center
    <View> { align: { x: 1.0, y: 0.0 } }  // Top-right
    <View> { align: { x: 0.0, y: 1.0 } }  // Bottom-left
}
```

## Common Layout Patterns

### Card Layout

```rust
live_design! {
    Card = <View> {
        width: Fill, height: Fit
        flow: Down
        padding: 16
        spacing: 12
        margin: { bottom: 12 }

        show_bg: true
        draw_bg: {
            color: #fff
            instance border_radius: 8.0
            fn pixel(self) -> vec4 {
                let sdf = Sdf2d::viewport(self.pos * self.rect_size)
                sdf.box(0., 0., self.rect_size.x, self.rect_size.y, self.border_radius)
                sdf.fill(self.color)
                return sdf.result
            }
        }

        // Card content
        title = <Label> { text: "Card Title" }
        body = <Label> { text: "Card content..." }
    }
}
```

### List Item (Row with Avatar)

Pattern from Robrix:

```rust
live_design! {
    ListItem = <View> {
        width: Fill, height: Fit
        flow: Right
        spacing: 12
        padding: 12
        align: { y: 0.5 }  // Vertically center children

        // Left: Avatar
        avatar = <Avatar> {
            width: 48, height: 48
        }

        // Middle: Text stack (fills remaining space)
        <View> {
            width: Fill, height: Fit
            flow: Down
            spacing: 4

            title = <Label> {
                width: Fill
                draw_text: { wrap: Ellipsis }
                text: "Title"
            }
            subtitle = <Label> {
                width: Fill
                draw_text: { color: #888 }
                text: "Subtitle"
            }
        }

        // Right: Timestamp or action
        timestamp = <Label> {
            width: Fit
            draw_text: { color: #aaa, text_style: { font_size: 10 } }
            text: "12:34"
        }
    }
}
```

### Form Layout

```rust
live_design! {
    FormField = <View> {
        width: Fill, height: Fit
        flow: Down
        spacing: 6
        margin: { bottom: 16 }

        label = <Label> {
            draw_text: { color: #666, text_style: { font_size: 12 } }
            text: "Field Label"
        }
        input = <TextInput> {
            width: Fill, height: 44
            padding: { left: 12, right: 12 }
        }
    }

    Form = <View> {
        width: Fill, height: Fit
        flow: Down
        padding: 20

        <FormField> { label = { text: "Email" } }
        <FormField> { label = { text: "Password" } }
        <Button> { text: "Submit", width: Fill }
    }
}
```

### Split View (Sidebar + Content)

```rust
live_design! {
    SplitView = <View> {
        width: Fill, height: Fill
        flow: Right

        // Fixed width sidebar
        sidebar = <View> {
            width: 280, height: Fill
            flow: Down
            padding: 16
            show_bg: true
            draw_bg: { color: #f5f5f5 }

            // Sidebar content
        }

        // Flexible content area
        content = <View> {
            width: Fill, height: Fill
            flow: Down
            padding: 20

            // Main content
        }
    }
}
```

### Header + Content + Footer

```rust
live_design! {
    PageLayout = <View> {
        width: Fill, height: Fill
        flow: Down

        // Fixed header
        header = <View> {
            width: Fill, height: 56
            padding: { left: 16, right: 16 }
            align: { y: 0.5 }
            show_bg: true
            draw_bg: { color: #fff }

            <Label> { text: "Header" }
        }

        // Scrollable content (fills remaining space)
        content = <View> {
            width: Fill, height: Fill
            flow: Down
            padding: 16

            // Content...
        }

        // Fixed footer
        footer = <View> {
            width: Fill, height: 60
            padding: 10
            show_bg: true
            draw_bg: { color: #f9f9f9 }

            <Button> { text: "Action", width: Fill }
        }
    }
}
```

### Centered Content

```rust
live_design! {
    CenteredView = <View> {
        width: Fill, height: Fill
        align: { x: 0.5, y: 0.5 }

        <View> {
            width: 400, height: Fit
            flow: Down
            padding: 32
            spacing: 16

            <Label> { text: "Centered Card" }
            <Button> { text: "Action" }
        }
    }
}
```

### Tag Cloud (RightWrap)

```rust
live_design! {
    TagCloud = <View> {
        width: Fill, height: Fit
        flow: RightWrap
        spacing: 8
        padding: 10

        <Tag> { text: "Rust" }
        <Tag> { text: "Makepad" }
        <Tag> { text: "UI" }
        <Tag> { text: "Cross-platform" }
        <Tag> { text: "GPU" }
    }

    Tag = <View> {
        width: Fit, height: Fit
        padding: { top: 4, bottom: 4, left: 8, right: 8 }
        show_bg: true
        draw_bg: { color: #e0e0e0, instance border_radius: 4.0 }

        <Label> { text: "Tag" }
    }
}
```

## Layout Debugging Tips

```rust
// Make layout visible with background color
<View> {
    show_bg: true
    draw_bg: { color: #ff000033 }  // Semi-transparent red
    // ... children
}

// Common issues:
// - height: Fill in flow: Down parent → each child takes all space
// - width: Fill with no parent width → collapses to 0
// - Missing spacing → children overlap
```
