---
name: makepad-2.0-shaders
description: |
  CRITICAL: Use for Makepad 2.0 shader system. Triggers on:
  makepad shader, Sdf2d, pixel shader, draw_bg, draw_text, draw_quad,
  makepad gpu, shader function, pixel fn, vertex fn, instance, uniform,
  shader variable, sdf, premultiply, Pal.premul, GaussShadow,
  makepad graphics, custom draw, DrawQuad, DrawVector,
  着色器, 像素, 渲染, 自定义绘制, 距离场
---

# Makepad 2.0 Shader Skill

> **Version:** makepad-widgets (dev branch) | **Last Updated:** 2026-03-03

## Overview

Makepad uses a custom GPU shader system integrated into the widget property tree. Shaders are defined inline using `pixel: fn() { ... }` and `vertex: fn() { ... }` blocks within `draw_bg`, `draw_text`, or custom draw objects.

## Documentation

Refer to the local files for detailed documentation:
- `./references/shader-reference.md` - Shader syntax, variables, built-ins, custom functions
- `./references/sdf2d-reference.md` - SDF2D primitives, combinators, drawing operations

---

## Shader Basics

### Pixel Shader Structure

```
draw_bg +: {
    // Declare variables
    instance hover: 0.0          // Animatable per-instance
    uniform accent: #4488ff      // Shared across all instances

    pixel: fn() {
        let sdf = Sdf2d.viewport(self.pos * self.rect_size)
        // ... SDF operations ...
        return sdf.result
    }
}
```

### Variable Types

| Type | Declaration | Animatable | Scope |
|------|-------------|-----------|-------|
| `instance` | `instance hover: 0.0` | Yes (via Animator) | Per-widget instance |
| `uniform` | `uniform color: #fff` | No | Shared across instances |
| `texture_2d` | `texture_2d tex: none` | No | Texture sampler |
| `varying` | `varying uv: vec2` | No | Vertex → fragment |

### Built-in Variables

| Variable | Type | Description |
|----------|------|-------------|
| `self.pos` | `vec2` | Normalized position (0.0 to 1.0) |
| `self.rect_size` | `vec2` | Widget size in pixels |
| `self.dpi_factor` | `float` | Screen DPI factor |
| `self.draw_pass.time` | `float` | Time in seconds |

---

## CRITICAL: Premultiply Alpha

**Every pixel shader MUST return premultiplied alpha color!**

```
// WRONG - non-premultiplied
pixel: fn() {
    return vec4(1.0, 0.0, 0.0, 0.5)
}

// CORRECT - use Pal.premul()
pixel: fn() {
    return Pal.premul(vec4(1.0, 0.0, 0.0, 0.5))
}

// ALSO CORRECT - sdf.result is already premultiplied
pixel: fn() {
    let sdf = Sdf2d.viewport(self.pos * self.rect_size)
    sdf.circle(cx, cy, r)
    sdf.fill(#f00)
    return sdf.result
}
```

---

## SDF2D Quick Reference

### Setup
```
let sdf = Sdf2d.viewport(self.pos * self.rect_size)
```

### Primitives
```
sdf.circle(cx, cy, radius)
sdf.rect(x, y, w, h)
sdf.box(x, y, w, h, border_radius)
sdf.hexagon(cx, cy, radius)
sdf.arc(cx, cy, radius, start_angle, end_angle, thickness)
sdf.move_to(x, y)
sdf.line_to(x, y)
sdf.close_path()
```

### Drawing
```
sdf.fill(color)         // Filled shape
sdf.stroke(color, width) // Outlined shape
sdf.glow(color, amount)  // Glow effect
sdf.clear(color)         // Clear with color
```

### Combinators
```
sdf.union()       // Add shapes together
sdf.intersect()   // Keep overlap only
sdf.subtract()    // Remove second from first
sdf.gloop(radius) // Smooth union
sdf.blend(amount) // Linear blend
```

### Transforms
```
sdf.translate(x, y)
sdf.rotate(angle, cx, cy)
sdf.scale(factor, cx, cy)
```

---

## Color Operations

