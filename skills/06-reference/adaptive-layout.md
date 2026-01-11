---
name: makepad-adaptive-layout
description: Create responsive desktop and mobile layouts with automatic switching in Makepad.
---

# Adaptive Layout

This guide covers responsive cross-platform UIs that automatically adapt between desktop and mobile layouts.

## Overview

Makepad provides `AdaptiveView` for automatic layout switching based on device type or screen size. Key features:
- Automatic Desktop/Mobile variant selection
- Custom variant selectors for responsive breakpoints
- State preservation with `CachedWidget`
- Platform-specific navigation patterns

## AdaptiveView Basic Usage

```rust
live_design! {
    use link::widgets::*;

    pub MyScreen = <AdaptiveView> {
        // Desktop layout - shown on desktop platforms
        Desktop = <View> {
            flow: Right
            sidebar = <SideBar> { width: 300 }
            main_content = <MainContent> { width: Fill }
        }

        // Mobile layout - shown on mobile platforms
        Mobile = <View> {
            flow: Down
            // No sidebar on mobile
            main_content = <MainContent> { width: Fill, height: Fill }
        }
    }
}
```

## Default Variant Selection

By default, `AdaptiveView` selects variants based on:

```rust
// Default selector logic
if cx.display_context.is_desktop() || !cx.display_context.is_screen_size_known() {
    live_id!(Desktop)
} else {
    live_id!(Mobile)
}
```

## Custom Variant Selector

Override the default selector for responsive breakpoints:

```rust
impl MatchEvent for App {
    fn handle_startup(&mut self, cx: &mut Cx) {
        // Screen width-based selection
        self.ui.adaptive_view(ids!(my_adaptive_view))
            .set_variant_selector(|cx, parent_size| {
                if cx.display_context.screen_size.x >= 1280.0 {
                    live_id!(Desktop)
                } else if cx.display_context.screen_size.x >= 768.0 {
                    live_id!(Tablet)
                } else {
                    live_id!(Mobile)
                }
            });
    }
}
```

### Parent Size-Based Selection

```rust
self.ui.adaptive_view(ids!(content_view))
    .set_variant_selector(|_cx, parent_size| {
        if parent_size.x >= 800.0 {
            live_id!(Wide)
        } else {
            live_id!(Narrow)
        }
    });
```

## State Preservation with CachedWidget

Use `CachedWidget` to maintain widget state across variant switches:

```rust
live_design! {
    pub HomeScreen = <AdaptiveView> {
        Desktop = <View> {
            flow: Right

            // CachedWidget ensures single instance across switches
            <CachedWidget> {
                navigation = <NavigationBar> {}
            }

            <CachedWidget> {
                main_content = <MainContent> {}
            }
        }

        Mobile = <View> {
            flow: Down

            // Same CachedWidget references - state preserved
            <CachedWidget> {
                main_content = <MainContent> {}
            }

            <CachedWidget> {
                navigation = <NavigationBar> {}
            }
        }
    }
}
```

## Retain Unused Variants

Keep previously active variants in memory for faster switching:

```rust
live_design! {
    <AdaptiveView> {
        retain_unused_variants: true

        Desktop = <HeavyDesktopView> {}
        Mobile = <HeavyMobileView> {}
    }
}
```

## Mobile Navigation Patterns

### StackNavigation for Mobile

```rust
live_design! {
    pub MobileUI = <StackNavigation> {
        // Root view - always visible
        root_view = {
            width: Fill, height: Fill
            flow: Down

            <RoomsList> {}

            bottom_nav = <BottomNavBar> {}
        }

        // Detail view - pushed on top
        detail_view = <StackNavigationView> {
            header = {
                content = {
                    title = { text: "Detail" }
                }
            }
            body = {
                <DetailContent> {}
            }
        }
    }
}

// Handle navigation
impl MatchEvent for App {
    fn handle_actions(&mut self, cx: &mut Cx, actions: &Actions) {
        // Push detail view
        if self.ui.button(ids!(item_button)).clicked(&actions) {
            cx.widget_action(widget_uid, &path,
                StackNavigationAction::Push(id!(detail_view)));
        }

        // Pop back
        if self.ui.button(ids!(back_button)).clicked(&actions) {
            cx.widget_action(widget_uid, &path,
                StackNavigationAction::Pop);
        }

        // Forward actions to stack navigation
        self.ui.stack_navigation(ids!(view_stack))
            .handle_stack_view_actions(cx, &actions);
    }
}
```

### PageFlip for Tab Switching

