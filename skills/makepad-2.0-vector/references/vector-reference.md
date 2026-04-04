# Makepad 2.0 Vector Graphics Reference

## Overview

The `Vector{}` widget renders SVG-like vector graphics declaratively in Splash. It supports paths, shapes, gradients, filters, groups, transforms, and animations -- all without loading external SVG files.

---

## Basic Usage

```
Vector{width: 200 height: 200 viewbox: vec4(0 0 200 200)
    Rect{x: 10 y: 10 w: 80 h: 60 rx: 5 ry: 5 fill: #f80}
    Circle{cx: 150 cy: 50 r: 30 fill: #08f}
    Line{x1: 10 y1: 150 x2: 190 y2: 150 stroke: #fff stroke_width: 2}
}
```

The `viewbox` property defines the coordinate space as `vec4(x y width height)`. The widget sizes itself to fit the viewbox when `width: Fit` and `height: Fit` (the defaults), or you can set explicit pixel dimensions.

---

## Common Style Properties

All shapes support these properties:

| Property | Type | Default | Notes |
|----------|------|---------|-------|
| `fill` | color, Gradient, RadGradient, Tween, or `false` | inherited | `false` = no fill |
| `fill_opacity` | f32 | 1.0 | multiplied with fill alpha |
| `stroke` | color, Gradient, or Tween | none | outline color |
| `stroke_width` | f32 or Tween | 0.0 | outline thickness |
| `stroke_opacity` | f32 or Tween | 1.0 | outline alpha |
| `opacity` | f32 or Tween | 1.0 | overall shape opacity |
| `stroke_linecap` | string | "butt" | "butt", "round", "square" |
| `stroke_linejoin` | string | "miter" | "miter", "round", "bevel" |
| `transform` | Transform or array | identity | see Transforms section |
| `filter` | Filter ref | none | see Filters section |
| `shader_id` | f32 | 0.0 | for custom GPU effects on Svg widget |

---

## Shape Types

### Path -- SVG path data
```
Path{d: "M 10 10 L 100 100 C 50 50 200 200 300 300 Z" fill: #f00 stroke: #000 stroke_width: 2}
```
The `d` property accepts standard SVG path data strings (M, L, C, Q, A, Z, etc.).

### Rect -- Rectangle
```
Rect{x: 10 y: 20 w: 100 h: 50 rx: 5 ry: 5 fill: #f80 stroke: #fff stroke_width: 1}
```
Properties: `x`, `y`, `w`, `h`, `rx` (corner radius x), `ry` (corner radius y)

### Circle
```
Circle{cx: 50 cy: 50 r: 40 fill: #08f}
```
Properties: `cx` (center x), `cy` (center y), `r` (radius)

### Ellipse
```
Ellipse{cx: 100 cy: 50 rx: 80 ry: 40 fill: #0f8}
```
Properties: `cx`, `cy`, `rx` (x radius), `ry` (y radius)

### Line
```
Line{x1: 10 y1: 10 x2: 190 y2: 190 stroke: #fff stroke_width: 2 stroke_linecap: "round"}
```
Properties: `x1`, `y1`, `x2`, `y2`

### Polyline -- open connected segments
```
Polyline{pts: [10 10 50 80 100 20 150 90] fill: false stroke: #ff0 stroke_width: 2}
```
Properties: `pts` (flat array of x y pairs)

### Polygon -- closed connected segments
```
Polygon{pts: [100 10 40 198 190 78 10 78 160 198] fill: #f0f stroke: #fff stroke_width: 1}
```
Properties: `pts` (flat array of x y pairs, auto-closed)

---

## Groups

`Group{}` composes shapes and applies shared styles/transforms to all children:

```
Vector{width: 200 height: 200 viewbox: vec4(0 0 200 200)
    Group{opacity: 0.7 transform: Rotate{deg: 15}
        Rect{x: 20 y: 20 w: 60 h: 60 fill: #f00}
        Circle{cx: 130 cy: 50 r: 30 fill: #0f0}
    }
}
```

