---
name: callout-tooltip
author: robius
source: robrix
date: 2024-01-01
tags: [tooltip, callout, popup, hover, sdf, overlay]
level: advanced
---

# Pattern 14: Callout Tooltip

Tooltip with arrow/triangle pointing at the referenced widget, with automatic edge detection and position adjustment.

## Problem

You need tooltips that:
- Visually connect to their target element with an arrow
- Automatically adjust position when near screen edges
- Can be triggered from any widget without tight coupling
- Support all four directions (top/bottom/left/right)

## Solution

Use a global tooltip widget with:
1. Action-based event system for decoupled show/hide
2. SDF shader for drawing the callout triangle
3. Position calculation with edge detection
4. Instance variables for dynamic arrow positioning

## Implementation

### Data Types

```rust
use makepad_widgets::*;

/// The location of the tooltip with respect to its target widget.
#[derive(Clone, Debug, Default, PartialEq, Eq)]
pub enum TooltipPosition {
    Top,
    Bottom,
    Left,
    #[default]
    Right,
}

/// Options that affect how a CalloutTooltip is displayed.
#[derive(Clone, Debug)]
pub struct CalloutTooltipOptions {
    pub text_color: Vec4,
    pub bg_color: Vec4,
    pub position: TooltipPosition,
    pub triangle_height: f64,
}

impl Default for CalloutTooltipOptions {
    fn default() -> Self {
        Self {
            text_color: vec4(1.0, 1.0, 1.0, 1.0),      // White text
            bg_color: vec4(0.26, 0.30, 0.33, 1.0),     // Dark gray bg
            position: TooltipPosition::Right,
            triangle_height: 7.5,
        }
    }
}

/// Actions emitted to show/hide the tooltip from anywhere.
#[derive(Clone, Debug, DefaultNone)]
pub enum TooltipAction {
    HoverIn {
        text: String,
        widget_rect: Rect,
        options: CalloutTooltipOptions,
    },
    HoverOut,
    None,
}
```

### Position Calculation (Key Algorithm)

```rust
struct PositionCalculation {
    tooltip_pos: DVec2,
    callout_angle: f64,
}

impl CalloutTooltip {
    /// Calculate tooltip position with edge detection and fallback.
    fn calculate_position(
        options: &CalloutTooltipOptions,
        widget_rect: Rect,
        tooltip_size: DVec2,
        screen_size: DVec2,
        triangle_height: f64,
    ) -> PositionCalculation {
        let target_pos = widget_rect.pos;
        let target_size = widget_rect.size;
        let mut tooltip_pos = DVec2::default();
        let mut callout_angle = 0.0;

        match options.position {
            TooltipPosition::Top => {
                // Position above target
                tooltip_pos.x = target_pos.x + (target_size.x - tooltip_size.x) * 0.5;
                tooltip_pos.y = target_pos.y - tooltip_size.y - triangle_height;
                callout_angle = 180.0;  // Arrow points down

                // Flip to bottom if would go off top
                if tooltip_pos.y < 0.0 {
                    tooltip_pos.y = target_pos.y + target_size.y + triangle_height;
                    callout_angle = 0.0;
                }
            }
            TooltipPosition::Bottom => {
                // Position below target
                tooltip_pos.x = target_pos.x + (target_size.x - tooltip_size.x) * 0.5;
                tooltip_pos.y = target_pos.y + target_size.y + triangle_height;
                callout_angle = 0.0;  // Arrow points up

                // Flip to top if would go off bottom
                if tooltip_pos.y + tooltip_size.y > screen_size.y {
                    tooltip_pos.y = target_pos.y - tooltip_size.y - triangle_height;
                    callout_angle = 180.0;
                }
            }
            TooltipPosition::Left => {
                // Position to left of target
                tooltip_pos.x = target_pos.x - tooltip_size.x - triangle_height;
                tooltip_pos.y = target_pos.y + (target_size.y - tooltip_size.y) * 0.5;
                callout_angle = 90.0;  // Arrow points right

                // Flip to right if would go off left
                if tooltip_pos.x < 0.0 {
                    tooltip_pos.x = target_pos.x + target_size.x + triangle_height;
                    callout_angle = 270.0;
                }
            }
            TooltipPosition::Right => {
                // Position to right of target
                tooltip_pos.x = target_pos.x + target_size.x + triangle_height;
                tooltip_pos.y = target_pos.y + (target_size.y - tooltip_size.y) * 0.5;
                callout_angle = 270.0;  // Arrow points left

                // Flip to left if would go off right
                if tooltip_pos.x + tooltip_size.x > screen_size.x {
                    tooltip_pos.x = target_pos.x - tooltip_size.x - triangle_height;
                    callout_angle = 90.0;
                }
            }
        }

        // Clamp horizontal position to screen bounds
        tooltip_pos.x = tooltip_pos.x.max(0.0).min(screen_size.x - tooltip_size.x);
        // Clamp vertical position to screen bounds
        tooltip_pos.y = tooltip_pos.y.max(0.0).min(screen_size.y - tooltip_size.y);

        PositionCalculation { tooltip_pos, callout_angle }
    }
}
```

