---
name: state-machine
author: robius
source: moly
date: 2024-01-01
tags: [state-machine, lifecycle, enum, complex-state]
level: advanced
---

# Pattern 10: State Machine Widget

Manage complex widget lifecycle with enum states.

## Problem

Your widget has multiple states (idle, searching, showing results, error) with different behaviors and transitions. Using multiple boolean flags gets messy.

## Solution

Use an enum to represent all possible states, with each state containing its relevant data.

## Implementation

```rust
enum SearchState {
    Idle,
    Searching {
        query: String,
        receiver: mpsc::Receiver<SearchResult>,
        cancel_token: Arc<AtomicBool>,
    },
    ShowingResults(Vec<SearchResult>),
    Error(String),
}

#[derive(Live, Widget)]
pub struct SearchWidget {
    #[deref] view: View,
    #[rust] state: SearchState,
    #[rust] all_items: Vec<Item>,
}

impl Default for SearchState {
    fn default() -> Self {
        SearchState::Idle
    }
}

impl Widget for SearchWidget {
    fn handle_event(&mut self, cx: &mut Cx, event: &Event, scope: &mut Scope) {
        self.view.handle_event(cx, event, scope);

        // State-specific event handling
        match &mut self.state {
            SearchState::Searching { receiver, .. } => {
                // Check for results
                while let Ok(result) = receiver.try_recv() {
                    // Collect results...
                }
            }
            _ => {}
        }
    }

    fn draw_walk(&mut self, cx: &mut Cx2d, scope: &mut Scope, walk: Walk) -> DrawStep {
        // State-specific drawing
        match &self.state {
            SearchState::Idle => {
                self.view.view(ids!(empty_state)).set_visible(cx, true);
                self.view.view(ids!(loading_state)).set_visible(cx, false);
                self.view.view(ids!(results_state)).set_visible(cx, false);
            }
            SearchState::Searching { .. } => {
                self.view.view(ids!(empty_state)).set_visible(cx, false);
                self.view.view(ids!(loading_state)).set_visible(cx, true);
                self.view.view(ids!(results_state)).set_visible(cx, false);
            }
            SearchState::ShowingResults(results) => {
                self.view.view(ids!(empty_state)).set_visible(cx, false);
                self.view.view(ids!(loading_state)).set_visible(cx, false);
                self.view.view(ids!(results_state)).set_visible(cx, true);
                // Render results...
            }
            SearchState::Error(msg) => {
                // Show error...
            }
        }

        self.view.draw_walk(cx, scope, walk)
    }
}

impl SearchWidget {
    fn start_search(&mut self, cx: &mut Cx, query: String) {
        // Cancel previous search if any
        if let SearchState::Searching { cancel_token, .. } = &self.state {
            cancel_token.store(true, Ordering::Relaxed);
        }

        let cancel = Arc::new(AtomicBool::new(false));
        let rx = spawn_search(query.clone(), self.all_items.clone(), cancel.clone());

        self.state = SearchState::Searching {
            query,
            receiver: rx,
            cancel_token: cancel,
        };
        self.redraw(cx);
    }

    fn show_results(&mut self, cx: &mut Cx, results: Vec<SearchResult>) {
        self.state = SearchState::ShowingResults(results);
        self.redraw(cx);
    }

    fn show_error(&mut self, cx: &mut Cx, error: String) {
        self.state = SearchState::Error(error);
        self.redraw(cx);
    }

    fn reset(&mut self, cx: &mut Cx) {
        if let SearchState::Searching { cancel_token, .. } = &self.state {
            cancel_token.store(true, Ordering::Relaxed);
        }
        self.state = SearchState::Idle;
        self.redraw(cx);
    }
}
```

## When to Use

- Widgets with complex lifecycles
- Multi-step wizards
- Connection states (connecting, connected, error)
- Media players (loading, playing, paused, ended)

## Benefits

- Compile-time state validation
- Clear state transitions
- State-specific data is scoped
- Easy to add new states
