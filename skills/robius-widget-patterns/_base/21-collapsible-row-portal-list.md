---
name: collapsible-row-portal-list
author: alanpoon
source: robrix
date: 2026-01-19
tags: [portal-list, grouping, collapsible, fold-header, rangemap]
level: advanced
---

# Portal List Auto-Grouping

Automatically group consecutive identical items in a portal list under collapsible headers.

## Problem

When displaying large datasets in a portal list (like a news feed or message list), consecutive items with the same category or key can create visual clutter. Users need a way to collapse related items into groups to better scan and navigate the list, especially when 3 or more consecutive items share the same key.

## Solution

Use a `GroupHeaderManager` with `RangeMap` to track consecutive items with identical keys and automatically render them as `FoldHeader` widgets with collapsible content. This pattern integrates seamlessly with Makepad's portal list rendering system.

## Implementation

### Custom Widgets

This pattern uses two custom helper widgets that extend Makepad's built-in functionality:

#### FoldButtonWithText

**Derived from**: `FoldButton` widget

**Unique Functionality**:
- Combines the triangular fold indicator with dynamic text labels in a single interactive component
- Text automatically switches between `open_text` and `close_text` based on fold state
- Unified hover and click interactions for both indicator and text
- Useful for accessibility and clearer UI communication (e.g., "Show More" / "Show Less")

**Key Differences from FoldButton**:
- Standard `FoldButton`: Only displays animated triangle indicator
- `FoldButtonWithText`: Triangle + text label that changes with state

**IMPORTANT**: Must use `makepad_widgets::fold_button::FoldButtonAction` for action events. Do NOT create a custom FoldButtonAction type. This ensures compatibility with the FoldHeader widget system.

```rust
use makepad_widgets::*;
use makepad_widgets::widget::WidgetActionData;
use makepad_widgets::fold_button::FoldButtonAction;  // IMPORTANT: Use existing action type

#[derive(Live, Widget)]
pub struct FoldButtonWithText {
    #[animator] animator: Animator,
    #[redraw] #[live] draw_bg: DrawQuad,
    #[redraw] #[live] draw_text: DrawText,
    #[walk] walk: Walk,
    #[layout] layout: Layout,
    #[live] active: f64,
    #[live] triangle_size: f64,
    #[live] open_text: ArcStringMut,   // Text when closed
    #[live] close_text: ArcStringMut,  // Text when open
    #[action_data] #[rust] action_data: WidgetActionData,
}

impl Widget for FoldButtonWithText {
    fn handle_event(&mut self, cx: &mut Cx, event: &Event, scope: &mut Scope) {
        let uid = self.widget_uid();
        let res = self.animator_handle_event(cx, event);

        if res.is_animating() {
            if self.animator.is_track_animating(cx, ids!(active)) {
                let mut value = [0.0];
                self.draw_bg.get_instance(cx, ids!(active), &mut value);
                // Use makepad's FoldButtonAction, not a custom one
                cx.widget_action(uid, &scope.path, FoldButtonAction::Animating(value[0] as f64))
            }
            if res.must_redraw() {
                self.draw_bg.redraw(cx);
            }
        }

        match event.hits(cx, self.draw_bg.area()) {
            Hit::FingerDown(_fe) => {
                if self.animator_in_state(cx, ids!(active.on)) {
                    self.animator_play(cx, ids!(active.off));
                    // Use makepad's FoldButtonAction::Closing
                    cx.widget_action(uid, &scope.path, FoldButtonAction::Closing)
                } else {
                    self.animator_play(cx, ids!(active.on));
                    // Use makepad's FoldButtonAction::Opening
                    cx.widget_action(uid, &scope.path, FoldButtonAction::Opening)
                }
                self.animator_play(cx, ids!(hover.on));
            },
            Hit::FingerHoverIn(_) => {
                cx.set_cursor(MouseCursor::Hand);
                self.animator_play(cx, ids!(hover.on));
            }
            Hit::FingerHoverOut(_) => {
                self.animator_play(cx, ids!(hover.off));
            }
            Hit::FingerUp(fe) => {
                if fe.is_over {
                    if fe.device.has_hovers() {
                        self.animator_play(cx, ids!(hover.on));
                    } else {
                        self.animator_play(cx, ids!(hover.off));
                    }
                } else {
                    self.animator_play(cx, ids!(hover.off));
                }
            }
            _ => ()
        }
    }

    fn draw_walk(&mut self, cx: &mut Cx2d, _scope: &mut Scope, walk: Walk) -> DrawStep {
        self.draw_bg.begin(cx, walk, self.layout);

        // Dynamically select text based on state
        let text = if self.active > 0.5 {
            self.close_text.as_ref()  // Expanded state
        } else {
            self.open_text.as_ref()   // Collapsed state
        };

        let label_walk = walk.with_margin_left(self.triangle_size * 2.0 + 10.0);
        self.draw_text.draw_walk(cx, label_walk, Align::default(), text);
        self.draw_bg.end(cx);
        DrawStep::done()
    }
}

// Helper methods can use the standard FoldButtonAction
impl FoldButtonWithText {
    pub fn opening(&self, actions: &Actions) -> bool {
        if let Some(item) = actions.find_widget_action(self.widget_uid()) {
            if let FoldButtonAction::Opening = item.cast() {
                return true
            }
        }
        false
    }

    pub fn closing(&self, actions: &Actions) -> bool {
        if let Some(item) = actions.find_widget_action(self.widget_uid()) {
            if let FoldButtonAction::Closing = item.cast() {
                return true
            }
        }
        false
    }
}
```

