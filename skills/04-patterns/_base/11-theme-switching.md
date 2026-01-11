---
name: theme-switching
author: robius
source: moly
date: 2024-01-01
tags: [theme, dark-mode, light-mode, colors, styling]
level: intermediate
---

# Pattern 11: Theme Switching

Multi-theme support with dynamic color application.

## Problem

Your app needs multiple themes (dark, light, custom) that users can switch between at runtime.

## Solution

Define theme colors as structs, store current theme, and use `apply_over()` to update widget colors.

## Implementation

```rust
#[derive(Clone, Copy, Debug, PartialEq, Default)]
pub enum Theme {
    #[default]
    Dark,
    Light,
    Cyberpunk,
}

struct ThemeColors {
    bg_primary: Vec4,
    bg_card: Vec4,
    accent: Vec4,
    text_primary: Vec4,
    text_secondary: Vec4,
}

impl Theme {
    fn next(&self) -> Theme {
        match self {
            Theme::Dark => Theme::Light,
            Theme::Light => Theme::Cyberpunk,
            Theme::Cyberpunk => Theme::Dark,
        }
    }

    fn colors(&self) -> ThemeColors {
        match self {
            Theme::Dark => ThemeColors {
                bg_primary: vec4(0.04, 0.04, 0.07, 1.0),
                bg_card: vec4(0.10, 0.10, 0.15, 1.0),
                accent: vec4(0.0, 1.0, 0.53, 1.0),
                text_primary: vec4(0.9, 0.9, 0.9, 1.0),
                text_secondary: vec4(0.5, 0.5, 0.5, 1.0),
            },
            Theme::Light => ThemeColors {
                bg_primary: vec4(0.96, 0.96, 0.98, 1.0),
                bg_card: vec4(1.0, 1.0, 1.0, 1.0),
                accent: vec4(0.2, 0.6, 0.86, 1.0),
                text_primary: vec4(0.1, 0.1, 0.1, 1.0),
                text_secondary: vec4(0.5, 0.5, 0.5, 1.0),
            },
            Theme::Cyberpunk => ThemeColors {
                bg_primary: vec4(0.08, 0.02, 0.12, 1.0),
                bg_card: vec4(0.15, 0.05, 0.2, 1.0),
                accent: vec4(1.0, 0.0, 0.6, 1.0),
                text_primary: vec4(0.95, 0.9, 1.0, 1.0),
                text_secondary: vec4(0.6, 0.5, 0.7, 1.0),
            },
        }
    }
}

#[derive(Live, LiveHook)]
pub struct App {
    #[live] ui: WidgetRef,
    #[rust] current_theme: Theme,
}

impl App {
    fn apply_theme(&mut self, cx: &mut Cx) {
        let colors = self.current_theme.colors();

        // Apply to various widgets
        self.ui.apply_over(cx, live!{
            draw_bg: { color: (colors.bg_primary) }
        });

        self.ui.view(id!(card)).apply_over(cx, live!{
            draw_bg: { color: (colors.bg_card) }
        });

        self.ui.label(id!(title)).apply_over(cx, live!{
            draw_text: { color: (colors.accent) }
        });

        self.ui.label(id!(subtitle)).apply_over(cx, live!{
            draw_text: { color: (colors.text_secondary) }
        });

        self.ui.redraw(cx);
    }
}

impl MatchEvent for App {
    fn handle_startup(&mut self, cx: &mut Cx) {
        self.apply_theme(cx);
    }

    fn handle_actions(&mut self, cx: &mut Cx, actions: &Actions) {
        if self.ui.button(id!(theme_btn)).clicked(&actions) {
            self.current_theme = self.current_theme.next();
            self.apply_theme(cx);
        }
    }
}
```

## Persistence

Save theme preference:

```rust
fn save_theme(&self) {
    let config_path = get_config_path();
    let _ = fs::write(&config_path, self.current_theme.to_string());
}

fn load_theme(&mut self) {
    let config_path = get_config_path();
    if let Ok(theme_str) = fs::read_to_string(&config_path) {
        self.current_theme = theme_str.parse().unwrap_or_default();
    }
}
```

## When to Use

- Dark/light mode toggle
- Brand customization
- Accessibility (high contrast)
- User personalization
