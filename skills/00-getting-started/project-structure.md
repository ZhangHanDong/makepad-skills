---
name: makepad-project-structure
description: Best practices for organizing Makepad application projects. Based on production patterns from Robrix and Moly. Covers directory structure, module organization, live_design registration, shared components, styles/themes, resource management, and Cargo.toml configuration.
---

# Makepad Project Structure

Best practices for organizing Makepad applications, based on production patterns from Robrix (Matrix chat client) and Moly (AI model manager).

---

## Directory Structure

### Recommended Layout

```
my_app/
├── src/
│   ├── app.rs                 # Main app orchestrator
│   ├── lib.rs                 # Module declarations, live_register
│   │
│   ├── home/                  # Feature: Main screen
│   │   ├── mod.rs             # Submodule declarations + live_design()
│   │   ├── home_screen.rs     # Main home screen widget
│   │   ├── sidebar.rs         # Sidebar component
│   │   └── content_view.rs    # Content area
│   │
│   ├── settings/              # Feature: Settings
│   │   ├── mod.rs
│   │   ├── settings_screen.rs
│   │   └── account_settings.rs
│   │
│   ├── login/                 # Feature: Authentication
│   │   ├── mod.rs
│   │   └── login_screen.rs
│   │
│   ├── shared/                # Reusable components
│   │   ├── mod.rs
│   │   ├── styles.rs          # Colors, fonts, icons
│   │   ├── helpers.rs         # Utility functions
│   │   ├── avatar.rs          # Avatar widget
│   │   ├── icon_button.rs     # Icon button widget
│   │   └── confirmation_modal.rs
│   │
│   └── utils.rs               # General utilities
│
├── resources/
│   ├── icons/                 # SVG icons
│   │   ├── add.svg
│   │   ├── close.svg
│   │   └── settings.svg
│   ├── img/                   # Images
│   │   ├── logo.png
│   │   └── default_avatar.png
│   └── fonts/                 # Custom fonts (if any)
│
├── packaging/                 # Platform-specific packaging
│   ├── macos/
│   ├── windows/
│   └── linux/
│
├── Cargo.toml
├── rustfmt.toml
├── rust-toolchain.toml
├── CLAUDE.md                  # AI assistant guidance (optional)
└── README.md
```

---

## Module Organization

### lib.rs Pattern

```rust
// src/lib.rs

// Feature modules (organized by screen/feature)
pub mod app;
pub mod home;
pub mod settings;
pub mod login;

// Shared components
pub mod shared;

// Utilities
pub mod utils;

// Optional: Feature-gated modules
#[cfg(feature = "analytics")]
pub mod analytics;

// App constants
pub const APP_QUALIFIER: &str = "com";
pub const APP_ORGANIZATION: &str = "mycompany";
pub const APP_NAME: &str = "myapp";

// Project directories (using robius-directories)
use std::path::Path;
use std::sync::OnceLock;
use robius_directories::ProjectDirs;

pub fn project_dir() -> &'static ProjectDirs {
    static PROJECT_DIRS: OnceLock<ProjectDirs> = OnceLock::new();

    PROJECT_DIRS.get_or_init(|| {
        ProjectDirs::from(APP_QUALIFIER, APP_ORGANIZATION, APP_NAME)
            .expect("Failed to obtain project directory")
    })
}

pub fn app_data_dir() -> &'static Path {
    project_dir().data_dir()
}
```

### Feature Module Pattern (mod.rs)

```rust
// src/home/mod.rs

// Submodule declarations
pub mod home_screen;
pub mod sidebar;
pub mod content_view;
pub mod toolbar;

// Re-export commonly used items
pub use home_screen::HomeScreen;

// live_design registration - ORDER MATTERS!
// Register dependencies before dependents
pub fn live_design(cx: &mut Cx) {
    // Base components first
    toolbar::live_design(cx);
    sidebar::live_design(cx);
    content_view::live_design(cx);
    // Composite components last
    home_screen::live_design(cx);
}
```

### Widget Module Pattern

