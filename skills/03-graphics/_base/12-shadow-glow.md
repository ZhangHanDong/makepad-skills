---
name: shadow-glow
author: robius
source: makepad-docs
date: 2024-01-01
tags: [shadow, glow, effect, pulse]
level: intermediate
---

# Shadow & Glow Effects

Inner shadows, outer shadows, and glow effects.

## Inner Shadow

```rust
draw_bg: {
    uniform shadow_color: #0007
    uniform shadow_radius: 10.0

    fn pixel(self) -> vec4 {
        let sdf = Sdf2d::viewport(self.pos * self.rect_size);

        sdf.box(0., 0., self.rect_size.x, self.rect_size.y, 4.0);
        let outer_dist = sdf.shape;

        let dist_from_edge = -outer_dist;
        let intensity = 1.0 - smoothstep(0.0, self.shadow_radius, dist_from_edge);
        let shadow_factor = clamp(intensity, 0.0, 1.0) * step(outer_dist, 0.0);

        let base_color = #FFFFFF;
        let final_rgb = mix(base_color.rgb, self.shadow_color.rgb,
                           shadow_factor * self.shadow_color.a);

        sdf.fill(vec4(final_rgb, 1.0));
        return sdf.result;
    }
}
```

## Card with Border

```rust
CurrencyCard = <View> {
    show_bg: true
    draw_bg: {
        color: #1a1a26

        fn pixel(self) -> vec4 {
            let sdf = Sdf2d::viewport(self.pos * self.rect_size);

            // Inset box for border effect
            sdf.box(1.0, 1.0, self.rect_size.x - 2.0, self.rect_size.y - 2.0, 6.0);
            sdf.fill(self.color);

            // Border stroke
            sdf.stroke(#333348, 1.0);

            return sdf.result;
        }
    }
}
```

## Pulsing Glow

```rust
draw_bg: {
    uniform time: 0.0
    color: #00ff88

    fn pixel(self) -> vec4 {
        // Pulsing intensity
        let pulse = sin(self.time * 3.0) * 0.3 + 0.7;
        return self.color * pulse;
    }
}

animator: {
    pulse = {
        default: on,
        on = {
            from: {all: Loop {duration: 2.0, end: 1.0}}
            apply: {draw_bg: {time: [{time: 0.0, value: 0.0}, {time: 1.0, value: 6.28}]}}
        }
    }
}
```

## Noise/Static Effect

```rust
draw_bg: {
    uniform time: 0.0

    fn random(st: vec2) -> f32 {
        return fract(sin(dot(st, vec2(12.9898, 78.233))) * 43758.5453);
    }

    fn pixel(self) -> vec4 {
        let noise = random(self.pos * self.rect_size + vec2(self.time, 0.0));
        let base = #1a1a26;
        return base + vec4(noise * 0.05, noise * 0.05, noise * 0.05, 0.0);
    }
}
```

## Rounded Rectangle with Soft Shadow

```rust
draw_bg: {
    color: #ffffff
    shadow_color: #00000044
    shadow_offset: vec2(4.0, 4.0)
    shadow_blur: 8.0

    fn pixel(self) -> vec4 {
        let sdf = Sdf2d::viewport(self.pos * self.rect_size);
        let radius = 8.0;

        // Shadow (offset and blurred)
        let shadow_pos = self.pos * self.rect_size - self.shadow_offset;
        let shadow_sdf = Sdf2d::viewport(shadow_pos);
        shadow_sdf.box(0., 0., self.rect_size.x, self.rect_size.y, radius);

        // Main shape
        sdf.box(0., 0., self.rect_size.x, self.rect_size.y, radius);
        sdf.fill(self.color);

        return sdf.result;
    }
}
```

## When to Use

- Use inner shadow for depth/embossed effect
- Use glow for highlighting important elements
- Use pulsing for attention-grabbing indicators
- Use noise for texture/visual interest
