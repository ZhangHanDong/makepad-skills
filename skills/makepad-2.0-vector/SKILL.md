---
name: makepad-2.0-vector
description: |
  CRITICAL: Use for Makepad 2.0 Vector graphics widget. Triggers on:
  makepad vector, Vector widget, SVG path, makepad path, makepad circle,
  makepad gradient, makepad tween, vector animation, Gradient, RadGradient,
  Filter, DropShadow, Group transform, vector drawing, inline SVG,
  矢量图形, SVG, 路径, 渐变, 矢量动画
---

# Makepad 2.0 Vector Graphics Skill

> **Version:** makepad-widgets (dev branch) | **Last Updated:** 2026-03-03

## Overview

The `Vector` widget renders resolution-independent vector graphics using SVG-like syntax. It supports paths, shapes, gradients, filters, groups, transforms, and property animation via `Tween`.

**Two ways to use SVG in Splash:**
- **`Vector{}`** - Define shapes inline in Splash (paths, rects, circles, etc.)
- **`Svg{}`** - Load external `.svg` files via `crate_resource()` or `http_resource()`, with optional animation and custom GPU shaders

## Documentation

Refer to the local files for detailed documentation:
- `./references/vector-reference.md` - Complete Vector API, shapes, gradients, filters, animation

---

## Basic Usage

```
Vector{
    width: 48 height: 48
    viewbox: vec4(0 0 24 24)
    Path{
        d: "M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"
        fill: false
        stroke: #4488ff
        stroke_width: 2.0
        stroke_linecap: "round"
        stroke_linejoin: "round"
    }
}
```

### Key Properties

| Property | Description | Example |
|----------|-------------|---------|
| `width` / `height` | Widget size in pixels | `48` |
| `viewbox` | SVG viewBox as vec4 | `vec4(0 0 24 24)` |

### CRITICAL: Shape Properties vs Widget Properties

**Vector shapes use SVG-style properties, NOT `draw_bg.*` widget properties:**

```
// CORRECT — SVG properties
Path{d:"M 0 0 L 10 10" stroke:#x66aaff stroke_width:2.5}
Circle{cx:10 cy:10 r:5 fill:#x44ddaa}

// WRONG — these do nothing on Vector shapes!
Path{d:"..." draw_bg.stroke_color:#x66aaff draw_bg.stroke_width:2.}
Circle{cx:10 cy:10 r:5 draw_bg.fill_color:#x44ddaa}
```

---

## Shape Types

### Path (SVG path data)
```
Path{
    d: "M10 10 L20 20 L10 20 Z"
    fill: #f00
    stroke: #000
    stroke_width: 1.5
}
```

### Built-in Shapes
```
Rect{x: 0 y: 0 width: 100 height: 50 fill: #f00 rx: 5}
Circle{cx: 50 cy: 50 r: 25 fill: #00f}
Ellipse{cx: 50 cy: 30 rx: 40 ry: 20 fill: #0f0}
Line{x1: 0 y1: 0 x2: 100 y2: 100 stroke: #fff stroke_width: 2}
Polyline{points: "0,0 50,25 100,0" fill: false stroke: #fff}
Polygon{points: "50,0 100,100 0,100" fill: #f0f}
```

---

## Gradients

### Linear Gradient
```
Gradient{
    id: "myGrad"
    x1: 0 y1: 0 x2: 1 y2: 1
    Stop{offset: 0 color: #ff0000}
    Stop{offset: 1 color: #0000ff}
}
Path{d: "..." fill: "url(#myGrad)"}
```

### Radial Gradient
```
RadGradient{
    id: "radGrad"
    cx: 0.5 cy: 0.5 r: 0.5
    Stop{offset: 0 color: #ffffff}
    Stop{offset: 1 color: #000000}
}
```

---

## Groups & Transforms

```
Group{
    transform: "translate(10 20) rotate(45 50 50)"
    opacity: 0.8

    Circle{cx: 0 cy: 0 r: 10 fill: #f00}
    Rect{x: 20 y: 0 width: 20 height: 20 fill: #0f0}
}
```

---

## Filters

```
Filter{
    id: "shadow"
    DropShadow{dx: 2 dy: 2 blur: 4 color: #0008}
}
Path{d: "..." fill: #fff filter: "url(#shadow)"}
```

---

## Tween Animation (SVG Property Animation)

**CRITICAL:** Tween is a **property value**, NOT a container. It replaces a shape property (fill, stroke, opacity, cx, cy, r, etc.) with an animated value.

### Basic Syntax
```
// Animate opacity (pulse effect)
Circle{cx:8 cy:8 r:6 fill:#x44ddaa opacity:Tween{from:0.3 to:1.0 dur:1.5 loop_:true}}

// Animate position (moving dot)
Circle{cx:Tween{from:20 to:380 dur:3.0 loop_:true} cy:25 r:5 fill:#x66aaff}

// Animate color
Circle{fill:Tween{from:#x44ddaa to:#x6688dd dur:3.0 loop_:true} cx:10 cy:10 r:8}

// Animate stroke
Path{d:"M 0 0 L 100 0" stroke:Tween{from:#x333333 to:#x66aaff dur:2.0 loop_:true} stroke_width:2.}
```