Groups can be nested. Style properties on a Group (fill, stroke, etc.) apply to its children.

---

## Gradients

Define gradients as `let` bindings and reference them in `fill` or `stroke`.

### Linear Gradient
```
let my_grad = Gradient{x1: 0 y1: 0 x2: 1 y2: 1
    Stop{offset: 0 color: #ff0000}
    Stop{offset: 0.5 color: #00ff00}
    Stop{offset: 1 color: #0000ff}
}

Vector{width: 200 height: 100 viewbox: vec4(0 0 200 100)
    Rect{x: 0 y: 0 w: 200 h: 100 fill: my_grad}
}
```

Gradient coordinates (`x1`, `y1`, `x2`, `y2`) are in the range 0-1 (object bounding box). `Stop` children define color stops with `offset` (0-1), `color`, and optional `opacity`.

### Radial Gradient
```
let radial = RadGradient{cx: 0.5 cy: 0.5 r: 0.5
    Stop{offset: 0 color: #fff}
    Stop{offset: 1 color: #000}
}

Vector{width: 200 height: 200 viewbox: vec4(0 0 200 200)
    Circle{cx: 100 cy: 100 r: 90 fill: radial}
}
```

RadGradient properties: `cx`, `cy` (center, default 0.5), `r` (radius, default 0.5), `fx`, `fy` (focal point, defaults to center).

### Gradient Stops with Opacity
```
let glass = Gradient{x1: 0 y1: 0 x2: 1 y2: 1
    Stop{offset: 0 color: #xffffff opacity: 0.35}
    Stop{offset: 0.4 color: #xffffff opacity: 0.08}
    Stop{offset: 1 color: #xffffff opacity: 0.2}
}
```

---

## Filters

Define a `Filter` with `DropShadow` effects:

```
let shadow = Filter{
    DropShadow{dx: 2 dy: 4 blur: 6 color: #000000 opacity: 0.5}
}

Vector{width: 200 height: 200 viewbox: vec4(0 0 200 200)
    Rect{x: 40 y: 40 w: 120 h: 120 rx: 10 ry: 10 fill: #445 filter: shadow}
}
```

DropShadow properties:
- `dx` -- x offset
- `dy` -- y offset
- `blur` -- blur radius
- `color` -- shadow color
- `opacity` -- shadow opacity

---

## Transforms

Transforms can be applied to any shape or group via the `transform` property. Use a single transform or an array of transforms (composed left-to-right).

### Available Transforms

| Transform | Syntax | Notes |
|-----------|--------|-------|
| Rotate | `Rotate{deg: 45}` | Optional `cx`, `cy` for rotation center |
| Scale | `Scale{x: 2 y: 1.5}` | If only `x` given, `y` defaults to same |
| Translate | `Translate{x: 100 y: 50}` | Translation offset |
| SkewX | `SkewX{deg: 30}` | Horizontal skew |
| SkewY | `SkewY{deg: 15}` | Vertical skew |

### Static Transforms
```
// Single transform
Rect{x: 0 y: 0 w: 50 h: 50 fill: #f00 transform: Rotate{deg: 45}}

// Multiple transforms (composed left-to-right)
Group{transform: [Translate{x: 100 y: 50} Scale{x: 2 y: 2} Rotate{deg: 30}]
    Circle{cx: 0 cy: 0 r: 20 fill: #0ff}
}
```

### Animated Transforms

Add `dur`, `from`, `to` (or `values`), and optionally `loop_` and `begin` to animate:

```
// Continuously rotating shape
Circle{cx: 100 cy: 100 r: 30 fill: #0ff
    transform: Rotate{deg: 0 dur: 2.0 from: 0 to: 360 loop_: true}
}

// Animated scale
Rect{x: 50 y: 50 w: 40 h: 40 fill: #f80
    transform: Scale{x: 1 dur: 1.5 from: 1 to: 2 loop_: true}
}
```

---

## Tween (Property Animation)

