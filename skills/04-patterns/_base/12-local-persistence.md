---
name: local-persistence
author: robius
source: moly
date: 2024-01-01
tags: [persistence, storage, config, preferences, save]
level: beginner
---

# Pattern 12: Local Data Persistence

Save and load user preferences and app state.

## Problem

You need to persist user settings, favorites, or app state between sessions.

## Solution

Use simple file I/O with JSON serialization for structured data.

## Basic Implementation (Text)

```rust
use std::fs;
use std::path::PathBuf;

fn get_config_path() -> PathBuf {
    let home = std::env::var("HOME").unwrap_or_else(|_| ".".to_string());
    PathBuf::from(home).join(".myapp_config.txt")
}

impl App {
    fn save_favorites(&self) {
        let path = get_config_path();
        let content = self.favorites.join("\n");
        let _ = fs::write(&path, content);
    }

    fn load_favorites(&mut self) {
        let path = get_config_path();
        if let Ok(content) = fs::read_to_string(&path) {
            self.favorites = content.lines()
                .map(|s| s.trim().to_string())
                .filter(|s| !s.is_empty())
                .collect();
        }
    }

    fn toggle_favorite(&mut self, item: &str) {
        if self.favorites.contains(&item.to_string()) {
            self.favorites.retain(|f| f != item);
        } else {
            self.favorites.push(item.to_string());
        }
        self.save_favorites();
    }
}
```

## JSON Implementation (Structured)

```rust
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Default)]
pub struct AppConfig {
    pub theme: String,
    pub favorites: Vec<String>,
    pub last_opened: Option<String>,
    pub window_size: Option<(u32, u32)>,
}

impl AppConfig {
    fn path() -> PathBuf {
        dirs::config_dir()
            .unwrap_or_else(|| PathBuf::from("."))
            .join("myapp")
            .join("config.json")
    }

    pub fn load() -> Self {
        let path = Self::path();
        if path.exists() {
            if let Ok(content) = fs::read_to_string(&path) {
                if let Ok(config) = serde_json::from_str(&content) {
                    return config;
                }
            }
        }
        Self::default()
    }

    pub fn save(&self) {
        let path = Self::path();
        if let Some(parent) = path.parent() {
            let _ = fs::create_dir_all(parent);
        }
        if let Ok(content) = serde_json::to_string_pretty(self) {
            let _ = fs::write(path, content);
        }
    }
}
```

## Usage

```rust
impl MatchEvent for App {
    fn handle_startup(&mut self, cx: &mut Cx) {
        // Load saved config
        self.config = AppConfig::load();
        self.apply_config(cx);
    }
}

impl App {
    fn apply_config(&mut self, cx: &mut Cx) {
        // Apply theme
        if let Ok(theme) = self.config.theme.parse() {
            self.current_theme = theme;
            self.apply_theme(cx);
        }

        // Apply window size if saved
        if let Some((w, h)) = self.config.window_size {
            // Set window size...
        }
    }

    fn on_window_resize(&mut self, width: u32, height: u32) {
        self.config.window_size = Some((width, height));
        self.config.save();
    }
}
```

## Cargo.toml

```toml
[dependencies]
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
dirs = "5.0"  # For cross-platform config directories
```

## When to Use

- User preferences (theme, language)
- Favorites/bookmarks
- Recent items
- Window position/size
- Any state that should survive app restart

## Platform Paths

| Platform | `dirs::config_dir()` |
|----------|---------------------|
| Linux | `~/.config/` |
| macOS | `~/Library/Application Support/` |
| Windows | `C:\Users\<User>\AppData\Roaming\` |
