# Makepad Event System Reference

## Event Enum (Complete)

```rust
pub enum Event {
    // Lifecycle Events
    Startup,                              // Application started
    Shutdown,                             // Application closing
    Foreground,                           // App came to foreground (mobile)
    Background,                           // App went to background (mobile)
    Resume,                               // App resumed (Android)
    Pause,                                // App paused (Android)

    // Drawing
    Draw(DrawEvent),                      // Draw request
    LiveEdit,                             // Live code edit detected

    // Window Events
    WindowGotFocus(WindowId),             // Window gained focus
    WindowLostFocus(WindowId),            // Window lost focus
    WindowGeomChange(WindowGeomChangeEvent), // Window geometry changed
    WindowClosed(WindowClosedEvent),      // Window closed
    WindowDragQuery(WindowDragQueryEvent), // Drag query
    WindowCloseRequested(WindowCloseRequestedEvent), // Close requested

    // Mouse Events
    MouseDown(MouseDownEvent),            // Mouse button pressed
    MouseMove(MouseMoveEvent),            // Mouse moved
    MouseUp(MouseUpEvent),                // Mouse button released
    Scroll(ScrollEvent),                  // Mouse scroll/wheel

    // Touch Events
    TouchUpdate(TouchUpdateEvent),        // Touch state changed

    // Keyboard Events
    KeyDown(KeyEvent),                    // Key pressed
    KeyUp(KeyEvent),                      // Key released
    TextInput(TextInputEvent),            // Text input (IME)
    TextCopy(TextClipboardEvent),         // Copy requested
    TextCut(TextClipboardEvent),          // Cut requested

    // Drag & Drop
    Drag(DragEvent),                      // Dragging
    Drop(DropEvent),                      // Dropped
    DragEnd,                              // Drag ended

    // System Events
    Timer(TimerEvent),                    // Timer fired
    Signal,                               // Signal received
    NextFrame(NextFrameEvent),            // Next frame callback

    // Network
    HttpResponse(HttpResponse),           // HTTP response
    NetworkResponses(NetworkResponsesEvent), // Network responses

    // Widget Actions
    Actions(ActionsBuf),                  // Actions from widgets
}
```

## Mouse Events

```rust
pub struct MouseDownEvent {
    pub abs: Vec2d,           // Absolute position
    pub button: MouseButton,  // Which button
    pub window_id: WindowId,  // Window ID
    pub modifiers: KeyModifiers, // Ctrl, Shift, etc.
    pub time: f64,            // Event time
    pub handled: Cell<Area>,  // Which area handled it
}

pub struct MouseMoveEvent {
    pub abs: Vec2d,
    pub window_id: WindowId,
    pub modifiers: KeyModifiers,
    pub time: f64,
    pub handled: Cell<Area>,
}

pub struct MouseUpEvent {
    pub abs: Vec2d,
    pub button: MouseButton,
    pub window_id: WindowId,
    pub modifiers: KeyModifiers,
    pub time: f64,
}

pub enum MouseButton {
    Left,
    Right,
    Middle,
    Other(u8),
}
```

## Keyboard Events

```rust
pub struct KeyEvent {
    pub key_code: KeyCode,
    pub is_repeat: bool,
    pub modifiers: KeyModifiers,
    pub time: f64,
}

pub struct KeyModifiers {
    pub shift: bool,
    pub control: bool,
    pub alt: bool,
    pub logo: bool,  // Cmd on macOS, Win on Windows
}

pub enum KeyCode {
    // Letters
    KeyA, KeyB, KeyC, /* ... */ KeyZ,

    // Numbers
    Key0, Key1, /* ... */ Key9,

    // Function keys
    F1, F2, /* ... */ F12,

    // Arrow keys
    ArrowLeft, ArrowRight, ArrowUp, ArrowDown,

    // Special keys
    Return, Tab, Escape, Backspace, Delete,
    Home, End, PageUp, PageDown,
    Space, Insert,

    // Modifiers
    Shift, Control, Alt, Logo,

    // Numpad
    Numpad0, /* ... */ Numpad9,
    NumpadAdd, NumpadSubtract, NumpadMultiply, NumpadDivide,
    NumpadEnter, NumpadDecimal,

    Unknown,
}
```

## Touch Events

```rust
pub struct TouchUpdateEvent {
    pub abs: Vec2d,
    pub uid: TouchUid,        // Unique touch ID
    pub state: TouchState,
    pub time: f64,
    pub modifiers: KeyModifiers,
    pub handled: Cell<Area>,
}

pub enum TouchState {
    Start,    // Touch began
    Move,     // Touch moved
    End,      // Touch ended
    Cancel,   // Touch cancelled
}
```

## Hit Enum

The `hit` method on events returns a `Hit` enum for easier handling:

```rust
pub enum Hit {
    // Finger/Mouse interactions
    FingerDown(FingerDownEvent),
    FingerUp(FingerUpEvent),
    FingerMove(FingerMoveEvent),
    FingerHoverIn(FingerHoverEvent),
    FingerHoverOver(FingerHoverEvent),
    FingerHoverOut(FingerHoverEvent),
    FingerLongPress(FingerLongPressEvent),

    // Keyboard interactions
    KeyDown(KeyEvent),
    KeyUp(KeyEvent),
    KeyFocus,
    KeyFocusLost,
    TextInput(TextInputEvent),
    TextCopy,

    // No interaction
    Nothing,
}

pub struct FingerDownEvent {
    pub abs: Vec2d,           // Absolute position
    pub rel: Vec2d,           // Position relative to widget
    pub rect: Rect,           // Widget rect
    pub digit: usize,         // Touch digit index
    pub tap_count: u32,       // Number of taps (double-click)
    pub modifiers: KeyModifiers,
    pub time: f64,
}

pub struct FingerUpEvent {
    pub abs: Vec2d,
    pub rel: Vec2d,
    pub rect: Rect,
    pub digit: usize,
    pub is_over: bool,        // Still over widget?
    pub modifiers: KeyModifiers,
    pub time: f64,
}
```

## Event Handling Pattern

```rust
impl Widget for MyWidget {
    fn handle_event(&mut self, cx: &mut Cx, event: &Event, scope: &mut Scope) {
        // Handle lifecycle events
        match event {
            Event::Startup => { /* Initialize */ }
            Event::Shutdown => { /* Cleanup */ }
            _ => {}
        }

        // Check if event hits this widget
        match event.hits(cx, self.area()) {
            Hit::FingerDown(fe) => {
                if fe.tap_count == 2 {
                    // Double-click
                }
            }
            Hit::FingerUp(fe) => {
                if fe.is_over {
                    // Click completed on this widget
                }
            }
            Hit::KeyDown(ke) => {
                match ke.key_code {
                    KeyCode::Return => { /* Enter pressed */ }
                    KeyCode::Escape => { /* Escape pressed */ }
                    _ => {}
                }
            }
            Hit::TextInput(te) => {
                let text = &te.input;
                // Handle text input
            }
            _ => {}
        }
    }
}
```

## Timer Events

```rust
// Start a timer
let timer = cx.start_timer(interval_seconds);

// Stop a timer
cx.stop_timer(timer);

// Handle timer event
if let Event::Timer(te) = event {
    if te.timer_id == self.my_timer {
        // Timer fired
    }
}
```

## NextFrame Events

```rust
// Request next frame callback
let next_frame = cx.new_next_frame();

// Handle next frame
if let Event::NextFrame(ne) = event {
    if ne.frame_id == self.next_frame {
        // Called on next frame
        // Useful for animations
    }
}
```