```rust
// src/home/sidebar.rs
use makepad_widgets::*;

live_design! {
    use link::theme::*;
    use link::shaders::*;
    use link::widgets::*;

    use crate::shared::styles::*;

    pub Sidebar = {{Sidebar}} {
        width: 280
        height: Fill

        flow: Down
        padding: 16

        show_bg: true
        draw_bg: {
            color: (COLOR_SIDEBAR_BG)
        }

        header = <View> {
            height: Fit
            // ...
        }

        list = <ScrollYView> {
            // ...
        }
    }
}

#[derive(Live, LiveHook, Widget)]
pub struct Sidebar {
    #[deref] view: View,
    #[rust] items: Vec<SidebarItem>,
}

impl Widget for Sidebar {
    fn handle_event(&mut self, cx: &mut Cx, event: &Event, scope: &mut Scope) {
        self.view.handle_event(cx, event, scope);
    }

    fn draw_walk(&mut self, cx: &mut Cx2d, scope: &mut Scope, walk: Walk) -> DrawStep {
        self.view.draw_walk(cx, scope, walk)
    }
}

// Widget Ref extension for type-safe API
pub trait SidebarWidgetRefExt {
    fn set_items(&mut self, items: Vec<SidebarItem>);
    fn get_selected(&self) -> Option<usize>;
}

impl SidebarWidgetRefExt for SidebarRef {
    fn set_items(&mut self, items: Vec<SidebarItem>) {
        if let Some(mut inner) = self.borrow_mut() {
            inner.items = items;
        }
    }

    fn get_selected(&self) -> Option<usize> {
        self.borrow().map(|inner| inner.selected_index).flatten()
    }
}
```

---

## Shared Components

### styles.rs Structure

