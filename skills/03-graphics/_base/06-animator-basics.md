---
name: animator-basics
author: robius
source: makepad-docs
date: 2024-01-01
tags: [animator, animation, hover, pressed]
level: beginner
---

# Animator Basics

Makepad animation system fundamentals.

## Animator Definition

```rust
live_design! {
    MyButton = {{MyButton}} {
        draw_bg: {
            instance hover: 0.0
            instance pressed: 0.0
        }

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
    }
}
```

## Animation Timing

| Timing | Description |
|--------|-------------|
| `Forward {duration: 0.15}` | Linear transition over duration |
| `Snap` | Instant change (no animation) |
| `Loop {duration: 1.0, end: 1.0}` | Continuous looping animation |
| `Reverse {duration: 0.15}` | Reverse direction animation |

## Triggering Animations

```rust
impl Widget for MyButton {
    fn handle_event(&mut self, cx: &mut Cx, event: &Event, scope: &mut Scope) {
        if self.animator_handle_event(cx, event).must_redraw() {
            self.draw_bg.redraw(cx);
        }

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
    }
}
```

## Animation State Check

```rust
impl MyWidget {
    fn is_animating(&self, cx: &Cx) -> bool {
        self.animator.is_playing(cx)
    }

    fn animation_progress(&self, cx: &Cx, path: &[LiveId]) -> f64 {
        self.animator.get_value(cx, path)
    }
}
```

## Best Practices

1. **Check must_redraw()** - Only redraw when animator needs it
2. **Keep durations short** - 0.1-0.3s for hover, 0.2-0.4s for transitions
3. **Snap for immediate** - Use Snap when instant response needed

## When to Use

- Use for hover/pressed states on interactive widgets
- Use for showing/hiding panels and overlays
- Use for state transitions (selected, disabled, etc.)
