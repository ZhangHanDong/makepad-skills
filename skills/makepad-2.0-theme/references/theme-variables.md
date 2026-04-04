# Makepad 2.0 Theme Variables -- Complete Reference

This is an exhaustive reference of every `theme.*` variable defined in the Makepad
2.0 theme system, with descriptions and usage context.

## Global Tuning Parameters

These parameters control the overall feel of the theme. Changing them affects
all derived values.

```
color_contrast: 1.0          // Controls palette spread (higher = more contrast)
color_tint: #0000ff          // Tint color applied to app backgrounds
color_tint_amount: 0.0       // Tint strength (0.0 = none, 1.0 = full)
space_factor: 6.0            // Base spacing multiplier for all spacing values
corner_radius: 2.5           // Base corner radius for widgets
beveling: 0.75               // Bevel depth for 3D widget effects
font_size_base: 10.0         // Base font size (all sizes derived from this)
font_size_contrast: 2.5      // Step multiplier between heading levels
```

## Color Palette -- Foundation

The color palette is built from two endpoints (white and black) using contrast-aware
interpolation. You rarely use these directly; they feed into semantic colors.

```
// Endpoints
theme.color_w              // White with full alpha (#FFFFFFFF)
theme.color_w_h            // White with zero alpha (#FFFFFF00)
theme.color_b              // Black with full alpha (#000000FF)
theme.color_b_h            // Black with zero alpha (#00000000)

// Light steps (u = up/light direction)
theme.color_white          // Near-white
theme.color_u_6            // Lightest visible step
theme.color_u_5            // Light step 5
theme.color_u_4            // Light step 4
theme.color_u_3            // Light step 3
theme.color_u_2            // Light step 2
theme.color_u_15           // Light step 1.5
theme.color_u_1            // Lightest subtle step
theme.color_u_hidden       // Fully transparent white

// Dark steps (d = down/dark direction)
theme.color_d_hidden       // Fully transparent black
theme.color_d_025          // Barely visible dark
theme.color_d_05           // Very subtle dark
theme.color_d_075          // Subtle dark (light theme only)
theme.color_d_1            // Light dark step
theme.color_d_2            // Medium-light dark step
theme.color_d_3            // Medium dark step
theme.color_d_4            // Medium-heavy dark step
theme.color_d_5            // Heavy dark step
theme.color_black          // Near-black

// Opaque mixes (premixed with fg_app for non-transparent overlays)
theme.color_opaque_u_1 through theme.color_opaque_u_6   // Light opaque steps
theme.color_opaque_d_1 through theme.color_opaque_d_5   // Dark opaque steps
theme.color_opaque_d_05    // Very subtle dark opaque (light theme only)
```

## Color Palette -- Background and App

```
theme.color_bg_app              // Main application background
theme.color_fg_app              // Foreground layer (panels, content area)
theme.color_bg_container        // Card and container backgrounds
theme.color_bg_even             // Even row in alternating lists
theme.color_bg_odd              // Odd row in alternating lists
theme.color_bg_highlight        // Highlight/selection background
theme.color_bg_unfocussed       // Unfocused highlight (85% of bg_highlight)
theme.color_bg_highlight_inline // Inline code/tag highlight background
theme.color_app_caption_bar     // Window caption bar background
theme.color_drag_quad           // Drag preview overlay
theme.color_drag_target_preview // Drag target indicator
theme.color_dock_tab_active     // Active dock tab background
```

## Color Palette -- Text

```
theme.color_text                // General content text
theme.color_text_val            // Value/number text
theme.color_text_hl             // Highlighted text
theme.color_text_hover          // Text on hover
theme.color_text_focus          // Text on focus
theme.color_text_down           // Text when pressed
theme.color_text_disabled       // Disabled text
theme.color_text_placeholder    // Input placeholder text
theme.color_text_placeholder_hover // Placeholder on hover
theme.color_text_meta           // Metadata/secondary text
theme.color_text_cursor         // Text cursor color
```

## Color Palette -- Labels (Inner and Outer)

Inner labels are text inside widgets (button text, input text):

