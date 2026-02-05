---
name: dropdown-overlay
author: makepad
source: makepad-widgets
date: 2026-01-19
tags: [dropdown, popup, overlay, drawlist2d, fold-header]
level: intermediate
---

# Dropdown Popup That Does Not Change Widget Area

Create dropdown popups that float over other content without affecting the parent layout.

## Problem

When a widget has expandable content (like a dropdown body), drawing that content inline within the widget's turtle causes it to push surrounding layout elements. The widget's total area grows to include the expanded content.

## Solution

Use a `DrawList2d` overlay to draw the popup content in a separate layer that doesn't participate in the parent's layout system.

## Two Approaches Compared

### Approach 1: Inline Body (FoldHeader) -- Body DOES change widget area

`widgets/src/fold_header.rs:91-119`

```
Outer Turtle (walk, layout)
  +-- Header (drawn inline)
  +-- Body Turtle (body_walk, with scroll offset)
        +-- Body content
End Body Turtle    <-- takes up space in outer turtle
End Outer Turtle   <-- total area = header + body
```

The body is drawn inside the same turtle hierarchy as the header. The outer turtle's used size includes the body, so surrounding widgets are pushed down.

The scroll trick `Layout::flow_down().with_scroll(dvec2(0.0, rect_size * (1.0 - opened)))` slides the body in/out during animation, but it still occupies layout space in the parent.

### Approach 2: Overlay Body (FoldHeaderDropDown) -- Body does NOT change widget area

`widgets/src/fold_header_dropdown.rs:91-126`

```
Outer Turtle (walk, layout)
  +-- Header (drawn inline)
  +-- [Body turtle started but body drawn elsewhere]

--- Separate overlay layer ---
DrawList2d overlay
  +-- Root Turtle (full pass size)
        +-- Body content (shifted to header position)
```

The body is drawn in a **separate overlay draw list**, not inside the widget's own turtle. The widget's area is only the header. The body floats on top of everything.

## Implementation

### 1. Add a `DrawList2d` field to your struct

```rust
#[derive(Live, LiveHook, Widget)]
pub struct MyDropdownWidget {
    #[deref] view: View,
    #[live] header: View,
    #[live] body: View,
    #[live] draw_list: DrawList2d,  // enables overlay drawing
    #[rust] is_open: bool,
    #[rust] area: Area,
}
```

`DrawList2d` is a separate draw list that can be registered as an overlay, meaning its contents render on top of the normal widget tree without participating in the parent's layout.

### 2. Draw the popup body in an overlay, not in the widget's turtle

From `fold_header_dropdown.rs:111-123`:

```rust
// Step 1: Begin the overlay draw list
self.draw_list.begin_overlay_reuse(cx);

// Step 2: Create a root turtle covering the entire pass (screen)
let size = cx.current_pass_size();
cx.begin_root_turtle(size, Layout::flow_down());

// Step 3: Draw your popup content
let _ = self.body.draw_walk(cx, scope, walk);

// Step 4: End the root turtle, shifting content to desired position
let shift = DVec2 { x: header_area.pos.x, y: header_area.size.y + header_area.pos.y };
cx.end_pass_sized_turtle_with_shift(self.area, shift);

// Step 5: End the overlay draw list
self.draw_list.end(cx);
```

### 3. Compute the shift to position the overlay relative to the trigger

`end_pass_sized_turtle_with_shift(area, shift)` positions all content drawn inside the root turtle relative to `area.pos + shift`.

In FoldHeaderDropDown (`fold_header_dropdown.rs:121`):

```rust
let header_area = self.header.area().rect(cx);
let shift = DVec2 {
    x: header_area.pos.x,                          // align horizontally with header
    y: header_area.size.y + header_area.pos.y       // place below header
};
cx.end_pass_sized_turtle_with_shift(self.area, shift);
```

The first argument (`self.area`) is the **reference area** -- the overlay is positioned relative to this area's position. The second argument (`shift`) is an additional offset applied on top.

## Complete Pattern

