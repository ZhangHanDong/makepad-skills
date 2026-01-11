---
name: modal-overlay
author: robius
source: robrix
date: 2024-01-01
tags: [modal, overlay, popup, dialog, dropdown]
level: intermediate
---

# Pattern 2: Modal/Overlay Widget

Renders content above all other UI using `DrawList2d`.

## Problem

You need popups, dialogs, or dropdowns that render on top of everything else and can be dismissed by clicking outside.

## Solution

Use `DrawList2d::begin_overlay_reuse()` to render content in overlay layer.

## Implementation

```rust
#[derive(Live, Widget)]
pub struct Modal {
    #[live] content: View,
    #[live] draw_bg: DrawQuad,
    #[rust(DrawList2d::new(cx))] draw_list: DrawList2d,
    #[rust] opened: bool,
}

impl Widget for Modal {
    fn draw_walk(&mut self, cx: &mut Cx2d, scope: &mut Scope, walk: Walk) -> DrawStep {
        if !self.opened {
            return DrawStep::done();
        }

        // Begin overlay rendering
        self.draw_list.begin_overlay_reuse(cx);

        cx.begin_pass_sized_turtle(Layout::flow_down());
        self.draw_bg.draw_walk(cx, Walk::fill());
        self.content.draw_all(cx, scope);
        cx.end_pass_sized_turtle();

        self.draw_list.end(cx);
        DrawStep::done()
    }

    fn handle_event(&mut self, cx: &mut Cx, event: &Event, scope: &mut Scope) {
        if !self.opened { return; }

        cx.sweep_unlock(self.draw_bg.area());
        self.content.handle_event(cx, event, scope);
        cx.sweep_lock(self.draw_bg.area());

        // Click outside to dismiss
        match event.hits(cx, self.draw_bg.area()) {
            Hit::FingerDown(fe) => {
                let content_rect = self.content.area().rect(cx);
                if !content_rect.contains(fe.abs) {
                    self.close(cx);
                    cx.widget_action(self.widget_uid(), &scope.path,
                        ModalAction::Dismissed);
                }
            }
            _ => {}
        }
    }
}

impl ModalRef {
    pub fn open(&self, cx: &mut Cx) {
        if let Some(mut inner) = self.borrow_mut() {
            inner.opened = true;
            inner.redraw(cx);
        }
    }

    pub fn close(&self, cx: &mut Cx) {
        if let Some(mut inner) = self.borrow_mut() {
            inner.opened = false;
            inner.redraw(cx);
        }
    }
}
```

## Usage

```rust
// Open modal
self.ui.modal(id!(confirm_dialog)).open(cx);

// Close modal
self.ui.modal(id!(confirm_dialog)).close(cx);

// Handle dismissal
if let ModalAction::Dismissed = action.cast() {
    // User clicked outside
}
```

## When to Use

- Confirmation dialogs
- Dropdown menus
- Image lightboxes
- Context menus