```
theme.color_label_inner            // Default inner label
theme.color_label_inner_hover      // On hover
theme.color_label_inner_down       // When pressed
theme.color_label_inner_drag       // During drag
theme.color_label_inner_focus      // When focused
theme.color_label_inner_active     // Active/selected state
theme.color_label_inner_inactive   // Muted/secondary text
theme.color_label_inner_disabled   // Disabled state
```

Outer labels are text outside widgets (tab headers, section titles):

```
theme.color_label_outer            // Default outer label
theme.color_label_outer_off        // Off/unselected state
theme.color_label_outer_down       // When pressed
theme.color_label_outer_drag       // During drag
theme.color_label_outer_hover      // On hover
theme.color_label_outer_focus      // When focused
theme.color_label_outer_active     // Active state
theme.color_label_outer_active_focus // Active and focused
theme.color_label_outer_disabled   // Disabled state
```

## Color Palette -- Widget Surfaces

### Outset (Buttons, Raised Elements)

```
// Primary outset (standard buttons)
theme.color_outset                 // Default
theme.color_outset_hover           // Hover
theme.color_outset_down            // Pressed
theme.color_outset_active          // Active/toggled on
theme.color_outset_focus           // Focused
theme.color_outset_drag            // During drag
theme.color_outset_disabled        // Disabled
theme.color_outset_inactive        // Inactive

// Outset level 1 (secondary buttons)
theme.color_outset_1               // Default
theme.color_outset_1_hover         // Hover
theme.color_outset_1_down          // Pressed
theme.color_outset_1_active        // Active
theme.color_outset_1_focus         // Focused
theme.color_outset_1_disabled      // Disabled

// Outset level 2 (subtle/flat buttons)
theme.color_outset_2               // Default
theme.color_outset_2_hover         // Hover
theme.color_outset_2_down          // Pressed
theme.color_outset_2_active        // Active
theme.color_outset_2_focus         // Focused
theme.color_outset_2_disabled      // Disabled
```

### Inset (Text Inputs, Checkboxes, Radio Buttons)

```
// Primary inset
theme.color_inset                  // Default input background
theme.color_inset_hover
theme.color_inset_down
theme.color_inset_active
theme.color_inset_focus
theme.color_inset_drag
theme.color_inset_disabled
theme.color_inset_empty

// Inset level 1
theme.color_inset_1 through theme.color_inset_1_empty

// Inset level 2
theme.color_inset_2 through theme.color_inset_2_empty
```

### Bevel System (3D Widget Effects)

```
// Flat bevel
theme.color_bevel                  // Default bevel line
theme.color_bevel_hover / _focus / _active / _empty / _down / _drag / _disabled

// Inner shadow (layer 1 -- darker edge)
theme.color_bevel_inset_1          // + _hover / _focus / _active / _empty / _down / _drag / _disabled

// Inner highlight (layer 2 -- lighter edge)
theme.color_bevel_inset_2          // + _hover / _focus / _active / _empty / _down / _drag / _disabled

// Outer highlight (layer 1 -- top/left bright edge)
theme.color_bevel_outset_1         // + _hover / _focus / _active / _down / _drag / _disabled

// Outer shadow (layer 2 -- bottom/right dark edge)
theme.color_bevel_outset_2         // + _hover / _focus / _active / _down / _drag / _disabled
```

## Color Palette -- Interactive Elements

### Selection

```
theme.color_selection              // Default selection
theme.color_selection_hover
theme.color_selection_down
theme.color_selection_focus        // Active text selection highlight
theme.color_selection_empty
theme.color_selection_disabled
```

### Marks (Checkmarks, Radio Dots)

```
theme.color_mark                   // Check/radio mark
theme.color_mark_empty             // Empty state
theme.color_mark_off               // Off state
theme.color_mark_hover
theme.color_mark_active
theme.color_mark_active_hover
theme.color_mark_focus
theme.color_mark_down
theme.color_mark_disabled
```

### Icons

```
theme.color_icon                   // Default icon color
theme.color_icon_inactive          // Inactive icon
theme.color_icon_active            // Active icon
theme.color_icon_disabled          // Disabled icon
theme.color_icon_wait              // Loading/wait indicator
theme.color_icon_panic             // Panic state icon
```

### Cursors

