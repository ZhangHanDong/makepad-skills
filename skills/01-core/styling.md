---
name: makepad-styling
description: Makepad fonts, text styles, theme fonts, and SVG icon usage.
---

# Styling

## Fonts and Text Styles

**IMPORTANT**: Makepad does NOT use a `font:` property. Use `text_style:` with either inline properties or theme font inheritance.

### Font Syntax Options

```rust
live_design! {
    use link::theme::*;

    // Option 1: Inline text_style (simplest)
    <Label> {
        draw_text: {
            text_style: { font_size: 14.0 }
            color: #000
        }
    }

    // Option 2: Inherit from theme font (recommended)
    <Label> {
        draw_text: {
            text_style: <THEME_FONT_REGULAR>{ font_size: 14.0 }
            color: #000
        }
    }

    // Option 3: Theme font without size override
    <Label> {
        draw_text: {
            text_style: <THEME_FONT_BOLD>{}
            color: #000
        }
    }
}
```

### Theme Fonts (Built-in)

```rust
live_design! {
    use link::theme::*;  // Required import

    // Available theme fonts:
    // THEME_FONT_LABEL       - Default for labels
    // THEME_FONT_REGULAR     - Regular weight text
    // THEME_FONT_BOLD        - Bold weight
    // THEME_FONT_ITALIC      - Italic style
    // THEME_FONT_BOLD_ITALIC - Bold + Italic
    // THEME_FONT_CODE        - Monospace for code
}
```

### Correct vs Wrong Syntax

```rust
// ✅ CORRECT - inline text_style
draw_text: {
    text_style: { font_size: 14.0 }
    color: #000
}

// ✅ CORRECT - theme font inheritance
draw_text: {
    text_style: <THEME_FONT_BOLD>{ font_size: 14.0 }
    color: #000
}

// ❌ WRONG - font property doesn't exist
draw_text: {
    font: "path/to/font.ttf"  // Error: no matching field
    font_size: 14.0
}

// ❌ WRONG - font_size outside text_style
draw_text: {
    font_size: 14.0  // Error: no matching field
    color: #000
}
```

### Creating Reusable Text Styles

Define custom text styles for consistency (pattern from Robrix/Moly):

```rust
live_design! {
    use link::theme::*;

    // Define your app's text styles
    pub TITLE_TEXT = <THEME_FONT_BOLD>{
        font_size: 18.0
    }

    pub SUBTITLE_TEXT = <THEME_FONT_REGULAR>{
        font_size: 14.0
        line_spacing: 1.3
    }

    pub BODY_TEXT = <THEME_FONT_REGULAR>{
        font_size: 12.0
        line_spacing: 1.4
    }

    pub CAPTION_TEXT = <THEME_FONT_REGULAR>{
        font_size: 10.0
    }

    pub CODE_TEXT = <THEME_FONT_CODE>{
        font_size: 11.0
    }

    pub BUTTON_TEXT = <THEME_FONT_BOLD>{
        font_size: 13.0
    }
}
```

### Using Custom Text Styles

```rust
live_design! {
    use link::theme::*;
    use crate::shared::styles::*;  // Import your styles

    PageHeader = <View> {
        <Label> {
            draw_text: {
                text_style: <TITLE_TEXT>{}
                color: #000
            }
            text: "Page Title"
        }

        <Label> {
            draw_text: {
                text_style: <SUBTITLE_TEXT>{}
                color: #666
            }
            text: "Page subtitle"
        }
    }
}
```

### Font Size Override

Override font size while keeping the font family:

```rust
<Label> {
    draw_text: {
        // Base style with custom size
        text_style: <THEME_FONT_REGULAR>{ font_size: 20.0 }
        color: #333
    }
}

// Or with your custom style
<Label> {
    draw_text: {
        text_style: <BODY_TEXT>{ font_size: 16.0 }  // Override size
        color: #333
    }
}
```

### HTML Widget Font Configuration

For HTML content widgets, configure each style variant:

```rust
html_content = <Html> {
    font_size: 12.0  // Base size

    draw_normal:      { text_style: <THEME_FONT_REGULAR>{ font_size: 12.0 } }
    draw_italic:      { text_style: <THEME_FONT_ITALIC>{ font_size: 12.0 } }
    draw_bold:        { text_style: <THEME_FONT_BOLD>{ font_size: 12.0 } }
    draw_bold_italic: { text_style: <THEME_FONT_BOLD_ITALIC>{ font_size: 12.0 } }
    draw_fixed:       { text_style: <THEME_FONT_CODE>{ font_size: 11.0 } }
}
```

### Multi-Script Support

Theme fonts automatically support multiple scripts (Latin, Chinese, Emoji):

```rust
// No extra configuration needed - theme fonts handle:
// - Latin characters (IBMPlexSans)
// - Chinese characters (LXGWWenKai)
// - Emoji (NotoColorEmoji)

<Label> {
    draw_text: {
        text_style: <THEME_FONT_REGULAR>{ font_size: 14.0 }
        color: #000
    }
    text: "Hello 你好 👋"  // All rendered correctly
}
```

### Text Properties Reference

| Property | Location | Example |
|----------|----------|---------|
| `text_style` | `draw_text: {}` | `text_style: <THEME_FONT_REGULAR>{}` |
| `font_size` | Inside text_style | `{ font_size: 14.0 }` |
| `line_spacing` | Inside text_style | `{ line_spacing: 1.3 }` |
| `color` | `draw_text: {}` | `color: #333` |
| `wrap` | `draw_text: {}` | `wrap: Word`, `wrap: Ellipsis` |

### Complete Example

```rust
live_design! {
    use link::theme::*;
    use link::widgets::*;

    // Custom styles
    pub HEADER_TEXT = <THEME_FONT_BOLD>{ font_size: 24.0 }
    pub BODY_TEXT = <THEME_FONT_REGULAR>{ font_size: 14.0, line_spacing: 1.4 }

    // Widget using custom styles
    ArticleCard = <RoundedView> {
        padding: 16
        draw_bg: { color: #fff, border_radius: 8.0 }

        flow: Down
        spacing: 8

        title = <Label> {
            width: Fill
            draw_text: {
                text_style: <HEADER_TEXT>{}
                color: #111
                wrap: Word
            }
        }

        body = <Label> {
            width: Fill
            draw_text: {
                text_style: <BODY_TEXT>{}
                color: #444
                wrap: Word
            }
        }
    }
}
```

---

## SVG Icons

### Defining Icon Dependencies

In `shared/styles.rs`, define icons using `dep()`:

```rust
live_design! {
    use link::theme::*;
    use link::widgets::*;

    // Define icon dependencies
    pub ICON_ADD      = dep("crate://self/resources/icons/add.svg")
    pub ICON_CLOSE    = dep("crate://self/resources/icons/close.svg")
    pub ICON_SEARCH   = dep("crate://self/resources/icons/search.svg")
    pub ICON_SETTINGS = dep("crate://self/resources/icons/settings.svg")
    pub ICON_HOME     = dep("crate://self/resources/icons/home.svg")
    pub ICON_USER     = dep("crate://self/resources/icons/user.svg")
    pub ICON_SEND     = dep("crate://self/resources/icons/send.svg")
    pub ICON_EDIT     = dep("crate://self/resources/icons/edit.svg")
    pub ICON_TRASH    = dep("crate://self/resources/icons/trash.svg")
}
```

### SVG File Requirements

Makepad requires specific SVG format:

```xml
<!-- Correct: viewBox, path with fill -->
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M12 2L2 7l10 5 10-5-10-5z" fill="#000000"/>
</svg>
```

**Requirements:**
- Must have `viewBox` attribute
- Use `path` elements with `fill` attribute
- Avoid complex gradients, filters, or effects
- Keep icons simple (single color paths work best)
- Standard sizes: 16x16, 20x20, 24x24

### Using Icons in Widgets