#### PortalList in FoldHeader Body

**Derived from**: Standard `PortalList` widget

**Unique Functionality**:
- Directly embeds a PortalList inside the FoldHeader body for dynamic content rendering
- Leverages the portal list's built-in template instantiation and rendering system
- No need for intermediate ViewList widget or dummy portal list pattern
- Manages widget lifecycle, drawing, and event handling automatically

**Key Differences from Dummy PortalList Pattern**:
- Old approach: Dummy PortalList (height: 0) + ViewList + manual WidgetRef management
- New approach: Direct PortalList in body with `height: Fit`

**Direct PortalList Pattern**:

This pattern uses a real PortalList directly inside the FoldHeader body:

```rust
// 1. Define a PortalList directly in your FoldHeader body
live_design! {
    SmallStateGroupHeader = <FoldHeader> {
        body: <View> {
            width: Fill,
            height: Fit
            flow: Down
            <PortalList> {
                height: Fit, width: Fill
                SmallStateEvent = <SmallStateEvent> {}
                Message = <Message> {}
            }
        }
    }
}

// 2. Use the FoldHeader's draw_walk to access and render the portal list
let mut walk = walk;
walk.height = Size::Fit;
while let Some(item) = fold_item.draw_walk(cx, scope, walk).step() {
    if let Some(mut list_ref) = item.as_portal_list().borrow_mut() {
        let list = list_ref.deref_mut();

        // Directly render items in the range
        for tl_idx in (group_range.start)..group_range.end {
            if let Some(timeline_item) = tl_items.get(tl_idx) {
                // Populate and draw items directly
                let item = list.item(cx, tl_idx, live_id!(SmallStateEvent));
                item.label(ids!(text)).set_text(cx, &data_item.text);
                item.draw_all(cx, scope);
            }
        }
    }
}
```

**Why Use Direct PortalList?**

This pattern has several advantages over the dummy PortalList + ViewList approach:
1. **Simpler architecture**: No need for intermediate ViewList widget
2. **Native portal list features**: Automatic virtualization, scroll handling, and item management
3. **Better performance**: Direct rendering without WidgetRef collection overhead
4. **Height: Fit support**: Portal list automatically sizes to content with `height: Fit`
5. **Less code**: Eliminates ViewList widget implementation and dummy portal list pattern

### GroupHeaderManager

```rust
use std::{collections::HashMap, ops::Range};
use rangemap::RangeMap;

#[derive(Debug, Clone, Default)]
struct GroupMeta {
    key: String,
    count: usize,
}

#[derive(Default)]
struct GroupHeaderManager {
    group_ranges: RangeMap<usize, String>,
    groups_by_id: HashMap<String, GroupMeta>,
}

impl GroupHeaderManager {
    fn new() -> Self {
        Self {
            group_ranges: RangeMap::new(),
            groups_by_id: HashMap::new(),
        }
    }

    fn check_group_header_status(&self, item_id: usize) -> Option<Range<usize>> {
        for (range, _) in self.group_ranges.iter() {
            if range.contains(&item_id) {
                return Some(range.clone())
            }
        }
        None
    }

    fn get_group_at_item_id(&self, item_id: usize) -> Option<&GroupMeta> {
        self.group_ranges
            .iter()
            .find(|(range, _)| range.start == item_id)
            .and_then(|(_, header_id)| self.groups_by_id.get(header_id))
    }

    /// Computes groups from data.
    ///
    /// **IMPORTANT**: Call this ONLY when data is first available or when data changes.
    /// DO NOT call this during `draw_walk()` as it would recompute on every frame.
    ///
    /// Correct usage:
    /// - In `after_new_from_doc()` hook after initializing data
    /// - When receiving new data from network/updates
    /// - In response to user actions that modify data
    ///
    /// Incorrect usage:
    /// - Inside `draw_walk()` or any rendering method
    /// - On every frame or animation tick
    fn compute_groups(&mut self, data: &[(String, String)]) {
        self.group_ranges.clear();
        let mut i = 0;

        while i < data.len() {
            let current_key = &data[i].0;
            let mut count = 1;

            // Count consecutive items with same key
            while i + count < data.len() && &data[i + count].0 == current_key {
                count += 1;
            }

            // Only create groups for 3+ consecutive items
            if count >= 3 {
                let header_id = format!("{}_group_{}", current_key, i);
                let start_index = i;
                let end_index = i + count - 1;

                self.group_ranges.insert(start_index..end_index + 1, header_id.clone());
                self.groups_by_id.insert(
                    header_id,
                    GroupMeta {
                        key: current_key.clone(),
                        count,
                    },
                );
            }

            i += count;
        }
    }
}
```

### Using FoldHeader Widget

**FoldHeader** is a built-in Makepad widget that provides collapsible sections with a header and body.