### Widget Implementation

```rust
#[derive(Live, LiveHook, Widget)]
pub struct CalloutTooltip {
    #[deref] view: View,
}

impl CalloutTooltip {
    pub fn show_with_options(
        &mut self,
        cx: &mut Cx,
        text: &str,
        widget_rect: Rect,
        options: CalloutTooltipOptions,
    ) {
        let mut tooltip = self.view.tooltip(ids!(tooltip));
        tooltip.set_text(cx, text);

        // Get tooltip dimensions after setting text
        let tooltip_size = tooltip.view(ids!(rounded_view)).area().rect(cx).size;
        let screen_size = tooltip.area().rect(cx).size;

        let calc = Self::calculate_position(
            &options,
            widget_rect,
            tooltip_size,
            screen_size,
            options.triangle_height,
        );

        // Apply shader instance variables
        tooltip.apply_over(cx, live! {
            content: {
                rounded_view = {
                    draw_bg: {
                        background_color: (options.bg_color)
                        triangle_height: (options.triangle_height)
                        callout_position: (calc.callout_angle)
                        tooltip_pos: (calc.tooltip_pos)
                        target_pos: (widget_rect.pos)
                        target_size: (widget_rect.size)
                        expected_dimension_x: (tooltip_size.x)
                    }
                    tooltip_label = {
                        draw_text: { color: (options.text_color) }
                    }
                }
            }
        });

        tooltip.show(cx);
    }

    pub fn show(&mut self, cx: &mut Cx) {
        self.view.tooltip(ids!(tooltip)).show(cx);
    }

    pub fn hide(&mut self, cx: &mut Cx) {
        self.view.tooltip(ids!(tooltip)).hide(cx);
    }
}
```

## live_design! (Complete Shader)

```rust
live_design! {
    use link::theme::*;
    use link::widgets::*;

    CalloutTooltipInner = <Tooltip> {
        content: <View> {
            flow: Overlay,
            width: Fit,
            height: Fit,

            rounded_view = <RoundedView> {
                width: Fit,
                height: Fit,
                padding: 15,

                draw_bg: {
                    color: #fff,
                    border_radius: 2.,

                    // Instance variables for dynamic positioning
                    instance background_color: #3b444b
                    instance tooltip_pos: vec2(0.0, 0.0)
                    instance target_pos: vec2(0.0, 0.0)
                    instance target_size: vec2(0.0, 0.0)
                    instance expected_dimension_x: 0.0
                    instance triangle_height: 7.5
                    instance callout_position: 180.0  // 0=Up, 90=Right, 180=Down, 270=Left

                    fn pixel(self) -> vec4 {
                        let sdf = Sdf2d::viewport(self.pos * self.rect_size);
                        let rect_size = self.rect_size;
                        let h = self.triangle_height;

                        // Don't draw until we have dimensions
                        if self.expected_dimension_x == 0.0 {
                            return sdf.result;
                        }

                        // Draw rounded box with padding for triangle
                        sdf.box(
                            h,
                            h,
                            rect_size.x - h * 2.0,
                            rect_size.y - h * 2.0,
                            max(1.0, self.border_radius)
                        );
                        sdf.fill(self.background_color);

                        // Calculate triangle vertices based on direction
                        let mut v1 = vec2(0.0, 0.0);
                        let mut v2 = vec2(0.0, 0.0);
                        let mut v3 = vec2(0.0, 0.0);

                        if self.callout_position == 0.0 {
                            // Arrow points UP (tooltip below target)
                            let center_x = self.target_pos.x + self.target_size.x * 0.5
                                         - self.tooltip_pos.x;
                            let clamped_x = min(
                                max(h * 3.0 + 2.0, center_x),
                                rect_size.x - h * 3.0 - 2.0
                            );
                            v1 = vec2(clamped_x, h + 2.0);
                            v2 = vec2(v1.x - h, 2.0);
                            v3 = vec2(v1.x + h, 2.0);
                        }
                        else if self.callout_position == 90.0 {
                            // Arrow points RIGHT (tooltip left of target)
                            v1 = vec2(rect_size.x - 2.0, rect_size.y * 0.5);
                            v2 = vec2(v1.x - h, v1.y - h);
                            v3 = vec2(v1.x - h, v1.y + h);
                        }
                        else if self.callout_position == 180.0 {
                            // Arrow points DOWN (tooltip above target)
                            let center_x = self.target_pos.x + self.target_size.x * 0.5
                                         - self.tooltip_pos.x + h;
                            let clamped_x = min(
                                max(h * 3.0 + 2.0, center_x),
                                rect_size.x - h - 2.0
                            );
                            v1 = vec2(clamped_x, rect_size.y - h - 2.0);
                            v2 = vec2(v1.x - h, rect_size.y - 2.0);
                            v3 = vec2(v1.x - h * 2.0, rect_size.y - h - 2.0);
                        }
                        else {
                            // Arrow points LEFT (tooltip right of target) - 270
                            v1 = vec2(2.0, rect_size.y * 0.5);
                            v2 = vec2(v1.x + h, v1.y - h);
                            v3 = vec2(v1.x + h, v1.y + h);
                        }

                        // Draw the triangle
                        sdf.move_to(v1.x, v1.y);
                        sdf.line_to(v2.x, v2.y);
                        sdf.line_to(v3.x, v3.y);
                        sdf.close_path();
                        sdf.fill(self.background_color);

                        return sdf.result;
                    }
                }

                tooltip_label = <Label> {
                    width: Fit,
                    height: Fit,
                    draw_text: {
                        text_style: <THEME_FONT_REGULAR>{ font_size: 9 },
                        text_wrap: Line,
                        color: #fff,
                    }
                }
            }
        }
    }

    // Public widget definition
    pub CalloutTooltip = {{CalloutTooltip}} {
        width: Fill,
        height: Fill,

        tooltip = <CalloutTooltipInner> {}
    }
}
```