```
theme.color_cursor                 // Default cursor
theme.color_cursor_focus           // Focused cursor
theme.color_cursor_empty           // Empty state cursor
theme.color_cursor_disabled        // Disabled cursor
theme.color_cursor_border          // Cursor border
```

### Value Indicators (Progress Bars, Sliders)

```
// Primary value fill
theme.color_val                    // Default fill
theme.color_val_hover / _focus / _drag / _disabled

// Level 1 value
theme.color_val_1                  // + _hover / _focus / _drag / _disabled

// Level 2 value
theme.color_val_2                  // + _hover / _focus / _drag / _disabled
```

### Handles (Slider Thumbs, Scrollbar Handles)

```
// Primary handle
theme.color_handle                 // Default
theme.color_handle_hover / _focus / _disabled / _drag

// Handle level 1
theme.color_handle_1               // + _hover / _focus / _disabled / _drag

// Handle level 2
theme.color_handle_2               // + _hover / _focus / _disabled / _drag
```

### Shadow and Light

```
theme.color_shadow                 // Default shadow
theme.color_shadow_focus           // Focused shadow
theme.color_shadow_disabled        // Disabled shadow
theme.color_shadow_flat            // Flat shadow
theme.color_shadow_flat_disabled   // Disabled flat shadow
theme.color_light                  // Highlight/light
theme.color_light_hover
theme.color_light_focus
theme.color_light_disabled
theme.color_flat_focus             // Flat focus indicator
```

## Typography Variables

### Font Sizes

```
theme.font_size_1              // 30.0 -- H1 / hero heading
theme.font_size_2              // 20.0 -- H2 / section heading
theme.font_size_3              // 15.0 -- H3 / subsection heading
theme.font_size_4              // 12.5 -- H4 / card title
theme.font_size_p              // 10.0 -- Body/paragraph text
theme.font_size_code           //  9.0 -- Monospace code text
```

### Font Styles (TextStyle objects)

```
theme.font_regular             // Regular body text
theme.font_bold                // Bold/semibold text
theme.font_italic              // Italic text
theme.font_bold_italic         // Bold italic text
theme.font_code                // Monospace code font (includes font_size: 9.0)
theme.font_label               // Label text (legacy, same as regular)
theme.font_icons               // FontAwesome icon font
```

### Line Spacing

```
theme.font_wdgt_line_spacing       // 1.2 -- Widget text spacing
theme.font_hl_line_spacing         // 1.05 -- Heading line spacing
theme.font_longform_line_spacing   // 1.2 -- Long-form content spacing
```

## Spacing Variables

### Base Spacing

```
theme.space_1              // 3.0 -- Extra small
theme.space_2              // 6.0 -- Small/standard
theme.space_3              // 9.0 -- Medium
```

### Inset Presets (All Sides)

```
theme.mspace_1             // Inset{top: 3, right: 3, bottom: 3, left: 3}
theme.mspace_2             // Inset{top: 6, right: 6, bottom: 6, left: 6}
theme.mspace_3             // Inset{top: 9, right: 9, bottom: 9, left: 9}
```

### Inset Presets (Horizontal Only)

```
theme.mspace_h_1           // Inset{top: 0, right: 3, bottom: 0, left: 3}
theme.mspace_h_2           // Inset{top: 0, right: 6, bottom: 0, left: 6}
theme.mspace_h_3           // Inset{top: 0, right: 9, bottom: 0, left: 9}
```

### Inset Presets (Vertical Only)

```
theme.mspace_v_1           // Inset{top: 3, right: 0, bottom: 3, left: 0}
theme.mspace_v_2           // Inset{top: 6, right: 0, bottom: 6, left: 0}
theme.mspace_v_3           // Inset{top: 9, right: 0, bottom: 9, left: 0}
```

### Widget Dimensions

```
theme.data_item_height             // 23.25 -- Standard data row height
theme.data_icon_width              // 15.6 -- Icon width in data views
theme.data_icon_height             // 21.6 -- Icon height in data views
theme.container_corner_radius      // 5.0 -- Container border radius
theme.textselection_corner_radius  // 1.25 -- Text selection corner radius
theme.tab_height                   // 36.0 -- Tab bar height
theme.tab_flat_height              // 33.0 -- Flat tab height
theme.splitter_size                // 5.0 -- Splitter handle size
theme.splitter_horizontal          // 16.0 -- Horizontal splitter bar
theme.splitter_min_horizontal      // tab_height
theme.splitter_max_horizontal      // tab_height + splitter_size
theme.splitter_min_vertical        // splitter_horizontal (16.0)
theme.splitter_max_vertical        // splitter_horizontal + splitter_size
theme.dock_border_size             // 0.0 -- Dock panel border
```

