# Channel Communication Patterns

Patterns for communication between UI thread and async runtime.

## Request Channel (UI → Async)

Using `tokio::sync::mpsc::unbounded_channel`:

```rust
use tokio::sync::mpsc::{UnboundedSender, UnboundedReceiver};

static REQUEST_SENDER: Mutex<Option<UnboundedSender<AppRequest>>> = Mutex::new(None);

pub fn submit_async_request(req: AppRequest) {
    if let Some(sender) = REQUEST_SENDER.lock().unwrap().as_ref() {
        sender.send(req).expect("Worker task died");
    }
}
```

## Update Queue (Async → UI)

Using `crossbeam_queue::SegQueue` for lock-free operations:

```rust
use crossbeam_queue::SegQueue;

static PENDING_UPDATES: SegQueue<Update> = SegQueue::new();

// Async side: enqueue update
pub fn enqueue_update(update: Update) {
    PENDING_UPDATES.push(update);
    SignalToUI::set_ui_signal();
}

// UI side: drain updates
fn handle_event(&mut self, cx: &mut Cx, event: &Event, scope: &mut Scope) {
    if let Event::Signal = event {
        while let Some(update) = PENDING_UPDATES.pop() {
            self.apply_update(cx, update);
        }
    }
}
```

## Per-Item Channels

Using `crossbeam_channel` for per-item communication:

```rust
use crossbeam_channel::{Sender, Receiver, unbounded};

struct ItemState {
    update_sender: Sender<ItemUpdate>,
    update_receiver: Receiver<ItemUpdate>,
}

impl ItemState {
    fn new() -> Self {
        let (sender, receiver) = unbounded();
        Self {
            update_sender: sender,
            update_receiver: receiver,
        }
    }

    fn poll_updates(&mut self, cx: &mut Cx) {
        while let Ok(update) = self.update_receiver.try_recv() {
            self.apply_update(cx, update);
        }
    }
}
```

## Action Posting (Async → UI Actions)

For result actions that need central handling:

```rust
// In async task
Cx::post_action(ResultAction::Success { data });
SignalToUI::set_ui_signal();

// In App::handle_actions
fn handle_actions(&mut self, cx: &mut Cx, actions: &Actions) {
    for action in actions {
        if let Some(result) = action.downcast_ref::<ResultAction>() {
            match result {
                ResultAction::Success { data } => { /* handle */ }
                ResultAction::Failed { error } => { /* handle */ }
            }
        }
    }
}
```

## Thread-Local State

For UI-thread-only state:

```rust
use std::{cell::RefCell, rc::Rc};

thread_local! {
    static UI_ONLY_STATE: Rc<RefCell<HashMap<Id, Data>>> =
        Rc::new(RefCell::new(HashMap::new()));
}

pub fn get_ui_state(_cx: &mut Cx) -> Rc<RefCell<HashMap<Id, Data>>> {
    // _cx parameter ensures this is called from UI thread
    UI_ONLY_STATE.with(Rc::clone)
}

pub fn clear_ui_state(_cx: &mut Cx) {
    UI_ONLY_STATE.with(|state| state.borrow_mut().clear());
}
```
