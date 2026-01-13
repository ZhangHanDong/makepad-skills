---
name: ui-complete-specification
author: TigerInYourDream
source: robrix-matrix-client
date: 2026-01-12
tags: [ui, layout, button, spacing, best-practices]
level: beginner
---

# UI Complete Specification Pattern

Provide complete layout specifications upfront to prevent common UI issues like text overlap, misalignment, and spacing problems.

## Problem

A common pattern in AI-assisted UI development:

1. User asks to add a button
2. AI adds button with approximate positioning
3. Button appears but text overlaps with adjacent elements ("text fighting")
4. User asks to fix it
5. AI struggles with iterative adjustments, often missing properties

This happens because **partial specifications** leave too many layout properties undefined, leading to unexpected behavior. The AI enters an "edit loop" where each fix introduces new issues.

## Solution

Always provide **complete specifications** with all layout properties defined upfront. This includes size, padding, margin, text configuration, and alignment—even if some seem obvious.

The pattern follows a checklist approach: before writing any UI code, ensure all critical properties are explicitly set.

## Implementation

### Example 1: Reaction Button (from Robrix)

Real-world button with complete specifications from the Robrix Matrix client:

```rust
live_design! {
    use link::theme::*;

    pub ReactionList = {{ReactionList}} {
        width: Fill,
        height: Fit,
        flow: RightWrap,
        margin: {top: 5.0}
        padding: {right: 30.0}

        item: <Button> {
            width: Fit,
            height: Fit,
            padding: 6,
            // Zero left margin to flush with message text
            margin: { top: 3, bottom: 3, left: 0, right: 6 },

            draw_bg: {
                instance reaction_bg_color: #B6BABF
                instance reaction_border_color: #001A11
                color_hover: #fef65b
                hover: 0.0
                border_size: 1.5
                border_radius: 3.0

                fn get_color(self) -> vec4 {
                    return mix(self.reaction_bg_color,
                              mix(self.reaction_bg_color, self.color_hover, 0.2),
                              self.hover)
                }
            }

            draw_text: {
                text_style: <REGULAR_TEXT>{font_size: 9},
                color: #000000
            }
        }
    }
}
```

**Key specifications**:
- ✅ Explicit `width: Fit, height: Fit` for content-sized button
- ✅ `padding: 6` for internal spacing
- ✅ Asymmetric `margin` with intentional zero left (design decision documented)
- ✅ Complete `draw_bg` with border, radius, and hover behavior
- ✅ `draw_text` with specific font size and color

### Example 2: SSO Button (from Robrix)

Full-width action button with complete layout properties:

```rust
live_design! {
    sso_button = <MaskableButton> {
        width: Fill,
        height: 40,
        padding: 10,
        margin: {top: 10},
        align: {x: 0.5, y: 0.5},

        draw_bg: {
            color: #00D9A3  // COLOR_ACTIVE_PRIMARY
            mask: 0.0
        }

        draw_text: {
            color: #FFFFFF  // COLOR_PRIMARY
            text_style: <REGULAR_TEXT> {}
        }

        text: "Continue with SSO"
    }
}
```

**Key specifications**:
- ✅ Fixed `width: Fill, height: 40` for consistent sizing
- ✅ `padding: 10` for text breathing room
- ✅ `margin: {top: 10}` for spacing from above elements
- ✅ `align: {x: 0.5, y: 0.5}` for centered content
- ✅ Complete `draw_bg` and `draw_text` configuration

### Example 3: Homeserver Selection Button (from Robrix)

Button in a list with complete specifications:

```rust
live_design! {
    matrix_option = <RobrixIconButton> {
        width: Fill,
        height: Fit,
        padding: {left: 10, right: 10, top: 8, bottom: 8},

        draw_bg: {
            color: #F5F5F5  // COLOR_BG_DISABLED
        }

        draw_text: {
            color: #000000  // COLOR_TEXT
            text_style: <REGULAR_TEXT>{font_size: 11}
        }

        text: "● matrix.org"
    }
}
```