## Theme-Aware Component Examples

### Themed Card

```
let ThemedCard = RoundedView{
    width: Fill height: Fit
    padding: theme.mspace_2
    draw_bg.color: theme.color_bg_container
    draw_bg.border_radius: theme.container_corner_radius
    flow: Down spacing: theme.space_1

    title := Label{
        text: "Card Title"
        draw_text.color: theme.color_label_inner
        draw_text.text_style: theme.font_bold{font_size: theme.font_size_4}
    }
    body := Label{
        text: "Card body text goes here."
        draw_text.color: theme.color_label_inner_inactive
        draw_text.text_style.font_size: theme.font_size_p
    }
}
```

### Themed Header Bar

```
let HeaderBar = SolidView{
    width: Fill height: Fit
    padding: theme.mspace_3{left: theme.space_3 * 2, right: theme.space_3 * 2}
    flow: Right spacing: theme.space_2
    align: Align{y: 0.5}
    draw_bg.color: theme.color_app_caption_bar

    Label{
        text: "App Title"
        draw_text.color: theme.color_label_inner
        draw_text.text_style: theme.font_bold{font_size: theme.font_size_2}
    }
    Filler{}
    Label{
        text: "Subtitle"
        draw_text.color: theme.color_label_inner_inactive
        draw_text.text_style.font_size: theme.font_size_p
    }
}
```

### Themed Tag Badge

```
let TagBadge = RoundedView{
    width: Fit height: Fit
    padding: theme.mspace_h_1{left: theme.space_2, right: theme.space_2}
    draw_bg.color: theme.color_bg_highlight_inline
    draw_bg.border_radius: 4.0
    Label{
        text: "tag"
        draw_text.color: theme.color_highlight
        draw_text.text_style.font_size: theme.font_size_code
        draw_text.text_style: theme.font_bold{}
    }
}
```

### Themed Status Bar

```
let StatusBar = SolidView{
    width: Fill height: Fit
    padding: theme.mspace_2
    draw_bg.color: theme.color_bg_container
    flow: Right
    align: Align{y: 0.5}

    status_label := Label{
        text: "Ready"
        draw_text.color: theme.color_label_inner_inactive
        draw_text.text_style.font_size: theme.font_size_code
    }
    Filler{}
    action_button := ButtonFlatter{
        text: "Action"
    }
}
```

## Dark/Light Mode Switching Example

Complete pattern for an app with a theme toggle:

```rust
// In app.rs

use makepad_widgets::*;
app_main!(App);

script_mod! {
    use mod.prelude.widgets.*

    let is_dark = true

    let app = startup() do #(App::script_component(vm)){
        ui: Root{
            main_window := Window{
                pass.clear_color: theme.color_bg_app
                body +: {
                    width: Fill height: Fill
                    flow: Down spacing: theme.space_2
                    padding: theme.mspace_3

                    Label{
                        text: "Theme Demo"
                        draw_text.color: theme.color_label_inner
                        draw_text.text_style: theme.font_bold{font_size: theme.font_size_1}
                    }

                    Label{
                        text: "This text uses theme colors."
                        draw_text.color: theme.color_label_inner_inactive
                        draw_text.text_style.font_size: theme.font_size_p
                    }

                    RoundedView{
                        width: Fill height: Fit
                        padding: theme.mspace_2
                        draw_bg.color: theme.color_bg_container
                        draw_bg.border_radius: theme.container_corner_radius
                        Label{
                            text: "A themed card"
                            draw_text.color: theme.color_label_inner
                            draw_text.text_style.font_size: theme.font_size_4
                        }
                    }

                    toggle_theme := Button{
                        text: "Toggle Theme"
                    }
                }
            }
        }
    }
    app
}

impl App {
    fn run(vm: &mut ScriptVm) -> Self {
        crate::makepad_widgets::theme_mod(vm);
        script_eval!(vm, {
            mod.theme = mod.themes.dark
        });
        crate::makepad_widgets::widgets_mod(vm);
        App::from_script_mod(vm, self::script_mod)
    }
}

#[derive(Script, ScriptHook)]
pub struct App {
    #[live]
    ui: WidgetRef,
}

impl MatchEvent for App {
    fn handle_actions(&mut self, cx: &mut Cx, actions: &Actions) {
        if self.ui.button(cx, ids!(toggle_theme)).clicked(actions) {
            script_eval!(cx, {
                if is_dark {
                    mod.theme = mod.themes.light
                    is_dark = false
                } else {
                    mod.theme = mod.themes.dark
                    is_dark = true
                }
            });
        }
    }
}

impl AppMain for App {
    fn handle_event(&mut self, cx: &mut Cx, event: &Event) {
        self.match_event(cx, event);
        self.ui.handle_event(cx, event, &mut Scope::empty());
    }
}
```

