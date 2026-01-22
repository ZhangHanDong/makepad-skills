# Makepad Shader Basics Reference

## Overview

Makepad shaders are written in a custom language that's a subset of Rust syntax. They compile at runtime to platform-specific GPU code (Metal, WebGPU, Vulkan, etc.).

## Shader Types

### draw_bg (Background)

Most common shader for widget backgrounds.

```rust
<View> {
    show_bg: true
    draw_bg: {
        // Uniforms
        color: #FF0000

        // Pixel shader
        fn pixel(self) -> vec4 {
            return self.color;
        }
    }
}
```

### draw_text (Text)

For text rendering.

```rust
<Label> {
    draw_text: {
        color: #FFFFFF
        text_style: { font_size: 14.0 }

        fn get_color(self) -> vec4 {
            return self.color;
        }
    }
}
```

### draw_icon (Icons)

For SVG icon rendering.

```rust
<Button> {
    draw_icon: {
        color: #FFFFFF
        svg_file: dep("crate://self/icons/menu.svg")
    }
}
```

## Uniform Types

| Type | DSL Example | Shader Type |
|------|-------------|-------------|
| Color | `color: #FF0000` | `vec4` |
| Float | `radius: 8.0` | `float` |
| Vec2 | `offset: { x: 1.0, y: 2.0 }` | `vec2` |
| Vec4 | `inset: { ... }` | `vec4` |
| Texture | `image: texture2d` | `texture2d` |

## Built-in Variables

### Position and Size

```rust
fn pixel(self) -> vec4 {
    // Normalized position (0.0 to 1.0)
    let uv = self.pos;

    // Widget size in pixels
    let size = self.rect_size;

    // Actual pixel position
    let pixel_pos = self.pos * self.rect_size;

    // ...
}
```

### Available Built-ins

| Variable | Type | Description |
|----------|------|-------------|
| `self.pos` | vec2 | Normalized UV (0-1) |
| `self.rect_size` | vec2 | Widget dimensions |
| `self.rect_pos` | vec2 | Widget position |
| `self.draw_clip` | vec4 | Clipping rectangle |

## Basic Shader Examples

### Solid Color

```rust
draw_bg: {
    color: #0066CC

    fn pixel(self) -> vec4 {
        return self.color;
    }
}
```

### Horizontal Gradient

```rust
draw_bg: {
    color: #FF0000
    color_2: #0000FF

    fn pixel(self) -> vec4 {
        return mix(self.color, self.color_2, self.pos.x);
    }
}
```

### Vertical Gradient

```rust
draw_bg: {
    color: #FF0000
    color_2: #0000FF

    fn pixel(self) -> vec4 {
        return mix(self.color, self.color_2, self.pos.y);
    }
}
```

### Radial Gradient

```rust
draw_bg: {
    color: #FFFFFF
    color_2: #000000

    fn pixel(self) -> vec4 {
        let center = vec2(0.5, 0.5);
        let dist = length(self.pos - center) * 2.0;
        return mix(self.color, self.color_2, clamp(dist, 0.0, 1.0));
    }
}
```

### Checkerboard Pattern

```rust
draw_bg: {
    color: #333333
    color_2: #444444
    size: 20.0

    fn pixel(self) -> vec4 {
        let p = floor(self.pos * self.rect_size / self.size);
        let checker = mod(p.x + p.y, 2.0);
        return mix(self.color, self.color_2, checker);
    }
}
```

## Built-in Functions

### Math Functions

```rust
abs(x)          // Absolute value
sign(x)         // Sign (-1, 0, 1)
floor(x)        // Floor
ceil(x)         // Ceiling
fract(x)        // Fractional part
mod(x, y)       // Modulo
min(x, y)       // Minimum
max(x, y)       // Maximum
clamp(x, a, b)  // Clamp to range
```

### Interpolation

```rust
mix(a, b, t)        // Linear interpolation
step(edge, x)       // Step function
smoothstep(a, b, x) // Smooth interpolation
```

### Trigonometric

```rust
sin(x), cos(x), tan(x)
asin(x), acos(x), atan(x)
radians(deg), degrees(rad)
```

### Vector Operations

```rust
length(v)           // Vector length
distance(a, b)      // Distance between points
dot(a, b)           // Dot product
cross(a, b)         // Cross product (vec3)
normalize(v)        // Normalize vector
reflect(i, n)       // Reflection
refract(i, n, eta)  // Refraction
```

### Exponential

```rust
pow(x, y)       // Power
exp(x)          // e^x
exp2(x)         // 2^x
log(x)          // Natural log
log2(x)         // Log base 2
sqrt(x)         // Square root
inversesqrt(x)  // 1/sqrt(x)
```

## Vertex Shaders

For advanced positioning:

```rust
draw_bg: {
    fn vertex(self) -> vec4 {
        // Transform vertex position
        let pos = self.clip_and_transform_vertex(
            self.rect_pos,
            self.rect_size
        );
        return pos;
    }

    fn pixel(self) -> vec4 {
        return self.color;
    }
}
```

## Texture Sampling

```rust
draw_bg: {
    image: texture2d

    fn pixel(self) -> vec4 {
        return sample2d(self.image, self.pos);
    }
}
```

## Live Editing

Shaders are live-reloaded. Edit shader code and see changes immediately without recompilation. This enables rapid visual development and iteration.