Use `Tween{}` to animate individual shape properties (fill, stroke, d, x, y, r, etc.):

```
// Animated path morphing
Path{d: Tween{
    dur: 2.0 loop_: true
    values: ["M 10 80 Q 50 10 100 80" "M 10 80 Q 50 150 100 80"]
} fill: #f0f}

// Animated fill color
Circle{cx: 50 cy: 50 r: 30
    fill: Tween{dur: 1.5 loop_: true from: #ff0000 to: #0000ff}
}

// Animated stroke width
Rect{x: 10 y: 10 w: 80 h: 80
    fill: false stroke: #fff
    stroke_width: Tween{dur: 2.0 loop_: true from: 1 to: 5}
}
```

### Tween Properties

| Property | Type | Description |
|----------|------|-------------|
| `from` | value | Start value |
| `to` | value | End value |
| `values` | array | Array of keyframe values (alternative to from/to) |
| `dur` | f32 | Duration in seconds |
| `begin` | f32 | Start delay in seconds |
| `loop_` | bool or number | `true` for indefinite, or a number for repeat count |
| `calc` | string | "linear" (default), "discrete", "paced", "spline" |
| `fill_mode` | string | "remove" (default) or "freeze" |

---

## Vector vs Svg Widget

| | `Vector{}` | `Svg{}` |
|---|---|---|
| **Input** | Declarative shapes in Splash script | External `.svg` file via resource handle |
| **Use case** | Programmatic/inline vector graphics | Loading pre-made SVG assets |
| **Source** | Inline `Path{}`, `Rect{}`, `Circle{}`, etc. | `crate_resource("self:path.svg")` or `http_resource("url")` |
| **Gradients** | `let` bindings, referenced by name | Parsed from SVG `<defs>` (linear, radial) |
| **Filters** | `Filter{DropShadow{...}}` | Parsed from SVG `<filter>` (feDropShadow) |
| **Animation** | `Tween{}` on properties, animated transforms | Parsed from SVG `<animate>` elements + `animating: true` |
| **Custom shaders** | `shader_id` + custom `get_color` on Svg | Override `get_color` via `draw_svg +:` |
| **Color override** | Set `fill`/`stroke` on shapes directly | `draw_svg.color` replaces all SVG colors (or `-1` for original) |
| **Syntax** | `Vector{viewbox: ... Path{} Rect{}}` | `Svg{draw_svg +: {svg: crate_resource("self:file.svg")}}` |

Use `Vector{}` when you want to define graphics inline in your UI script. Use `Svg{}` when loading existing SVG files as assets.

### Svg Widget Quick Reference

```
// Load from local resource
Svg{
    width: 300 height: 300
    animating: false
    draw_svg +: { svg: crate_resource("self:resources/icon.svg") }
}

// Load from URL
Svg{
    width: 300 height: 100
    draw_svg +: { svg: http_resource("https://example.com/logo.svg") }
}

// With animation and custom shader
Svg{
    width: 600 height: 450
    animating: true
    draw_svg +: {
        svg: crate_resource("self:resources/scene.svg")
        get_color: fn() {
            let base = self.eval_gradient();
            let t = self.svg_time;
            return mix(base, vec4(1.0), sin(t) * 0.1);
        }
    }
}
```

**Svg properties:** `draw_svg.svg` (resource), `draw_svg.color` (tint override, default `-1` = original), `draw_svg.svg_time` (animation time uniform), `animating` (bool, enables per-frame updates).

---

## SVG Icons as Vector Paths

Simple SVG icons can be embedded directly as `Path` shapes:

