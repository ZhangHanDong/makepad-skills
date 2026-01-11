---
name: easing-functions
author: robius
source: makepad-docs
date: 2024-01-01
tags: [animator, easing, timing, curve]
level: intermediate
---

# Easing Functions

Animation curves and timing control.

## Adding Easing

Add `ease:` to control animation curve:

```rust
animator: {
    slide = {
        default: off,
        on = {
            from: {all: Forward {duration: 0.4}}
            ease: ExpDecay {d1: 0.80, d2: 0.97}  // Smooth deceleration
            apply: { draw_bg: {offset_x: 100.0} }
        }
        off = {
            from: {all: Forward {duration: 0.3}}
            ease: InQuad
            apply: { draw_bg: {offset_x: 0.0} }
        }
    }
}
```

## Available Easing Functions

| Easing | Description | Use Case |
|--------|-------------|----------|
| `Linear` | Constant speed | Default, mechanical feel |
| `InQuad` | Slow start, fast end | Exit animations |
| `OutQuad` | Fast start, slow end | Enter animations |
| `InOutQuad` | Slow start and end | Smooth transitions |
| `InCubic` / `OutCubic` | Stronger curve | More dramatic effect |
| `InExp` / `OutExp` | Exponential | Very pronounced |
| `ExpDecay {d1: 0.8, d2: 0.97}` | Natural deceleration | Physics-like motion |
| `Ease` | Standard CSS-like ease | General purpose |

## Multi-Property Animation

Animate multiple properties together:

```rust
animator: {
    expand = {
        default: off,
        off = {
            from: {all: Forward {duration: 0.3}}
            ease: OutQuad
            apply: {
                draw_bg: {
                    scale: 1.0,
                    opacity: 1.0,
                    rotation: 0.0
                }
            }
        }
        on = {
            from: {all: Forward {duration: 0.4}}
            ease: ExpDecay {d1: 0.7, d2: 0.95}
            apply: {
                draw_bg: {
                    scale: 1.2,
                    opacity: 0.8,
                    rotation: 0.1
                }
            }
        }
    }
}
```

## Scale/Bounce Effect

```rust
animator: {
    bounce = {
        default: normal,
        normal = {
            from: {all: Forward {duration: 0.2}}
            ease: OutQuad
            apply: { draw_bg: {scale: 1.0} }
        }
        pressed = {
            from: {all: Snap}
            apply: { draw_bg: {scale: 0.95} }
        }
        // Overshoot bounce back
        release = {
            from: {all: Forward {duration: 0.3}}
            ease: ExpDecay {d1: 0.5, d2: 0.9}
            apply: { draw_bg: {scale: 1.05} }
        }
    }
}
```

## When to Use

- **OutQuad**: Enter animations (fast start, ease to stop)
- **InQuad**: Exit animations (ease out, fast exit)
- **ExpDecay**: Physics-like motion, spring effects
- **Snap**: Instant state changes (pressed feedback)
