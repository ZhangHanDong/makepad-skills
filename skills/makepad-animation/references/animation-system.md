# Makepad Animation System Reference

## Overview

Makepad's animation system is based on **states** and **transitions**. Each widget can have multiple states (hover, pressed, focus, etc.), and the animator smoothly transitions between property values when states change.

## Animator Structure

```rust
<Widget> {
    animator: {
        // State 1
        state_name = {
            default: initial_value    // Initial state

            value_1 = {
                from: { ... }         // Transition timing
                apply: { ... }        // Properties to change
            }

            value_2 = {
                from: { ... }
                apply: { ... }
            }
        }

        // State 2
        another_state = {
            // ...
        }
    }
}
```

## State Values

### Common State Patterns

#### On/Off States
```rust
hover = {
    default: off

    off = {
        from: { all: Forward { duration: 0.15 } }
        apply: { draw_bg: { color: #333333 } }
    }

    on = {
        from: { all: Forward { duration: 0.15 } }
        apply: { draw_bg: { color: #555555 } }
    }
}
```

#### Custom Values
```rust
mode = {
    default: normal

    normal = {
        from: { all: Forward { duration: 0.2 } }
        apply: { draw_bg: { color: #333333 } }
    }

    active = {
        from: { all: Forward { duration: 0.2 } }
        apply: { draw_bg: { color: #0066CC } }
    }

    error = {
        from: { all: Forward { duration: 0.2 } }
        apply: { draw_bg: { color: #CC0000 } }
    }
}
```

## Timeline Types

### Forward

Linear animation over duration.

```rust
from: {
    all: Forward { duration: 0.2 }
}
```

### Snap

Instant change, no animation.

```rust
from: {
    all: Snap
}
```

### Ease

Animation with easing function.

```rust
from: {
    all: Ease {
        duration: 0.3
        ease: InOutQuad
    }
}
```

### Per-State Transitions

Different timing from different previous states:

```rust
from: {
    off: Forward { duration: 0.1 }    // Fast from off
    on: Forward { duration: 0.3 }     // Slow from on
    all: Forward { duration: 0.2 }    // Default for others
}
```

## Apply Properties

### Basic Properties

```rust
apply: {
    draw_bg: {
        color: #FF0000
        border_radius: 8.0
        border_size: 2.0
    }
}
```

### Nested Properties

```rust
apply: {
    draw_bg: {
        color: #0066CC
        border_color: #0088FF
    }
    draw_text: {
        color: #FFFFFF
    }
    draw_icon: {
        color: #FFFFFF
    }
}
```

### Transform Properties

```rust
apply: {
    draw_bg: {
        scale: 0.95          // Scale factor
        rotation: 45.0       // Degrees
        offset: { x: 5.0, y: 5.0 }
    }
}
```

## Common Animation Patterns

### Hover Effect

```rust
animator: {
    hover = {
        default: off

        off = {
            from: { all: Forward { duration: 0.15 } }
            apply: {
                draw_bg: {
                    color: #333333
                    border_color: #444444
                }
            }
        }

        on = {
            from: { all: Forward { duration: 0.15 } }
            apply: {
                draw_bg: {
                    color: #444444
                    border_color: #666666
                }
            }
        }
    }
}
```

### Press Effect

```rust
animator: {
    pressed = {
        default: off

        off = {
            from: { all: Forward { duration: 0.1 } }
            apply: {
                draw_bg: { scale: 1.0 }
            }
        }

        on = {
            from: { all: Forward { duration: 0.05 } }
            apply: {
                draw_bg: { scale: 0.97 }
            }
        }
    }
}
```

### Focus Ring

```rust
animator: {
    focus = {
        default: off

        off = {
            from: { all: Forward { duration: 0.2 } }
            apply: {
                draw_bg: {
                    border_size: 0.0
                    border_color: #00000000
                }
            }
        }

        on = {
            from: { all: Forward { duration: 0.2 } }
            apply: {
                draw_bg: {
                    border_size: 2.0
                    border_color: #0066CCFF
                }
            }
        }
    }
}
```

### Disabled State

```rust
animator: {
    disabled = {
        default: off

        off = {
            from: { all: Snap }
            apply: {
                draw_bg: { color: #0066CC }
                draw_text: { color: #FFFFFF }
            }
        }

        on = {
            from: { all: Snap }
            apply: {
                draw_bg: { color: #222222 }
                draw_text: { color: #444444 }
            }
        }
    }
}
```

### Complete Button Animation

```rust
<Button> {
    text: "Animated Button"

    animator: {
        hover = {
            default: off
            off = {
                from: { all: Forward { duration: 0.15 } }
                apply: {
                    draw_bg: { color: #0066CC }
                }
            }
            on = {
                from: { all: Forward { duration: 0.15 } }
                apply: {
                    draw_bg: { color: #0088FF }
                }
            }
        }

        pressed = {
            default: off
            off = {
                from: { all: Forward { duration: 0.1 } }
                apply: {
                    draw_bg: { color: #0066CC }
                }
            }
            on = {
                from: { all: Forward { duration: 0.05 } }
                apply: {
                    draw_bg: { color: #004499 }
                }
            }
        }

        disabled = {
            default: off
            off = {
                from: { all: Snap }
                apply: {
                    draw_bg: { color: #0066CC }
                    draw_text: { color: #FFFFFF }
                }
            }
            on = {
                from: { all: Snap }
                apply: {
                    draw_bg: { color: #333333 }
                    draw_text: { color: #666666 }
                }
            }
        }
    }
}
```

## Triggering Animations in Rust

```rust
// Animate to a state
self.ui.view(id!(my_view)).animator_play(cx, id!(hover.on));

// Cut to state (no animation)
self.ui.view(id!(my_view)).animator_cut(cx, id!(hover.off));

// Check current state
if self.ui.view(id!(my_view)).animator_in_state(cx, id!(hover.on)) {
    // Currently hovering
}
```