### CRITICAL: `loop_` Must Be Boolean
```
// CORRECT — indefinite loop
opacity:Tween{from:0.3 to:1.0 dur:1.5 loop_:true}

// CORRECT — play 3 times
opacity:Tween{from:0.3 to:1.0 dur:1.5 loop_:3.0}

// WRONG — string doesn't trigger Indefinite, plays only once!
opacity:Tween{from:0.3 to:1.0 dur:1.5 loop_:"indefinite"}
```

### Tween Properties

| Property | Type | Description | Default |
|----------|------|-------------|---------|
| `from` | value | Start value (color, float, string) | - |
| `to` | value | End value | - |
| `values` | Vec | Keyframe values (alternative to from/to) | - |
| `dur` | f32 | Duration in seconds | 1.0 |
| `begin` | f32 | Delay offset in seconds | 0.0 |
| `loop_` | bool/f32 | `true` = indefinite, float = repeat count | 1.0 |
| `calc` | string | "discrete", "paced", "spline" | "linear" |
| `fill_mode` | string | "freeze" or "remove" | "remove" |

### Animatable Properties
Any shape property can be animated with Tween:
- `fill`, `stroke` — color animation
- `stroke_width`, `opacity`, `stroke_opacity` — float animation
- `cx`, `cy`, `r` (Circle) — position/size animation
- `d` (Path) — path morphing animation

### Common Patterns

**Pulsing indicator:**
```
Vector{width:16 height:16
  Circle{cx:8 cy:8 r:6 fill:#x44ddaa opacity:Tween{from:0.3 to:1.0 dur:1.5 loop_:true}}
}
```

**Moving dot along a line:**
```
Vector{width:Fill height:40
  Path{d:"M 20 20 L 380 20" stroke:#x333355 stroke_width:1.}
  Circle{cx:Tween{from:20 to:380 dur:3.0 loop_:true} cy:20 r:4 fill:Tween{from:#x44ddaa to:#xffaa44 dur:3.0 loop_:true}}
}
```

**Delayed sequential animation:**
```
Circle{cx:8 cy:8 r:6 fill:#x44ddaa opacity:Tween{from:0.3 to:1.0 dur:1.5 begin:0.0 loop_:true}}
Circle{cx:8 cy:8 r:6 fill:#xffaa44 opacity:Tween{from:0.3 to:1.0 dur:1.5 begin:0.5 loop_:true}}
Circle{cx:8 cy:8 r:6 fill:#x6688dd opacity:Tween{from:0.3 to:1.0 dur:1.5 begin:1.0 loop_:true}}
```

### Tween vs Animator

| Feature | `Tween` (Vector) | `Animator` (Widget) |
|---------|------------------|---------------------|
| Scope | SVG shape properties | Widget shader `instance` vars |
| Syntax | Property value replacement | `animator: Animator{...}` block |
| Triggers | Automatic on render | State transitions (hover, etc.) |
| Loop | `loop_:true` | `Loop {duration: 1.0}` |
| Use for | SVG animations | UI hover/focus/active effects |

---

## Icon Pattern (Common)

Most Vector widgets in Makepad 2.0 are used as icons with SVG paths:

```
let IconCheck = Vector{width: 18 height: 18 viewbox: vec4(0 0 24 24)
    Path{d: "M20 6L9 17L4 12" fill: false stroke: theme.color_highlight stroke_width: 2.5
        stroke_linecap: "round" stroke_linejoin: "round"}
}

let IconTrash = Vector{width: 14 height: 14 viewbox: vec4(0 0 24 24)
    Path{d: "M3 6h18M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6" fill: false stroke: theme.color_label_inner_inactive stroke_width: 1.8 stroke_linecap: "round" stroke_linejoin: "round"}
}
```

**Use with theme colors** for consistent styling across light/dark modes.

---

## Vector vs Svg vs SDF2D

| Feature | `Vector{}` | `Svg{}` | SDF2D Shader |
|---------|-----------|---------|-------------|
| Input | Inline shapes in Splash | External `.svg` file | Shader code |
| SVG path data | Yes (`d: "..."`) | Yes (parsed from file) | No |
| Gradients | `let` bindings | SVG `<defs>` | Manual |
| Filters | `Filter{DropShadow{}}` | SVG `<filter>` | Manual |
| Animation | `Tween{}` | SVG `<animate>` + `animating: true` | Shader uniforms |
| Custom GPU shader | `shader_id` | `draw_svg +: {get_color: fn(){...}}` | Full control |
| URL loading | No | Yes (`http_resource()`) | No |
| Resolution-independent | Yes | Yes | Yes |
| Performance | Good for static | Good for complex SVGs | Best for animated |

**Use `Vector{}` for:** Inline icons, illustrations, programmatic vector graphics
**Use `Svg{}` for:** Loading pre-made SVG files, complex SVG assets, SVG from URLs
**Use SDF2D for:** Animated shapes, hover effects, custom widget backgrounds

---

## Hex Color Escape

When using hex colors containing the letter 'e', prefix with `#x`:

```
// WRONG - parser misreads 'e' as exponent
stroke: #2ecc71

// CORRECT
stroke: #x2ecc71
```

---

## Best Practices

1. **Use `viewbox`** to define coordinate space independent of widget size
2. **Use theme colors** for icon strokes/fills for dark/light mode support
3. **Use `let` bindings** for reusable icon definitions
4. **Keep paths simple** - Complex SVG paths can impact performance
5. **Use `fill: false`** for outline-only icons (most common pattern)
6. **Set `stroke_linecap: "round"`** for cleaner line endings on icons