**Key specifications**:
- ✅ `width: Fill, height: Fit` for list item behavior
- ✅ Explicit `padding` on all sides (left, right, top, bottom)
- ✅ Complete `draw_bg` with background color
- ✅ `draw_text` with font size specification

## Usage

### Self-Check Checklist

Before applying any UI changes, verify:

- [ ] **Size specified**: width and height defined (Fit/Fill/fixed)
- [ ] **Padding added**: Internal spacing prevents text from touching edges
- [ ] **Spacing/margin set**: External spacing prevents collision with neighbors
- [ ] **Alignment configured**: Parent has `align: { x, y }` if needed
- [ ] **Text wrapping defined**: `wrap:` property set explicitly
- [ ] **Minimum dimensions**: Button width accommodates longest expected text
- [ ] **Parent flow**: Parent View has `flow: Right/Down` matching intent

### Screenshot-Driven Debugging

When user reports layout issues:

1. **Request screenshot** with problem areas circled/marked
2. **Ask for expected result** (sketch, reference app, or description)
3. **Provide complete code replacement** (not "change X to Y" instructions)
4. **Explain each property's role** in fixing the issue

Example response pattern:

```
I see the text overlap issue. The problem is missing padding inside the button
and insufficient spacing between buttons. Here's the complete fixed code:

[Full button definition with all properties]

Changes made:
- Added padding: { left: 16, right: 16 } to give text breathing room
- Added margin: { left: 8, right: 8 } to space from adjacent buttons
- Set explicit width: Fit to size to content
- Added wrap: Line to prevent text wrapping
```

## When to Use

This comprehensive specification approach is essential when:

- Adding new buttons or interactive elements
- Modifying existing UI that has layout issues
- Creating forms with multiple aligned fields
- Mixing different UI element types (icons, text, buttons)
- User reports text overlap or spacing problems
- Working with AI assistance for UI development

## When NOT to Use

- Prototyping where exact spacing doesn't matter yet
- Copying exact code from working examples (already complete)
- Simple single-element tests

## Common Text Collision Causes

| Problem | Root Cause | Fix |
|---------|------------|-----|
| Text overlaps next button | No spacing/margin between siblings | Add `spacing: 8` to parent or `margin: { left: 8, right: 8 }` |
| Text touches button edge | No padding inside button | Add `padding: { left: 16, right: 16 }` |
| Buttons not aligned | Different heights, no parent alignment | Add `align: { y: 0.5 }` to parent View |
| Text wraps unexpectedly | No wrap setting | Set `draw_text: { wrap: Line }` |
| Button too narrow | width: Fit but text longer than expected | Use fixed width or increase padding |
| Vertical misalignment | Mixed element sizes in horizontal layout | Add `align: { y: 0.5 }` to parent |

## Anti-Patterns

### ❌ Bad: Partial Specification

```rust
// Missing padding, margin, explicit size
<Button> {
    text: "Click Me"
}
```

### ✅ Good: Complete Specification

```rust
<Button> {
    width: Fit
    height: 40
    padding: { left: 16, right: 16 }
    margin: { left: 8, right: 8 }
    text: "Click Me"
    draw_text: {
        text_style: <THEME_FONT_BOLD>{ font_size: 14.0 }
        wrap: Line
    }
}
```

### ❌ Bad: Incremental Fixes

```
"Try adding some padding"
[User applies, still broken]
"Maybe increase the margin"
[User applies, still broken]
"Let's adjust the spacing"
```

### ✅ Good: Complete Solution

```
"Here's the complete corrected button definition with all layout properties:

[Full code block]

This fixes the issue by:
1. Adding padding for internal spacing
2. Setting margin for external spacing
3. Defining explicit dimensions
"
```

## Related Patterns

- [Layout System](../../01-core/layout.md) - Flow, sizing, spacing fundamentals
- [Widgets](../../01-core/widgets.md) - Button, Label, TextInput reference

## References

- Emerged from real-world Makepad UI development in Robrix Matrix client
- Addresses the "edit loop" problem where iterative fixes fail
- Based on Makepad layout system best practices
- Examples extracted from production code: `robrix/src/home/event_reaction_list.rs` and `robrix/src/register/register_screen.rs`