```rust
live_design! {
    use crate::shared::styles::*;

    // Icon in a View
    <View> {
        <Icon> {
            draw_icon: {
                svg_file: (ICON_SEARCH)
                color: #666
            }
            icon_walk: { width: 20, height: 20 }
        }
    }

    // Icon in a Button
    <Button> {
        draw_icon: {
            svg_file: (ICON_ADD)
            color: #fff
        }
        icon_walk: { width: 16, height: 16 }
        text: "Add"
    }
}
```

### Icon with Dynamic Color (Hover/Press States)

```rust
live_design! {
    use crate::shared::styles::*;

    pub IconButton = <Button> {
        draw_icon: {
            svg_file: (ICON_SETTINGS)
            instance color: #666
            instance color_hover: #333
            fn get_color(self) -> vec4 {
                return mix(self.color, self.color_hover, self.hover)
            }
        }
        icon_walk: { width: 20, height: 20 }
        text: ""

        // Transparent background
        draw_bg: {
            fn pixel(self) -> vec4 {
                return vec4(0.0, 0.0, 0.0, 0.0)
            }
        }
    }
}
```

### Icon Button with Background

Pattern from Robrix:

```rust
live_design! {
    use crate::shared::styles::*;

    COLOR_PRIMARY = #f5f5f5
    COLOR_META = #888

    pub RobrixIconButton = <Button> {
        width: Fit
        height: Fit
        padding: 10
        align: { x: 0.5, y: 0.5 }

        draw_bg: {
            instance color: (COLOR_PRIMARY)
            instance color_hover: #ddd
            instance border_radius: 4.0

            fn get_color(self) -> vec4 {
                return mix(self.color, self.color_hover, self.hover)
            }

            fn pixel(self) -> vec4 {
                let sdf = Sdf2d::viewport(self.pos * self.rect_size)
                sdf.box(
                    0.0, 0.0,
                    self.rect_size.x,
                    self.rect_size.y,
                    self.border_radius
                )
                sdf.fill(self.get_color())
                return sdf.result
            }
        }

        draw_icon: {
            instance color: (COLOR_META)
            instance color_hover: #333
            fn get_color(self) -> vec4 {
                return mix(self.color, self.color_hover, self.hover)
            }
        }
        icon_walk: { width: 16, height: 16 }
        text: ""
    }
}
```

### Rotatable Icon

```rust
live_design! {
    use crate::shared::styles::*;

    pub IconRotated = <Icon> {
        draw_icon: {
            svg_file: (ICON_ARROW)
            // Rotation angle in radians
            instance rotation_angle: 0.0

            fn get_color(self) -> vec4 {
                return #666
            }
        }
        icon_walk: { width: 16, height: 16 }
    }
}
```

Rotate programmatically:

```rust
// Rotate icon 90 degrees (PI/2 radians)
self.ui.icon(id!(arrow_icon)).apply_over(cx, live! {
    draw_icon: { rotation_angle: 1.5708 }
});
self.ui.redraw(cx);
```

### Changing Icon Dynamically

```rust
impl MyWidget {
    fn update_icon(&mut self, cx: &mut Cx, is_favorite: bool) {
        let icon = if is_favorite {
            live!(svg_file: (ICON_HEART_FILLED))
        } else {
            live!(svg_file: (ICON_HEART_OUTLINE))
        };

        self.view.icon(id!(fav_icon)).apply_over(cx, icon);
        self.view.redraw(cx);
    }
}
```

### Icon Sizes Reference

| Use Case | Size | icon_walk |
|----------|------|-----------|
| Toolbar button | 16x16 | `{ width: 16, height: 16 }` |
| List item icon | 20x20 | `{ width: 20, height: 20 }` |
| Card action | 24x24 | `{ width: 24, height: 24 }` |
| Large button | 32x32 | `{ width: 32, height: 32 }` |
| Hero icon | 48x48 | `{ width: 48, height: 48 }` |

### Common Icon Mistakes

| Mistake | Fix |
|---------|-----|
| Icon not showing | Check SVG file path in `dep()` |
| Icon wrong color | Add `fn get_color()` in `draw_icon` |
| Icon not scaling | Set `icon_walk` with explicit size |
| Complex SVG broken | Simplify SVG to single-color paths |
| Icon blurry | Use integer sizes (16, 20, 24) |