#### Basic FoldHeader Structure

```rust
live_design! {
    MyFoldHeader = <FoldHeader> {
        // Header: Always visible, controls fold state
        header: <View> {
            width: Fill, height: 50
            // Add fold button and header content
            fold_button = <FoldButton> {}
        }

        // Body: Collapsible content
        body: <View> {
            width: Fill, height: Fit
            // Add body content here
        }
    }
}
```

#### Accessing FoldHeader in Code

```rust
use makepad_widgets::fold_header::FoldHeaderWidgetRefExt;

// Get a reference to a FoldHeader
let fold_header_ref = some_view.as_fold_header();

// Access nested widgets within the FoldHeader (no need to specify header/body)
let view_list_ref = fold_header_ref.view_list(ids!(my_view_list));
```

#### Programmatically Populating FoldHeader Body

When you need to dynamically generate content inside the FoldHeader body:

```rust
// 1. Get reference to FoldHeader from portal list item
let item = list.item(cx, item_id, live_id!(FoldHeader));

// 2. Set header text (no need to specify "header" prefix)
item.label(ids!(summary_text))
    .set_text(cx, &format!("Group {} ({} items)", group_name, count));

// 3. Access dummy portal list (no need to specify "body" prefix)
let mut widgetref_list = vec![];
let dummy_portal_list = item.portal_list(ids!(dummy_portal_list));

// 4. Use dummy portal list to create widget instances
if let Some(mut list_ref) = dummy_portal_list.borrow_mut() {
    let list = list_ref.deref_mut();

    // 5. Create widget instances from templates
    for (idx, data_item) in my_data_items.iter().enumerate() {
        let widget_item = list.item(cx, idx, live_id!(SmallStateEvent));
        widget_item.label(ids!(text)).set_text(cx, &data_item.text);
        widgetref_list.push(widget_item);
    }
}

// 6. Access ViewList and set widgets (no need to specify "body" prefix)
let mut view_widget = item.view_list(ids!(view_list));
view_widget.set_widgetref_list(widgetref_list);

// 7. Draw the complete FoldHeader
item.draw_all(cx, &mut Scope::empty());
```

### Using PortalList in FoldHeader Body

**PortalList** directly embedded in the FoldHeader body provides native list rendering capabilities.

#### Direct PortalList Rendering Pattern

```rust
// 1. Get FoldHeader item from the main portal list
let fold_item = list.item(cx, item_id, live_id!(FoldHeader));

// 2. Set header content (no need to specify "header" prefix)
fold_item.label(ids!(summary_text)).set_text(cx, "Group Summary");

// 3. Draw FoldHeader and access the inner PortalList
let mut walk = walk;
walk.height = Size::Fit;  // IMPORTANT: Use Fit for proper sizing
while let Some(item) = fold_item.draw_walk(cx, scope, walk).step() {
    if let Some(mut list_ref) = item.as_portal_list().borrow_mut() {
        let list = list_ref.deref_mut();

        // 4. Directly render items in the portal list
        for i in 0..10 {
            let widget_item = list.item(cx, i, live_id!(ItemTemplate));

            // Populate the widget with data
            widget_item.label(ids!(title)).set_text(cx, &format!("Item {}", i));
            widget_item.button(ids!(action_btn)).set_text(cx, "Click");

            // Draw immediately
            widget_item.draw_all(cx, scope);
        }
    }
}
```

### Portal List Integration

Integrating FoldHeader with GroupHeaderManager in a portal list:

