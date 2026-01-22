# Styling Patterns Reference

Dynamic styling patterns in Makepad.

## apply_over Usage

```rust
// Apply color
self.view(ids!(bg)).apply_over(cx, live! {
    draw_bg: { color: #ff0000 }
});

// Apply multiple properties
self.view(ids!(content)).apply_over(cx, live! {
    padding: { left: 20, right: 20, top: 10, bottom: 10 }
    margin: { left: 5 }
});

// Apply with Rust variables
let color = if is_active { vec4(1.0, 0.0, 0.0, 1.0) } else { vec4(0.5, 0.5, 0.5, 1.0) };
let padding = if is_compact { 5.0 } else { 15.0 };

self.view(ids!(item)).apply_over(cx, live! {
    draw_bg: { color: (color) }
    padding: (padding)
});
```

## Shader Uniforms

Define custom shader uniforms:

```rust
live_design! {
    MyView = <View> {
        show_bg: true,
        draw_bg: {
            uniform highlight: 0.0
            uniform border_color: #000

            fn pixel(self) -> vec4 {
                let base_color = mix(#fff, #fafafa, self.highlight);
                // Use uniforms in shader
                return base_color
            }
        }
    }
}

// Update uniform at runtime
self.view(ids!(my_view)).apply_over(cx, live! {
    draw_bg: { highlight: 1.0 }
});
```

## Animator for Transitions

```rust
live_design! {
    MyWidget = {{MyWidget}} {
        animator: {
            highlight = {
                default: off
                off = {
                    redraw: true,
                    from: { all: Forward {duration: 2.0} }
                    ease: ExpDecay {d1: 0.80, d2: 0.97}
                    apply: { draw_bg: {highlight: 0.0} }
                }
                on = {
                    redraw: true,
                    from: { all: Forward {duration: 0.5} }
                    ease: ExpDecay {d1: 0.80, d2: 0.97}
                    apply: { draw_bg: {highlight: 1.0} }
                }
            }
            hover = {
                default: off
                off = {
                    redraw: true,
                    from: { all: Snap }
                    apply: { draw_bg: {hover: 0.0} }
                }
                on = {
                    redraw: true,
                    from: { all: Snap }
                    apply: { draw_bg: {hover: 1.0} }
                }
            }
        }
    }
}

impl MyWidget {
    fn highlight(&mut self, cx: &mut Cx) {
        self.animator_play(cx, id!(highlight.on));
    }

    fn unhighlight(&mut self, cx: &mut Cx) {
        self.animator_play(cx, id!(highlight.off));
    }
}
```

## Conditional Styling

```rust
impl MyWidget {
    fn update_style(&mut self, cx: &mut Cx) {
        // Based on state
        let (bg_color, text_color) = match self.state {
            State::Normal => (vec4(1.0, 1.0, 1.0, 1.0), vec4(0.0, 0.0, 0.0, 1.0)),
            State::Selected => (vec4(0.9, 0.95, 1.0, 1.0), vec4(0.0, 0.0, 0.8, 1.0)),
            State::Disabled => (vec4(0.9, 0.9, 0.9, 1.0), vec4(0.5, 0.5, 0.5, 1.0)),
        };

        self.view(ids!(container)).apply_over(cx, live! {
            draw_bg: { color: (bg_color) }
        });

        self.label(ids!(text)).apply_over(cx, live! {
            draw_text: { color: (text_color) }
        });
    }
}
```

## Size and Layout

```rust
// Dynamic sizing
let width = if is_expanded { 300.0 } else { 100.0 };
self.view(ids!(panel)).apply_over(cx, live! {
    width: (width)
});

// Fit vs Fill
self.view(ids!(content)).apply_over(cx, live! {
    width: Fill,
    height: Fit,
});

// Absolute positioning (in Overlay flow)
let pos_x = 100.0;
let pos_y = 50.0;
self.view(ids!(popup)).apply_over(cx, live! {
    margin: { left: (pos_x), top: (pos_y) }
});
```

## Theme-Aware Colors

```rust
// Define theme colors in styles
live_design! {
    // In styles.rs
    COLOR_PRIMARY = #1a73e8
    COLOR_BG = #ffffff
    COLOR_TEXT = #202124
    COLOR_SECONDARY = #5f6368

    // Use in widgets
    MyButton = <Button> {
        draw_bg: { color: (COLOR_PRIMARY) }
        draw_text: { color: #fff }
    }
}
```

## Mentions Bar Pattern

Custom shader for side indicator:

```rust
live_design! {
    Message = <View> {
        show_bg: true
        draw_bg: {
            instance mentions_bar_color: #ffffff
            instance mentions_bar_width: 4.0

            fn pixel(self) -> vec4 {
                let sdf = Sdf2d::viewport(self.pos * self.rect_size);

                // Draw main background
                sdf.rect(0., 0., self.rect_size.x, self.rect_size.y);
                sdf.fill(self.color);

                // Draw left vertical indicator bar
                sdf.rect(0., 0., self.mentions_bar_width, self.rect_size.y);
                sdf.fill(self.mentions_bar_color);

                return sdf.result;
            }
        }
    }
}

// Set mentions bar color
let bar_color = if has_mention { vec4(1.0, 0.8, 0.0, 1.0) } else { vec4(1.0, 1.0, 1.0, 0.0) };
self.view(ids!(message)).apply_over(cx, live! {
    draw_bg: { mentions_bar_color: (bar_color) }
});
```
