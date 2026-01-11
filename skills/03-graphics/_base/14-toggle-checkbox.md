---
name: toggle-checkbox
author: robius
source: makepad-docs
date: 2024-01-01
tags: [toggle, switch, checkbox, interactive]
level: intermediate
---

# Toggle & Checkbox Visuals

Switch tracks and checkbox with checkmark.

## Switch Track with Toggle State

```rust
draw_bg: {
    instance on: 0.0
    instance hover: 0.0

    fn pixel(self) -> vec4 {
        let sdf = Sdf2d::viewport(self.pos * self.rect_size);
        let sz = self.rect_size;
        let r = sz.y * 0.5;

        // Draw capsule
        sdf.circle(r, r, r);
        sdf.rect(r, 0.0, sz.x - sz.y, sz.y);
        sdf.circle(sz.x - r, r, r);

        let bg_off = #cbd5e1;
        let bg_on = #3b82f6;
        let color = mix(bg_off, bg_on, self.on);

        sdf.fill(color);
        return sdf.result;
    }
}
```

## Checkbox with Checkmark

```rust
draw_bg: {
    instance checked: 0.0

    fn pixel(self) -> vec4 {
        let sdf = Sdf2d::viewport(self.pos * self.rect_size);
        let sz = self.rect_size;

        // Box
        sdf.box(0., 0., sz.x, sz.y, 4.0);
        let bg = mix(#ffffff, #3b82f6, self.checked);
        sdf.fill(bg);
        sdf.stroke(#cbd5e1, 1.5);

        // Checkmark (only when checked)
        if self.checked > 0.5 {
            let cx = sz.x * 0.5;
            let cy = sz.y * 0.5;

            sdf.move_to(cx - 4.0, cy);
            sdf.line_to(cx - 1.0, cy + 3.0);
            sdf.line_to(cx + 5.0, cy - 4.0);
            sdf.stroke(#ffffff, 2.5);
        }

        return sdf.result;
    }
}
```

## Color Overlay on Image

```rust
draw_bg: {
    instance overlay_opacity: 0.3
    uniform overlay_color: #000000

    fn pixel(self) -> vec4 {
        let img = sample2d(self.image, self.pos);
        let overlay = vec4(self.overlay_color.rgb, self.overlay_opacity);
        return mix(img, overlay, overlay.a);
    }
}
```

## Toggling State

```rust
impl Switch {
    pub fn toggle(&mut self, cx: &mut Cx) {
        self.is_on = !self.is_on;
        let target = if self.is_on { ids!(toggle.on) } else { ids!(toggle.off) };
        self.animator_play(cx, target);
    }
}
```

## Animator for Toggle

```rust
animator: {
    toggle = {
        default: off,
        off = {
            from: {all: Forward {duration: 0.2}}
            ease: OutQuad
            apply: {
                draw_bg: {on: 0.0}
                draw_thumb: {thumb_x: 0.0}
            }
        }
        on = {
            from: {all: Forward {duration: 0.2}}
            ease: OutQuad
            apply: {
                draw_bg: {on: 1.0}
                draw_thumb: {thumb_x: 1.0}
            }
        }
    }
}
```

## When to Use

- Use switch for on/off toggles (settings, preferences)
- Use checkbox for boolean selection in forms
- Animate both the track color and thumb position
- Use `if` for checkmark since it's a static branch