```rust
use makepad_widgets::*;
use makepad_widgets::fold_header::FoldHeaderWidgetRefExt;

#[derive(Live, Widget)]
struct MyPortalList {
    #[deref] view: View,
    #[rust] data: Vec<(String, String)>,
    #[rust] group_manager: GroupHeaderManager,
}

impl Widget for MyPortalList {
    fn draw_walk(&mut self, cx: &mut Cx2d, scope: &mut Scope, walk: Walk) -> DrawStep {
        while let Some(item) = self.view.draw_walk(cx, scope, walk).step() {
            if let Some(mut list) = item.as_portal_list().borrow_mut() {
                list.set_item_range(cx, 0, self.data.len());

                // IMPORTANT: Do NOT call compute_groups() here!
                // Groups should already be computed when data was loaded/updated

                while let Some(item_id) = list.next_visible_item(cx) {
                    // Check if this item is part of a group
                    if let Some(range) = self.group_manager.check_group_header_status(item_id) {
                        if item_id == range.start {
                            // This is the start of a group (item_id == range.start)
                            // Render FoldHeader and populate it with ALL items in the range
                            self.render_fold_header(cx, &mut list, item_id, &range);
                        } else {
                            // This item is within the range (range.start < item_id < range.end)
                            // Render Empty placeholder - content already shown in FoldHeader
                            list.item(cx, item_id, live_id!(Empty)).draw_all(cx, &mut Scope::empty());
                        }
                    } else {
                        // Normal ungrouped item (outside any range)
                        self.render_normal_item(cx, &mut list, item_id);
                    }
                }
            }
        }
        DrawStep::done()
    }
}

impl MyPortalList {
    fn render_fold_header(&mut self, cx: &mut Cx2d, scope: &mut Scope, list: &mut PortalListRef,
                          item_id: usize, range: &Range<usize>, walk: Walk) {
        // item_id == range.start when this function is called
        let group_meta = self.group_manager.get_group_at_item_id(item_id).unwrap();

        // Get FoldHeader item from portal list at range.start
        let fold_item = list.item(cx, item_id, live_id!(FoldHeader));

        // Set header summary text (no need to specify "header" prefix)
        fold_item.label(ids!(summary_text))
            .set_text(cx, &format!("{} ({} items)", group_meta.key, group_meta.count));

        // Draw the FoldHeader and access the inner PortalList
        let mut walk = walk;
        walk.height = Size::Fit;
        while let Some(item) = fold_item.draw_walk(cx, scope, walk).step() {
            if let Some(mut list_ref) = item.as_portal_list().borrow_mut() {
                let list = list_ref.deref_mut();

                // Iterate through the ENTIRE range to render items directly
                for tl_idx in range.start..range.end {
                    if let Some((key, text)) = self.data.get(tl_idx) {
                        let widget_item = list.item(cx, tl_idx, live_id!(Post));
                        widget_item.label(ids!(content.text))
                            .set_text(cx, &format!("{}: {}", key, text));
                        widget_item.draw_all(cx, scope);
                    }
                }
            }
        }
    }

    fn render_normal_item(&mut self, cx: &mut Cx2d, list: &mut PortalListRef, item_id: usize) {
        if let Some((key, text)) = self.data.get(item_id) {
            let item = list.item(cx, item_id, live_id!(Post));
            item.label(ids!(content.text))
                .set_text(cx, &format!("{}: {}", key, text));
            item.draw_all(cx, &mut Scope::empty());
        }
    }
}
```

## Complete Usage Example

### Step 1: Project Setup

```toml
# Cargo.toml
[dependencies]
rangemap = "1.5"
makepad-widgets = { path = "../../widgets" }
```

```rust
// lib.rs or main.rs
pub mod fold_button_with_text;  // Custom widget (see "Custom Widgets" section)
```

### Step 2: Define live_design! Structure

```rust
live_design! {
    use link::widgets::*;
    use crate::fold_button_with_text::*;

    MyApp = <View> {
        width: Fill, height: Fill

        my_list = <PortalList> {
            width: Fill, height: Fill

            // Template for normal ungrouped items
            Post = <View> {
                width: Fill, height: 60
                padding: 10
                content = <View> {
                    text = <Label> { text: "" }
                }
            }

            // Empty placeholder for items within groups
            Empty = <View> { height: 0, show_bg: false }

            // FoldHeader for grouped items
            FoldHeader = <FoldHeader> {
                header: <View> {
                    width: Fill, height: 50
                    align: { x: 0.5, y: 0.5 }
                    fold_button = <FoldButtonWithText> {
                        open_text: "Show More"
                        close_text: "Show Less"
                    }
                    summary_text = <Label> { text: "" }
                }

                body: <View> {
                    width: Fill, height: Fit
                    flow: Down
                    // Direct PortalList for rendering grouped items
                    <PortalList> {
                        height: Fit, width: Fill
                        Post = <Post> {}  // Reuse Post template
                    }
                }
            }
        }
    }
}
```

### Step 3: Implement Widget with GroupHeaderManager

```rust
use makepad_widgets::*;
use makepad_widgets::fold_header::FoldHeaderWidgetRefExt;

#[derive(Live, Widget)]
struct MyApp {
    #[deref] view: View,
    #[rust] data: Vec<(String, String)>,
    #[rust] group_manager: GroupHeaderManager,
}

impl LiveHook for MyApp {
    fn after_new_from_doc(&mut self, _cx: &mut Cx) {
        // Initialize data with groupable keys
        self.data = vec![
            ("Category A".to_string(), "Item 1".to_string()),
            ("Category A".to_string(), "Item 2".to_string()),
            ("Category A".to_string(), "Item 3".to_string()),  // Group forms here
            ("Category B".to_string(), "Item 4".to_string()),
            ("Category C".to_string(), "Item 5".to_string()),
            ("Category C".to_string(), "Item 6".to_string()),
            ("Category C".to_string(), "Item 7".to_string()),  // Another group
        ];

        // IMPORTANT: Compute groups ONCE when data is first available
        // Do NOT call compute_groups() in draw_walk()
        self.group_manager = GroupHeaderManager::new();
        self.group_manager.compute_groups(&self.data);
    }
}

// When data changes (e.g., from network updates or user actions)
impl MyApp {
    fn handle_data_update(&mut self, new_data: Vec<(String, String)>) {
        self.data = new_data;

        // Recompute groups when data changes
        self.group_manager.compute_groups(&self.data);

        // Trigger redraw
        // self.redraw(cx);
    }
}

impl Widget for MyApp {
    fn draw_walk(&mut self, cx: &mut Cx2d, scope: &mut Scope, walk: Walk) -> DrawStep {
        // Standard portal list rendering with grouping logic
        // See "Portal List Integration" section for complete implementation
        // ...
        DrawStep::done()
    }
}
```

### Step 4: Understanding the Rendering Flow