## Integration in App (Action Handler)

```rust
// In app.rs or main widget handle_event
fn handle_event(&mut self, cx: &mut Cx, event: &Event, scope: &mut Scope) {
    // ... other event handling ...

    // Handle tooltip actions from any widget
    for action in cx.actions() {
        match action.as_widget_action().cast() {
            TooltipAction::HoverIn { text, widget_rect, options } => {
                self.ui.callout_tooltip(ids!(app_tooltip))
                    .show_with_options(cx, &text, widget_rect, options);
            }
            TooltipAction::HoverOut => {
                self.ui.callout_tooltip(ids!(app_tooltip)).hide(cx);
            }
            _ => {}
        }
    }
}
```

## Usage (Emit from Any Widget)

```rust
impl Widget for MyButton {
    fn handle_event(&mut self, cx: &mut Cx, event: &Event, scope: &mut Scope) {
        match event.hits(cx, self.draw_bg.area()) {
            Hit::FingerHoverIn(_) | Hit::FingerHoverOver(_) => {
                // Emit action to show tooltip
                cx.widget_action(
                    self.widget_uid(),
                    &scope.path,
                    TooltipAction::HoverIn {
                        text: "Button description".to_string(),
                        widget_rect: self.draw_bg.area().rect(cx),
                        options: CalloutTooltipOptions {
                            position: TooltipPosition::Top,
                            ..Default::default()
                        },
                    },
                );
            }
            Hit::FingerHoverOut(_) => {
                cx.widget_action(
                    self.widget_uid(),
                    &scope.path,
                    TooltipAction::HoverOut,
                );
            }
            _ => {}
        }
    }
}
```

## App Layout

```rust
live_design! {
    App = {{App}} {
        ui: <Root> {
            main_content = <View> {
                // Your app content here
            }

            // Global tooltip - always on top due to declaration order
            app_tooltip = <CalloutTooltip> {}
        }
    }
}
```

## Key Techniques

### 1. Dynamic Arrow Positioning
The arrow automatically points to the target's center:
```rust
let center_x = self.target_pos.x + self.target_size.x * 0.5 - self.tooltip_pos.x;
```

### 2. Edge Detection & Fallback
When tooltip would go off-screen, it flips to the opposite side:
```rust
if tooltip_pos.y < 0.0 {
    tooltip_pos.y = target_pos.y + target_size.y + triangle_height;
    callout_angle = 0.0;  // Flip direction
}
```

### 3. Triangle Padding
The box is inset by `triangle_height` to leave room for the arrow:
```rust
sdf.box(h, h, rect_size.x - h*2.0, rect_size.y - h*2.0, radius);
```

### 4. Decoupled Event System
Any widget can trigger tooltips via actions without direct references:
```rust
cx.widget_action(uid, &path, TooltipAction::HoverIn { ... });
```

## When to Use

- User guidance and feature explanations
- Hover information for icons
- Error/warning details
- Reaction/emoji explanations
- Read receipts or status indicators

## When NOT to Use

- For persistent information (use labels)
- For interactive content (use popups/modals)
- For very long text (use expandable sections)
