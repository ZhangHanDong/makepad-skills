# Makepad 2.0 Sdf2d Reference

## SDF2D Primitives

```
let sdf = Sdf2d.viewport(self.pos * self.rect_size)
sdf.circle(cx, cy, radius)
sdf.rect(x, y, w, h)
sdf.box(x, y, w, h, border_radius)
sdf.box_all(x, y, w, h, r_lt, r_rt, r_rb, r_lb)  // per-corner
sdf.box_x(x, y, w, h, r_left, r_right)
sdf.box_y(x, y, w, h, r_top, r_bottom)
sdf.hexagon(cx, cy, radius)
sdf.hline(y, half_height)
sdf.arc_round_caps(cx, cy, radius, start_angle, end_angle, thickness)
sdf.arc_flat_caps(cx, cy, radius, start_angle, end_angle, thickness)
```

Note: Args are space-separated in shader code, no commas.

## SDF Path Operations

```
sdf.move_to(x, y)
sdf.line_to(x, y)
sdf.close_path()
```

## SDF Combinators

Operate on current + previous shape:

```
sdf.union()       // merge (min distances)
sdf.intersect()   // overlap only (max distances)
sdf.subtract()    // cut current from previous
sdf.gloop(k)      // smooth/gooey union
sdf.blend(k)      // linear blend (0=previous, 1=current)
```

Ring example: circle -> smaller circle -> subtract -> fill
Toggle animation: ring -> circle -> blend(self.active)

## SDF Drawing

```
sdf.fill(color)          // fill + reset
sdf.fill_keep(color)     // fill + keep (for stroke after)
sdf.stroke(color, width) // stroke + reset
sdf.stroke_keep(c, w)    // stroke + keep
sdf.glow(color, width)   // additive glow + reset
sdf.glow_keep(c, w)      // additive glow + keep
sdf.clear(color)         // clear buffer
sdf.fill_premul(color)   // fill with premultiplied color
```

## SDF Transforms

```
sdf.translate(x, y)
sdf.rotate(angle, cx, cy)
sdf.scale(factor, cx, cy)
```

## SDF Anti-aliasing

```
sdf.aa = sdf.aa * 3.0  // sharper edges for small icons
```

## Complete Examples

### 1. Rounded button with hover

```
pixel: fn() {
    let sdf = Sdf2d.viewport(self.pos * self.rect_size)
    sdf.box(0.0, 0.0, self.rect_size.x, self.rect_size.y, 4.0)
    sdf.fill(self.color.mix(self.color_hover, self.hover))
    return sdf.result
}
```

### 2. Fill + border stroke

```
pixel: fn() {
    let sdf = Sdf2d.viewport(self.pos * self.rect_size)
    sdf.box(1. 1. self.rect_size.x - 2. self.rect_size.y - 2. 4.0)
    sdf.fill_keep(self.color)
    sdf.stroke(self.border_color, 1.0)
    return sdf.result
}
```

### 3. Loading spinner arc

```
pixel: fn() {
    let sdf = Sdf2d.viewport(self.pos * self.rect_size)
    let t = self.draw_pass.time * self.rotation_speed
    sdf.arc_round_caps(cx, cy, r, t, t + gap, self.stroke_width)
    sdf.fill(self.color)
    return sdf.result
}
```
