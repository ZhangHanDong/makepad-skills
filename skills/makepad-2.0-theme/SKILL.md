---
name: makepad-2.0-theme
description: |
  CRITICAL: Use for Makepad 2.0 theme system. Triggers on:
  makepad theme, theme variable, theme color, theme font, theme spacing,
  dark mode, light mode, theme switching, mod.themes, theme_mod,
  theme.color_, theme.font_, theme.space_, theme.mspace_,
  主题, 颜色, 字体, 暗色模式, 亮色模式, 主题切换, 样式
---

# Makepad 2.0 Theme System

## Overview

The Makepad 2.0 theme system provides a comprehensive set of design tokens accessed
through `theme.*` variables in Splash scripts. It delivers consistent styling for
colors, typography, spacing, and widget states across your entire application.

Three built-in themes are available:
- `mod.themes.dark` -- dark desktop theme (default)
- `mod.themes.light` -- light desktop theme
- `mod.themes.skeleton` -- minimal skeleton theme with hardcoded values

**Golden rule**: Always use `theme.*` variables instead of hardcoded values for any
color, font size, or spacing in production UIs. This ensures your app automatically
supports theme switching and maintains visual consistency.

## Theme Setup in App::run

The theme must be loaded **before** widgets are loaded. The standard pattern is:

```rust
impl App {
    fn run(vm: &mut ScriptVm) -> Self {
        // Step 1: Load theme definitions (dark, light, skeleton)
        crate::makepad_widgets::theme_mod(vm);

        // Step 2: Select active theme (MUST come before widgets_mod)
        script_eval!(vm, {
            mod.theme = mod.themes.light  // or mod.themes.dark
        });

        // Step 3: Load widget definitions (they reference mod.theme)
        crate::makepad_widgets::widgets_mod(vm);

        // Step 4: Load your app's script_mod
        App::from_script_mod(vm, self::script_mod)
    }
}
```

If you skip steps 1-2, the default theme is dark (set inside `theme_mod`).
The counter example uses the simplified one-liner `crate::makepad_widgets::script_mod(vm)`
which bundles steps 1-3 with the default dark theme.

### How It Works Internally

`theme_mod()` does the following:
1. Calls `makepad_draw::script_mod(vm)` to load drawing primitives
2. Creates the `mod.themes` module
3. Loads `theme_desktop_dark`, `theme_desktop_light`, and `theme_desktop_skeleton`
4. Sets `mod.theme = mod.themes.dark` as the default

Then `widgets_mod()` creates `mod.prelude.widgets_internal` with `theme: mod.theme`,
making `theme.*` available in all widget scripts that `use mod.prelude.widgets.*`.

## Theme Global Parameters

Each theme defines tunable global parameters that control the overall feel:

| Parameter | Purpose | Default (dark/light) |
|-----------|---------|---------------------|
| `color_contrast` | Controls color palette spread | 1.0 |
| `color_tint` | Tint applied to backgrounds | `#0000ff` |
| `color_tint_amount` | How much tint to apply (0-1) | 0.0 |
| `space_factor` | Base spacing multiplier | 6.0 |
| `corner_radius` | Base corner radius | 2.5 |
| `beveling` | Bevel intensity | 0.75 |
| `font_size_base` | Base font size in px | 10.0 |
| `font_size_contrast` | Font size step between levels | 2.5 |

## Theme Color Variables -- Primary

These are the colors you will use most often in application code:

