---
name: widget-extension
author: robius
source: robrix
date: 2024-01-01
tags: [widget, extension, trait, helper]
level: intermediate
---

# Pattern 1: Widget Reference Extension

Add helper methods to widget references without modifying the widget itself.

## Problem

You want to add convenience methods like `set_user()` to a widget reference, but you don't own the widget code.

## Solution

Use Rust extension traits on the widget's `Ref` type.

## Implementation

```rust
pub trait AvatarWidgetRefExt {
    fn set_user(&self, cx: &mut Cx, user: &UserInfo);
    fn show_placeholder(&self, cx: &mut Cx);
}

impl AvatarWidgetRefExt for AvatarRef {
    fn set_user(&self, cx: &mut Cx, user: &UserInfo) {
        if let Some(mut inner) = self.borrow_mut() {
            inner.user_info = Some(user.clone());
            inner.view.label(ids!(name)).set_text(cx, &user.name);
            inner.redraw(cx);
        }
    }

    fn show_placeholder(&self, cx: &mut Cx) {
        if let Some(mut inner) = self.borrow_mut() {
            inner.user_info = None;
            inner.view.label(ids!(name)).set_text(cx, "?");
            inner.redraw(cx);
        }
    }
}
```

## Usage

```rust
// Now you can call extension methods on any AvatarRef
self.ui.avatar(id!(user_avatar)).set_user(cx, &user_info);
```

## When to Use

- Adding domain-specific helpers to generic widgets
- Encapsulating common widget update patterns
- Creating fluent APIs for your app's widgets
