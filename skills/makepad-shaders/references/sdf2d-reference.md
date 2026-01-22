# Makepad Sdf2d Reference

## Overview

`Sdf2d` (Signed Distance Field 2D) is Makepad's primary tool for drawing 2D shapes in shaders. It provides a high-level API for shapes, paths, fills, strokes, and boolean operations.

## Creating Sdf2d Context

```rust
fn pixel(self) -> vec4 {
    // Create SDF context with pixel coordinates
    let sdf = Sdf2d::viewport(self.pos * self.rect_size);

    // Draw shapes...

    return sdf.result;
}
```

## Shapes

### Circle

```rust
sdf.circle(center_x, center_y, radius);

// Example: centered circle
let c = self.rect_size * 0.5;
sdf.circle(c.x, c.y, min(c.x, c.y) - 1.0);
```

### Rectangle

```rust
sdf.rect(x, y, width, height);

// Example: full widget rect with padding
sdf.rect(2.0, 2.0, self.rect_size.x - 4.0, self.rect_size.y - 4.0);
```

### Box (Rounded Rectangle)

```rust
sdf.box(x, y, width, height, radius);

// Example: rounded corners
sdf.box(1.0, 1.0,
        self.rect_size.x - 2.0,
        self.rect_size.y - 2.0,
        8.0);
```

### Box Variants

```rust
// Individual corner radii
sdf.box_all(x, y, w, h, r_tl, r_tr, r_br, r_bl);

// Horizontal only (left/right)
sdf.box_x(x, y, w, h, r_left, r_right);

// Vertical only (top/bottom)
sdf.box_y(x, y, w, h, r_top, r_bottom);
```

### Hexagon

```rust
sdf.hexagon(center_x, center_y, radius);
```

### Horizontal Line

```rust
sdf.hline(y, x1, x2);
```

### Arc

```rust
sdf.arc2(center_x, center_y, inner_radius, outer_radius, start_angle, end_angle);
```

## Paths

### Creating Paths

```rust
// Start path
sdf.move_to(x, y);

// Draw lines
sdf.line_to(x1, y1);
sdf.line_to(x2, y2);

// Close path (connect to start)
sdf.close_path();
```

### Path Example: Triangle

```rust
fn pixel(self) -> vec4 {
    let sdf = Sdf2d::viewport(self.pos * self.rect_size);
    let s = self.rect_size;

    sdf.move_to(s.x * 0.5, 5.0);          // Top
    sdf.line_to(s.x - 5.0, s.y - 5.0);    // Bottom right
    sdf.line_to(5.0, s.y - 5.0);          // Bottom left
    sdf.close_path();

    sdf.fill(self.color);
    return sdf.result;
}
```

## Fill and Stroke

### Fill

```rust
// Fill and consume shape
sdf.fill(color);

// Fill but keep shape for stroke
sdf.fill_keep(color);

// Fill with premultiplied alpha
sdf.fill_premul(color);
sdf.fill_keep_premul(color);
```

### Stroke

```rust
// Stroke and consume shape
sdf.stroke(color, width);

// Stroke but keep shape
sdf.stroke_keep(color, width);
```

### Fill + Stroke Example

```rust
fn pixel(self) -> vec4 {
    let sdf = Sdf2d::viewport(self.pos * self.rect_size);

    sdf.box(1.0, 1.0,
            self.rect_size.x - 2.0,
            self.rect_size.y - 2.0,
            self.border_radius);

    sdf.fill_keep(self.color);
    sdf.stroke(self.border_color, self.border_size);

    return sdf.result;
}
```

## Boolean Operations

### Union

Combine shapes (add).

```rust
sdf.circle(50.0, 50.0, 30.0);
sdf.union();  // Merge with previous shape
sdf.circle(80.0, 50.0, 30.0);
sdf.fill(color);
```

### Intersect

Keep only overlapping area.

```rust
sdf.circle(50.0, 50.0, 40.0);
sdf.intersect();
sdf.rect(30.0, 30.0, 40.0, 40.0);
sdf.fill(color);
```

### Subtract

Remove second shape from first.

```rust
sdf.circle(50.0, 50.0, 40.0);
sdf.subtract();
sdf.circle(60.0, 50.0, 20.0);
sdf.fill(color);
```

## Transformations

### Translate

```rust
sdf.translate(offset_x, offset_y);
sdf.circle(0.0, 0.0, 20.0);  // Drawn at offset
```

### Rotate

```rust
sdf.rotate(angle_radians, center_x, center_y);
sdf.rect(-20.0, -20.0, 40.0, 40.0);
```

### Scale

```rust
sdf.scale(scale_factor, center_x, center_y);
sdf.circle(0.0, 0.0, 10.0);  // Scaled
```

## Effects

### Glow

Add glow effect.

```rust
sdf.circle(50.0, 50.0, 30.0);
sdf.glow(glow_color, glow_radius);

// Or keep shape for more operations
sdf.glow_keep(glow_color, glow_radius);
```

### Gloop

Soft blend between shapes.

```rust
sdf.circle(40.0, 50.0, 25.0);
sdf.gloop(blend_amount);
sdf.circle(70.0, 50.0, 25.0);
sdf.fill(color);
```

## Sdf2d Fields

| Field | Type | Description |
|-------|------|-------------|
| `pos` | vec2 | Current position |
| `result` | vec4 | Final color output |
| `shape` | float | Current shape distance |
| `dist` | float | Distance field value |
| `aa` | float | Anti-aliasing factor |
| `blur` | float | Blur amount |
| `clip` | float | Clip region |
| `scale_factor` | float | Current scale |

## Complete Examples

### Rounded Button

```rust
draw_bg: {
    color: #0066CC
    color_hover: #0088FF
    border_radius: 6.0

    fn pixel(self) -> vec4 {
        let sdf = Sdf2d::viewport(self.pos * self.rect_size);
        sdf.box(1.0, 1.0,
                self.rect_size.x - 2.0,
                self.rect_size.y - 2.0,
                self.border_radius);
        sdf.fill(self.color);
        return sdf.result;
    }
}
```

### Circle with Shadow

```rust
draw_bg: {
    color: #FFFFFF
    shadow_color: #00000044

    fn pixel(self) -> vec4 {
        let sdf = Sdf2d::viewport(self.pos * self.rect_size);
        let c = self.rect_size * 0.5;
        let r = min(c.x, c.y) - 10.0;

        // Shadow
        sdf.circle(c.x + 3.0, c.y + 3.0, r);
        sdf.fill(self.shadow_color);

        // Main circle
        sdf.circle(c.x, c.y, r);
        sdf.fill(self.color);

        return sdf.result;
    }
}
```

### Ring Shape

```rust
draw_bg: {
    color: #0066CC
    inner_radius: 20.0
    outer_radius: 40.0

    fn pixel(self) -> vec4 {
        let sdf = Sdf2d::viewport(self.pos * self.rect_size);
        let c = self.rect_size * 0.5;

        sdf.circle(c.x, c.y, self.outer_radius);
        sdf.subtract();
        sdf.circle(c.x, c.y, self.inner_radius);
        sdf.fill(self.color);

        return sdf.result;
    }
}
```
