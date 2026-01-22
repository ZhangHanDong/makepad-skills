# Tokio Integration Reference

Detailed patterns for integrating Tokio async runtime with Makepad UI.

## Runtime Initialization

```rust
use std::sync::Mutex;
use tokio::runtime::Runtime;

// Global static for the Tokio runtime
static TOKIO_RUNTIME: Mutex<Option<Runtime>> = Mutex::new(None);

/// Get or create the Tokio runtime handle
pub fn get_runtime_handle() -> tokio::runtime::Handle {
    TOKIO_RUNTIME.lock().unwrap()
        .get_or_insert_with(|| {
            Runtime::new().expect("Failed to create Tokio runtime")
        })
        .handle()
        .clone()
}
```

## Per-Item Background Task Management

For items that need dedicated background listeners (like room timelines):

```rust
use tokio::task::JoinHandle;
use matrix_sdk::event_handler::EventHandlerDropGuard;

struct ItemDetails {
    item_id: OwnedItemId,
    data: Arc<ItemData>,
    update_sender: crossbeam_channel::Sender<ItemUpdate>,
    // Task handle for cleanup
    subscriber_task: JoinHandle<()>,
    // Event handlers dropped on item close
    event_handlers: Option<EventHandlerDropGuard>,
}

impl Drop for ItemDetails {
    fn drop(&mut self) {
        // Abort background task when item is closed
        self.subscriber_task.abort();
        // Drop event handlers
        drop(self.event_handlers.take());
    }
}
```

## Subscriber Task Pattern

```rust
async fn spawn_item_subscriber(
    item_id: OwnedItemId,
    data_stream: impl Stream<Item = DataUpdate>,
    sender: crossbeam_channel::Sender<ItemUpdate>,
) -> JoinHandle<()> {
    tokio::spawn(async move {
        pin_mut!(data_stream);

        while let Some(update) = data_stream.next().await {
            // Process update
            let processed = process_update(update);

            // Send to UI
            if sender.send(processed).is_err() {
                // Receiver dropped, exit
                break;
            }

            // Wake UI thread
            SignalToUI::set_ui_signal();
        }
    })
}
```

## Blocking with Timeout

For shutdown scenarios where you need to wait for async operations:

```rust
pub fn block_on_async_with_timeout<F, T>(
    timeout: Option<Duration>,
    future: F,
) -> Result<T, Elapsed>
where
    F: Future<Output = T>,
{
    let rt_handle = get_runtime_handle();

    rt_handle.block_on(async {
        match timeout {
            Some(duration) => tokio::time::timeout(duration, future).await,
            None => Ok(future.await),
        }
    })
}

// Usage in shutdown:
let res = block_on_async_with_timeout(
    Some(Duration::from_secs(3)),
    async move {
        // Save state...
    },
);
```

## Client Access Pattern

```rust
static CLIENT: Mutex<Option<Client>> = Mutex::new(None);

pub fn get_client() -> Option<Client> {
    CLIENT.lock().unwrap().clone()
}

pub fn set_client(client: Client) {
    *CLIENT.lock().unwrap() = Some(client);
}
```
