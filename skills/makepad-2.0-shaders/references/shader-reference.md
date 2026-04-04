# Makepad 2.0 Shader Reference

## Shader Function Syntax (Makepad 2.0)

```
draw_bg +: {
    pixel: fn() {
        // shader code
        return sdf.result
    }
}
```

Note: Use `pixel: fn()` NOT `fn pixel(self) -> vec4` (old syntax).

## Variable Types

- `instance(value)` - Per-widget, animatable by Animator, varies per draw call
- `uniform(value)` - Shared across all instances, theme constants
- `texture_2d(float)` - Texture sampler
- `varying(vec2(0))` - Vertex->pixel interpolated

## Built-in Variables

- `self.pos` - vec2: normalized position [0,1]
- `self.rect_size` - vec2: pixel size
- `self.rect_pos` - vec2: pixel position
- `self.dpi_factor` - float: display DPI
- `self.draw_pass.time` - float: elapsed seconds
- `self.draw_pass.dpi_dilate` - float: DPI dilation
- `self.draw_depth` - float: z depth
- `self.geom_pos` - vec2: raw geometry position

## CRITICAL: Premultiply Alpha!

When hand-coding pixel() that returns color (not via sdf.result):

```
pixel: fn(){
    return Pal.premul(self.color.mix(self.color_hover, self.hover))
}
```

sdf.fill()/sdf.stroke() already premultiply, so `return sdf.result` is safe.

## Color Operations

- `mix(color1, color2, factor)` - linear interpolation
- `color1.mix(color2, factor)` - method chaining (preferred)
- `Pal.premul(color)` - premultiply alpha (REQUIRED for pixel() return)
- `Pal.hsv2rgb(vec4(h s v 1.0))` - HSV to RGB
- `Pal.rgb2hsv(color)` - RGB to HSV
- `Pal.iq(t a b c d)` / `Pal.iq0(t)..Pal.iq7(t)` - cosine palettes

## Custom Shader Functions

```
draw_bg +: {
    get_color: fn() {
        return self.color.mix(self.color_hover, self.hover)
    }
    pixel: fn() {
        return Pal.premul(self.get_color())
    }
}
```

With parameters:

```
get_color_at: fn(scale: vec2, pan: vec2) {
    return self.my_texture.sample(self.pos * scale + pan)
}
```

## Vertex Shader

```
vertex: fn() {
    let dpi = self.dpi_factor
    let ceil_size = ceil(self.rect_size * dpi) / dpi
    return self.clip_and_transform_vertex(self.rect_pos, self.rect_size)
}
```

## Texture Sampling

```
self.my_tex.sample(self.pos)          // standard 2D
sample2d(self.my_tex, uv)            // free-function form
sample2d_rt(self.image, uv)          // render-target (handles Y-flip)
```

## Mutable Variables

```
let mut color = self.color
if self.hover > 0.5 { color = self.color_hover }
```

## Control Flow

- Conditionals: `if/else`, `match` on enum instance variables
- For loops: `for i in 0..4 { ... }`

## Math Utilities

- `Math.random_2d(vec2)` - pseudo-random
- `Math.rotate_2d(v, angle)` - 2D rotation
- Constants: `PI`, `E`, `TORAD`, `GOLDEN`
- Standard GLSL: sin, cos, pow, sqrt, abs, floor, ceil, fract, clamp, smoothstep, etc.
- Vector: length, distance, dot, cross, normalize
- Fragment: dFdx, dFdy

## Gradient Pattern

```
color_2: uniform(vec4(-1.0, -1.0, -1.0, -1.0))  // sentinel: no gradient
pixel: fn() {
    let mut fill = self.color
    if self.color_2.x > -0.5 {
        let dither = Math.random_2d(self.pos.xy) * 0.04
        fill = mix(self.color, self.color_2, self.pos.y + dither)
    }
    return Pal.premul(fill)
}
```

## GaussShadow

```
GaussShadow.box_shadow(lower, upper, point, sigma)
GaussShadow.rounded_box_shadow(lower, upper, point, sigma, corner)
```

## Splash Shader Capabilities & Boundaries

### What Splash CAN Do (via `+:` merge operator)

Splash can **override shader functions** on any pre-defined draw type:

```
// Override pixel shader
draw_bg +: {
    pixel: fn() {
        let sdf = Sdf2d.viewport(self.pos * self.rect_size)
        sdf.circle(self.rect_size.x * 0.5, self.rect_size.y * 0.5, 20.0)
        sdf.fill(#f00)
        return sdf.result
    }
}

// Override get_color (e.g. on DrawSvg)
draw_svg +: {
    svg: crate_resource("self:resources/scene.svg")
    get_color: fn() {
        let base = self.eval_gradient();
        let t = self.svg_time;
        return mix(base, vec4(1.0, 0.0, 0.0, 1.0), sin(t) * 0.5 + 0.5);
    }
}

// Override vertex shader
draw_bg +: {
    vertex: fn() {
        let pos = self.clip_and_transform_vertex(self.rect_pos, self.rect_size);
        return pos;
    }
}

// Define helper functions
draw_bg +: {
    wave: fn(pos: vec2, time: float) -> float {
        return sin(pos.x * 10.0 + time * 3.0) * 0.1
    }
    pixel: fn() {
        let w = self.wave(self.pos, self.draw_pass.time);
        return Pal.premul(vec4(w, w, w, 1.0))
    }
}

// Set instance/uniform variables
draw_bg +: {
    instance hover: 0.0
    uniform accent: #4488ff
}
```

### What Splash CANNOT Do

| Not Supported | Reason | Workaround |
|---------------|--------|------------|
| Create new DrawQuad types | Requires `#[repr(C)]` + Rust struct | Define in Rust with `#[derive(Script)]` |
| Add new instance fields to existing shaders | GPU memory layout fixed at compile time | Define custom DrawQuad in Rust |
| Define new draw types (DrawBar, DrawArc, etc.) | Must be registered via `script_shader(vm)` | Rust-side `#[derive(Script, ScriptHook)]` |

**Rule: Rust defines "what exists" (types, fields), Splash overrides "how it draws" (pixel/vertex/get_color)**

### Custom Draw Type Pattern (Rust + Splash)

**Step 1: Define in Rust**
```rust
#[derive(Script, ScriptHook)]
#[repr(C)]
pub struct DrawBar {
    #[deref] pub draw_super: DrawQuad,
    #[live] pub amplitude: f32,    // instance field (AFTER deref)
    #[live] pub bar_color: Vec4,   // instance field
}
```

**Step 2: Register in script_mod!**
```rust
script_mod! {
    mod.draw.DrawBar = #(DrawBar::script_shader(vm))
}
```

**Step 3: Override pixel shader in Splash**
```
draw_bar +: {
    pixel: fn() {
        let bar_h = self.amplitude * self.rect_size.y;
        let sdf = Sdf2d.viewport(self.pos * self.rect_size);
        sdf.rect(0.0, self.rect_size.y - bar_h, self.rect_size.x, bar_h);
        sdf.fill(self.bar_color);
        return sdf.result
    }
}
```

---

## Custom Draw Shader Struct

```rust
#[derive(Script, ScriptHook)]
#[repr(C)]
struct DrawMyShader {
    #[live] pub svg: Option<ScriptHandleRef>,  // non-instance BEFORE deref
    #[rust] my_state: bool,                     // non-instance BEFORE deref
    #[deref] pub draw_super: DrawQuad,          // contains DrawVars
    #[live] pub tint: Vec4f,                    // instance field AFTER deref
}
```

CRITICAL: Non-instance data MUST be BEFORE `#[deref]`, instance fields AFTER.
