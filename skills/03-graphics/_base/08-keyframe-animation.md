---
name: keyframe-animation
author: robius
source: makepad-docs
date: 2024-01-01
tags: [animator, keyframe, loop, cycle]
level: intermediate
---

# Keyframe Animation

Multi-value animations and loops.

## Keyframe Definition

Animate through multiple values:

```rust
animator: {
    color_cycle = {
        default: on,
        on = {
            from: {all: Loop {duration: 3.0, end: 1.0}}
            apply: {
                draw_bg: {
                    color: [
                        {time: 0.0, value: #ff0000},   // Red at 0%
                        {time: 0.33, value: #00ff00}, // Green at 33%
                        {time: 0.66, value: #0000ff}, // Blue at 66%
                        {time: 1.0, value: #ff0000}   // Back to red
                    ]
                }
            }
        }
    }
}
```

## Fade In/Out

```rust
live_design! {
    FadeView = {{FadeView}} {
        draw_bg: {
            instance opacity: 0.0

            fn pixel(self) -> vec4 {
                return vec4(0., 0., 0., self.opacity);
            }
        }

        animator: {
            fade = {
                default: hidden,
                hidden = {
                    from: {all: Forward {duration: 0.2}}
                    apply: { draw_bg: {opacity: 0.0} }
                }
                visible = {
                    from: {all: Forward {duration: 0.3}}
                    ease: OutQuad
                    apply: { draw_bg: {opacity: 1.0} }
                }
            }
        }
    }
}
```

## Slide Animation

```rust
live_design! {
    SlidePanel = {{SlidePanel}} {
        draw_bg: {
            instance slide_x: -300.0  // Start off-screen

            fn pixel(self) -> vec4 {
                let pos = self.pos + vec2(self.slide_x / self.rect_size.x, 0.);
                // ... draw content
            }
        }

        animator: {
            slide = {
                default: closed,
                closed = {
                    from: {all: Forward {duration: 0.3}}
                    ease: InQuad
                    apply: { draw_bg: {slide_x: -300.0} }
                }
                open = {
                    from: {all: Forward {duration: 0.4}}
                    ease: ExpDecay {d1: 0.8, d2: 0.97}
                    apply: { draw_bg: {slide_x: 0.0} }
                }
            }
        }
    }
}
```

## Pulse/Glow Effect

```rust
animator: {
    pulse = {
        default: on,
        on = {
            from: {all: Loop {duration: 2.0, end: 1.0}}
            apply: {
                draw_bg: {
                    glow_intensity: [
                        {time: 0.0, value: 0.3},
                        {time: 0.5, value: 1.0},
                        {time: 1.0, value: 0.3}
                    ]
                }
            }
        }
        off = {
            from: {all: Forward {duration: 0.3}}
            apply: { draw_bg: {glow_intensity: 0.0} }
        }
    }
}
```

## Bouncing Dots (Loading)

```rust
draw_bg: {
    uniform anim_time: 0.0
    uniform freq: 0.9
    uniform dot_radius: 3.0

    fn pixel(self) -> vec4 {
        let sdf = Sdf2d::viewport(self.pos * self.rect_size);

        let amplitude = self.rect_size.y * 0.2;
        let center_y = self.rect_size.y * 0.5;

        // Three dots with phase offset
        let phase1 = self.anim_time * 2.0 * PI * self.freq;
        let phase2 = phase1 + 2.0;
        let phase3 = phase1 + 4.0;

        sdf.circle(self.rect_size.x * 0.25,
                   amplitude * sin(phase1) + center_y, self.dot_radius);
        sdf.fill_keep(#4A90D9);

        sdf.circle(self.rect_size.x * 0.5,
                   amplitude * sin(phase2) + center_y, self.dot_radius);
        sdf.fill_keep(#4A90D9);

        sdf.circle(self.rect_size.x * 0.75,
                   amplitude * sin(phase3) + center_y, self.dot_radius);
        sdf.fill(#4A90D9);

        return sdf.result;
    }
}

animator: {
    dots = {
        default: off,
        on = {
            from: {all: Loop {duration: 1.0, end: 1.0}}
            apply: {draw_bg: {anim_time: [{time: 0.0, value: 0.0}, {time: 1.0, value: 1.0}]}}
        }
    }
}
```

## When to Use

- Use keyframes for color cycling, complex motion
- Use `Loop` for continuous animations (spinners, pulses)
- Use fade animations for showing/hiding elements
- Use slide for drawer/panel transitions
