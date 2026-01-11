---
name: sdf-drawing
author: robius
source: makepad-docs
date: 2024-01-01
tags: [sdf, line, arc, triangle, path]
level: intermediate
---

# SDF Path Drawing

Lines, arcs, and complex paths in Makepad SDF.

## Line Drawing

```rust
fn pixel(self) -> vec4 {
    let sdf = Sdf2d::viewport(self.pos * self.rect_size);

    // Move to start point
    sdf.move_to(10.0, 10.0);

    // Line to end point
    sdf.line_to(100.0, 50.0);

    // Stroke the line
    sdf.stroke(#ffffff, 2.0);

    return sdf.result;
}
```

## Arc Drawing

```rust
fn pixel(self) -> vec4 {
    let sdf = Sdf2d::viewport(self.pos * self.rect_size);
    let center = self.rect_size * 0.5;
    let radius = min(center.x, center.y) - 4.0;

    // Draw arc from angle1 to angle2
    let start_angle = 0.0;
    let end_angle = PI * 1.5;  // 270 degrees

    sdf.move_to(
        center.x + cos(start_angle) * radius,
        center.y + sin(start_angle) * radius
    );
    sdf.arc(center.x, center.y, radius, start_angle, end_angle);
    sdf.stroke(#4A90D9, 3.0);

    return sdf.result;
}
```

## Triangle Drawing

```rust
fn pixel(self) -> vec4 {
    let sdf = Sdf2d::viewport(self.pos * self.rect_size);

    // Define three vertices
    let v1 = vec2(50.0, 10.0);   // Top
    let v2 = vec2(10.0, 90.0);   // Bottom left
    let v3 = vec2(90.0, 90.0);   // Bottom right

    sdf.move_to(v1.x, v1.y);
    sdf.line_to(v2.x, v2.y);
    sdf.line_to(v3.x, v3.y);
    sdf.close_path();

    sdf.fill(#4A90D9);

    return sdf.result;
}
```

## Combining Shapes

```rust
fn pixel(self) -> vec4 {
    let sdf = Sdf2d::viewport(self.pos * self.rect_size);

    // First shape - fill and keep
    sdf.circle(50., 50., 30.);
    sdf.fill_keep(#FF0000);

    // Second shape - additive
    sdf.circle(80., 50., 30.);
    sdf.fill(#00FF00);

    return sdf.result;
}
```

## Orientation-Switchable Shape

Use instance variable for vertical/horizontal:

```rust
draw_track: {
    instance vertical: 0.0  // 0.0 = horizontal, 1.0 = vertical

    fn pixel(self) -> vec4 {
        let sdf = Sdf2d::viewport(self.pos * self.rect_size);
        let sz = self.rect_size;

        let is_vert = self.vertical;
        let length = mix(sz.x, sz.y, is_vert);
        let thickness = mix(sz.y, sz.x, is_vert);
        let r = thickness * 0.5;

        if is_vert > 0.5 {
            sdf.circle(r, r, r);
            sdf.rect(0.0, r, sz.x, sz.y - sz.x);
            sdf.circle(r, sz.y - r, r);
        } else {
            sdf.circle(r, r, r);
            sdf.rect(r, 0.0, sz.x - sz.y, sz.y);
            sdf.circle(sz.x - r, r, r);
        }

        sdf.fill(#e2e8f0);
        return sdf.result;
    }
}
```

Note: Using `if` in shape construction is acceptable since it's a static branch.

## When to Use

- Use `move_to/line_to` for custom polygons and paths
- Use `arc` for progress indicators, circular UI
- Use `close_path` for filled polygons
- Use `fill_keep` to draw multiple shapes additively
