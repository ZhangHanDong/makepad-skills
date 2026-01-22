# Makepad Advanced Widgets Reference

## Helper Widgets

### FoldButton

Expandable/collapsible toggle button.

```rust
<FoldButton> {
    width: Fit
    height: Fit
    // Toggles between open/closed states
}
```

### ScrollBar

Single scrollbar widget.

```rust
<ScrollBar> {
    // Usually used internally by scroll views
}
```

### ScrollBars

Combined horizontal and vertical scrollbars.

```rust
<ScrollBars> {
    show_scroll_x: true
    show_scroll_y: true
}
```

### Spinner

Loading indicator.

```rust
<Spinner> {
    width: 40.0
    height: 40.0
    draw_bg: {
        color: #0066CC
    }
}
```

### Splitter

Resizable divider between panels.

```rust
<View> {
    flow: Right

    <View> { width: Fill, height: Fill }

    <Splitter> {
        // Drag to resize adjacent views
    }

    <View> { width: Fill, height: Fill }
}
```

### TabCloseButton

Close button typically used in tabs.

```rust
<TabCloseButton> {
    width: 16.0
    height: 16.0
}
```

### TextFlow

Rich text flow with inline formatting.

```rust
<TextFlow> {
    width: Fill
    height: Fit
    // Supports inline text formatting
}
```

## Advanced Widgets

### Dock

Dockable panel system for IDE-like layouts.

```rust
<Dock> {
    width: Fill
    height: Fill

    // Supports drag-and-drop panel docking
}
```

### FileTree

File system tree view.

```rust
<FileTree> {
    width: 250.0
    height: Fill

    // Displays hierarchical file structure
}
```

### FlatList

Flat list view for simple lists.

```rust
<FlatList> {
    width: Fill
    height: Fill

    // Renders items in a simple list
}
```

### PortalList

Virtualized list for large datasets.

```rust
<PortalList> {
    width: Fill
    height: Fill

    // Only renders visible items
    // Efficient for thousands of items
}
```

### Html

HTML content renderer.

```rust
<Html> {
    width: Fill
    height: Fit

    // Renders basic HTML content
}
```

### Markdown

Markdown content renderer.

```rust
<Markdown> {
    width: Fill
    height: Fit

    // Renders markdown content
}
```

### ImageBlend

Blended image composition.

```rust
<ImageBlend> {
    width: 200.0
    height: 200.0

    // Blends multiple images
}
```

### PageFlip

Page flip animation widget.

```rust
<PageFlip> {
    width: Fill
    height: Fill

    // Animated page transitions
}
```

### SlidesView

Slideshow presentation view.

```rust
<SlidesView> {
    width: Fill
    height: Fill

    // Displays slides with navigation
}
```

### StackNavigation

Stack-based navigation for mobile-style apps.

```rust
<StackNavigation> {
    width: Fill
    height: Fill

    // Push/pop navigation pattern
}
```

### AdaptiveView

Responsive layout that adapts to screen size.

```rust
<AdaptiveView> {
    width: Fill
    height: Fill

    // Changes layout based on available space
}
```

## Tab Widgets

### Tab

Individual tab in a tab bar.

```rust
<Tab> {
    text: "Tab 1"
    closable: true
}
```

### TabBar

Container for multiple tabs.

```rust
<TabBar> {
    width: Fill
    height: 40.0

    <Tab> { text: "Documents" }
    <Tab> { text: "Settings" }
}
```

## Popup Widgets

### PopupMenu

Context/popup menu.

```rust
<PopupMenu> {
    width: 200.0

    <PopupMenuItem> { text: "Cut" }
    <PopupMenuItem> { text: "Copy" }
    <PopupMenuItem> { text: "Paste" }
}
```

### PopupMenuItem

Individual menu item.

```rust
<PopupMenuItem> {
    text: "Save"
    shortcut: "Cmd+S"
}
```

## Icon Widget

SVG icon display.

```rust
<Icon> {
    width: 24.0
    height: 24.0

    draw_icon: {
        svg_file: dep("crate://self/icons/menu.svg")
        color: #FFFFFF
    }
}
```

## Video Widget

Video playback widget.

```rust
<Video> {
    width: Fill
    height: 300.0
    source: dep("crate://self/videos/intro.mp4")
}
```

## LinkLabel

Clickable text link.

```rust
<LinkLabel> {
    text: "Click here"

    draw_text: {
        color: #0066CC
        color_hover: #0088FF
    }
}
```

## RotatedImage

Image with rotation support.

```rust
<RotatedImage> {
    width: 100.0
    height: 100.0
    source: dep("crate://self/images/arrow.png")
    rotation: 45.0  // degrees
}
```