## Color Palette Visual Reference (Text-Based)

### Dark Theme Palette

```
Background layers (darkest to lightest):
  color_bg_app        [################]  Deep dark gray
  color_fg_app        [################]  Slightly lighter
  color_bg_container  [####  ##########]  Semi-transparent dark
  color_bg_highlight  [      ##########]  Very subtle white overlay

Text colors (lightest to darkest):
  color_label_inner   [================]  Bright (color_u_5)
  color_text          [==============  ]  Slightly muted (color_u_5)
  color_label_inner_inactive [========  ]  Muted (color_u_4)
  color_text_disabled [====            ]  Very muted (color_u_1)

Accent colors:
  color_highlight     [  ====          ]  Subtle white accent
  color_makepad       [  ====  ########]  #FF5C39 (Makepad orange)
  color_error/high    [####            ]  #C00 (Red)
  color_warning/mid   [####====        ]  #FA0 (Orange)
  color_low           [    ====        ]  #8A0 (Yellow-green)
```

### Light Theme Palette

```
Background layers (lightest to darkest):
  color_bg_app        [                ]  Light gray (~#DDD)
  color_fg_app        [                ]  Slightly darker
  color_bg_container  [    ############]  Semi-transparent light overlay
  color_bg_highlight  [            ####]  Very subtle dark overlay

Text colors (darkest to lightest):
  color_label_inner   [================]  Dark (color_d_4)
  color_text          [==============  ]  Slightly lighter (color_d_4)
  color_label_inner_inactive [========  ]  Muted (color_d_3)
  color_text_disabled [====            ]  Very light (color_d_1)

Accent colors (same as dark):
  color_highlight     [  ====          ]  Subtle dark accent
  color_makepad       [  ====  ########]  #FF5C39 (Makepad orange)
  color_error/high    [####            ]  #C00 (Red)
  color_warning/mid   [####====        ]  #FA0 (Orange)
  color_low           [    ====        ]  #8A0 (Yellow-green)
```

## Key Differences: Dark vs Light

| Variable | Dark Theme | Light Theme |
|----------|-----------|-------------|
| `color_bg_app` | Dark (~30% white) | Light (~85% white) |
| `color_label_inner` | `color_u_5` (bright) | `color_d_4` (dark) |
| `color_label_inner_inactive` | `color_u_4` (muted bright) | `color_d_3` (muted dark) |
| `color_bg_container` | `color_d_3 * 0.8` | `color_u_3 * 0.8` |
| `color_text` | `color_u_5` (bright) | `color_d_4` (dark) |
| `color_highlight` | `color_u_1` (subtle light) | `color_d_1` (subtle dark) |
| `color_outset` | `color_u_15` (subtle light) | `color_u_3` (medium light) |
| `color_inset` | `color_d_1` (subtle dark) | `color_d_075` (very subtle dark) |

The fundamental principle: in dark mode, text is light (`color_u_*`) on dark
backgrounds (`color_d_*`). In light mode, the polarity reverses -- text is dark
(`color_d_*`) on light backgrounds (`color_u_*`). The theme system handles this
automatically when you use semantic variables like `color_label_inner`.
