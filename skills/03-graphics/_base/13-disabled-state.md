---
name: disabled-state
author: robius
source: makepad-docs
date: 2024-01-01
tags: [disabled, state, interactive, pattern]
level: intermediate
---

# Disabled State Pattern

Visual patterns for disabled interactive elements.

## Implementation

```rust
draw_thumb: {
    instance hover: 0.0
    instance pressed: 0.0
    instance disabled: 0.0
    instance border_color: #3b82f6
    instance disabled_border_color: #94a3b8

    fn pixel(self) -> vec4 {
        let sdf = Sdf2d::viewport(self.pos * self.rect_size);
        let c = self.rect_size * 0.5;

        // Choose color based on disabled state
        let border_col = mix(self.border_color, self.disabled_border_color, self.disabled);

        // Shadow (only when not disabled)
        let shadow_alpha = mix(0.2, 0.0, self.disabled);
        sdf.circle(c.x + 2.0, c.y + 2.0, c.x - 2.0);
        sdf.fill(vec4(0.0, 0.0, 0.0, shadow_alpha));

        // Main circle
        sdf.circle(c.x, c.y, c.x - 2.0);

        // Base colors with disabled variation
        let base_color = mix(#ffffff, #f8fafc, self.disabled);
        let hover_color = #f0f9ff;
        let pressed_color = #e0f2fe;

        // Disable hover/pressed effects when disabled
        let active_hover = self.hover * (1.0 - self.disabled);
        let active_pressed = self.pressed * (1.0 - self.disabled);

        let color = mix(base_color, hover_color, active_hover);
        let color = mix(color, pressed_color, active_pressed);

        sdf.fill(color);
        sdf.stroke(border_col, 2.5);

        return sdf.result;
    }
}
```

## Key Techniques

1. **Interpolate colors**: `mix(normal, disabled, self.disabled)`
2. **Disable interactions**: `hover * (1.0 - self.disabled)`
3. **Remove effects**: `mix(normal_alpha, 0.0, self.disabled)`

## Setting Disabled State

In Rust:

```rust
impl MyWidget {
    pub fn set_disabled(&mut self, cx: &mut Cx, disabled: bool) {
        self.draw_thumb.apply_over(cx, live!{
            disabled: (if disabled { 1.0 } else { 0.0 })
        });
        self.redraw(cx);
    }
}
```

In event handling:

```rust
fn handle_event(&mut self, cx: &mut Cx, event: &Event, scope: &mut Scope) {
    // Skip interactions when disabled
    if self.disabled {
        return;
    }

    match event.hits(cx, self.draw_bg.area()) {
        // ... normal handling
    }
}
```

## When to Use

- Use for form inputs that are conditionally editable
- Use for buttons that require prerequisites
- Use for read-only states
- Gray out colors and remove shadows when disabled