```rust
// src/shared/styles.rs
use makepad_widgets::*;

live_design! {
    use link::theme::*;
    use link::shaders::*;
    use link::widgets::*;

    // ============================================
    // ICONS
    // ============================================
    pub ICON_ADD = dep("crate://self/resources/icons/add.svg")
    pub ICON_CLOSE = dep("crate://self/resources/icons/close.svg")
    pub ICON_SETTINGS = dep("crate://self/resources/icons/settings.svg")
    pub ICON_SEARCH = dep("crate://self/resources/icons/search.svg")
    pub ICON_HOME = dep("crate://self/resources/icons/home.svg")
    pub ICON_USER = dep("crate://self/resources/icons/user.svg")
    // ... more icons

    // ============================================
    // COLORS
    // ============================================

    // Brand colors
    pub COLOR_PRIMARY = #2196F3
    pub COLOR_PRIMARY_DARK = #1976D2
    pub COLOR_PRIMARY_LIGHT = #BBDEFB
    pub COLOR_ACCENT = #FF4081

    // Semantic colors
    pub COLOR_SUCCESS = #4CAF50
    pub COLOR_WARNING = #FF9800
    pub COLOR_ERROR = #F44336
    pub COLOR_INFO = #2196F3

    // UI colors
    pub COLOR_BG_PRIMARY = #FFFFFF
    pub COLOR_BG_SECONDARY = #F5F5F5
    pub COLOR_BG_TERTIARY = #EEEEEE
    pub COLOR_SIDEBAR_BG = #FAFAFA

    // Text colors
    pub COLOR_TEXT_PRIMARY = #212121
    pub COLOR_TEXT_SECONDARY = #757575
    pub COLOR_TEXT_DISABLED = #BDBDBD
    pub COLOR_TEXT_INVERSE = #FFFFFF

    // Border colors
    pub COLOR_DIVIDER = #0000001F
    pub COLOR_BORDER = #E0E0E0

    // ============================================
    // TYPOGRAPHY
    // ============================================

    pub FONT_SIZE_H1 = 24.0
    pub FONT_SIZE_H2 = 20.0
    pub FONT_SIZE_H3 = 16.0
    pub FONT_SIZE_BODY = 14.0
    pub FONT_SIZE_CAPTION = 12.0
    pub FONT_SIZE_SMALL = 10.0

    pub TEXT_H1 = <THEME_FONT_BOLD>{
        font_size: (FONT_SIZE_H1)
    }

    pub TEXT_H2 = <THEME_FONT_BOLD>{
        font_size: (FONT_SIZE_H2)
    }

    pub TEXT_H3 = <THEME_FONT_BOLD>{
        font_size: (FONT_SIZE_H3)
    }

    pub TEXT_BODY = <THEME_FONT_REGULAR>{
        font_size: (FONT_SIZE_BODY)
        line_spacing: 1.4
    }

    pub TEXT_CAPTION = <THEME_FONT_REGULAR>{
        font_size: (FONT_SIZE_CAPTION)
    }

    pub TEXT_BUTTON = <THEME_FONT_BOLD>{
        font_size: (FONT_SIZE_BODY)
    }

    // ============================================
    // SPACING
    // ============================================

    pub SPACING_XS = 4.0
    pub SPACING_SM = 8.0
    pub SPACING_MD = 16.0
    pub SPACING_LG = 24.0
    pub SPACING_XL = 32.0

    // ============================================
    // COMPONENT SIZES
    // ============================================

    pub BUTTON_HEIGHT = 40.0
    pub INPUT_HEIGHT = 44.0
    pub ICON_SIZE_SM = 16.0
    pub ICON_SIZE_MD = 24.0
    pub ICON_SIZE_LG = 32.0
    pub AVATAR_SIZE_SM = 32.0
    pub AVATAR_SIZE_MD = 48.0
    pub AVATAR_SIZE_LG = 64.0
    pub BORDER_RADIUS = 8.0

    // ============================================
    // REUSABLE COMPONENT STYLES
    // ============================================

    pub FilledButton = <Button> {
        width: Fit
        height: (BUTTON_HEIGHT)
        padding: {left: 16, right: 16}

        draw_bg: {
            color: (COLOR_PRIMARY)
            color_hover: (COLOR_PRIMARY_DARK)
            border_radius: (BORDER_RADIUS)
        }

        draw_text: {
            text_style: <TEXT_BUTTON>{}
            color: (COLOR_TEXT_INVERSE)
        }
    }

    pub OutlinedButton = <Button> {
        width: Fit
        height: (BUTTON_HEIGHT)
        padding: {left: 16, right: 16}

        draw_bg: {
            color: #0000
            color_hover: (COLOR_BG_SECONDARY)
            border_width: 1.0
            border_color: (COLOR_PRIMARY)
            border_radius: (BORDER_RADIUS)
        }

        draw_text: {
            text_style: <TEXT_BUTTON>{}
            color: (COLOR_PRIMARY)
        }
    }

    pub Card = <RoundedView> {
        width: Fill
        height: Fit
        padding: (SPACING_MD)

        draw_bg: {
            color: (COLOR_BG_PRIMARY)
            border_radius: (BORDER_RADIUS)
        }
    }

    pub Divider = <View> {
        width: Fill
        height: 1
        show_bg: true
        draw_bg: { color: (COLOR_DIVIDER) }
    }
}
```

### shared/mod.rs Pattern

```rust
// src/shared/mod.rs

// Component modules
pub mod avatar;
pub mod icon_button;
pub mod confirmation_modal;
pub mod loading_indicator;
pub mod empty_state;
pub mod search_input;
pub mod toast;

// Styles and helpers
pub mod styles;
pub mod helpers;

// Re-exports
pub use avatar::*;
pub use icon_button::*;

// live_design registration - dependencies first!
pub fn live_design(cx: &mut Cx) {
    // Styles must be first (others depend on it)
    styles::live_design(cx);
    helpers::live_design(cx);

    // Base components
    icon_button::live_design(cx);
    avatar::live_design(cx);
    loading_indicator::live_design(cx);
    empty_state::live_design(cx);
    search_input::live_design(cx);

    // Complex components (may depend on base)
    confirmation_modal::live_design(cx);
    toast::live_design(cx);
}
```

---

## App Orchestrator

### app.rs Structure

