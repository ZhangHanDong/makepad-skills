---
name: hover-effect
author: robius
source: makepad-docs
date: 2024-01-01
tags: [hover, effect, interactive, button]
level: beginner
---

# Hover Effect

Interactive hover state for buttons and clickable elements.

## Basic Hover

```rust
draw_bg: {
    instance hover: 0.0
    uniform base_color: #4A90D9

    fn pixel(self) -> vec4 {
        let sdf = Sdf2d::viewport(self.pos * self.rect_size);
        sdf.box(0., 0., self.rect_size.x, self.rect_size.y, 4.0);

        let hover_color = mix(self.base_color, #FFFFFF, 0.2);
        let final_color = mix(self.base_color, hover_color, self.hover);

        sdf.fill(final_color);
        return sdf.result;
    }
}
```

## Button with Pressed Effect

```rust
draw_bg: {
    instance hover: 0.0
    instance pressed: 0.0

    fn pixel(self) -> vec4 {
        let sdf = Sdf2d::viewport(self.pos * self.rect_size);

        // Slightly smaller when pressed
        let shrink = self.pressed * 2.0;
        sdf.box(
            shrink,
            shrink,
            self.rect_size.x - shrink * 2.0,
            self.rect_size.y - shrink * 2.0,
            4.0
        );

        let base = #4A90D9;
        let hover_color = mix(base, #FFFFFF, 0.1);
        let pressed_color = mix(base, #000000, 0.1);

        let color = mix(base, hover_color, self.hover);
        let color = mix(color, pressed_color, self.pressed);

        sdf.fill(color);
        return sdf.result;
    }
}
```

## Animator for Hover

```rust
animator: {
    hover = {
        default: off,
        off = {
            from: {all: Forward {duration: 0.15}}
            apply: { draw_bg: {hover: 0.0} }
        }
        on = {
            from: {all: Forward {duration: 0.1}}
            apply: { draw_bg: {hover: 1.0} }
        }
    }
    pressed = {
        default: off,
        off = {
            from: {all: Forward {duration: 0.2}}
            apply: { draw_bg: {pressed: 0.0} }
        }
        on = {
            from: {all: Snap}
            apply: { draw_bg: {pressed: 1.0} }
        }
    }
}
```

## Event Handling

```rust
match event.hits(cx, self.draw_bg.area()) {
    Hit::FingerHoverIn(_) => {
        self.animator_play(cx, ids!(hover.on));
    }
    Hit::FingerHoverOut(_) => {
        self.animator_play(cx, ids!(hover.off));
    }
    Hit::FingerDown(_) => {
        self.animator_play(cx, ids!(pressed.on));
    }
    Hit::FingerUp(_) => {
        self.animator_play(cx, ids!(pressed.off));
    }
    _ => {}
}
```

## When to Use

- Use for all clickable/interactive elements
- Keep hover duration short (0.1-0.15s)
- Use Snap for immediate pressed feedback
- Lighten colors on hover, darken on press
