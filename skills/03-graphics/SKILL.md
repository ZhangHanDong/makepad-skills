---
name: makepad-graphics
description: Makepad shaders, SDF drawing, animations, and visual effects.
globs: _base/*.md, community/*.md
---

# Graphics & Effects

GPU-accelerated shaders, SDF drawing, and animations in Makepad.

## Shader Basics

| Skill | Description |
|-------|-------------|
| [Shader Structure](_base/01-shader-structure.md) | Variables, types, built-ins |
| [Shader Math](_base/02-shader-math.md) | Math functions, colors, textures |

## SDF Drawing

| Skill | Description |
|-------|-------------|
| [SDF Shapes](_base/03-sdf-shapes.md) | Circle, box, capsule |
| [SDF Path Drawing](_base/04-sdf-drawing.md) | Lines, arcs, triangles |
| [Progress & Track](_base/05-progress-track.md) | Progress bars, sliders |

## Animation

| Skill | Description |
|-------|-------------|
| [Animator Basics](_base/06-animator-basics.md) | Definition, timing, triggering |
| [Easing Functions](_base/07-easing-functions.md) | Curves, multi-property |
| [Keyframe Animation](_base/08-keyframe-animation.md) | Keyframes, loops |
| [Loading Spinner](_base/09-loading-spinner.md) | Rotating arc animation |

## Visual Effects

| Skill | Description |
|-------|-------------|
| [Hover Effect](_base/10-hover-effect.md) | Interactive hover states |
| [Gradient Effects](_base/11-gradient-effects.md) | Linear, radial, vignette |
| [Shadow & Glow](_base/12-shadow-glow.md) | Shadows, glow, pulse |
| [Disabled State](_base/13-disabled-state.md) | Disabled visual pattern |
| [Toggle & Checkbox](_base/14-toggle-checkbox.md) | Switch, checkbox visuals |

## Community Effects

See [community/](community/) for community-contributed shaders and effects.

To contribute your own shader/effect, use the template at [99-evolution/templates/shader-template.md](../99-evolution/templates/shader-template.md).

## Quick Reference

### SDF Operations

```rust
sdf.circle(x, y, r)      // Circle
sdf.box(x, y, w, h, r)   // Rounded rect
sdf.fill(color)          // Fill shape
sdf.stroke(color, w)     // Stroke outline
sdf.fill_keep(color)     // Fill, keep shape
```

### Animator Timing

```rust
Forward {duration: 0.15}  // Linear transition
Snap                      // Instant change
Loop {duration: 1.0}      // Continuous loop
```

### Common Easing

```rust
OutQuad                   // Enter animations
InQuad                    // Exit animations
ExpDecay {d1: 0.8, d2: 0.97}  // Physics-like
```

## References

- [Makepad draw source](https://github.com/makepad/makepad/tree/main/draw)
- [Shader examples in ui_zoo](https://github.com/makepad/makepad/tree/main/examples/ui_zoo)