```rust
// src/app.rs
use makepad_widgets::*;

live_design! {
    use link::theme::*;
    use link::shaders::*;
    use link::widgets::*;

    use crate::shared::styles::*;

    // Import screens
    use crate::home::home_screen::HomeScreen;
    use crate::settings::settings_screen::SettingsScreen;
    use crate::login::login_screen::LoginScreen;

    // Import modals
    use crate::shared::confirmation_modal::ConfirmationModal;

    App = {{App}} {
        ui: <Root> {
            main_window = <Window> {
                window: {
                    title: "My App"
                    inner_size: vec2(1200, 800)
                }

                show_bg: true
                draw_bg: { color: (COLOR_BG_PRIMARY) }

                // Overlay flow for modals
                body = <View> {
                    flow: Overlay

                    // Main content (switches based on app state)
                    content = <View> {
                        width: Fill
                        height: Fill

                        login_screen = <LoginScreen> {
                            visible: true
                        }

                        home_screen = <HomeScreen> {
                            visible: false
                        }

                        settings_screen = <SettingsScreen> {
                            visible: false
                        }
                    }

                    // Modal overlay
                    modal_overlay = <View> {
                        width: Fill
                        height: Fill
                        visible: false

                        show_bg: true
                        draw_bg: { color: #0008 }

                        align: {x: 0.5, y: 0.5}

                        confirmation_modal = <ConfirmationModal> {}
                    }
                }
            }
        }
    }
}

#[derive(Live, LiveHook)]
pub struct App {
    #[live] ui: WidgetRef,
    #[rust] state: AppState,
}

#[derive(Default)]
pub struct AppState {
    pub current_screen: Screen,
    pub user: Option<User>,
}

#[derive(Default, Clone, Copy, PartialEq)]
pub enum Screen {
    #[default]
    Login,
    Home,
    Settings,
}

impl LiveRegister for App {
    fn live_register(cx: &mut Cx) {
        // Register Makepad built-in widgets
        makepad_widgets::live_design(cx);

        // Register app modules IN DEPENDENCY ORDER
        crate::shared::live_design(cx);
        crate::login::live_design(cx);
        crate::home::live_design(cx);
        crate::settings::live_design(cx);
    }
}

impl MatchEvent for App {
    fn handle_startup(&mut self, cx: &mut Cx) {
        // Initialize app on startup
        self.check_existing_session(cx);
    }

    fn handle_actions(&mut self, cx: &mut Cx, actions: &Actions) {
        // Handle login actions
        if let Some(LoginAction::Success(user)) = actions.find_widget_action(
            self.ui.widget(id!(login_screen)).widget_uid()
        ).cast() {
            self.state.user = Some(user);
            self.navigate_to(cx, Screen::Home);
        }

        // Handle navigation
        if self.ui.button(id!(settings_btn)).clicked(actions) {
            self.navigate_to(cx, Screen::Settings);
        }

        if self.ui.button(id!(back_btn)).clicked(actions) {
            self.navigate_to(cx, Screen::Home);
        }

        // Handle logout
        if let Some(SettingsAction::Logout) = actions.find_widget_action(
            self.ui.widget(id!(settings_screen)).widget_uid()
        ).cast() {
            self.state.user = None;
            self.navigate_to(cx, Screen::Login);
        }
    }
}

impl App {
    fn navigate_to(&mut self, cx: &mut Cx, screen: Screen) {
        self.state.current_screen = screen;

        // Update visibility
        self.ui.view(id!(login_screen)).set_visible(screen == Screen::Login);
        self.ui.view(id!(home_screen)).set_visible(screen == Screen::Home);
        self.ui.view(id!(settings_screen)).set_visible(screen == Screen::Settings);

        self.ui.redraw(cx);
    }

    fn show_modal(&mut self, cx: &mut Cx) {
        self.ui.view(id!(modal_overlay)).set_visible(true);
        self.ui.redraw(cx);
    }

    fn hide_modal(&mut self, cx: &mut Cx) {
        self.ui.view(id!(modal_overlay)).set_visible(false);
        self.ui.redraw(cx);
    }

    fn check_existing_session(&mut self, cx: &mut Cx) {
        // Check for saved session
        if let Some(user) = self.load_saved_session() {
            self.state.user = Some(user);
            self.navigate_to(cx, Screen::Home);
        }
    }

    fn load_saved_session(&self) -> Option<User> {
        // Load from persistence
        None
    }
}

impl AppMain for App {
    fn handle_event(&mut self, cx: &mut Cx, event: &Event) {
        self.match_event(cx, event);
        self.ui.handle_event(cx, event, &mut Scope::empty());
    }
}

app_main!(App);
```

