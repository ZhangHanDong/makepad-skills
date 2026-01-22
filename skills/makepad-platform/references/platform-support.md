# Makepad Platform Support Reference

## Overview

Makepad is a cross-platform UI framework that compiles to native code for each supported platform. The platform abstraction layer is located in `platform/src/os/`.

## Platform Architecture

```
makepad/platform/src/os/
├── apple/          # macOS + iOS (Metal)
│   ├── metal_*.rs       # Metal graphics backend
│   ├── cocoa_*.rs       # macOS Cocoa APIs
│   └── ios_*.rs         # iOS-specific APIs
├── mswindows/      # Windows (D3D11)
│   ├── d3d11_*.rs       # Direct3D 11 backend
│   └── win32_*.rs       # Win32 APIs
├── linux/          # Linux (OpenGL)
│   ├── opengl_*.rs      # OpenGL backend
│   ├── x11*.rs          # X11 window system
│   └── wayland*.rs      # Wayland window system
├── web/            # Web (WebGL2)
│   ├── web_gl.rs        # WebGL2 backend
│   └── web_browser/     # Browser integration
├── android/        # Android (OpenGL ES)
├── open_harmony/   # OpenHarmony (OHOS)
└── open_xr/        # OpenXR (VR/AR)
```

## OsType Enum

```rust
pub enum OsType {
    Unknown,
    Windows,
    Macos,
    Linux { custom_window_chrome: bool },
    Ios,
    Android(AndroidParams),
    OpenHarmony,
    Web(WebParams),
    OpenXR,
}

pub struct AndroidParams {
    pub cache_path: String,
    pub density: f64,
}

pub struct WebParams {
    pub protocol: String,
    pub hostname: String,
    pub port: u16,
    pub pathname: String,
    pub search: String,
    pub hash: String,
}
```

## Cx Platform APIs

```rust
impl Cx {
    // Platform info
    pub fn os_type(&self) -> OsType;
    pub fn gpu_info(&self) -> &GpuInfo;
    pub fn xr_capabilities(&self) -> &XrCapabilities;
    pub fn cpu_cores(&self) -> usize;

    // Platform operations
    pub fn show_keyboard(&mut self);
    pub fn hide_keyboard(&mut self);
    pub fn set_cursor(&mut self, cursor: MouseCursor);
    pub fn copy_to_clipboard(&mut self, text: &str);
    pub fn request_paste_from_clipboard(&mut self);

    // Window management
    pub fn set_window_title(&mut self, title: &str);
    pub fn set_window_position(&mut self, x: f64, y: f64);
    pub fn set_window_size(&mut self, w: f64, h: f64);
    pub fn toggle_fullscreen(&mut self);
}
```

## GpuInfo Struct

```rust
pub struct GpuInfo {
    pub vendor: String,
    pub renderer: String,
    pub version: String,
    pub max_texture_size: usize,
}
```

## MouseCursor Enum

```rust
pub enum MouseCursor {
    Default,
    Crosshair,
    Hand,
    Arrow,
    Move,
    Text,
    Wait,
    Help,
    NotAllowed,
    NResize,
    NeResize,
    EResize,
    SeResize,
    SResize,
    SwResize,
    WResize,
    NwResize,
    NsResize,
    NeswResize,
    EwResize,
    NwseResize,
    ColResize,
    RowResize,
    Hidden,
}
```

## Platform-Specific Lifecycle Events

```rust
pub enum Event {
    // App lifecycle
    Startup,      // App started
    Shutdown,     // App closing
    Foreground,   // App came to foreground (mobile)
    Background,   // App went to background (mobile)
    Resume,       // App resumed (Android)
    Pause,        // App paused (Android)
    // ...
}
```

## Building for Platforms

### macOS
```bash
cargo run
# or
cargo build --release
```

### Windows
```bash
cargo run --target x86_64-pc-windows-msvc
```

### Linux
```bash
cargo run --target x86_64-unknown-linux-gnu
```

### Web
```bash
cargo makepad wasm run
# or
cargo makepad wasm build
```

### Android
```bash
cargo makepad android run
# or
cargo makepad android build
```

### iOS
```bash
cargo makepad ios run
# or
cargo makepad ios build
```

## Display Context

```rust
pub struct DisplayContext {
    pub dpi_factor: f64,           // Display scale factor
    pub screen_size: Vec2d,        // Screen dimensions
    pub safe_area: Rect,           // Safe area (notch, etc.)
    pub is_portrait: bool,         // Orientation
}

// Access in widgets
fn draw_walk(&mut self, cx: &mut Cx2d, scope: &mut Scope, walk: Walk) -> DrawStep {
    let dpi = cx.display_context().dpi_factor;
    // ...
}
```
