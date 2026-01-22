# Moly Async Patterns

Additional async patterns from Moly codebase - an AI chat application with cross-platform support (native + WASM).

## Platform-Agnostic Spawn

Moly provides a unified `spawn()` function that works on both native (Tokio) and WASM:

```rust
use std::pin::Pin;
use futures::Future;

cfg_if::cfg_if! {
    if #[cfg(target_arch = "wasm32")] {
        pub trait PlatformSendInner {}
        impl<T> PlatformSendInner for T {}
    } else {
        pub trait PlatformSendInner: Send {}
        impl<T> PlatformSendInner for T where T: Send {}
    }
}

/// Implies [`Send`] only on native platforms, but not on WASM.
pub trait PlatformSend: PlatformSendInner {}
impl<T> PlatformSend for T where T: PlatformSendInner {}

/// A future that requires [`Send`] on native, but not on WASM.
pub trait PlatformSendFuture: Future + PlatformSend {}
impl<F, O> PlatformSendFuture for F where F: Future<Output = O> + PlatformSend {}

/// Platform-agnostic spawn
pub fn spawn(fut: impl PlatformSendFuture<Output = ()> + 'static) {
    #[cfg(not(target_arch = "wasm32"))]
    spawn_native(fut);

    #[cfg(target_arch = "wasm32")]
    wasm_bindgen_futures::spawn_local(fut);
}

#[cfg(not(target_arch = "wasm32"))]
fn spawn_native(fut: impl Future<Output = ()> + 'static + Send) {
    use std::sync::OnceLock;
    use tokio::runtime::{Builder, Handle, Runtime};

    static RUNTIME: OnceLock<Runtime> = OnceLock::new();

    if let Ok(handle) = Handle::try_current() {
        handle.spawn(fut);
    } else {
        // Create shared runtime if none exists
        let rt = RUNTIME.get_or_init(|| {
            Builder::new_multi_thread()
                .enable_io()
                .enable_time()
                .thread_name("app-tokio")
                .build()
                .expect("Failed to create Tokio runtime")
        });
        rt.spawn(fut);
    }
}
```

## UiRunner Pattern

Moly extends Makepad's `UiRunner` for async defer operations:

```rust
use makepad_widgets::{Cx, DeferWithRedraw, Scope, UiRunner, Widget};
use futures::channel::oneshot;

pub trait AsyncDeferCallback<T, R>:
    FnOnce(&mut T, &mut Cx, &mut Scope) -> R + Send + 'static
where
    R: Send + 'static,
{
}

impl<T, R: Send + 'static, F: FnOnce(&mut T, &mut Cx, &mut Scope) -> R + Send + 'static>
    AsyncDeferCallback<T, R> for F
{
}

/// Async extension to UiRunner
pub trait DeferAsync<T> {
    /// Awaitable variant of UiRunner::defer
    async fn defer_async<R>(self, f: impl AsyncDeferCallback<T, R>) -> Option<R>
    where
        R: Send + 'static,
        Self: Sized;
}

impl<T: 'static> DeferAsync<T> for UiRunner<T> {
    async fn defer_async<R: Send + 'static>(
        self,
        f: impl AsyncDeferCallback<T, R>
    ) -> Option<R> {
        let (tx, rx) = oneshot::channel::<R>();
        self.defer(move |me, cx, scope| {
            let _ = tx.send(f(me, cx, scope));
        });
        rx.await.ok()
    }
}

/// Usage example - async Store initialization:
pub fn load_store_into_app() {
    spawn(async move {
        let store = Store::load().await;

        // Use UiRunner to update App on UI thread
        app_runner().defer(move |app, cx, _| {
            app.store = Some(store);
            app.ui.view(id!(body)).set_visible(cx, true);
            cx.redraw_all();
        });
    });
}
```

## AbortOnDropHandle

Task cancellation when widget is dropped:

```rust
use futures::future::{AbortHandle, Abortable, abortable};

/// Handle that aborts its associated future when dropped.
pub struct AbortOnDropHandle(AbortHandle);

impl Drop for AbortOnDropHandle {
    fn drop(&mut self) {
        self.0.abort();
    }
}

impl AbortOnDropHandle {
    pub fn abort(&mut self) {
        self.0.abort();
    }
}

/// Constructs a future + AbortOnDropHandle pair.
pub fn abort_on_drop<F, T>(future: F) -> (Abortable<F>, AbortOnDropHandle)
where
    F: PlatformSendFuture<Output = T> + 'static,
{
    let (abort_handle, abort_registration) = abortable(future);
    (abort_handle, AbortOnDropHandle(abort_registration))
}

// Usage in widget
#[derive(Live, Widget)]
pub struct ChatWidget {
    #[deref] view: View,
    #[rust] task_handle: Option<AbortOnDropHandle>,
}

impl ChatWidget {
    fn start_streaming(&mut self) {
        let (future, handle) = abort_on_drop(async {
            // Streaming task...
        });
        self.task_handle = Some(handle);
        spawn(async { let _ = future.await; });
    }
}
// Task automatically cancelled when widget is dropped
```

## ThreadToken for Non-Send Types

For WASM where you need to pass non-Send values across async boundaries:

```rust
use std::cell::RefCell;
use std::collections::HashMap;
use std::sync::Arc;
use std::sync::atomic::{AtomicU64, Ordering};

static NEXT_KEY: AtomicU64 = AtomicU64::new(0);

thread_local! {
    static STORAGE: RefCell<HashMap<u64, Option<Box<dyn std::any::Any>>>> =
        RefCell::new(HashMap::new());
}

/// Holds a value in thread-local storage, accessible via token.
/// Token is Send even if the value isn't (useful for WASM).
pub struct ThreadToken<T: 'static> {
    key: u64,
    _phantom: std::marker::PhantomData<fn() -> T>,
}

// ThreadToken is Send because it only stores a key
unsafe impl<T> Send for ThreadToken<T> {}

impl<T> ThreadToken<T> {
    pub fn new(value: T) -> Self {
        let key = NEXT_KEY.fetch_add(1, Ordering::Relaxed);
        STORAGE.with_borrow_mut(|storage| {
            storage.insert(key, Some(Box::new(value)));
        });
        Self { key, _phantom: std::marker::PhantomData }
    }

    pub fn peek<R>(&self, f: impl FnOnce(&T) -> R) -> R {
        STORAGE.with_borrow_mut(|storage| {
            let value = storage.get(&self.key)
                .expect("Token used from different thread")
                .as_ref()
                .expect("Value already taken")
                .downcast_ref::<T>()
                .unwrap();
            f(value)
        })
    }

    pub fn peek_mut<R>(&self, f: impl FnOnce(&mut T) -> R) -> R {
        STORAGE.with_borrow_mut(|storage| {
            let value = storage.get_mut(&self.key)
                .expect("Token used from different thread")
                .as_mut()
                .expect("Value already taken")
                .downcast_mut::<T>()
                .unwrap();
            f(value)
        })
    }
}

// Usage: Pass non-Send FileHandle across async boundary on WASM
let file_token = ThreadToken::new(file_handle);
spawn(async move {
    file_token.peek(|handle| {
        // Use handle...
    });
});
```

## App Runner Global Access

Create a global accessor for the App's UiRunner:

```rust
pub fn app_runner() -> UiRunner<App> {
    // `0` is reserved for whatever implements `AppMain`
    UiRunner::new(0)
}

// Usage from any async context:
spawn(async move {
    let result = fetch_data().await;

    app_runner().defer(move |app, cx, _| {
        app.data = result;
        cx.redraw_all();
    });
});
```
