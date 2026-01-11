---
name: collapsible
author: robius
source: robrix
date: 2024-01-01
tags: [collapsible, expandable, accordion, toggle]
level: intermediate
---

# Pattern 3: Collapsible Widget

Toggle visibility of content with animation.

## Problem

You need expandable/collapsible sections like accordions, expandable cards, or tree nodes.

## Solution

Use animator states to control visibility and rotation of indicator icons.

## Implementation

```rust
#[derive(Clone, Debug, DefaultNone)]
pub enum CollapsibleAction {
    Toggled { now_expanded: bool },
    None,
}

#[derive(Live, LiveHook, Widget)]
pub struct CollapsibleHeader {
    #[deref] view: View,
    #[animator] animator: Animator,
    #[rust] is_expanded: bool,
}

impl Widget for CollapsibleHeader {
    fn handle_event(&mut self, cx: &mut Cx, event: &Event, scope: &mut Scope) {
        if self.animator_handle_event(cx, event).must_redraw() {
            self.redraw(cx);
        }

        self.view.handle_event(cx, event, scope);

        match event.hits(cx, self.view.area()) {
            Hit::FingerDown(_) => {
                self.is_expanded = !self.is_expanded;

                if self.is_expanded {
                    self.animator_play(cx, ids!(expand.on));
                } else {
                    self.animator_play(cx, ids!(expand.off));
                }

                cx.widget_action(self.widget_uid(), &scope.path,
                    CollapsibleAction::Toggled { now_expanded: self.is_expanded });
            }
            _ => {}
        }
    }

    fn draw_walk(&mut self, cx: &mut Cx2d, scope: &mut Scope, walk: Walk) -> DrawStep {
        // Rotate arrow icon based on state
        let rotation = if self.is_expanded { 180.0_f64.to_radians() } else { 0.0 };
        self.view.icon(ids!(arrow)).apply_over(cx, live! {
            draw_icon: { rotation_angle: (rotation) }
        });

        self.view.draw_walk(cx, scope, walk)
    }
}
```

## live_design!

```rust
live_design! {
    CollapsibleSection = <View> {
        flow: Down

        header = <CollapsibleHeader> {
            width: Fill, height: 48
            padding: { left: 16, right: 16 }
            align: { y: 0.5 }

            <Label> { text: "Section Title" }
            <Filler> {}
            arrow = <Icon> {
                draw_icon: { svg_file: dep("crate://self/icons/chevron-down.svg") }
            }
        }

        body = <View> {
            visible: false
            padding: 16

            <Label> { text: "Expandable content here" }
        }
    }
}
```

## Usage

```rust
// Handle toggle in parent
if let CollapsibleAction::Toggled { now_expanded } = action.cast() {
    self.ui.view(id!(body)).set_visible(cx, now_expanded);
}
```

## When to Use

- FAQ sections
- Settings categories
- File tree nodes
- Accordion menus