When the portal list renders with grouping logic:

1. **Item ID 0-2** (Category A - forms a group):
   - `next_visible_item()` returns 0
   - Check: `item_id == range.start` (0 == 0) → TRUE
   - **Render `FoldHeader` at position 0**
   - Iterate through range (0..3) to generate widgetref_list with items 0, 1, 2
   - Call `view_list.set_widgetref_list()` to populate FoldHeader body
   - `next_visible_item()` returns 1
   - Check: 1 is within range (0..3) but not at start → Render `Empty`
   - `next_visible_item()` returns 2
   - Check: 2 is within range (0..3) but not at start → Render `Empty`

2. **Item ID 3** (Category B - not grouped):
   - `next_visible_item()` returns 3
   - Not part of any group → Render normal `Post` template

3. **Item ID 4-6** (Category C - forms a group):
   - `next_visible_item()` returns 4
   - Check: `item_id == range.start` (4 == 4) → TRUE
   - **Render `FoldHeader` at position 4**
   - Iterate through range (4..7) to generate widgetref_list with items 4, 5, 6
   - Call `view_list.set_widgetref_list()` to populate FoldHeader body
   - `next_visible_item()` returns 5
   - Check: 5 is within range (4..7) but not at start → Render `Empty`
   - `next_visible_item()` returns 6
   - Check: 6 is within range (4..7) but not at start → Render `Empty`

### Step 5: Key FoldHeader Operations

```rust
// Called when item_id == range.start
// range represents all items in the group (e.g., 0..3)

// 1. Get FoldHeader reference from portal list at range.start position
let fold_item = list.item(cx, item_id, live_id!(FoldHeader));

// 2. Set header text (no need to specify "header" prefix)
fold_item.label(ids!(summary_text))
    .set_text(cx, "Group Name (3 items)");

// 3. Draw FoldHeader and access the inner PortalList
let mut walk = walk;
walk.height = Size::Fit;
while let Some(item) = fold_item.draw_walk(cx, scope, walk).step() {
    if let Some(mut list_ref) = item.as_portal_list().borrow_mut() {
        let list = list_ref.deref_mut();

        // 4. Iterate through the ENTIRE range to render items directly
        for tl_idx in range.start..range.end {
            if let Some(data) = my_data.get(tl_idx) {
                let widget_item = list.item(cx, tl_idx, live_id!(Post));
                widget_item.label(ids!(content.text)).set_text(cx, &data.text);
                widget_item.draw_all(cx, scope);
            }
        }
    }
}

// Note: When next_visible_item() later returns item_ids within the range
// (range.start < item_id < range.end), they will render as Empty widgets
```

## When to Use

- News feeds or social media feeds grouped by topic/author
- Message lists grouped by conversation thread
- File browsers grouped by directory or file type
- E-commerce catalogs grouped by category
- Event lists grouped by date or location
- Any scrollable list where consecutive identical keys indicate natural groupings

## When NOT to Use

- When items don't have natural grouping keys
- When groups are expected to be smaller than 3 items (configure threshold)
- When you need groups to persist across non-consecutive items
- When manual grouping control is required

## Key Concepts

### Custom Widget Extensions

The pattern uses a custom helper widget (`FoldButtonWithText`) that extends the standard Makepad `FoldButton` widget with domain-specific functionality:

- **Alternative**: You can use the standard `FoldButton` widget instead of `FoldButtonWithText` if dynamic text labels aren't needed
- **Reusability**: The custom widget can be reused in other contexts beyond this pattern

**Important Note on FoldButtonWithText**: This custom widget MUST use `makepad_widgets::fold_button::FoldButtonAction` for its action events. Do not create a custom `FoldButtonAction` enum. Using the standard action type ensures proper integration with FoldHeader and the broader Makepad widget system.

### The Direct PortalList Pattern Explained

The "direct PortalList" pattern uses a real PortalList directly inside the FoldHeader body:

**Why Use Direct PortalList Instead of ViewList?**
- No need for intermediate ViewList widget or dummy portal list
- Portal lists provide native virtualization and scroll handling
- Simpler architecture with fewer custom components
- Built-in support for `height: Fit` to automatically size to content

**How It Works:**
1. Define a PortalList with `height: Fit` inside the FoldHeader body
2. Use `fold_item.draw_walk()` to step through and access the inner PortalList
3. Use `item.as_portal_list()` to get a mutable reference to the PortalList
4. Directly render items using `list.item()` and `item.draw_all()`

**Benefits:**
- **Simpler**: No intermediate widgets or WidgetRef collection
- **Native Features**: Full portal list capabilities (virtualization, scrolling)
- **Better Performance**: Direct rendering without overhead
- **Height: Fit**: Automatic content sizing
- **Less Code**: Eliminates ViewList widget implementation

### RangeMap for Efficient Lookups

The pattern uses `RangeMap<usize, String>` to efficiently map item indices to group IDs. This allows O(log n) lookup to check if an item belongs to a group.

### Three Rendering Modes

The portal list rendering logic handles three cases based on the item's position:

1. **Group Header** (`item_id == range.start`):
   - Renders a `FoldHeader` widget at this position
   - Iterates through the **entire range** (from `range.start` to `range.end`) to generate `widgetref_list`
   - Calls `view_list.set_widgetref_list()` to populate the FoldHeader body with all grouped items
   - This single FoldHeader contains all items in the group

2. **Empty Placeholder** (`range.start < item_id < range.end`):
   - When `next_visible_item()` returns an `item_id` within the range (but not at start)
   - Renders `Empty` widget with 0 height
   - Content already displayed in the FoldHeader, so these items are hidden

3. **Normal Item** (outside range):
   - Renders regular item template
   - Not part of any group

### Threshold Configuration

The default threshold is 3 consecutive items. Adjust this based on your use case:

```rust
if count >= 3 {  // Change to >= 2 or >= 4 as needed
    // Create group
}
```

### Performance Considerations

1. **Caching Group Metadata**: Pre-compute summaries and avatar lists to avoid recalculation during rendering
2. **RangeMap Efficiency**: O(log n) lookups for checking if an item belongs to a group
3. **Empty Placeholders**: Items within a group render as 0-height views, minimal overhead
4. **Lazy Widget Creation**: Widgets in collapsed FoldHeaders aren't created until expanded
5. **Compute Groups ONLY When Data Changes**: **CRITICAL** - Never call `compute_groups()` during `draw_walk()`

#### ❌ WRONG: Computing Groups During Rendering

```rust
impl Widget for MyPortalList {
    fn draw_walk(&mut self, cx: &mut Cx2d, scope: &mut Scope, walk: Walk) -> DrawStep {
        // ❌ WRONG: This recomputes groups on EVERY FRAME
        self.group_manager.compute_groups(&self.data);

        // ... rendering logic
    }
}
```

#### ✅ CORRECT: Computing Groups When Data Changes

```rust
impl LiveHook for MyApp {
    fn after_new_from_doc(&mut self, _cx: &mut Cx) {
        self.data = load_initial_data();

        // ✅ CORRECT: Compute once when data is first available
        self.group_manager.compute_groups(&self.data);
    }
}

impl MyApp {
    fn handle_data_update(&mut self, new_data: Vec<Item>) {
        self.data = new_data;

        // ✅ CORRECT: Recompute when data changes
        self.group_manager.compute_groups(&self.data);
    }
}

impl Widget for MyApp {
    fn draw_walk(&mut self, cx: &mut Cx2d, scope: &mut Scope, walk: Walk) -> DrawStep {
        // ✅ CORRECT: Only READ group data during rendering
        if let Some(range) = self.group_manager.check_group_header_status(item_id) {
            // Use pre-computed group data
        }
    }
}
```

#### Caching Expensive Computations

```rust
// Good: Cache expensive computations when groups are created
impl SmallStateGroup {
    pub fn update_cached_data(&mut self) {
        self.cached_summary = Some(generate_summary(&self.user_events_map, SUMMARY_LENGTH));
        self.cached_avatar_user_ids = Some(extract_avatar_user_ids(&self.user_events_map, MAX_VISIBLE_AVATARS));
    }
}

// Use cached data during rendering (no "header" prefix needed)
if let Some(summary) = &group.cached_summary {
    fold_item.label(ids!(summary_text)).set_text(cx, summary);
}
```

## Related Patterns

- [Pattern 3: Collapsible Widget](./_base/03-collapsible.md) - Basic collapsible behavior
- [Pattern 4: List with Template](./_base/04-list-template.md) - Dynamic list rendering
- [Pattern 5: LRU View Cache](./_base/05-lru-view-cache.md) - Performance optimization for large lists

## API Reference

### FoldHeader Widget

**Import**: `use makepad_widgets::fold_header::FoldHeaderWidgetRefExt;`

**Core Methods**:
```rust
// Access nested widgets within FoldHeader
// Note: No need to specify "header" or "body" prefixes
fn label(&self, path: &[LiveId]) -> LabelRef
fn button(&self, path: &[LiveId]) -> ButtonRef

// Draw the FoldHeader and get access to body widgets
fn draw_walk(&mut self, cx: &mut Cx2d, scope: &mut Scope, walk: Walk) -> DrawStep

// Example usage
fold_item.label(ids!(summary_text))  // Not ids!(header.summary_text)

// Access inner PortalList during draw_walk
while let Some(item) = fold_item.draw_walk(cx, scope, walk).step() {
    if let Some(mut list_ref) = item.as_portal_list().borrow_mut() {
        // Access the PortalList inside the FoldHeader body
    }
}
```

**Structure in live_design!**:
```rust
<FoldHeader> {
    header: <View> {
        // Always visible header content
        // Must include a fold button (FoldButton or FoldButtonWithText)
    }
    body: <View> {
        // Collapsible body content with direct PortalList
        <PortalList> {
            height: Fit, width: Fill
            // Templates for items
        }
    }
}
```

### PortalList in FoldHeader Body

**Built-in Makepad widget** used directly inside FoldHeader body.

**Core Methods**:
```rust
// Access PortalList during FoldHeader draw_walk
item.as_portal_list().borrow_mut()

// Render items in the PortalList
list.item(cx, index, template_id)
```

