---
name: gradient-effects
author: robius
source: makepad-docs
date: 2024-01-01
tags: [gradient, background, color, effect]
level: beginner
---

# Gradient Effects

Linear, radial, and custom gradients.

## Vertical Gradient

```rust
draw_bg: {
    uniform color1: #4A90D9
    uniform color2: #2E5A8A

    fn pixel(self) -> vec4 {
        let sdf = Sdf2d::viewport(self.pos * self.rect_size);
        sdf.box(0., 0., self.rect_size.x, self.rect_size.y, 0.0);

        // Vertical gradient (top to bottom)
        let gradient = mix(self.color1, self.color2, self.pos.y);
        sdf.fill(gradient);

        return sdf.result;
    }
}
```

## Horizontal Gradient

```rust
fn pixel(self) -> vec4 {
    let gradient = mix(self.color1, self.color2, self.pos.x);
    // ...
}
```

## Radial Gradient

```rust
draw_bg: {
    color: #4A90D9
    color2: #1a1a26

    fn pixel(self) -> vec4 {
        let center = vec2(0.5, 0.5);
        let dist = length(self.pos - center);

        // Radial gradient from center
        return mix(self.color, self.color2, dist * 2.0);
    }
}
```

## Vignette Effect

```rust
fn pixel(self) -> vec4 {
    let img = sample2d(self.image, self.pos);

    // Distance from center
    let center = vec2(0.5, 0.5);
    let dist = length(self.pos - center);

    // Vignette darkening
    let vignette = smoothstep(0.7, 0.2, dist);

    return img * vignette;
}
```

## Scanline Background (CRT Effect)

```rust
draw_bg: {
    color: #0a0a12

    fn pixel(self) -> vec4 {
        // Vertical gradient
        let bg = mix(self.color, self.color * 1.1, self.pos.y);

        // Scanline effect
        let scanline = sin(self.pos.y * 500.0) * 0.012;

        return bg + vec4(scanline, scanline, scanline * 1.2, 0.0);
    }
}
```

## Glowing Divider

```rust
divider = <View> {
    width: Fill
    height: 1
    show_bg: true
    draw_bg: {
        color: #00ff88

        fn pixel(self) -> vec4 {
            // Horizontal sine wave glow
            let glow = sin(self.pos.x * 8.0) * 0.3 + 0.5;
            return self.color * glow;
        }
    }
}
```

## When to Use

- Use vertical gradient for headers, cards
- Use radial gradient for spotlight effects
- Use vignette for image focus
- Use scanlines for retro/tech aesthetics
