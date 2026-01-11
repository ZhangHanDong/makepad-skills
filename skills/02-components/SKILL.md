---
name: makepad-components
description: Quick reference for all Makepad built-in widgets with usage examples. Extracted from ui_zoo examples. Use when you need to know available widgets, their variants, and configuration options.
---

# Makepad Widget Gallery

Quick reference for Makepad built-in widgets. For complete examples, see [ui_zoo](https://github.com/makepad/makepad/tree/main/examples/ui_zoo).

## Quick Navigation

| Widget Type | Description |
|-------------|-------------|
| [Buttons](#buttons) | Button, ButtonGradient, ButtonIcon |
| [Text Input](#text-input) | TextInput variants |
| [Sliders](#sliders) | Slider, SliderRound, SliderMinimal |
| [Checkboxes](#checkboxes) | CheckBox, CheckBoxToggle |
| [Radio Buttons](#radio-buttons) | RadioButton groups |
| [Dropdowns](#dropdowns) | Dropdown menus |
| [Labels](#labels) | Label, H1-H4, P |
| [Icons & Images](#icons) | Icon, Image, RotatedImage |
| [Views & Containers](#views-and-containers) | RoundedView, ScrollView |
| [Lists](#portallist-virtual-list) | PortalList (virtual) |
| [Navigation](#pageflip) | PageFlip, Fold |

---

## Buttons

### Button Variants

```rust
live_design! {
    use link::theme::*;
    use link::widgets::*;

    // Standard Button
    <Button> { text: "Click me" }

    // Button with icon
    <Button> {
        draw_icon: {
            svg_file: dep("crate://self/resources/icon.svg")
            color: #fff
        }
        text: "With Icon"
    }

    // Disabled Button
    <Button> {
        text: "Disabled"
        animator: { disabled = { default: on } }
    }

    // Gradient Buttons
    <ButtonGradientX> { text: "Gradient X" }
    <ButtonGradientY> { text: "Gradient Y" }

    // Icon-only Button
    <ButtonIcon> {
        draw_icon: {
            svg_file: dep("crate://self/resources/icon.svg")
        }
    }
}
```

### Button Customization

```rust
<Button> {
    width: 120, height: 40
    padding: { left: 16, right: 16 }

    draw_bg: {
        color: #2196F3
        color_hover: #42A5F5
        color_down: #1976D2
        border_radius: 8.0
    }

    draw_text: {
        color: #fff
        text_style: { font_size: 14.0 }
    }

    text: "Custom Button"
}
```

---

## Text Input

### TextInput Variants

```rust
live_design! {
    // Standard TextInput
    <TextInput> { empty_text: "Enter text..." }

    // With initial value
    <TextInput> { text: "Initial value" }

    // Password input
    <TextInput> {
        is_password: true
        empty_text: "Password"
    }

    // Read-only
    <TextInput> {
        is_read_only: true
        text: "Cannot edit"
    }

    // Numeric only
    <TextInput> {
        is_numeric_only: true
        empty_text: "Numbers only"
    }

    // Disabled
    <TextInput> {
        empty_text: "Disabled"
        animator: { disabled = { default: on } }
    }

    // Flat style
    <TextInputFlat> { empty_text: "Flat style" }

    // Gradient styles
    <TextInputGradientX> { empty_text: "Gradient X" }
    <TextInputGradientY> { empty_text: "Gradient Y" }
}
```

### TextInput Customization

```rust
<TextInput> {
    width: Fill, height: 44
    padding: { left: 12, right: 12 }
    empty_text: "Custom input"

    draw_bg: {
        color: #f5f5f5
        color_focus: #fff
        border_radius: 8.0
        border_size: 1.0
        border_color: #ddd
        border_color_focus: #2196F3
    }

    draw_text: {
        color: #333
        color_empty: #999
        text_style: { font_size: 14.0 }
    }

    draw_cursor: {
        color: #2196F3
    }

    draw_selection: {
        color: #2196F344
    }
}
```

---

## Sliders

### Slider Variants

```rust
live_design! {
    // Standard Slider
    <Slider> { text: "Default", min: 0., max: 100. }

    // With step
    <Slider> { text: "Stepped", step: 10.0, min: 0., max: 100. }

    // With precision
    <Slider> { text: "Precision", precision: 2 }

    // Label alignment
    <Slider> { text: "Centered", label_align: { x: 0.5, y: 0. } }

    // Disabled
    <Slider> {
        text: "Disabled"
        animator: { disabled = { default: on } }
    }

    // Style variants
    <SliderFlat> { text: "Flat" }
    <SliderRound> { text: "Round" }
    <SliderMinimal> { text: "Minimal" }
    <SliderMinimalFlat> { text: "Minimal Flat" }
    <SliderGradientX> { text: "Gradient X" }
    <SliderGradientY> { text: "Gradient Y" }
}
```

---

## Checkboxes

### Checkbox Variants

```rust
live_design! {
    // Standard Checkbox
    <CheckBox> { text: "Accept terms" }

    // Checked by default
    <CheckBox> {
        text: "Checked"
        animator: { selected = { default: on } }
    }

    // Disabled
    <CheckBox> {
        text: "Disabled"
        animator: { disabled = { default: on } }
    }

    // Style variants
    <CheckBoxFlat> { text: "Flat style" }
    <CheckBoxGradientX> { text: "Gradient X" }
    <CheckBoxGradientY> { text: "Gradient Y" }

    // Toggle switch style
    <CheckBoxToggle> { text: "Toggle" }
}
```

---

## Radio Buttons

### RadioButton Usage

```rust
live_design! {
    // Radio button group
    <View> {
        flow: Down
        spacing: 8

        <RadioButton> { text: "Option A", radio_group: my_group }
        <RadioButton> { text: "Option B", radio_group: my_group }
        <RadioButton> { text: "Option C", radio_group: my_group }
    }

    // Selected by default
    <RadioButton> {
        text: "Selected"
        radio_group: my_group
        animator: { selected = { default: on } }
    }

    // Style variants
    <RadioButtonFlat> { text: "Flat", radio_group: flat_group }
    <RadioButtonGradientX> { text: "Gradient X", radio_group: gx_group }
    <RadioButtonGradientY> { text: "Gradient Y", radio_group: gy_group }
}
```

---

## Dropdowns

### Dropdown Usage

```rust
live_design! {
    <Dropdown> {
        width: 200

        labels: ["Option 1", "Option 2", "Option 3"]
        values: [opt1, opt2, opt3]

        // Or with items
        items: [
            { value: opt1, label: "First Option" }
            { value: opt2, label: "Second Option" }
            { value: opt3, label: "Third Option" }
        ]
    }

    // Style variants
    <DropdownFlat> { labels: ["A", "B", "C"] }
    <DropdownGradientX> { labels: ["A", "B", "C"] }
    <DropdownGradientY> { labels: ["A", "B", "C"] }
}
```

---

## Labels

### Label Variants

```rust
live_design! {
    // Standard Label
    <Label> { text: "Hello World" }

    // With text wrapping
    <Label> {
        width: 200
        draw_text: { wrap: Word }
        text: "This is a long text that will wrap"
    }

    // Ellipsis overflow
    <Label> {
        width: 100
        draw_text: { wrap: Ellipsis }
        text: "Very long text that gets truncated"
    }

    // Custom styling
    <Label> {
        draw_text: {
            color: #2196F3
            text_style: {
                font_size: 24.0
                font: { path: dep("crate://self/resources/font.ttf") }
            }
        }
        text: "Custom Label"
    }

    // Heading styles (from theme)
    <H1> { text: "Heading 1" }
    <H2> { text: "Heading 2" }
    <H3> { text: "Heading 3" }
    <H4> { text: "Heading 4" }
    <P> { text: "Paragraph" }
}
```

---

## Link Labels

```rust
live_design! {
    <LinkLabel> {
        text: "Click here"
        url: "https://example.com"
    }

    // Custom colors
    <LinkLabel> {
        draw_text: {
            color: #2196F3
            color_hover: #1976D2
        }
        text: "Custom link"
        url: "https://example.com"
    }
}
```

---

## Icons

```rust
live_design! {
    <Icon> {
        draw_icon: {
            svg_file: dep("crate://self/resources/icon.svg")
            color: #333
        }
        icon_walk: { width: 24, height: 24 }
    }

    // With gradient
    <Icon> {
        draw_icon: {
            svg_file: dep("crate://self/resources/icon.svg")
            gradient_fill_horizontal: 1.0
            color: #f00
            color_2: #00f
        }
    }
}
```

---

## Images

```rust
live_design! {
    // Standard Image
    <Image> {
        width: 200, height: 150
        source: dep("crate://self/resources/image.png")
    }

    // Fit modes
    <Image> {
        fit: Horizontal  // Fit width
        source: dep("crate://self/resources/image.png")
    }
    <Image> {
        fit: Vertical    // Fit height
        source: dep("crate://self/resources/image.png")
    }
    <Image> {
        fit: Smallest    // Fit smallest dimension
        source: dep("crate://self/resources/image.png")
    }

    // Rotated Image
    <RotatedImage> {
        source: dep("crate://self/resources/image.png")
        rotation: 0.5  // radians
    }

    // Image Blend
    <ImageBlend> {
        width: 200, height: 150
        source_1: dep("crate://self/resources/image1.png")
        source_2: dep("crate://self/resources/image2.png")
        blend: 0.5  // 0.0 = image1, 1.0 = image2
    }
}
```

---

## Views and Containers

### RoundedView

```rust
live_design! {
    <RoundedView> {
        width: 200, height: 100
        padding: 16

        draw_bg: {
            color: #fff
            border_radius: 8.0
        }

        <Label> { text: "Content" }
    }

    // With shadow
    <RoundedShadowView> {
        width: 200, height: 100
        draw_bg: {
            color: #fff
            border_radius: 8.0
            shadow_color: #00000033
            shadow_offset: vec2(0., 4.)
            shadow_radius: 8.0
        }
    }
}
```

### ScrollView

```rust
live_design! {
    <ScrollXYView> {
        width: Fill, height: 400

        // Scrollable content
        <View> {
            width: 800, height: 800
            // Large content...
        }
    }

    <ScrollXView> { /* Horizontal scroll only */ }
    <ScrollYView> { /* Vertical scroll only */ }
}
```

---

## PortalList (Virtual List)

For large lists with recycled items:

```rust
live_design! {
    <PortalList> {
        width: Fill, height: Fill

        Item = <View> {
            width: Fill, height: 60
            <Label> { text: "Item" }
        }
    }
}

// Rust - populate items
impl Widget for MyList {
    fn draw_walk(&mut self, cx: &mut Cx2d, scope: &mut Scope, walk: Walk) -> DrawStep {
        let portal_list = self.view.portal_list(id!(list));

        for i in 0..1000 {
            let item = portal_list.item(cx, id!(Item), i);
            item.label(id!(label)).set_text(cx, &format!("Item {}", i));
            item.draw_all(cx, &mut Scope::empty());
        }

        DrawStep::done()
    }
}
```

---

## PageFlip

Tab-style page switching:

```rust
live_design! {
    <PageFlip> {
        width: Fill, height: Fill
        active_page: page1

        page1 = <View> {
            <Label> { text: "Page 1 content" }
        }
        page2 = <View> {
            <Label> { text: "Page 2 content" }
        }
        page3 = <View> {
            <Label> { text: "Page 3 content" }
        }
    }
}

// Switch page
self.view.page_flip(id!(flip)).set_active_page(cx, id!(page2));
```

---

## Fold / Collapsible

```rust
live_design! {
    <FoldButton> {
        text: "Click to expand"
    }

    <FoldHeader> {
        header = <FoldButton> { text: "Section Title" }
        body = <View> {
            <Label> { text: "Collapsible content" }
        }
    }
}
```

---

## Spinners / Loading

```rust
live_design! {
    <Spinner> {
        width: 40, height: 40
    }

    // With custom animation
    <View> {
        width: 40, height: 40
        show_bg: true
        draw_bg: {
            instance rotation: 0.0
            // Custom spinner shader...
        }
        animator: {
            spin = {
                default: on,
                on = {
                    from: {all: Loop {duration: 1.0, end: 1.0}}
                    apply: { draw_bg: { rotation: [{time: 0., value: 0.}, {time: 1., value: 1.}] } }
                }
            }
        }
    }
}
```

---

## Rotary (Knob)

```rust
live_design! {
    <Rotary> {
        width: 60, height: 60
        min: 0.0
        max: 100.0
        text: "Volume"
    }

    // Variants
    <RotaryGradientX> { text: "Knob" }
    <RotaryGradientY> { text: "Knob" }
}
```

---

## Markdown / HTML

```rust
live_design! {
    // Markdown from file
    <Markdown> {
        body: dep("crate://self/resources/readme.md")
    }

    // Inline markdown
    <Markdown> {
        body: "# Title\n\nSome **bold** text"
    }

    // HTML
    <Html> {
        body: "<h1>Title</h1><p>Paragraph</p>"
    }
}
```

---

## FileTree

```rust
live_design! {
    <FileTree> {
        width: 250, height: Fill

        // Tree structure defined programmatically
    }
}

// Populate tree
fn populate_tree(&mut self, cx: &mut Cx) {
    let tree = self.view.file_tree(id!(tree));
    tree.set_folder_node(cx, live_id!(root), 0, "Root", false);
    tree.set_file_node(cx, live_id!(file1), live_id!(root), "file.rs");
    // ...
}
```

---

## Widget Properties Reference

### Common Properties

| Property | Values | Description |
|----------|--------|-------------|
| `width` | `Fill`, `Fit`, `100` | Widget width |
| `height` | `Fill`, `Fit`, `100` | Widget height |
| `padding` | `10`, `{left: 10, ...}` | Inner spacing |
| `margin` | `10`, `{top: 10, ...}` | Outer spacing |
| `flow` | `Down`, `Right`, `Overlay` | Child layout |
| `spacing` | `10` | Gap between children |
| `align` | `{x: 0.5, y: 0.5}` | Child alignment |
| `visible` | `true`, `false` | Show/hide |
| `cursor` | `Default`, `Hand`, `Text` | Mouse cursor |

### Animator States

| State | Usage |
|-------|-------|
| `disabled = { default: on }` | Disable widget |
| `selected = { default: on }` | Pre-select (checkbox, radio) |
| `hover`, `pressed`, `focus` | Interaction states |

---

## Resources

- [ui_zoo source](https://github.com/makepad/makepad/tree/main/examples/ui_zoo) - Complete widget showcase
- [Makepad widgets](https://github.com/makepad/makepad/tree/main/widgets) - Widget source code
