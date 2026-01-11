---
name: lru-view-cache
author: robius
source: moly
date: 2024-01-01
tags: [cache, lru, memory, view, performance]
level: advanced
---

# Pattern 5: LRU Cache for Views

Keep only N views in memory for memory-constrained applications.

## Problem

Your app has many screens/views (e.g., chat rooms), but keeping all of them in memory is expensive. You want to cache recently used views and evict old ones.

## Solution

Use `HashMap` with `VecDeque` access order tracking to implement LRU eviction.

## Implementation

```rust
use std::collections::{HashMap, VecDeque};

const MAX_CACHED_VIEWS: usize = 10;

#[derive(Live, Widget)]
pub struct ViewDeck {
    #[deref] view: View,
    #[live] view_template: Option<LivePtr>,
    #[rust] view_refs: HashMap<ViewId, WidgetRef>,
    #[rust] access_order: VecDeque<ViewId>,
    #[rust] current_view: Option<ViewId>,
}

impl ViewDeck {
    fn get_or_create_view(&mut self, cx: &mut Cx, id: ViewId) -> &WidgetRef {
        if !self.view_refs.contains_key(&id) {
            // Create new view
            let widget = WidgetRef::new_from_ptr(cx, self.view_template);
            self.view_refs.insert(id.clone(), widget);

            // Evict oldest if over limit
            if self.view_refs.len() > MAX_CACHED_VIEWS {
                if let Some(oldest) = self.access_order.pop_front() {
                    self.view_refs.remove(&oldest);
                }
            }
        }

        // Update access order (move to back = most recent)
        self.access_order.retain(|x| x != &id);
        self.access_order.push_back(id.clone());

        self.view_refs.get(&id).unwrap()
    }

    pub fn switch_to(&mut self, cx: &mut Cx, id: ViewId) {
        self.get_or_create_view(cx, id.clone());
        self.current_view = Some(id);
        self.redraw(cx);
    }
}

impl Widget for ViewDeck {
    fn draw_walk(&mut self, cx: &mut Cx2d, scope: &mut Scope, walk: Walk) -> DrawStep {
        if let Some(id) = &self.current_view {
            if let Some(view) = self.view_refs.get(id) {
                return view.draw_walk(cx, scope, walk);
            }
        }
        DrawStep::done()
    }
}
```

## Usage

```rust
// Switch to a room view (auto-creates if needed, evicts old if full)
self.ui.view_deck(id!(chat_deck)).switch_to(cx, room_id);
```

## When to Use

- Chat applications with many rooms
- Tab systems with heavy content
- Image galleries
- Any app where views are expensive to keep in memory

## Configuration

Adjust `MAX_CACHED_VIEWS` based on:
- Memory constraints of target platform
- Complexity of each view
- User behavior (how often they switch)