```
// Mix two colors
mix(#f00, #00f, 0.5)           // 50% blend

// Premultiply alpha
Pal.premul(vec4(r, g, b, a))

// HSV conversions
Pal.hsv2rgb(vec4(h, s, v, 1.0))
Pal.rgb2hsv(color)

// Random
Math.random_2d(vec2(x, y))
```

---

## Common Shader Patterns

### Gradient Background
```
draw_bg +: {
    pixel: fn() {
        let grad = mix(#1a1a2e, #16213e, self.pos.y)
        return Pal.premul(vec4(grad.xyz, 1.0))
    }
}
```

### Hover Color Change
```
draw_bg +: {
    instance hover: 0.0
    color: #333
    pixel: fn() {
        return Pal.premul(mix(self.color, self.color * 1.3, self.hover))
    }
}
```

### Box Shadow
```
draw_bg +: {
    pixel: fn() {
        let sdf = Sdf2d.viewport(self.pos * self.rect_size)
        // Shadow
        sdf.box(2.0, 2.0, self.rect_size.x - 4.0, self.rect_size.y - 4.0, 8.0)
        sdf.fill(GaussShadow.box_shadow(sdf, 4.0, #0005))
        // Card
        sdf.box(0.0, 0.0, self.rect_size.x - 2.0, self.rect_size.y - 2.0, 8.0)
        sdf.fill(#2a2a3d)
        return sdf.result
    }
}
```

### Rounded Button with States
```
draw_bg +: {
    instance hover: 0.0
    instance down: 0.0
    uniform color_bg: #4488ff
    uniform color_hover: #5599ff
    uniform color_down: #3377ee

    pixel: fn() {
        let sdf = Sdf2d.viewport(self.pos * self.rect_size)
        sdf.box(0.0, 0.0, self.rect_size.x, self.rect_size.y, 6.0)
        let color = mix(self.color_bg, self.color_hover, self.hover)
        let color = mix(color, self.color_down, self.down)
        sdf.fill(color)
        return sdf.result
    }
}
```

---

## Custom Shader Functions

```
draw_bg +: {
    fn wave(pos: vec2, time: float) -> float {
        return sin(pos.x * 10.0 + time * 3.0) * 0.1
    }

    pixel: fn() {
        let w = self.wave(self.pos, self.draw_pass.time)
        let color = mix(#1a1a2e, #4488ff, self.pos.y + w)
        return Pal.premul(vec4(color.xyz, 1.0))
    }
}
```

---

## Splash Shader Capability Boundary

**Splash CAN:**
- Override `pixel: fn()`, `vertex: fn()`, `get_color: fn()` on existing draw types via `+:`
- Define helper shader functions within `+:` blocks
- Set instance/uniform variables on existing draw types
- Use all SDF2D, color, math built-ins in shader functions

**Splash CANNOT:**
- Create new DrawQuad/DrawText/DrawSvg types (must define in Rust)
- Add new instance fields to existing shaders (GPU layout is compile-time)

**Rule:** Rust defines the draw type struct + registers it; Splash overrides how it draws.

See `./references/shader-reference.md` "Splash Shader Capabilities & Boundaries" for the full pattern.

---

## Custom Fullscreen Shader Pattern (learned 2026-03-26)

For standalone shader-driven widgets (e.g. particle fields, visualizers), follow the `examples/shader` pattern:

### 1. Custom Draw Type (Rust)

```rust
#[derive(Script, ScriptHook)]
#[repr(C)]  // CRITICAL: must be repr(C) for GPU layout
pub struct DrawMyShader {
    #[deref] draw_super: DrawQuad,  // inherits from DrawQuad
    #[live] my_param: f32,           // maps to shader variable
}
```

### 2. Register + Define Shader (script_mod!)

```
set_type_default() do #(DrawMyShader::script_shader(vm)){
    ..mod.draw.DrawQuad        // inherit DrawQuad defaults
    my_param: 0.5              // default value

    // Custom functions: property-style syntax, NOT fn name(self, ...)
    my_helper: fn(a: float, b: float) -> vec2 {
        return vec2(a * 2.0, b * 0.5)
    }

    pixel: fn() {
        let result = self.my_helper(self.pos.x, self.pos.y)
        return Pal.premul(vec4(result.x, result.y, 0.0, 1.0))
    }
}
```

