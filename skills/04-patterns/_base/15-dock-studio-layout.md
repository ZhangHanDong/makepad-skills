# Pattern 15: Dock-Based Studio Layout

<!-- Evolution: 2025-01-12 | source: flex-layout-demo | author: dorobot -->

Create IDE/studio-style layouts with resizable panels using Makepad's Dock and Splitter widgets.

## Overview

This pattern creates a professional studio layout with:
- Fixed header
- Resizable left sidebar, main content, right sidebar
- Resizable footer/timeline area
- Nested splitters for complex layouts

## live_design!

```rust
live_design! {
    use link::theme::*;
    use link::shaders::*;
    use link::widgets::*;

    // Panel components
    LeftSidebar = <View> {
        width: Fill, height: Fill
        flow: Down
        show_bg: true
        draw_bg: { color: #80a0d0 }
        // Sidebar content...
    }

    RightSidebar = <View> {
        width: Fill, height: Fill
        flow: Down
        show_bg: true
        draw_bg: { color: #a0a0c0 }
        // Sidebar content...
    }

    ContentArea = <View> {
        width: Fill, height: Fill
        show_bg: true
        draw_bg: { color: #e8e8f0 }
        // Main content...
    }

    StudioHeader = <View> {
        width: Fill, height: 48
        show_bg: true
        draw_bg: { color: #4080c0 }
        padding: { left: 16, right: 16 }
        flow: Right
        align: { y: 0.5 }

        <Label> { text: "Studio Title" }
    }

    StudioFooter = <View> {
        width: Fill, height: Fill
        show_bg: true
        draw_bg: { color: #60a060 }
        padding: 12

        <Label> { text: "Footer / Timeline" }
    }

    // Main layout using Dock with nested Splitters
    StudioLayout = {{StudioLayout}} {
        width: Fill, height: Fill
        flow: Down

        // Fixed header (not in Dock)
        <StudioHeader> {}

        // Resizable areas using Dock
        <Dock> {
            width: Fill, height: Fill

            // Root: vertical splitter for footer
            root = Splitter {
                axis: Vertical
                align: FromB(100.0)  // Footer starts at 100px from bottom
                a: main_area
                b: footer_panel
            }

            // Main area: horizontal splitter for left sidebar
            main_area = Splitter {
                axis: Horizontal
                align: FromA(280.0)  // Left sidebar 280px from left
                a: left_panel
                b: right_area
            }

            // Right area: horizontal splitter for right sidebar
            right_area = Splitter {
                axis: Horizontal
                align: FromB(300.0)  // Right sidebar 300px from right
                a: center_panel
                b: right_panel
            }

            // Tab wrappers for each panel
            left_panel = Tab { name: "", kind: left_sidebar }
            center_panel = Tab { name: "", kind: center_content }
            right_panel = Tab { name: "", kind: right_sidebar }
            footer_panel = Tab { name: "", kind: footer_content }

            // Actual content widgets
            left_sidebar = <LeftSidebar> {}
            center_content = <ContentArea> {}
            right_sidebar = <RightSidebar> {}
            footer_content = <StudioFooter> {}
        }
    }

    App = {{App}} {
        ui: <Root> {
            main_window = <Window> {
                window: { title: "Studio Layout", inner_size: vec2(1400, 900) }
                body = <StudioLayout> {}
            }
        }
    }
}
```

## Dock Structure

The Dock widget creates a tree of splitters:

```
root (Vertical Splitter)
├── main_area (Horizontal Splitter)
│   ├── left_panel (Tab → LeftSidebar)
│   └── right_area (Horizontal Splitter)
│       ├── center_panel (Tab → ContentArea)
│       └── right_panel (Tab → RightSidebar)
└── footer_panel (Tab → StudioFooter)
```

## Splitter Alignment

| Alignment | Meaning |
|-----------|---------|
| `FromA(px)` | Panel A has fixed size from start |
| `FromB(px)` | Panel B has fixed size from end |
| `Weighted(0.5)` | 50/50 split (0.0 to 1.0) |

## Rust Implementation

```rust
#[derive(Live, LiveHook, Widget)]
pub struct StudioLayout {
    #[deref]
    view: View,
}

impl Widget for StudioLayout {
    fn handle_event(&mut self, cx: &mut Cx, event: &Event, scope: &mut Scope) {
        self.view.handle_event(cx, event, scope);
    }

    fn draw_walk(&mut self, cx: &mut Cx2d, scope: &mut Scope, walk: Walk) -> DrawStep {
        self.view.draw_walk(cx, scope, walk)
    }
}
```

## Alternative: Simple Splitter (Without Dock)

For simpler layouts without Tab support:

```rust
live_design! {
    // Nested Splitters directly
    CenterRightSplit = <Splitter> {
        width: Fill, height: Fill
        axis: Horizontal
        align: FromB(300.0)

        a = <ContentArea> {}
        b = <RightSidebar> {}
    }

    MiddleSplit = <Splitter> {
        width: Fill, height: Fill
        axis: Horizontal
        align: FromA(280.0)

        a = <LeftSidebar> {}
        b = <CenterRightSplit> {}
    }

    // Main layout
    SimpleStudioLayout = <View> {
        width: Fill, height: Fill
        flow: Down

        <StudioHeader> {}

        <Splitter> {
            width: Fill, height: Fill
            axis: Vertical
            align: FromB(100.0)

            a = <MiddleSplit> {}
            b = <StudioFooter> {}
        }
    }
}
```

## When to Use

| Scenario | Recommendation |
|----------|----------------|
| IDE/editor layout | Use Dock (supports tabs) |
| Simple 2-3 panel split | Use nested Splitters |
| Fixed panels (no resize) | Use View with fixed sizes |

## References

- [Makepad Studio](https://github.com/makepad/makepad/tree/main/studio) - Production example
- [Dock widget source](https://github.com/makepad/makepad/blob/main/widgets/src/dock.rs)
- [Splitter widget source](https://github.com/makepad/makepad/blob/main/widgets/src/splitter.rs)
