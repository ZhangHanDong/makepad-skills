---
name: shader-structure
author: robius
source: makepad-docs
date: 2024-01-01
tags: [shader, structure, instance, uniform, basics]
level: beginner
---

# Shader Structure

Basic Makepad shader architecture and variable types.

## Basic Structure

```rust
live_design! {
    MyWidget = {{MyWidget}} {
        draw_bg: {
            // Instance variables (per-widget)
            instance hover: 0.0
            instance pressed: 0.0

            // Uniforms (global parameters)
            uniform color: #4A90D9
            uniform border_radius: 4.0

            fn pixel(self) -> vec4 {
                let sdf = Sdf2d::viewport(self.pos * self.rect_size);
                sdf.box(0., 0., self.rect_size.x, self.rect_size.y, self.border_radius);
                sdf.fill(self.color);
                return sdf.result;
            }
        }
    }
}
```

## Variable Types

| Type | Scope | Usage |
|------|-------|-------|
| `instance` | Per-widget | `instance hover: 0.0` |
| `uniform` | Global | `uniform color: #4A90D9` |
| `varying` | Vertex->Fragment | `varying uv: vec2` |
| `texture` | Texture sampler | `texture my_tex: texture2d` |

## Instance Variables

Per-widget state that can be animated:

```rust
draw_bg: {
    instance hover: 0.0      // 0.0 to 1.0 for hover animation
    instance pressed: 0.0    // 0.0 to 1.0 for press animation
    instance selected: 0.0   // 0.0 or 1.0 for selection state
    instance disabled: 0.0   // 0.0 or 1.0 for disabled state
    instance progress: 0.0   // 0.0 to 1.0 for progress
}
```

## Uniform Variables

Global parameters shared across all instances:

```rust
draw_bg: {
    uniform color: #4A90D9           // Color
    uniform border_radius: 4.0       // Number
    uniform shadow_offset: vec2(2.0, 2.0)  // Vector
}
```

## Built-in Variables

| Variable | Type | Description |
|----------|------|-------------|
| `self.pos` | vec2 | Normalized position (0-1) within widget |
| `self.rect_size` | vec2 | Widget size in pixels |
| `self.rect_pos` | vec2 | Widget position in window |
| `self.geom_pos` | vec2 | Geometry position |

## Using Built-in Variables

```rust
fn pixel(self) -> vec4 {
    // Position within widget (0-1)
    let x = self.pos.x;  // 0 at left, 1 at right
    let y = self.pos.y;  // 0 at top, 1 at bottom

    // Pixel position
    let px = self.pos * self.rect_size;  // In pixels

    // Widget dimensions
    let width = self.rect_size.x;
    let height = self.rect_size.y;

    // Create SDF viewport
    let sdf = Sdf2d::viewport(self.pos * self.rect_size);
    // ...
}
```

## When to Use

- Use `instance` for per-widget animated state (hover, pressed, etc.)
- Use `uniform` for global parameters that apply to all instances
- Access `self.pos` for position-based effects
- Access `self.rect_size` for dimension-based calculations
