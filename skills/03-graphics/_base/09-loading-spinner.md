---
name: loading-spinner
author: robius
source: makepad-docs
date: 2024-01-01
tags: [spinner, loading, animation, arc]
level: intermediate
---

# Loading Spinner

Rotating arc animation for loading states.

## Implementation

```rust
live_design! {
    Spinner = {{Spinner}} {
        width: 40, height: 40

        draw_bg: {
            instance rotation: 0.0

            fn pixel(self) -> vec4 {
                let sdf = Sdf2d::viewport(self.pos * self.rect_size);
                let center = self.rect_size * 0.5;
                let radius = min(center.x, center.y) - 4.0;

                // Rotating arc
                let angle = self.rotation * 2.0 * PI;
                let arc_start = angle;
                let arc_end = angle + PI * 1.5;

                sdf.move_to(
                    center.x + cos(arc_start) * radius,
                    center.y + sin(arc_start) * radius
                );
                sdf.arc(center.x, center.y, radius, arc_start, arc_end);
                sdf.stroke(#4A90D9, 3.0);

                return sdf.result;
            }
        }

        animator: {
            spin = {
                default: on,
                on = {
                    from: {all: Loop {duration: 1.0, end: 1.0}}
                    apply: {
                        draw_bg: {
                            rotation: [{time: 0.0, value: 0.0}, {time: 1.0, value: 1.0}]
                        }
                    }
                }
            }
        }
    }
}
```

## Rust Implementation

```rust
#[derive(Live, LiveHook, Widget)]
pub struct Spinner {
    #[deref] view: View,
    #[animator] animator: Animator,
}

impl Widget for Spinner {
    fn handle_event(&mut self, cx: &mut Cx, event: &Event, scope: &mut Scope) {
        if self.animator_handle_event(cx, event).must_redraw() {
            self.redraw(cx);
        }
    }

    fn draw_walk(&mut self, cx: &mut Cx2d, scope: &mut Scope, walk: Walk) -> DrawStep {
        // Start spinning animation
        if self.animator.is_default() {
            self.animator_play(cx, ids!(spin.on));
        }
        self.view.draw_walk(cx, scope, walk)
    }
}
```

## Usage

```rust
live_design! {
    <Spinner> {
        width: 24, height: 24
    }
}
```

## Customization

### Different Colors

```rust
<Spinner> {
    draw_bg: {
        fn pixel(self) -> vec4 {
            // ... same shader code ...
            sdf.stroke(#10b981, 3.0);  // Green spinner
            return sdf.result;
        }
    }
}
```

### Different Speed

```rust
animator: {
    spin = {
        default: on,
        on = {
            from: {all: Loop {duration: 0.6, end: 1.0}}  // Faster
            // ...
        }
    }
}
```

## When to Use

- Use for loading states during async operations
- Use for indicating background processing
- Auto-starts on draw, no manual triggering needed
