---
name: list-template
author: robius
source: robrix
date: 2024-01-01
tags: [list, template, dynamic, data-driven]
level: intermediate
---

# Pattern 4: List with Template

Dynamic list from data using a template widget.

## Problem

You need to render a list of items where the number of items is determined at runtime, and each item follows the same template.

## Solution

Use `LivePtr` to store a template reference and `WidgetRef::new_from_ptr()` to instantiate items.

## Implementation

```rust
#[derive(Live, Widget)]
pub struct ItemList {
    #[deref] view: View,
    #[live] item_template: Option<LivePtr>,
    #[rust] items: Vec<ItemData>,
    #[rust] item_widgets: Vec<WidgetRef>,
}

impl Widget for ItemList {
    fn draw_walk(&mut self, cx: &mut Cx2d, scope: &mut Scope, walk: Walk) -> DrawStep {
        // Ensure we have enough widgets
        while self.item_widgets.len() < self.items.len() {
            let widget = WidgetRef::new_from_ptr(cx, self.item_template);
            self.item_widgets.push(widget);
        }

        cx.begin_turtle(walk, self.layout);

        for (i, item) in self.items.iter().enumerate() {
            let widget = &self.item_widgets[i];

            // Populate widget with data
            widget.label(ids!(title)).set_text(cx, &item.title);
            widget.label(ids!(subtitle)).set_text(cx, &item.subtitle);

            widget.draw_all(cx, scope);
        }

        cx.end_turtle();
        DrawStep::done()
    }
}

impl ItemListRef {
    pub fn set_items(&self, cx: &mut Cx, items: Vec<ItemData>) {
        if let Some(mut inner) = self.borrow_mut() {
            inner.items = items;
            inner.redraw(cx);
        }
    }
}
```

## live_design!

```rust
live_design! {
    ItemList = {{ItemList}} {
        flow: Down
        spacing: 8

        item_template: <ListItem> {
            width: Fill, height: 64
            padding: 12

            title = <Label> { text: "" }
            subtitle = <Label> {
                draw_text: { color: #888 }
                text: ""
            }
        }
    }
}
```

## Usage

```rust
// Set data
let items = vec![
    ItemData { title: "Item 1".into(), subtitle: "Description 1".into() },
    ItemData { title: "Item 2".into(), subtitle: "Description 2".into() },
];
self.ui.item_list(id!(my_list)).set_items(cx, items);
```

## When to Use

- Contact lists
- Message threads
- Product catalogs
- Search results
