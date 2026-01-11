---
name: radio-navigation
author: robius
source: robrix
date: 2024-01-01
tags: [navigation, tabs, radio, sidebar]
level: beginner
---

# Pattern 7: Radio Button Navigation

Tab-style navigation using radio button sets.

## Problem

You need tab navigation where selecting one tab deselects others and shows the corresponding page.

## Solution

Use `radio_button_set()` to group radio buttons and handle selection changes.

## Implementation

```rust
impl MatchEvent for App {
    fn handle_actions(&mut self, cx: &mut Cx, actions: &Actions) {
        let tabs = self.ui.radio_button_set(ids!(
            sidebar.home_tab,
            sidebar.settings_tab,
            sidebar.profile_tab
        ));

        if let Some(selected) = tabs.selected(cx, actions) {
            // Hide all pages
            self.ui.view(ids!(pages.home)).set_visible(cx, false);
            self.ui.view(ids!(pages.settings)).set_visible(cx, false);
            self.ui.view(ids!(pages.profile)).set_visible(cx, false);

            // Show selected page
            match selected {
                0 => self.ui.view(ids!(pages.home)).set_visible(cx, true),
                1 => self.ui.view(ids!(pages.settings)).set_visible(cx, true),
                2 => self.ui.view(ids!(pages.profile)).set_visible(cx, true),
                _ => {}
            }
        }
    }
}
```

## live_design!

```rust
live_design! {
    App = {{App}} {
        ui: <Root> {
            <Window> {
                body = <View> {
                    flow: Right

                    // Sidebar with tabs
                    sidebar = <View> {
                        width: 200, height: Fill
                        flow: Down

                        home_tab = <RadioButton> {
                            text: "Home"
                            animator: { selected = { default: on } }
                        }
                        settings_tab = <RadioButton> {
                            text: "Settings"
                        }
                        profile_tab = <RadioButton> {
                            text: "Profile"
                        }
                    }

                    // Page content
                    pages = <View> {
                        width: Fill, height: Fill
                        flow: Overlay

                        home = <HomeScreen> {}
                        settings = <SettingsScreen> { visible: false }
                        profile = <ProfileScreen> { visible: false }
                    }
                }
            }
        }
    }
}
```

## Alternative: PageFlip

For lazy-loaded pages, use `PageFlip`:

```rust
if let Some(selected) = tabs.selected(cx, actions) {
    let page_id = match selected {
        0 => id!(home),
        1 => id!(settings),
        2 => id!(profile),
        _ => return,
    };
    self.ui.page_flip(id!(pages)).set_active_page(cx, page_id);
}
```

## When to Use

- Main app navigation
- Settings tabs
- Dashboard sections
- Any mutually exclusive selection