```rust
fn draw_walk(&mut self, cx: &mut Cx2d, scope: &mut Scope, walk: Walk) -> DrawStep {
    // 1. Draw the trigger/header normally (this determines widget area)
    cx.begin_turtle(walk, self.layout);
    let header_walk = self.header.walk(cx);
    self.header.draw_walk(cx, scope, header_walk)?;
    cx.end_turtle_with_area(&mut self.area);

    // 2. If open, draw body in overlay (does NOT affect widget area)
    if self.is_open {
        self.draw_list.begin_overlay_reuse(cx);
        cx.begin_root_turtle(cx.current_pass_size(), Layout::flow_down());

        // draw popup content here
        let _ = self.body.draw_walk(cx, scope, body_walk);

        // position relative to trigger
        let trigger_rect = self.area.rect(cx);
        let shift = DVec2 { x: 0.0, y: trigger_rect.size.y };
        cx.end_pass_sized_turtle_with_shift(self.area, shift);
        self.draw_list.end(cx);
    }

    DrawStep::done()
}
```

## Side-by-Side Comparison

| | FoldHeader (inline) | FoldHeaderDropDown (overlay) |
|---|---|---|
| Body drawn in | Widget's own turtle | Separate `DrawList2d` overlay |
| Widget area | Header + Body | Header only |
| Pushes siblings | Yes | No |
| Extra field needed | None | `DrawList2d` |
| Positioning | Automatic (flow layout) | Manual (shift calculation) |
| Body turtle | `begin_turtle` / `end_turtle` inside outer | `begin_root_turtle` / `end_pass_sized_turtle_with_shift` in overlay |

## Key Rules

1. **Always close what you open.** `begin_overlay_reuse` must pair with `draw_list.end`. `begin_root_turtle` must pair with `end_pass_sized_turtle_with_shift` or `end_pass_sized_turtle`. Close them even if there is nothing to draw.

2. **The overlay root turtle covers the full pass.** Use `cx.current_pass_size()` so the overlay has the entire screen to position content in.

3. **Shift is relative to the reference area.** `end_pass_sized_turtle_with_shift(ref_area, shift)` places content at `ref_area.pos + shift`. To place a dropdown below its trigger, use `shift.y = trigger_height`.

4. **The widget's own area is determined only by non-overlay content.** Whatever you draw before the overlay block determines the widget's footprint in the parent layout. The overlay content is invisible to the parent's layout system.

## live_design! Example

```rust
live_design! {
    use link::widgets::*;

    MyDropdown = {{MyDropdown}} {
        width: Fit, height: Fit

        header: <View> {
            width: 200, height: 40
            show_bg: true
            draw_bg: { color: #333 }

            <Label> { text: "Click to expand" }
            <Icon> {
                draw_icon: { svg_file: dep("crate://self/icons/chevron-down.svg") }
            }
        }

        body: <View> {
            width: 200, height: Fit
            show_bg: true
            draw_bg: { color: #444 }
            padding: 10

            <Label> { text: "Dropdown content here" }
            <Button> { text: "Option 1" }
            <Button> { text: "Option 2" }
        }
    }
}
```

## When to Use

- Dropdown menus that should float over other content
- Autocomplete suggestions
- Context menus
- Tooltips that shouldn't push content
- Any expandable content that should overlay rather than push

## When NOT to Use

- Accordion-style collapsible sections where you WANT content to push down
- Inline expandable cards
- Tree view nodes where children should be part of the flow

## Related Patterns

- [Pattern 2: Modal Overlay](./02-modal-overlay.md) - Full-screen modal dialogs
- [Pattern 3: Collapsible Widget](./03-collapsible.md) - Inline collapsible sections
- [Pattern 14: Callout Tooltip](./14-callout-tooltip.md) - Positioned tooltips with arrows

## API Reference

### DrawList2d

**Import**: Built into makepad-widgets

**Key Methods**:
```rust
// Begin drawing in overlay mode (reuses existing draw list if available)
fn begin_overlay_reuse(&mut self, cx: &mut Cx2d)

// End the draw list
fn end(&mut self, cx: &mut Cx2d)
```

### Turtle Methods

**Key Methods**:
```rust
// Start a root turtle covering the full pass size
fn begin_root_turtle(&mut self, size: DVec2, layout: Layout)

// End turtle and position content relative to area + shift
fn end_pass_sized_turtle_with_shift(&mut self, area: Area, shift: DVec2)

// Get current pass (screen) size
fn current_pass_size(&self) -> DVec2
```

### Positioning

```rust
// Position dropdown below header
let header_rect = self.header.area().rect(cx);
let shift = DVec2 {
    x: 0.0,                    // same x as widget
    y: header_rect.size.y      // directly below header
};

// Position dropdown above header (menu opening upward)
let shift = DVec2 {
    x: 0.0,
    y: -body_height            // negative y to go above
};

// Position to the right of header
let shift = DVec2 {
    x: header_rect.size.x,     // right edge of header
    y: 0.0
};
```