```rust
live_design! {
    <PageFlip> {
        width: Fill, height: Fill
        lazy_init: true
        active_page: home_page

        home_page = <View> {
            <HomeContent> {}
        }

        settings_page = <View> {
            <SettingsContent> {}
        }

        profile_page = <View> {
            <ProfileContent> {}
        }
    }
}

// Switch pages
fn switch_to_settings(&mut self, cx: &mut Cx) {
    self.view.page_flip(ids!(page_flip))
        .set_active_page(cx, id!(settings_page));
}
```

## Complete Example: Robrix-Style Layout

```rust
live_design! {
    use link::widgets::*;

    pub HomeScreen = <AdaptiveView> {
        // Desktop: sidebar + tabbed dock
        Desktop = <View> {
            width: Fill, height: Fill
            flow: Right

            <CachedWidget> {
                nav_bar = <NavigationTabBar> {}
            }

            <PageFlip> {
                active_page: home_page

                home_page = <View> {
                    flow: Down

                    <RoomFilterBar> {}
                    <MainDesktopUI> {}
                }

                settings_page = <View> {
                    <CachedWidget> {
                        settings = <SettingsScreen> {}
                    }
                }
            }
        }

        // Mobile: stack navigation
        Mobile = <View> {
            width: Fill, height: Fill
            flow: Down

            <StackNavigation> {
                root_view = {
                    flow: Down
                    padding: {top: 40}

                    <PageFlip> {
                        active_page: home_page

                        home_page = <View> {
                            <RoomsSideBar> {}
                        }

                        settings_page = <View> {
                            <CachedWidget> {
                                settings = <SettingsScreen> {}
                            }
                        }
                    }

                    <CachedWidget> {
                        nav_bar = <NavigationTabBar> {}
                    }
                }

                detail_view = <StackNavigationView> {
                    header = { /* back button, title */ }
                    body = {
                        <MainMobileUI> {}
                    }
                }
            }
        }
    }
}
```

## Platform-Specific Code

### Conditional Compilation

```rust
#[derive(Live, Widget)]
pub struct MyWidget {
    #[deref] view: View,

    // Platform-specific state
    #[cfg(any(target_os = "android", target_os = "ios"))]
    #[rust] touch_state: TouchState,

    #[cfg(not(any(target_os = "android", target_os = "ios")))]
    #[rust] mouse_state: MouseState,
}
```

### Runtime Platform Detection

```rust
impl Widget for MyWidget {
    fn handle_event(&mut self, cx: &mut Cx, event: &Event, scope: &mut Scope) {
        if cx.display_context.is_desktop() {
            // Desktop-specific handling
            self.handle_desktop_event(cx, event, scope);
        } else {
            // Mobile-specific handling
            self.handle_mobile_event(cx, event, scope);
        }
    }
}
```

## Display Context Reference

| Method | Description |
|--------|-------------|
| `cx.display_context.is_desktop()` | Desktop platform (macOS, Windows, Linux) |
| `cx.display_context.is_screen_size_known()` | Screen size has been determined |
| `cx.display_context.screen_size` | Screen dimensions (Vec2) |

## Best Practices

| Practice | Reason |
|----------|--------|
| Use `CachedWidget` for shared components | Preserves state across layout switches |
| Keep Desktop/Mobile variants similar | Easier maintenance, consistent UX |
| Use `StackNavigation` on Mobile | Native-feeling navigation pattern |
| Use `PageFlip` for tab content | Lazy loading, smooth transitions |
| Set `retain_unused_variants: true` for heavy views | Faster layout switching |
| Test on actual devices | Simulators may not reflect real behavior |

## Common Patterns

### Responsive Sidebar

```rust
live_design! {
    <AdaptiveView> {
        Desktop = <View> {
            flow: Right
            <Sidebar> { width: 280 }
            <Content> { width: Fill }
        }

        Mobile = <View> {
            // Sidebar in drawer/modal on mobile
            <Content> { width: Fill }
            <DrawerOverlay> {
                <Sidebar> {}
            }
        }
    }
}
```

### Bottom Navigation (Mobile Only)

```rust
live_design! {
    <AdaptiveView> {
        Desktop = <View> {
            // Sidebar navigation on desktop
            <SideNav> {}
            <Content> {}
        }

        Mobile = <View> {
            flow: Down
            <Content> { height: Fill }
            <BottomTabBar> { height: 56 }
        }
    }
}
```

## References

- [AdaptiveView source](https://github.com/makepad/makepad/blob/main/widgets/src/adaptive_view.rs)
- [Robrix HomeScreen](https://github.com/project-robius/robrix) - Production example