### 3. Widget with Turtle Layout

```rust
fn draw_walk(&mut self, cx: &mut Cx2d, _: &mut Scope, walk: Walk) -> DrawStep {
    cx.begin_turtle(walk, self.layout);
    let rect = cx.turtle().rect();
    self.draw_bg.draw_abs(cx, rect);      // single fullscreen quad
    cx.end_turtle_with_area(&mut self.area);
    DrawStep::done()
}
```

### 4. Updating Shader Variables from Rust

```rust
// Direct field access (when draw type has #[live] fields):
self.draw_bg.my_param = 0.75;
self.area.redraw(cx);

// Via NextFrame for animation:
if let Event::NextFrame(ne) = event {
    if ne.set.contains(&self.next_frame) {
        self.draw_bg.my_param += 0.01;
        self.area.redraw(cx);
        self.next_frame = cx.new_next_frame();
    }
}
```

---

## Instanced Particle Rendering (learned 2026-03-26)

For drawing thousands of independent particles (dots, stars, etc.):

### Draw Shader

```rust
#[derive(Script, ScriptHook)]
#[repr(C)]
pub struct DrawDot {
    #[deref] draw_super: DrawQuad,
    #[live] dot_color: Vec3,  // per-instance color
}
```

```
// Shader: each instance is a small circle
pixel: fn() {
    let d = length(self.pos - vec2(0.5, 0.5))
    let alpha = 1.0 - smoothstep(0.35, 0.5, d)
    return Pal.premul(vec4(self.dot_color * alpha, alpha))
}
```

### Rendering Loop

```rust
self.draw_dot.begin_many_instances(cx);  // start batch

for i in 0..particles.len() {
    let (x, y) = particles[i];
    self.draw_dot.dot_color = vec3(r, g, b);  // set per-instance data
    self.draw_dot.draw_abs(cx, Rect {
        pos: dvec2(x - radius, y - radius),
        size: dvec2(radius * 2.0, radius * 2.0),
    });
}

self.draw_dot.end_many_instances(cx);  // submit batch as one draw call
```

### Physics Pattern (spring-back displacement)

```rust
// Per particle: store persistent displacement
displacements: Vec<(f64, f64)>,

// Each frame:
for i in 0..dots.len() {
    let (mut dx, mut dy) = displacements[i];

    // 1. Decay (spring back, 0.94 = ~2-3 sec return)
    dx *= 0.94;
    dy *= 0.94;

    // 2. Apply forces (cursor push, ripples, etc.)
    let dist = distance(dot_pos, mouse_pos);
    let t = (1.0 - dist / radius).max(0.0);
    let push = t * t * t * strength;  // cubic falloff
    dx += direction.x * push;
    dy += direction.y * push;

    displacements[i] = (dx, dy);
    // Draw at original_pos + displacement
}
```

### Performance Notes

- 10,000 particles at 60fps: OK on macOS Metal (one draw call via instancing)
- CPU physics loop: 10K × 17 distance checks = ~170K ops/frame, negligible
- Key: `begin_many_instances` / `end_many_instances` batches into single GPU draw call

---

## Shader Syntax Pitfalls (learned 2026-03-26)

| Pitfall | Error | Fix |
|---------|-------|-----|
| `let x = 1.0; x = 2.0` | `cannot assign to let binding` | Use different names: `let x2 = ...` |
| `fn push(self, ...) -> vec2` | `method not found on self` | Use property syntax: `push: fn(...) -> vec2 { }` |
| `return vec4(r, g, b, a)` without premul | Incorrect alpha blending | `return Pal.premul(vec4(r, g, b, a))` |
| Custom shader in Splash eval | Silent blank render | Must use compiled `script_mod!` path |
| Missing `#[repr(C)]` on draw struct | GPU layout mismatch | Always add `#[repr(C)]` |
| `fn calc(self, x: float)` syntax | `cannot push to frozen vec` | Use `calc: fn(x: float) -> float { }` |

