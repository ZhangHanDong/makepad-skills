# Makepad Core Widgets Reference

## View

The fundamental container widget. All layout containers inherit from View.

### Basic Usage

```rust
<View> {
    width: Fill
    height: Fill
    flow: Down
    padding: 16.0
    spacing: 8.0

    // Children
}
```

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `width` | Size | Width |
| `height` | Size | Height |
| `flow` | Flow | Child layout direction |
| `padding` | Padding | Inner spacing |
| `margin` | Margin | Outer spacing |
| `spacing` | f64 | Gap between children |
| `align` | Align | Child alignment |
| `show_bg` | bool | Enable background |
| `visible` | bool | Visibility |
| `clip_x` | bool | Clip horizontal |
| `clip_y` | bool | Clip vertical |
| `draw_bg` | DrawQuad | Background shader |

### View Variants

#### SolidView
```rust
<SolidView> {
    width: Fill
    height: 100.0
    draw_bg: { color: #333333 }
}
```

#### RoundedView
```rust
<RoundedView> {
    width: 200.0
    height: 100.0
    draw_bg: {
        color: #444444
        border_radius: 12.0
        border_size: 1.0
        border_color: #666666
    }
}
```

#### RoundedShadowView
```rust
<RoundedShadowView> {
    width: 200.0
    height: 100.0
    draw_bg: {
        color: #FFFFFF
        border_radius: 8.0
        shadow_color: #00000033
        shadow_offset: { x: 0.0, y: 4.0 }
        shadow_radius: 8.0
    }
}
```

#### GradientXView / GradientYView
```rust
<GradientXView> {
    width: Fill
    height: 100.0
    draw_bg: {
        color: #FF0000
        color_2: #0000FF
    }
}
```

#### ScrollYView
```rust
<ScrollYView> {
    width: Fill
    height: Fill

    <View> {
        width: Fill
        height: Fit
        flow: Down
        // Scrollable content
    }
}
```

## Button

Interactive button widget.

### Basic Usage

```rust
<Button> {
    text: "Click Me"
}
```

### Full Configuration

```rust
<Button> {
    width: Fit
    height: Fit
    padding: { top: 10.0, right: 20.0, bottom: 10.0, left: 20.0 }
    text: "Submit"

    draw_bg: {
        color: #0066CC
        color_hover: #0088FF
        color_down: #004499
        color_disabled: #333333
        border_radius: 4.0
        border_size: 0.0
    }

    draw_text: {
        color: #FFFFFF
        color_hover: #FFFFFF
        color_down: #CCCCCC
        text_style: {
            font_size: 14.0
        }
    }

    draw_icon: {
        color: #FFFFFF
        svg_file: dep("crate://self/icons/arrow.svg")
    }
}
```

### Button States

- `hover` - Mouse over
- `down` - Being pressed
- `focus` - Has keyboard focus
- `disabled` - Not interactive

### Button Variants

| Widget | Description |
|--------|-------------|
| `ButtonFlat` | Minimal flat style |
| `ButtonFlatIcon` | Flat with icon |
| `ButtonFlatter` | No background |
| `ButtonGradientX` | Horizontal gradient |
| `ButtonGradientY` | Vertical gradient |
| `ButtonIcon` | With icon |

## Label

Text display widget.

### Basic Usage

```rust
<Label> {
    text: "Hello World"
}
```

### Full Configuration

```rust
<Label> {
    width: Fit
    height: Fit
    margin: { bottom: 8.0 }
    text: "Styled Label"

    draw_text: {
        color: #FFFFFF
        text_style: {
            font_size: 18.0
            font: dep("crate://self/fonts/Roboto.ttf")
            line_spacing: 1.5
        }
    }
}
```

## Image

Image display widget.

### Basic Usage

```rust
<Image> {
    source: dep("crate://self/resources/image.png")
}
```

### Full Configuration

```rust
<Image> {
    width: 300.0
    height: 200.0
    source: dep("crate://self/resources/photo.jpg")
    fit: Contain

    draw_bg: {
        // Additional shader properties
    }
}
```

### ImageFit Values

| Value | Behavior |
|-------|----------|
| `Stretch` | Fill area, may distort |
| `Contain` | Fit inside, letterbox |
| `Cover` | Fill area, may crop |
| `Fill` | Fill both dimensions |

## TextInput

Text entry field.

### Basic Usage

```rust
<TextInput> {
    width: Fill
    height: Fit
    text: "Enter text..."
}
```

### Full Configuration

```rust
<TextInput> {
    width: Fill
    height: 40.0
    padding: { left: 12.0, right: 12.0 }
    text: ""

    draw_bg: {
        color: #222222
        border_radius: 4.0
        border_size: 1.0
        border_color: #444444
    }

    draw_text: {
        color: #FFFFFF
        text_style: { font_size: 14.0 }
    }

    draw_selection: {
        color: #0066CC44
    }

    draw_cursor: {
        color: #0066CC
    }
}
```

## CheckBox

Toggle checkbox.

### Basic Usage

```rust
<CheckBox> {
    text: "Accept terms"
}
```

### Full Configuration

```rust
<CheckBox> {
    width: Fit
    height: Fit
    text: "Remember me"

    draw_check: {
        color: #0066CC
    }

    draw_text: {
        color: #FFFFFF
    }
}
```

## RadioButton

Radio selection button.

### Basic Usage

```rust
<View> {
    flow: Down

    <RadioButton> { text: "Option A" }
    <RadioButton> { text: "Option B" }
    <RadioButton> { text: "Option C" }
}
```

## Slider

Value slider.

### Basic Usage

```rust
<Slider> {
    width: Fill
    height: 30.0
    min: 0.0
    max: 100.0
    step: 1.0
}
```

## DropDown

Selection dropdown menu.

### Basic Usage

```rust
<DropDown> {
    width: 200.0
    height: 40.0
    labels: ["Option 1", "Option 2", "Option 3"]
}
```