```
// Check mark icon
let IconCheck = Vector{width: 18 height: 18 viewbox: vec4(0 0 24 24)
    Path{d: "M20 6L9 17L4 12" fill: false stroke: #fff stroke_width: 2.5
        stroke_linecap: "round" stroke_linejoin: "round"}
}

// File icon
Vector{width: 32 height: 32 viewbox: vec4(0 0 49 49)
    Path{d: "M12.069,11.678c0,-2.23 1.813,-4.043 4.043,-4.043l10.107,0l0,8.086c0,1.118 0.903,2.021 2.021,2.021l8.086,0l0,18.193c0,2.23 -1.813,4.043 -4.043,4.043l-16.171,0c-2.23,0 -4.043,-1.813 -4.043,-4.043l0,-24.257Zm24.257,4.043l-8.086,0l0,-8.086l8.086,8.086Z"}
}

// Folder icon
Vector{width: 32 height: 32 viewbox: vec4(0 0 49 49)
    Path{d: "M11.884,37.957l24.257,0c2.23,0 4.043,-1.813 4.043,-4.043l0,-16.172c0,-2.23 -1.813,-4.042 -4.043,-4.042l-10.107,0c-0.638,0 -1.238,-0.297 -1.617,-0.809l-1.213,-1.617c-0.765,-1.017 -1.965,-1.617 -3.235,-1.617l-8.085,0c-2.23,0 -4.043,1.813 -4.043,4.043l0,20.214c0,2.23 1.813,4.043 4.043,4.043Z"}
}
```

---

## Hex Color Escaping

When using hex colors containing the letter `e` inside `script_mod!`, use the `#x` prefix to avoid parse errors:

```
// These need #x prefix (contain 'e' adjacent to digits)
fill: #x2ecc71
fill: #x1e1e2e
fill: #x4466ee

// These are fine without #x (no 'e' adjacent to digits)
fill: #ff4444
fill: #44cc44
```

---

## Complete Example: App Icon with Gradients, Groups, and Filters

```
// Define gradients
let glass_bg = Gradient{x1: 0 y1: 0 x2: 1 y2: 1
    Stop{offset: 0 color: #x556677 opacity: 0.45}
    Stop{offset: 1 color: #x334455 opacity: 0.35}
}
let brain_grad = Gradient{x1: 0.5 y1: 0 x2: 0.5 y2: 1
    Stop{offset: 0 color: #x77ccff}
    Stop{offset: 0.4 color: #x7799ee}
    Stop{offset: 0.75 color: #x8866dd}
    Stop{offset: 1 color: #x9944cc}
}
let brain_glow = RadGradient{cx: 0.5 cy: 0.45 r: 0.45
    Stop{offset: 0 color: #x4466ee opacity: 0.4}
    Stop{offset: 1 color: #x4466dd opacity: 0.0}
}

// Define filter
let icon_shadow = Filter{
    DropShadow{dx: 0 dy: 4 blur: 6 color: #x000000 opacity: 0.5}
}

Vector{width: 256 height: 256 viewbox: vec4(0 0 256 256)
    // Glass background with shadow
    Rect{x: 16 y: 16 w: 224 h: 224 rx: 44 ry: 44
        fill: glass_bg filter: icon_shadow}

    // Brain glow
    Circle{cx: 128 cy: 95 r: 80 fill: brain_glow}

    // Brain paths (scaled and translated group)
    Group{transform: [Translate{x: 36.8 y: 11.4} Scale{x: 7.6 y: 7.6}]
        Path{d: "M15.5 13a3.5 3.5 0 0 0 -3.5 3.5v1a3.5 3.5 0 0 0 7 0v-1.8"
            fill: false stroke: brain_grad stroke_width: 0.35
            stroke_linecap: "round" stroke_linejoin: "round"}
        Path{d: "M8.5 13a3.5 3.5 0 0 1 3.5 3.5v1a3.5 3.5 0 0 1 -7 0v-1.8"
            fill: false stroke: brain_grad stroke_width: 0.35
            stroke_linecap: "round" stroke_linejoin: "round"}
    }

    // Keyboard keys
    Rect{x: 73 y: 190 w: 9 h: 6 rx: 1 ry: 1 fill: #xffffff fill_opacity: 0.18}
    Rect{x: 85 y: 190 w: 9 h: 6 rx: 1 ry: 1 fill: #xffffff fill_opacity: 0.18}
}
```