---

## Best Practices

1. **Always premultiply** - Use `Pal.premul()` or return `sdf.result`
2. **Use `instance` for animation** - Only instance variables work with Animator
3. **Use `uniform` for shared values** - Colors, sizes shared across instances
4. **Use `+:` merge operator** - Extend default shaders: `draw_bg +: { ... }`
5. **Keep shaders simple** - Complex shaders impact rendering performance
6. **Use SDF for shapes** - Much cleaner than manual math
7. **Test with `new_batch: true`** - Required when mixing shaders with text
8. **Property-style functions** - `name: fn(args) -> type { }`, call via `self.name(args)`
9. **Immutable let** - Shader `let` cannot be reassigned; use unique names per step
10. **`#[repr(C)]` on draw structs** - Required for GPU memory layout alignment

---

## SDF Capsule (Pill) Shape Pattern (learned 2026-03-31)

`sdf.box()` with large `border_radius` breaks when radius approaches half the dimension — the formula `size.xy - vec2(2*r, 2*r)` goes negative, producing diamond/spiky shapes. Use this standard capsule SDF instead:

```
draw_bg +: {
    pixel: fn() {
        let w = self.rect_size.x
        let h = self.rect_size.y
        let r = h * 0.5
        let px = self.pos.x * w
        let py = self.pos.y * h
        // Standard capsule: clamp x to center segment, then circle distance
        let cx = clamp(px, r, max(r, w - r))
        let cy = h * 0.5
        let d = length(vec2(px - cx, py - cy)) - r
        let alpha = 1.0 - smoothstep(-1.0, 1.0, d)
        return Pal.premul(vec4(0.1, 0.1, 0.18, alpha * 0.82))
    }
}
```

**Key points:**
- `clamp(px, r, w-r)` constrains x to the center line segment between the two end circles
- `max(r, w-r)` prevents clamp range inversion when widget is very narrow
- Smoothstep `(-1.0, 1.0, d)` provides 2px anti-aliasing
- Works correctly at **any width** — dynamically adapts as `width: Fit` content changes
- No three-part union (circles + rect) needed — single formula, no seam artifacts

### Pulsing Dot in Background Shader (learned 2026-03-31)

Embed animation directly in the background shader to avoid z-order issues with child widgets (LoadingSpinner/other widgets can cause bleed-through at capsule edges):

```
draw_bg +: {
    pixel: fn() {
        let w = self.rect_size.x
        let h = self.rect_size.y
        let r = h * 0.5
        let px = self.pos.x * w
        let py = self.pos.y * h

        // Capsule background
        let cx_bg = clamp(px, r, max(r, w - r))
        let cy = h * 0.5
        let d_bg = length(vec2(px - cx_bg, py - cy)) - r
        let bg_alpha = 1.0 - smoothstep(-1.0, 1.0, d_bg)
        let bg = vec4(0.1, 0.1, 0.18, bg_alpha * 0.82)

        // Pulsing dot (driven by draw_pass.time)
        let t = self.draw_pass.time
        let pulse = 0.5 + 0.5 * sin(t * 4.0)
        let dot_r = 4.0 + pulse * 3.0
        let dot_cx = r + 2.0
        let d_dot = length(vec2(px - dot_cx, py - cy)) - dot_r
        let dot_alpha = (1.0 - smoothstep(-1.0, 1.0, d_dot)) * bg_alpha
        let dot_color = mix(vec3(0.3, 0.6, 1.0), vec3(0.2, 0.9, 0.5), pulse)

        // Composite
        let final_rgb = mix(bg.xyz, dot_color, dot_alpha * 0.8)
        let final_a = bg.w + dot_alpha * 0.6 * (1.0 - bg.w)
        return Pal.premul(vec4(final_rgb, final_a))
    }
}
```

**IMPORTANT:** Must call `self.ui.widget(cx, ids!(my_window)).redraw(cx)` from `handle_next_frame` to keep `draw_pass.time` advancing. Without continuous redraw, time-based animation freezes.
