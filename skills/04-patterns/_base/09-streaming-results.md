---
name: streaming-results
author: robius
source: moly
date: 2024-01-01
tags: [streaming, search, incremental, background]
level: advanced
---

# Pattern 9: Streaming Results

Process and display results as they arrive from a background thread.

## Problem

You have a long-running operation (like search) that produces results incrementally. You want to show results as they're found, not wait for completion.

## Solution

Use `mpsc::channel` to stream results from background thread, with `SignalToUI` to wake the UI.

## Implementation

```rust
use std::sync::mpsc;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use makepad_widgets::SignalToUI;

pub fn spawn_search(
    query: String,
    items: Vec<Item>,
    cancel: Arc<AtomicBool>,
) -> mpsc::Receiver<Item> {
    let (tx, rx) = mpsc::channel();

    std::thread::spawn(move || {
        for (i, item) in items.iter().enumerate() {
            // Check for cancellation
            if cancel.load(Ordering::Relaxed) {
                return;
            }

            if item.matches(&query) {
                let _ = tx.send(item.clone());

                // Wake UI periodically (not every item for performance)
                if i % 10 == 0 {
                    SignalToUI::set_ui_signal();
                }
            }
        }
        // Final wake to ensure UI gets last items
        SignalToUI::set_ui_signal();
    });

    rx
}

#[derive(Live, Widget)]
pub struct SearchWidget {
    #[deref] view: View,
    #[rust] search_receiver: Option<mpsc::Receiver<Item>>,
    #[rust] cancel_token: Option<Arc<AtomicBool>>,
    #[rust] results: Vec<Item>,
}

impl MatchEvent for SearchWidget {
    fn handle_signal(&mut self, cx: &mut Cx) {
        // Drain all available results
        if let Some(rx) = &self.search_receiver {
            while let Ok(item) = rx.try_recv() {
                self.results.push(item);
            }
            if !self.results.is_empty() {
                self.redraw(cx);
            }
        }
    }
}

impl SearchWidget {
    fn start_search(&mut self, cx: &mut Cx, query: String) {
        // Cancel previous search
        if let Some(cancel) = &self.cancel_token {
            cancel.store(true, Ordering::Relaxed);
        }

        // Clear results
        self.results.clear();

        // Start new search
        let cancel = Arc::new(AtomicBool::new(false));
        let rx = spawn_search(query, self.all_items.clone(), cancel.clone());

        self.cancel_token = Some(cancel);
        self.search_receiver = Some(rx);
        self.redraw(cx);
    }
}
```

## Usage

```rust
// Start search when text changes
if let Some(query) = self.ui.text_input(id!(search_input)).changed(&actions) {
    self.start_search(cx, query);
}
```

## When to Use

- Search with live results
- File scanning
- Log streaming
- Any incremental processing

## Performance Tips

- Don't signal on every item (batch with `i % 10`)
- Use `try_recv()` to drain all available items
- Provide cancellation for user experience
