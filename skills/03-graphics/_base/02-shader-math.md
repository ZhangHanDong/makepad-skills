---
name: shader-math
author: robius
source: makepad-docs
date: 2024-01-01
tags: [shader, math, interpolation, color, texture]
level: beginner
---

# Shader Math & Colors

Math functions, color operations, and texture sampling.

## Interpolation

```rust
// Linear interpolation
let color = mix(#ff0000, #00ff00, 0.5);  // 50% between red and green

// Smooth interpolation (0 to 1 with easing)
let t = smoothstep(0.0, 1.0, self.pos.x);

// Clamp value to range
let clamped = clamp(value, 0.0, 1.0);

// Step function (hard edge)
let mask = step(0.5, self.pos.x);  // 0 if x < 0.5, else 1
```

## Trigonometry

```rust
let angle = self.pos.x * 2.0 * PI;
let wave = sin(angle);
let wave2 = cos(angle);
```

## Vector Math

```rust
let v = vec2(1.0, 2.0);
let len = length(v);           // Vector length
let norm = normalize(v);       // Unit vector
let d = dot(v1, v2);          // Dot product
let dist = length(self.pos - center);  // Distance
```

## Color Operations

```rust
// Color from hex
let color = #4A90D9;      // RGB
let color = #4A90D9FF;    // RGBA

// Color components
let r = color.r;  // 0.0 to 1.0
let g = color.g;
let b = color.b;
let a = color.a;

// Create color
let color = vec4(1.0, 0.0, 0.0, 1.0);  // Red, full opacity

// Mix colors
let blended = mix(color1, color2, factor);

// Adjust alpha
let semi_transparent = vec4(color.rgb, 0.5);
```

## Texture Sampling

```rust
draw_bg: {
    texture my_image: texture2d

    fn pixel(self) -> vec4 {
        // Sample at current position
        let color = sample2d(self.my_image, self.pos);

        // Sample with custom UV (tiling)
        let custom_uv = vec2(self.pos.x * 2.0, self.pos.y);
        let tiled = sample2d(self.my_image, fract(custom_uv));

        return color;
    }
}
```

## Helper Functions

Define reusable functions within shader:

```rust
draw_bg: {
    fn get_color(self) -> vec4 {
        return mix(self.color_normal, self.color_hover, self.hover);
    }

    fn random(st: vec2) -> f32 {
        return fract(sin(dot(st, vec2(12.9898, 78.233))) * 43758.5453);
    }

    fn pixel(self) -> vec4 {
        let color = self.get_color();
        let noise = random(self.pos);
        return color + vec4(noise * 0.05);
    }
}
```

## Avoid Branching

GPU prefers math over if/else:

```rust
// Avoid if statements in pixel shader
if self.hover > 0.5 {
    return color1;
} else {
    return color2;
}

// Use mix instead
return mix(color2, color1, step(0.5, self.hover));

// Or smoothstep for gradual transition
return mix(color1, color2, smoothstep(0.0, 1.0, self.hover));
```

## When to Use

- Use `mix()` for smooth color transitions
- Use `smoothstep()` for antialiased edges
- Use `step()` for hard conditional without branching
- Use custom helper functions for repeated calculations
