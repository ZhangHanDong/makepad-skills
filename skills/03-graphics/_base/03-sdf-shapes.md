---
name: sdf-shapes
author: robius
source: makepad-docs
date: 2024-01-01
tags: [sdf, shapes, circle, box, hexagon]
level: beginner
---

# SDF Basic Shapes

Signed Distance Field primitives in Makepad.

## SDF Operations

| Function | Description |
|----------|-------------|
| `sdf.circle(x, y, r)` | Circle at (x,y) with radius r |
| `sdf.box(x, y, w, h, r)` | Rounded rect with corner radius r |
| `sdf.hexagon(x, y, r)` | Hexagon |
| `sdf.fill(color)` | Fill current shape |
| `sdf.stroke(color, width)` | Stroke outline |
| `sdf.fill_keep(color)` | Fill and preserve shape |
| `sdf.stroke_keep(color, width)` | Stroke and preserve shape |

## Circle

```rust
fn pixel(self) -> vec4 {
    let sdf = Sdf2d::viewport(self.pos * self.rect_size);
    let center = self.rect_size * 0.5;
    let radius = min(center.x, center.y) - 2.0;

    sdf.circle(center.x, center.y, radius);
    sdf.fill(#4A90D9);

    return sdf.result;
}
```

## Rounded Rectangle

```rust
fn pixel(self) -> vec4 {
    let sdf = Sdf2d::viewport(self.pos * self.rect_size);

    sdf.box(
        0.0,                   // x
        0.0,                   // y
        self.rect_size.x,      // width
        self.rect_size.y,      // height
        8.0                    // corner radius
    );
    sdf.fill(#ffffff);

    return sdf.result;
}
```

## Capsule/Stadium Shape

**Important**: `sdf.box()` with large radius may not produce correct capsule shapes. Use shape composition:

```rust
fn pixel(self) -> vec4 {
    let sdf = Sdf2d::viewport(self.pos * self.rect_size);
    let sz = self.rect_size;
    let r = sz.y * 0.5;

    // Draw capsule: left circle + rectangle + right circle
    sdf.circle(r, r, r);
    sdf.rect(r, 0.0, sz.x - sz.y, sz.y);
    sdf.circle(sz.x - r, r, r);

    sdf.fill(#3b82f6);
    return sdf.result;
}
```

## Fill with Stroke

```rust
fn pixel(self) -> vec4 {
    let sdf = Sdf2d::viewport(self.pos * self.rect_size);

    sdf.box(2., 2., self.rect_size.x - 4., self.rect_size.y - 4., 6.0);
    sdf.fill(#1a1a26);      // Fill color
    sdf.stroke(#333348, 1.0);  // Border color, width

    return sdf.result;
}
```

## Circular Avatar Mask

```rust
draw_bg: {
    fn pixel(self) -> vec4 {
        let sdf = Sdf2d::viewport(self.pos * self.rect_size);
        let c = self.rect_size * 0.5;

        sdf.circle(c.x, c.y, c.x);
        let img_color = sample2d(self.image, self.pos);
        sdf.fill(img_color);

        return sdf.result;
    }
}
```

## Inset for Border Effect

```rust
fn pixel(self) -> vec4 {
    let sdf = Sdf2d::viewport(self.pos * self.rect_size);

    // Inset box leaves room for border
    sdf.box(
        1.0,
        1.0,
        self.rect_size.x - 2.0,
        self.rect_size.y - 2.0,
        6.0
    );
    sdf.fill(#1a1a26);
    sdf.stroke(#333348, 1.0);

    return sdf.result;
}
```

## When to Use

- Use `circle` for avatars, dots, round buttons
- Use `box` for cards, panels, buttons
- Use capsule composition for pill-shaped elements (switches, tags)
- Use `fill_keep` when you need to add more shapes to the same SDF