| Variable | Purpose | Light Appearance | Dark Appearance |
|----------|---------|-----------------|-----------------|
| `theme.color_bg_app` | App background | Light gray (~#DDD) | Dark gray (~#333) |
| `theme.color_fg_app` | Foreground layer | Slightly darker | Slightly lighter |
| `theme.color_bg_container` | Card/container bg | Semi-transparent light | Semi-transparent dark |
| `theme.color_bg_even` | Alternating row (even) | Lighter | Darker |
| `theme.color_bg_odd` | Alternating row (odd) | Darker | Lighter |
| `theme.color_bg_highlight` | Highlight background | White-ish `#FFFFFF22` | White-ish low opacity |
| `theme.color_bg_highlight_inline` | Inline highlight | `color_d_1` | `color_d_3` |
| `theme.color_bg_unfocussed` | Unfocused highlight | 85% of bg_highlight | 85% of bg_highlight |
| `theme.color_app_caption_bar` | Caption bar bg | Transparent | Transparent |
| `theme.color_white` | Pure white | `#FFFFFF` | `#FFFFFF` |
| `theme.color_makepad` | Makepad brand | `#FF5C39` | `#FF5C39` |

## Theme Color Variables -- Text and Labels

| Variable | Purpose |
|----------|---------|
| `theme.color_label_inner` | Primary text on inner elements (buttons, labels) |
| `theme.color_label_inner_hover` | Text on hover |
| `theme.color_label_inner_down` | Text when pressed |
| `theme.color_label_inner_focus` | Text when focused |
| `theme.color_label_inner_active` | Text when active/selected |
| `theme.color_label_inner_inactive` | Secondary/muted text |
| `theme.color_label_inner_disabled` | Disabled text |
| `theme.color_label_outer` | Primary text on outer elements (tabs, headers) |
| `theme.color_label_outer_off` | Outer text when off |
| `theme.color_label_outer_disabled` | Disabled outer text |
| `theme.color_text` | General text color |
| `theme.color_text_hover` | Text on hover |
| `theme.color_text_focus` | Text on focus |
| `theme.color_text_disabled` | Disabled text |
| `theme.color_text_placeholder` | Placeholder text |
| `theme.color_text_meta` | Metadata text |
| `theme.color_text_cursor` | Text cursor color |

## Theme Color Variables -- Widget States

Outset colors (buttons, raised elements):

| Variable | Purpose |
|----------|---------|
| `theme.color_outset` | Default button background |
| `theme.color_outset_hover` | Button on hover |
| `theme.color_outset_down` | Button when pressed |
| `theme.color_outset_active` | Active toggle state |
| `theme.color_outset_focus` | Focused button |
| `theme.color_outset_disabled` | Disabled button |
| `theme.color_outset_inactive` | Inactive button |

Inset colors (text inputs, checkboxes, radio buttons):

| Variable | Purpose |
|----------|---------|
| `theme.color_inset` | Default input background |
| `theme.color_inset_hover` | Input on hover |
| `theme.color_inset_focus` | Input on focus |
| `theme.color_inset_disabled` | Disabled input |
| `theme.color_inset_empty` | Empty input |

Selection and highlight:

| Variable | Purpose |
|----------|---------|
| `theme.color_selection_focus` | Text selection highlight |
| `theme.color_selection_hover` | Selection on hover |
| `theme.color_highlight` | General accent/highlight |
| `theme.color_cursor` | Cursor color |
| `theme.color_cursor_focus` | Focused cursor |

## Theme Color Variables -- Semantic/Status

| Variable | Purpose | Value |
|----------|---------|-------|
| `theme.color_error` | Error state | Red (`#C00`) |
| `theme.color_warning` | Warning state | Orange (`#FA0`) |
| `theme.color_high` | High severity | Red (`#C00`) |
| `theme.color_mid` | Medium severity | Orange (`#FA0`) |
| `theme.color_low` | Low severity | Yellow-green (`#8A0`) |
| `theme.color_panic` | Panic/critical | Magenta (`#f0f`) |

## Theme Color Variables -- Bevel System

The theme has a layered bevel system for 3D-like widget effects:

| Group | Variables | Purpose |
|-------|-----------|---------|
| `color_bevel*` | `_hover`, `_focus`, `_active`, `_down`, `_disabled` | Flat bevel |
| `color_bevel_inset_1*` | Same suffixes | Inner shadow (layer 1) |
| `color_bevel_inset_2*` | Same suffixes | Inner highlight (layer 2) |
| `color_bevel_outset_1*` | Same suffixes | Outer highlight (layer 1) |
| `color_bevel_outset_2*` | Same suffixes | Outer shadow (layer 2) |

## Theme Color Variables -- Additional Widget Colors

| Variable Group | Purpose |
|----------------|---------|
| `theme.color_icon*` | Icon colors (default, inactive, active, disabled) |
| `theme.color_mark*` | Checkmark/radio mark colors |
| `theme.color_val*` | Progress bar and slider fill colors |
| `theme.color_handle*` | Slider handle colors |
| `theme.color_shadow*` | Shadow effects |
| `theme.color_drag_quad` | Drag preview overlay |
| `theme.color_dock_tab_active` | Active dock tab background |

## Theme Font Variables

### Font Sizes

Font sizes are computed from `font_size_base` and `font_size_contrast`:

| Variable | Formula | Default Value |
|----------|---------|---------------|
| `theme.font_size_1` | base + 8 * contrast | 30.0 (largest heading) |
| `theme.font_size_2` | base + 4 * contrast | 20.0 (medium heading) |
| `theme.font_size_3` | base + 2 * contrast | 15.0 (small heading) |
| `theme.font_size_4` | base + 1 * contrast | 12.5 (subheading) |
| `theme.font_size_p` | base | 10.0 (body text) |
| `theme.font_size_code` | fixed | 9.0 (monospace code) |

### Font Styles (TextStyle objects)

| Variable | Description | Font File |
|----------|-------------|-----------|
| `theme.font_regular` | Regular weight body text | IBMPlexSans-Text.ttf |
| `theme.font_bold` | Bold/semibold text | IBMPlexSans-SemiBold.ttf |
| `theme.font_italic` | Italic text | IBMPlexSans-Italic.ttf |
| `theme.font_bold_italic` | Bold italic text | IBMPlexSans-BoldItalic.ttf |
| `theme.font_code` | Monospace code font | LiberationMono-Regular.ttf |
| `theme.font_label` | Label text (legacy) | IBMPlexSans-Text.ttf |
| `theme.font_icons` | Icon font (FontAwesome) | fa-solid-900.ttf |

Each font style includes multi-language support:
- Latin: IBM Plex Sans family
- Chinese: LXGW WenKai family
- Emoji: Noto Color Emoji

### Line Spacing Constants

| Variable | Value | Purpose |
|----------|-------|---------|
| `theme.font_wdgt_line_spacing` | 1.2 | Widget text |
| `theme.font_hl_line_spacing` | 1.05 | Heading text |
| `theme.font_longform_line_spacing` | 1.2 | Long-form text |

## Theme Spacing Variables

### Base Spacing

Spacing is derived from `space_factor` (default 6.0):

| Variable | Formula | Default Value |
|----------|---------|---------------|
| `theme.space_1` | 0.5 * space_factor | 3.0 (extra small) |
| `theme.space_2` | 1.0 * space_factor | 6.0 (small/standard) |
| `theme.space_3` | 1.5 * space_factor | 9.0 (medium) |

### Margin/Padding Presets (Inset objects)

All-sides presets:

| Variable | Description | Values |
|----------|-------------|--------|
| `theme.mspace_1` | XS padding all sides | 3px each |
| `theme.mspace_2` | SM padding all sides | 6px each |
| `theme.mspace_3` | MD padding all sides | 9px each |

Horizontal-only presets:

| Variable | Description | Values |
|----------|-------------|--------|
| `theme.mspace_h_1` | XS horizontal padding | left/right: 3px, top/bottom: 0 |
| `theme.mspace_h_2` | SM horizontal padding | left/right: 6px, top/bottom: 0 |
| `theme.mspace_h_3` | MD horizontal padding | left/right: 9px, top/bottom: 0 |

Vertical-only presets:

| Variable | Description | Values |
|----------|-------------|--------|
| `theme.mspace_v_1` | XS vertical padding | top/bottom: 3px, left/right: 0 |
| `theme.mspace_v_2` | SM vertical padding | top/bottom: 6px, left/right: 0 |
| `theme.mspace_v_3` | MD vertical padding | top/bottom: 9px, left/right: 0 |

### Dimension Variables

| Variable | Purpose | Default |
|----------|---------|---------|
| `theme.data_item_height` | Standard data row height | ~23px |
| `theme.data_icon_width` | Standard icon width | ~16px |
| `theme.data_icon_height` | Standard icon height | ~22px |
| `theme.container_corner_radius` | Container border radius | 5.0 |
| `theme.textselection_corner_radius` | Text selection radius | 1.25 |
| `theme.tab_height` | Tab bar height | 36.0 |

## Using Theme Variables in Splash

### Colors

```
// Background color
draw_bg.color: theme.color_bg_container

// Text color
draw_text.color: theme.color_label_inner

// Muted/secondary text
draw_text.color: theme.color_label_inner_inactive

// Color math -- multiply for opacity
draw_text.color: theme.color_label_inner_inactive * 0.8

// Semantic colors
draw_bg.color: theme.color_warning
draw_bg.color: theme.color_error
```

### Font Sizes

```
// Body text size
draw_text.text_style.font_size: theme.font_size_p

// Heading sizes
draw_text.text_style.font_size: theme.font_size_1   // Largest
draw_text.text_style.font_size: theme.font_size_2   // Medium
draw_text.text_style.font_size: theme.font_size_3   // Small
draw_text.text_style.font_size: theme.font_size_4   // Sub-heading

// Code font size
draw_text.text_style.font_size: theme.font_size_code
```

### Font Styles

```
// Bold text with custom size (override with {} syntax)
draw_text.text_style: theme.font_bold{font_size: theme.font_size_2}

// Bold text keeping default size
draw_text.text_style: theme.font_bold{}

// Code font
draw_text.text_style: theme.font_code{}

// Override font size using +: merge syntax
draw_text +: {text_style +: {font_size: theme.font_size_3}}
```

### Spacing

```
// Uniform padding
padding: theme.mspace_2

// Padding with overrides
padding: theme.mspace_2{left: theme.space_3, right: theme.space_3}

// Horizontal-only padding with custom values
padding: theme.mspace_h_1{left: theme.space_2, right: theme.space_2}

// Spacing between children
spacing: theme.space_2

// Computed spacing
width: Fill height: 9. * theme.space_1
padding: theme.mspace_3{left: theme.space_3 * 2, right: theme.space_3 * 2}
```

## Color Syntax Reference

Splash supports multiple color formats (not theme-specific but essential):

| Syntax | Example | Description |
|--------|---------|-------------|
| `#RGB` | `#f00` | Short hex (red) |
| `#RRGGBB` | `#ff0000` | Full hex |
| `#RRGGBBAA` | `#ff000080` | Hex with alpha |
| `#xRRGGBB` | `#x2ecc71` | Hex starting with `e` (prefix `#x`) |
| `#N` | `#D` | Grayscale shorthand |
| `vec4(r,g,b,a)` | `vec4(1.0, 0.0, 0.0, 1.0)` | RGBA float (0.0-1.0) |
| `theme.*` | `theme.color_highlight` | Theme variable |

**Important**: When a hex color starts with the letter `e`, use the `#x` prefix
to avoid ambiguity with scientific notation. For example, `#x2ecc71` not `#2ecc71`.

Color math is supported:
```
// Multiply for opacity
theme.color_label_inner_inactive * 0.8

// Mix two colors
mix(theme.color_w, theme.color_b, 0.5)
```

## Theme Switching at Runtime

You can switch themes dynamically in Rust event handlers:

```rust
impl MatchEvent for App {
    fn handle_actions(&mut self, cx: &mut Cx, actions: &Actions) {
        if self.ui.button(cx, ids!(toggle_theme)).clicked(actions) {
            script_eval!(cx, {
                mod.theme = mod.themes.dark  // or mod.themes.light
            });
            // All widgets using theme.* will pick up new values
            // You may need to trigger a re-render
        }
    }
}
```

Or switch before widgets load (in `App::run`) for a static theme choice:
```rust
fn run(vm: &mut ScriptVm) -> Self {
    crate::makepad_widgets::theme_mod(vm);
    script_eval!(vm, {
        mod.theme = mod.themes.light
    });
    crate::makepad_widgets::widgets_mod(vm);
    App::from_script_mod(vm, self::script_mod)
}
```

## Complete Theme-Aware UI Example

This example demonstrates a themed card list using only theme variables:

```
script_mod! {
    use mod.prelude.widgets.*

    let CardItem = RoundedView{
        width: Fill height: Fit
        padding: theme.mspace_2{left: theme.space_3, right: theme.space_3}
        flow: Right spacing: theme.space_2
        align: Align{y: 0.5}
        draw_bg.color: theme.color_bg_container
        draw_bg.border_radius: theme.container_corner_radius

        icon := Label{
            width: 24 height: 24
            text: ""
        }
        content := View{
            width: Fill height: Fit
            flow: Down spacing: theme.space_1
            title := Label{
                text: "Title"
                draw_text.color: theme.color_label_inner
                draw_text.text_style: theme.font_bold{font_size: theme.font_size_4}
            }
            subtitle := Label{
                text: "Subtitle"
                draw_text.color: theme.color_label_inner_inactive
                draw_text.text_style.font_size: theme.font_size_p
            }
        }
        badge := RoundedView{
            width: Fit height: Fit
            padding: theme.mspace_h_1
            draw_bg.color: theme.color_bg_highlight_inline
            draw_bg.border_radius: 4.0
            badge_label := Label{
                text: "new"
                draw_text.color: theme.color_highlight
                draw_text.text_style.font_size: theme.font_size_code
                draw_text.text_style: theme.font_bold{}
            }
        }
    }

    startup() do #(App::script_component(vm)){
        ui: Root{
            main_window := Window{
                pass.clear_color: theme.color_bg_app
                window.inner_size: vec2(400, 600)
                body +: {
                    width: Fill height: Fill
                    flow: Down spacing: 0

                    // Header
                    SolidView{
                        width: Fill height: Fit
                        padding: theme.mspace_3
                        draw_bg.color: theme.color_app_caption_bar
                        Label{
                            text: "My Cards"
                            draw_text.color: theme.color_label_inner
                            draw_text.text_style: theme.font_bold{font_size: theme.font_size_2}
                        }
                    }

                    // Card list
                    ScrollYView{
                        width: Fill height: Fill
                        padding: theme.mspace_2
                        flow: Down spacing: theme.space_1
                        CardItem{title.text: "First Card" subtitle.text: "Description here"}
                        CardItem{title.text: "Second Card" subtitle.text: "Another card"}
                    }

                    // Footer
                    SolidView{
                        width: Fill height: Fit
                        padding: theme.mspace_2
                        draw_bg.color: theme.color_bg_container
                        Label{
                            text: "2 items"
                            draw_text.color: theme.color_label_inner_inactive
                            draw_text.text_style.font_size: theme.font_size_code
                        }
                    }
                }
            }
        }
    }
}
```

## Best Practices

1. **ALWAYS use `theme.*` for colors in production apps** -- never hardcode `#ff0000`
   when `theme.color_error` exists. This enables theme switching and accessibility.

2. **Use theme fonts for consistent typography** -- prefer `theme.font_bold{font_size: theme.font_size_2}`
   over manually specifying font families.

3. **Use theme spacing for consistent layout** -- `theme.mspace_2` and `theme.space_2`
   create a harmonious rhythm. Avoid magic numbers like `padding: Inset{top: 8, ...}`.

4. **Override with `{}` syntax** -- extend theme values without replacing them:
   `theme.font_bold{font_size: 20}` keeps the bold font family but overrides size.
   `theme.mspace_2{left: theme.space_3}` keeps top/right/bottom but overrides left.

5. **Use merge `+:` for partial overrides** -- when you only want to change one
   nested property: `draw_text +: {text_style +: {font_size: theme.font_size_3}}`

6. **Choose the right text color variable**:
   - `theme.color_label_inner` for primary UI text (buttons, labels)
   - `theme.color_label_inner_inactive` for secondary/muted text
   - `theme.color_text` for general content text
   - `theme.color_text_placeholder` for placeholder text

7. **Use state-aware color variants** -- widgets that change on hover/focus/press
   should use the matching `_hover`, `_focus`, `_down` suffixes.

8. **Multiply for subtle opacity** -- `theme.color_label_inner_inactive * 0.8`
   creates a subtler variant without a new variable.

9. **Select theme before `widgets_mod`** -- the theme must be set between
   `theme_mod()` and `widgets_mod()` calls, so widget definitions pick up the
   correct theme values.

10. **For simple apps**, use `crate::makepad_widgets::script_mod(vm)` which loads
    everything with the default dark theme in one call.

## Source Files

- Theme dark: `widgets/src/theme_desktop_dark.rs`
- Theme light: `widgets/src/theme_desktop_light.rs`
- Theme skeleton: `widgets/src/theme_desktop_skeleton.rs`
- Theme loader: `widgets/src/lib.rs` (`theme_mod` and `widgets_mod` functions)
- Example usage: `examples/todo/src/app.rs` (light theme with full theme variable usage)
- Example usage: `examples/counter/src/app.rs` (default dark theme)
