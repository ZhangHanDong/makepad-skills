---
name: tokio-integration
author: robius
source: robrix
date: 2024-01-01
tags: [async, tokio, runtime, channel, background]
level: advanced
---

# Pattern 13: Tokio Async Integration

Full tokio runtime integration for complex async operations.

## Problem

Your app needs real async capabilities: multiple concurrent requests, WebSockets, or integration with async SDKs like Matrix.

## Solution

Create a global tokio runtime with request channels and `Cx::post_action` for responses.

## Implementation

```rust
use std::sync::Mutex;
use tokio::runtime::{Runtime, Handle};
use tokio::sync::mpsc::{unbounded_channel, UnboundedSender};

// Global runtime
static TOKIO_RUNTIME: Mutex<Option<Runtime>> = Mutex::new(None);
static REQUEST_SENDER: Mutex<Option<UnboundedSender<AppRequest>>> = Mutex::new(None);

// Request types
pub enum AppRequest {
    FetchUsers,
    SendMessage { room_id: String, content: String },
    Logout,
}

// Response types
#[derive(Debug)]
pub enum AppResponse {
    UsersFetched(Vec<User>),
    MessageSent(Result<(), String>),
    LoggedOut,
}

pub fn start_async_runtime() {
    let rt = TOKIO_RUNTIME.lock().unwrap()
        .get_or_insert_with(|| {
            Runtime::new().expect("Failed to create Tokio runtime")
        })
        .handle()
        .clone();

    rt.spawn(async {
        let (sender, mut receiver) = unbounded_channel::<AppRequest>();
        *REQUEST_SENDER.lock().unwrap() = Some(sender);

        while let Some(request) = receiver.recv().await {
            match request {
                AppRequest::FetchUsers => {
                    let result = fetch_users_impl().await;
                    Cx::post_action(AppResponse::UsersFetched(result));
                }
                AppRequest::SendMessage { room_id, content } => {
                    let result = send_message_impl(&room_id, &content).await;
                    Cx::post_action(AppResponse::MessageSent(result));
                }
                AppRequest::Logout => {
                    logout_impl().await;
                    Cx::post_action(AppResponse::LoggedOut);
                }
            }
        }
    });
}

// Helper to submit requests (non-blocking)
pub fn submit_request(request: AppRequest) {
    if let Some(sender) = REQUEST_SENDER.lock().unwrap().as_ref() {
        let _ = sender.send(request);
    }
}
```

## App Integration

```rust
impl MatchEvent for App {
    fn handle_startup(&mut self, cx: &mut Cx) {
        start_async_runtime();
        submit_request(AppRequest::FetchUsers);
        self.show_loading(cx);
    }

    fn handle_actions(&mut self, cx: &mut Cx, actions: &Actions) {
        // Handle button clicks
        if self.ui.button(id!(refresh_btn)).clicked(&actions) {
            submit_request(AppRequest::FetchUsers);
        }

        if self.ui.button(id!(send_btn)).clicked(&actions) {
            let content = self.ui.text_input(id!(message_input)).text();
            submit_request(AppRequest::SendMessage {
                room_id: self.current_room.clone(),
                content,
            });
        }

        // Handle async responses
        for action in actions {
            if let Some(response) = action.downcast_ref::<AppResponse>() {
                match response {
                    AppResponse::UsersFetched(users) => {
                        self.users = users.clone();
                        self.hide_loading(cx);
                        self.update_user_list(cx);
                    }
                    AppResponse::MessageSent(Ok(())) => {
                        self.ui.text_input(id!(message_input)).set_text(cx, "");
                    }
                    AppResponse::MessageSent(Err(e)) => {
                        show_error(cx, e);
                    }
                    AppResponse::LoggedOut => {
                        self.navigate_to_login(cx);
                    }
                }
            }
        }
    }
}
```

## Cargo.toml

```toml
[dependencies]
tokio = { version = "1", features = ["rt-multi-thread", "macros", "sync"] }
```

## When to Use

- Multiple concurrent API requests
- WebSocket connections
- SDK integration (Matrix, etc.)
- Long-running background services

## vs std::thread

| Use Case | Use |
|----------|-----|
| One-off CPU work | `std::thread::spawn` |
| Single blocking HTTP | `std::thread::spawn` |
| Multiple concurrent I/O | Tokio |
| WebSockets/streaming | Tokio |
| Async SDK integration | Tokio |