**Structure in live_design!**:
```rust
body: <View> {
    width: Fill, height: Fit
    flow: Down
    <PortalList> {
        height: Fit, width: Fill  // IMPORTANT: Use Fit not 0
        ItemTemplate = <ItemView> {}
    }
}
```

**Note**: The PortalList uses `height: Fit` to automatically size to its content, not `height: 0` like the old dummy portal list pattern.

### GroupHeaderManager

**Custom utility struct** - see "GroupHeaderManager" section for implementation.

**Core Methods**:
```rust
// Check if item_id is part of a group, returns the full range
// Called during draw_walk() - fast O(log n) lookup
pub fn check_group_header_status(&self, item_id: usize) -> Option<Range<usize>>

// Get metadata for group starting at item_id
// Called during draw_walk() - fast lookup
pub fn get_group_at_item_id(&self, item_id: usize) -> Option<&GroupMeta>

// Compute groups from data
// IMPORTANT: Call ONLY when data is first available or changes
// DO NOT call during draw_walk() - would recompute on every frame!
pub fn compute_groups(&mut self, data: &[(String, String)])
```

**When to Call `compute_groups()`**:
- ✅ In `after_new_from_doc()` after loading initial data
- ✅ When receiving new data from network/updates
- ✅ In response to user actions that modify data
- ❌ **NEVER** in `draw_walk()` or any rendering method
- ❌ **NEVER** on every frame or animation tick

### Portal List Integration Pattern

```rust
while let Some(item_id) = list.next_visible_item(cx) {
    if let Some(range) = group_manager.check_group_header_status(item_id) {
        if item_id == range.start {
            // item_id == range.start: Render FoldHeader
            // Inside render function:
            // - Iterate through range.start..range.end
            // - Generate widgetref_list for all items in range
            // - Call view_list.set_widgetref_list(widgetref_list)
        } else {
            // range.start < item_id < range.end: Render Empty
            // Content already shown in FoldHeader
        }
    } else {
        // Outside any range: Render normal item
    }
}
```

## External Dependencies

- **RangeMap**: https://docs.rs/rangemap/ - Efficient range-to-value mapping for O(log n) group lookups
- **Makepad Widgets**: Built-in FoldHeader widget and portal list infrastructure

## Real-World Example: Small State Event Grouping (Robrix)

The Robrix Matrix client uses this pattern to group consecutive small state events (membership changes, profile updates, etc.) in chat room timelines. Here's a simplified version of the implementation:

### SmallStateGroupManager (Based on GroupHeaderManager pattern)

```rust
use rangemap::RangeMap;
use std::collections::HashMap;

#[derive(Debug, Default, Clone)]
pub struct SmallStateGroup {
    pub user_events_map: HashMap<OwnedUserId, Vec<UserEvent>>,
    pub cached_summary: Option<String>,
    pub cached_avatar_user_ids: Option<Vec<OwnedUserId>>,
}

#[derive(Default, Debug)]
pub struct SmallStateGroupManager {
    pub small_state_groups: RangeMap<usize, OwnedEventId>,
    pub groups_by_event_id: HashMap<OwnedEventId, SmallStateGroup>,
}

impl SmallStateGroupManager {
    pub fn check_group_range(&self, item_id: usize) -> Option<std::ops::Range<usize>> {
        self.small_state_groups.get_key_value(&item_id)
            .map(|(range, _)| range.clone())
    }

    pub fn get_group_at_item_id(&self, item_id: usize) -> Option<&SmallStateGroup> {
        self.small_state_groups
            .iter()
            .find(|(range, _)| range.start == item_id)
            .and_then(|(_, event_id)| self.groups_by_event_id.get(event_id))
    }

    /// Computes group state from small state events.
    ///
    /// **IMPORTANT**: Call this ONLY when timeline data is first loaded or updated.
    /// DO NOT call during draw_walk() rendering.
    pub fn compute_group_state(&mut self, small_state_events: Vec<UserEvent>) {
        // Clear existing groups
        self.small_state_groups.clear();
        self.groups_by_event_id.clear();

        // Group consecutive events with same characteristics
        // (See full implementation in PR for details)
    }
}
```

### When to Compute Groups

```rust
// ✅ CORRECT: Compute groups when timeline data is loaded or updated
impl RoomScreen {
    fn process_timeline_updates(&mut self, timeline_update: TimelineUpdate) {
        match timeline_update {
            TimelineUpdate::InitialItems { initial_items } => {
                tl.items = initial_items;

                // Compute groups ONCE when data is first available
                let small_state_events = extract_small_state_events(tl.items.iter().cloned());
                tl.small_state_group_manager.compute_group_state(small_state_events);
            }
            TimelineUpdate::NewItems { new_items, .. } => {
                tl.items = new_items;

                // Recompute groups when data changes
                let small_state_events = extract_small_state_events(tl.items.iter().cloned());
                tl.small_state_group_manager.compute_group_state(small_state_events);
            }
        }
    }
}
```

### Integration in RoomScreen Portal List