---

## Resource Organization

### Icon Naming Convention

```
resources/icons/
├── action/                    # Action icons
│   ├── add.svg
│   ├── edit.svg
│   ├── delete.svg
│   └── save.svg
├── navigation/                # Navigation icons
│   ├── arrow_back.svg
│   ├── arrow_forward.svg
│   ├── menu.svg
│   └── close.svg
├── status/                    # Status indicators
│   ├── check.svg
│   ├── error.svg
│   ├── warning.svg
│   └── info.svg
└── social/                    # Social/user icons
    ├── person.svg
    ├── group.svg
    └── chat.svg
```

### Image Naming Convention

```
resources/img/
├── logo.png                   # App logo
├── logo_dark.png              # Dark mode logo
├── default_avatar.png         # Fallback avatar
├── empty_state.png            # Empty state illustration
├── onboarding/                # Onboarding images
│   ├── step1.png
│   ├── step2.png
│   └── step3.png
└── providers/                 # Third-party logos
    ├── google.png
    └── github.png
```

---

## Cargo.toml Configuration

```toml
[package]
name = "my-app"
version = "0.1.0"
edition = "2021"
authors = ["Your Name <you@example.com>"]
description = "A cross-platform app built with Makepad"

[dependencies]
# Core framework
makepad-widgets = { git = "https://github.com/makepad/makepad", branch = "dev" }

# Robius utilities (optional but recommended)
robius-directories = { git = "https://github.com/project-robius/robius" }
robius-open = { git = "https://github.com/project-robius/robius" }

# Async runtime (if needed)
tokio = { version = "1.43", features = ["macros", "rt-multi-thread"] }

# Serialization
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"

# Unicode handling (recommended)
unicode-segmentation = "1.10"

# Date/time
chrono = "0.4"

# Logging
log = "0.4"

[features]
default = []
# Optional features
analytics = []
premium = []

# Development features
log_verbose = []

[profile.dev]
opt-level = 0
debug = true

[profile.dev.package."*"]
opt-level = 3

[profile.release]
opt-level = 3
lto = "thin"

[profile.release-lto]
inherits = "release"
lto = "fat"
codegen-units = 1

[profile.distribution]
inherits = "release"
lto = "fat"
codegen-units = 1
strip = true

# Packaging configuration
[package.metadata.packager]
product_name = "My App"
identifier = "com.mycompany.myapp"
icons = ["./resources/img/logo.png"]
```

---

## Configuration Files

### rustfmt.toml

```toml
edition = "2021"
max_width = 100
tab_spaces = 4
reorder_imports = true
reorder_modules = true
imports_granularity = "Crate"
group_imports = "StdExternalCrate"
```

### rust-toolchain.toml

```toml
[toolchain]
channel = "stable"
# Or for nightly features:
# channel = "nightly"
```

### .gitignore

```gitignore
# Build artifacts
/target
/dist

# IDE
.idea/
.vscode/
*.swp

# OS
.DS_Store
Thumbs.db

# Logs
*.log

# Local configuration
.env
.env.local
```

---

## Quick Reference

### Module Registration Order

```
1. makepad_widgets::live_design(cx)     # Framework first
2. crate::shared::live_design(cx)        # Shared components
3. crate::feature1::live_design(cx)      # Feature modules
4. crate::feature2::live_design(cx)      # (in dependency order)
```

### File Naming

| Type | Convention | Example |
|------|------------|---------|
| Module | snake_case | `home_screen.rs` |
| Widget | PascalCase in code | `HomeScreen` |
| Action | PascalCase + Action | `HomeScreenAction` |
| Style | SCREAMING_SNAKE | `COLOR_PRIMARY` |
| Icon | snake_case | `arrow_back.svg` |

### Directory Purpose

| Directory | Purpose |
|-----------|---------|
| `src/` | Rust source code |
| `src/shared/` | Reusable components |
| `src/shared/styles.rs` | Colors, fonts, icons |
| `resources/icons/` | SVG icons |
| `resources/img/` | Images |
| `packaging/` | Platform packaging configs |
