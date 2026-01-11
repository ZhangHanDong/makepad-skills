---
name: [effect-name]
author: [your-github-handle]
source: [project-where-you-created-this]
date: [YYYY-MM-DD]
tags: [shader, effect, tag1, tag2]
level: [beginner|intermediate|advanced]
---

# [Effect Name]

Brief one-line description of the visual effect.

## Preview

*Optional: Describe what the effect looks like, or link to a screenshot/gif*

## Effect Description

Explain what this shader does visually and any customizable parameters.

## Implementation

```rust
draw_bg: {
    // Instance variables for customization
    instance param1: 0.0
    instance param2: #ffffff

    fn pixel(self) -> vec4 {
        let sdf = Sdf2d::viewport(self.pos * self.rect_size);

        // Your shader code here
        // Add comments explaining the math

        return sdf.result;
    }
}
```

## Animator (if applicable)

```rust
animator: {
    effect = {
        default: off,
        on = {
            from: {all: Loop {duration: 1.0, end: 1.0}}
            apply: { draw_bg: { param1: [{time: 0.0, value: 0.0}, {time: 1.0, value: 1.0}] } }
        }
    }
}
```

## Usage

```rust
live_design! {
    <View> {
        show_bg: true
        draw_bg: {
            // Apply the effect
        }
    }
}
```

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `param1` | f32 | 0.0 | Description of parameter |
| `param2` | vec4 | #ffffff | Description of parameter |

## Performance Notes

- Optional: Any performance considerations
- Complexity of the shader
- Recommended use cases

## Related Effects

- Optional: links to similar or complementary effects