```rust
// ❌ DO NOT compute groups here - this is called every frame!
// ✅ Groups should already be computed when data was loaded

// In the portal list draw loop
while let Some(item_id) = list.next_visible_item(cx) {
    // Check if this item is part of a group (fast O(log n) lookup)
    if let Some(group_range) = tl_state.small_state_group_manager.check_group_range(item_id) {
        if item_id == group_range.start {
            // item_id == range.start: Render FoldHeader
            // This FoldHeader will contain ALL items in the range
            if let Some(group) = tl_state.small_state_group_manager.get_group_at_item_id(item_id) {
                let item = populate_small_state_group_header(
                    cx,
                    list,
                    item_id,
                    room_id,
                    &group_range,  // Pass the full range
                    group,
                    tl_items,
                    // ... other parameters
                );
                item.draw_all(cx, scope);
            }
            continue;
        } else if group_range.contains(&item_id) {
            // range.start < item_id < range.end: Render Empty
            // Content already displayed in the FoldHeader at range.start
            let item = list.item(cx, item_id, id!(Empty));
            item.draw_all(cx, scope);
            continue;
        }
    }

    // Normal ungrouped item rendering (outside any range)
    // ...
}
```

### Populating the FoldHeader with Small State Events

```rust
fn populate_small_state_group_header(
    cx: &mut Cx2d,
    scope: &mut Scope,
    walk: Walk,
    list: &mut PortalList,
    item_id: usize,
    room_id: &OwnedRoomId,
    group_range: &std::ops::Range<usize>,
    group: &SmallStateGroup,
    tl_items: &imbl::Vector<Arc<TimelineItem>>,
    // ... other parameters
) {
    // Get the FoldHeader item from portal list
    let (fold_item, _existed) = list.item_with_existed(cx, item_id, id!(SmallStateGroupHeader));

    // Set the header summary text from cached data (no "header" prefix needed)
    if let Some(summary) = &group.cached_summary {
        fold_item.label(ids!(summary_text)).set_text(cx, summary);
    }

    // Set the avatars in the header from cached user IDs (no "header" prefix needed)
    if let Some(user_ids) = &group.cached_avatar_user_ids {
        populate_avatar_row_from_user_ids(cx, &fold_item, room_id, user_ids);
    }

    // Draw the FoldHeader and access the inner PortalList
    let mut walk = walk;
    walk.height = Size::fit();  // IMPORTANT: Use Fit for proper sizing
    while let Some(item) = fold_item.draw_walk(cx, scope, walk).step() {
        if let Some(mut list_ref) = item.as_portal_list().borrow_mut() {
            let list = list_ref.deref_mut();

            // Directly render SmallStateEvent widgets for each item in the group range
            for tl_idx in (group_range.start)..group_range.end {
                if let Some(timeline_item) = tl_items.get(tl_idx) {
                    if let TimelineItemKind::Event(event_tl_item) = timeline_item.kind() {
                        // Create and draw appropriate widget based on event type
                        let (item, item_drawn_status) = match event_tl_item.content() {
                            TimelineItemContent::MembershipChange(membership_change) =>
                                populate_small_state_event(cx, list, tl_idx, room_id, event_tl_item, membership_change, item_drawn_status),
                            TimelineItemContent::ProfileChange(profile_change) =>
                                populate_small_state_event(cx, list, tl_idx, room_id, event_tl_item, profile_change, item_drawn_status),
                            // ... handle other event types
                            _ => (list.item_with_existed(cx, tl_idx, id!(Empty)).0, item_drawn_status)
                        };

                        // Draw the item immediately
                        item.draw_all(cx, scope);
                    }
                }
            }
        }
    }
}
```

### Live Design Structure

```rust
live_design! {
    SmallStateGroupHeader = <FoldHeader> {
        // Header: Always visible, shows summary and fold button
        header: <View> {
            width: Fill, height: Fit
            padding: { left: 7.0, top: 2.0, bottom: 2.0 }
            flow: Down, spacing: 7.0

            <View> {
                width: Fill, height: Fit
                user_event_avatar_row = <AvatarRow> {
                    margin: { left: 10.0 }
                }
                summary_text = <Label> {
                    width: Fill, height: Fit
                    draw_text: {
                        wrap: Word
                        text_style: <THEME_FONT_REGULAR> {
                            font_size: (SMALL_STATE_FONT_SIZE)
                        }
                    }
                }
            }

            <View> {
                width: Fill, height: Fit
                flow: Right, align: {x: 0.5, y: 0.5}
                fold_button = <FoldButtonWithText> {
                    open_text: "Show More"
                    close_text: "Show Less"
                }
            }
        }

        // Body: Collapsible content with direct PortalList
        body: <View> {
            width: Fill, height: Fit, flow: Down

            // Direct PortalList for rendering grouped items
            <PortalList> {
                height: Fit, width: Fill
                SmallStateEvent = <SmallStateEvent> {}
                CondensedMessage = <CondensedMessage> {}
                Message = <Message> {}
            }
        }
    }
}
```

### Key Benefits in This Use Case

1. **Reduced Visual Clutter**: Consecutive membership changes (joins/leaves) are collapsed into a single expandable summary
2. **Performance**: Only visible items are rendered, and group metadata is cached
3. **User Experience**: Users can expand groups to see details when needed
4. **Automatic Grouping**: Groups are computed automatically based on timeline data changes
