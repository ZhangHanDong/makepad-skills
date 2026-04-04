# Makepad 2.0 Optimization Guide

## 1. Draw Batching Deep Dive

### The Batching Pipeline

Makepad's renderer collects draw commands from the widget tree and sorts them by shader type. This batching dramatically reduces GPU state changes but introduces draw ordering constraints.

```
WIDGET TREE                    DEFAULT BATCH ORDER
============                   ===================

RoundedView (bg shader)        Batch 1: bg shaders
  +-- Label (text shader)           RoundedView bg
  +-- Icon  (icon shader)           SolidView bg
SolidView (bg shader)
  +-- Label (text shader)      Batch 2: text shaders
                                    Label "Hello"
                                    Label "World"

                               Batch 3: icon shaders
                                    Icon

RESULT: Both backgrounds draw FIRST, then ALL text draws on top.
        This works fine when backgrounds don't overlap with text
        from OTHER containers.
```

### The Overlap Problem

The problem arises when sibling Views have backgrounds AND text. Without `new_batch`, a Label inside the second View gets batched with the first View's Label, potentially rendering behind the second View's background:

```
WITHOUT new_batch:             WITH new_batch:
=================              ================

Draw order:                    Draw order:
1. View-A background           1. View-A background
2. View-B background           2. View-A text "Hello"
3. Text "Hello" (View-A)       --- new batch ---
4. Text "World" (View-B)       3. View-B background
                                4. Text "World" (View-B)
Problem: "World" draws
AFTER View-B's background,     Each View is self-contained.
but "Hello" also draws after   Text always renders on top of
View-B bg. If View-B bg is     its own parent's background.
opaque, it covers "Hello".
```

### Batch Boundary Visualization

Here is how `new_batch: true` creates draw boundaries in a real widget tree:

```
RoundedView{ new_batch: true draw_bg.color: #1e1e2e    <-- Batch 1 START
    Label{text: "Title"}                                     bg + text contained
    Hr{}
    View{ new_batch: true show_bg: true                 <-- Batch 2 START
        draw_bg.color: #2a2a3d
        Label{text: "Item 1"}                                bg + text contained
    }
    View{ new_batch: true show_bg: true                 <-- Batch 3 START
        draw_bg.color: #2a2a3d
        Label{text: "Item 2"}                                bg + text contained
    }
}
```

Each `new_batch: true` creates a `DrawList2d` internally. This means the GPU processes the draw commands in separate groups, ensuring correct layering within each batch.

### Cost of new_batch

Every `new_batch: true` creates a new `DrawList2d` with its own command buffer. For small numbers (10-50), this is negligible. For hundreds of items, consider using `PortalList` (which handles batching internally through virtualization) rather than hundreds of individual `new_batch` Views.

```
PERFORMANCE IMPACT:

  1-50 new_batch Views:    Negligible overhead
  50-200 new_batch Views:  Slight draw call increase, still fine
  200+ new_batch Views:    Consider PortalList or texture_caching
  1000+ new_batch Views:   Definitely use PortalList
```

---

## 2. GC Optimization Patterns

### Pattern 1: Static App Shell

The most impactful GC optimization. Mark your application's structural UI (dock, tabs, toolbars) as static immediately after definition.

```
// Step 1: Define the full application structure
let AppDock = Dock{
    tab_bar +: {
        EditorTab := DockTab{
            label := Label{text: "Editor" draw_text.color: #ddd}
        }
        SettingsTab := DockTab{
            label := Label{text: "Settings" draw_text.color: #ddd}
        }
    }
    root := DockSplitter{
        axis: SplitterAxis.Horizontal
        align: SplitterAlign.FromStart(300.0)
        a: sidebar_tabs
        b: main_tabs
    }
    sidebar_tabs := DockTabs{tabs: [file_tree]}
    main_tabs := DockTabs{tabs: [editor settings]}

    // Content templates
    TabFileTree := TabFileTree{}
    TabEditor := TabEditor{}
    TabSettings := TabSettings{}
}

// Step 2: Mark entire tree as permanent
mod.gc.set_static(AppDock)

// Step 3: Clean up construction temporaries
mod.gc.run()

// Step 4: Start the app (dynamic content uses automatic GC)
startup() do #(App::script_component(vm)){
    ui: Root{
        main_window := Window{
            body +: {
                AppDock{}
            }
        }
    }
}
```

**Why this matters:** The `set_static()` call recursively walks the AppDock object graph and marks every reachable object, array, string, pod, handle, and regex as static. During subsequent GC cycles, these objects are skipped entirely in the mark phase, making GC much faster.

### Pattern 2: GC Monitoring for Development

During development, use `run_status()` to understand your app's memory behavior:

```
// Add a debug button to trigger GC with stats
debug_gc_button := Button{text: "Run GC"}

// In Rust event handler:
// if self.ui.button(cx, ids!(debug_gc_button)).clicked(actions) {
//     script_eval!(cx, {
//         mod.gc.run_status()
//     });
// }
```

The output tells you:
```
GC 142us: obj[S:1200 A:340 R:89] arr[S:45 A:12 R:3] str[S:890 A:120 R:15]
          hdl[S:8 A:2 R:0] pod[S:200 A:45 R:10] rex[S:3 A:0 R:0]

Interpreting the numbers:
  S (Static) high  = good, set_static is working
  A (Alive) high   = many live objects, normal for large UIs
  R (Removed) high = lots of churn, maybe optimize allocation patterns
  Time > 1ms       = large heap, consider more set_static usage
```

### Pattern 3: Bulk Operations with GC Control

When performing bulk operations that create many temporary objects, bracket them with GC:

```
fn import_large_dataset(data) {
    // Disable automatic GC during bulk import by doing it manually after
    for i in 0..data.len() {
        items.push({
            id: data[i].id
            name: data[i].name
            value: data[i].value
        })
    }

    // Single GC pass after all allocations
    mod.gc.run()

    // Render once
    ui.item_list.render()
}
```

### GC Heap Type Buckets

The GC tracks six independent heap categories. Each has its own free list and threshold:

```
HEAP CATEGORY    CONTENTS                           MIN THRESHOLD
=============    ========                           =============
Objects          Widget instances, closures, maps   1,024
Arrays           Value arrays, typed arrays         128
Strings          Interned text strings               256
Pods             vec2, vec3, vec4, Inset, etc.      128
Handles          Native Rust object wrappers         64
Regexes          Compiled regex patterns             64

GC triggers when ANY category exceeds: MIN AND >= 2x since last GC
```

---

## 3. Render Tree Optimization Strategies

### Strategy 1: Minimal Render Scope

Always render the smallest possible sub-tree. A common mistake is rendering the root view when only a small part changed:

```
// BAD: Re-renders entire UI for a counter increment
fn increment() {
    state.counter += 1
    ui.main_view.render()     // main_view contains header, sidebar, list, counter
}

// GOOD: Re-render only the counter display
fn increment() {
    state.counter += 1
    ui.counter_label.render() // Only the counter label rebuilds
}
```

### Strategy 2: Separate Static and Dynamic Content

Structure your widget tree so dynamic content lives in isolated sub-trees:

```
ui: Root{
    main_window := Window{
        body +: {
            View{
                flow: Down height: Fill

                // STATIC: Header never changes, no on_render needed
                RoundedView{
                    width: Fill height: 60
                    new_batch: true
                    draw_bg.color: #1a1a2e
                    padding: Inset{left: 16 right: 16}
                    align: Align{y: 0.5}
                    Label{text: "My App" draw_text.color: #fff draw_text.text_style.font_size: 18}
                }

                // DYNAMIC: List changes frequently
                list_view := View{
                    width: Fill height: Fill
                    on_render: || {
                        for i, item in items {
                            ItemRow{label.text: item.name}
                        }
                    }
                }

                // DYNAMIC: Status bar updates occasionally
                status_view := View{
                    width: Fill height: 30
                    on_render: || {
                        Label{text: status_text draw_text.color: #888}
                    }
                }
            }
        }
    }
}
```

Now `ui.list_view.render()` and `ui.status_view.render()` can be called independently.

### Strategy 3: Conditional Rendering

Skip expensive rendering when the data has not actually changed:

```
var last_rendered_count = 0

fn maybe_update_list() {
    if items.len() != last_rendered_count {
        last_rendered_count = items.len()
        ui.list_view.render()
    }
    // No render call if count hasn't changed
}
```

### Strategy 4: Debounced Rendering for Rapid Input

For search-as-you-type or slider drag scenarios, avoid rendering on every keystroke:

```rust
// Rust side - use a timer to debounce
impl MatchEvent for App {
    fn handle_actions(&mut self, cx: &mut Cx, actions: &Actions) {
        if let Some(text) = self.ui.text_input(cx, ids!(search_input)).changed(actions) {
            // Store the search text but don't render yet
            self.pending_search = Some(text);
            // Start/reset a 100ms timer
            cx.start_timeout(0.1);
        }
    }

    fn handle_event(&mut self, cx: &mut Cx, event: &Event) {
        if let Event::Timer(_) = event {
            if let Some(search) = self.pending_search.take() {
                script_eval!(cx, {
                    state.search_query = search
                    ui.results_view.render()
                });
            }
        }
    }
}
```

---

## 4. Memory Management Best Practices

### Object Lifecycle

```
OBJECT LIFECYCLE IN SPLASH VM:

  Allocation
      |
      v
  [Live Object] ---.render()--> [Referenced by widget tree]
      |                              |
      | (no more references)         | (.render() with new content)
      v                              v
  [Unreachable] <-------------- [Old content replaced]
      |
      | (GC mark phase: not reached)
      v
  [Swept / Freed]
      |
      v
  [Free list] --> reused by next allocation
```

### Avoid Accidental Object Retention

Objects remain alive as long as any root can reach them. Common retention sources:

1. **Global variables** - `var` at module scope are permanent roots
2. **Closures** - Closures capture their enclosing scope
3. **Static marking** - `mod.gc.set_static()` is irreversible

```
// LEAK: Global array grows forever
var all_events = []
fn on_event(e) {
    all_events.push(e)  // Never shrinks!
}

// FIX: Bounded buffer
var recent_events = []
fn on_event(e) {
    recent_events.push(e)
    if recent_events.len() > 100 {
        recent_events.splice(0, 1)  // Remove oldest
    }
}
```

### String Interning

Splash interns all strings. Creating the same string value twice returns the same `ScriptString` reference. This means:
- String comparison is fast (pointer equality)
- Duplicate strings don't consume extra memory
- But strings are only freed by GC, not eagerly

### Handle Management

`ScriptHandle` wraps native Rust objects. They are reference-counted separately from the GC. Key points:
- Handles have a `ScriptHandleRef` that participates in Rust's reference counting
- The GC marks handles reachable from the script heap
- Unreachable handles are freed during sweep, which triggers their Rust `Drop`

---

## 5. Network Performance (HTTP Streaming)

### Efficient Streaming Pattern

For streaming API responses (e.g., LLM chat), render incrementally:

```
var stream_buffer = ""

fn start_chat_stream(prompt) {
    let req = net.HttpRequest{
        url: "https://api.example.com/chat"
        method: net.HttpMethod.POST
        is_streaming: true
        headers: {
            "Content-Type": "application/json"
            "Authorization": "Bearer " + api_key
        }
        body: {
            messages: [{role: "user" content: prompt}]
            stream: true
        }.to_json()
    }

    stream_buffer = ""

    net.http_request(req) do net.HttpEvents{
        on_stream: |res| {
            stream_buffer += res.body.to_string()
            // Render the response view to show incremental updates
            ui.response_view.render()
        }
        on_complete: |res| {
            // Final render with complete content
            ui.response_view.render()
        }
        on_error: |e| {
            stream_buffer = "Error: request failed"
            ui.response_view.render()
        }
    }
}
```

### Avoid Re-parsing on Every Chunk

When streaming JSON lines (e.g., SSE), accumulate and parse efficiently:

```
var partial_line = ""
var parsed_messages = []

fn handle_stream_chunk(chunk_text) {
    partial_line += chunk_text
    let lines = partial_line.split("\n")

    // Process all complete lines
    for i in 0..lines.len() - 1 {
        let line = lines[i]
        if line.len() > 0 {
            let parsed = line.parse_json()
            if parsed != nil {
                parsed_messages.push(parsed)
            }
        }
    }

    // Keep the last (potentially incomplete) line
    partial_line = lines[lines.len() - 1]

    // Single render for all processed messages
    ui.messages_view.render()
}
```

---

## 6. Complete Before/After Optimization Examples

### Example 1: Todo List (Batching Fix)

**Before (broken - text invisible):**
```
let TodoItem = RoundedView{
    width: Fill height: Fit
    padding: 12
    draw_bg.color: #2a2a3d
    draw_bg.border_radius: 6.0
    label := Label{text: "task" draw_text.color: #ddd}
}

View{
    flow: Down height: Fit spacing: 4 padding: 16
    TodoItem{label.text: "Buy groceries"}
    TodoItem{label.text: "Fix bug"}
    TodoItem{label.text: "Write tests"}
}
```

**After (fixed - text visible):**
```
let TodoItem = RoundedView{
    width: Fill height: Fit
    padding: 12
    new_batch: true
    draw_bg.color: #2a2a3d
    draw_bg.border_radius: 6.0
    label := Label{text: "task" draw_text.color: #ddd}
}

RoundedView{
    flow: Down height: Fit spacing: 4 padding: 16
    new_batch: true
    draw_bg.color: #1e1e2e
    draw_bg.border_radius: 10.0
    Label{text: "My Tasks" draw_text.color: #fff draw_text.text_style.font_size: 14}
    Hr{}
    TodoItem{label.text: "Buy groceries"}
    TodoItem{label.text: "Fix bug"}
    TodoItem{label.text: "Write tests"}
}
```

Changes:
- Added `new_batch: true` to `TodoItem` template
- Added `new_batch: true` to the outer container
- Both container and items now render text on top of their backgrounds

### Example 2: Large App with GC Optimization

**Before (GC runs frequently, pauses noticeable):**
```
use mod.prelude.widgets.*

// All templates defined at module level
let TabEditor = View{...}
let TabFileTree = View{...}
let TabSettings = View{...}
let TabSearch = View{...}
let AppDock = Dock{
    // ... 20+ tab templates ...
}

startup() do #(App::script_component(vm)){
    ui: Root{
        main_window := Window{
            body +: { AppDock{} }
        }
    }
}
// GC keeps scanning the entire AppDock tree every cycle
```

**After (GC skips static tree, runs faster):**
```
use mod.prelude.widgets.*

let TabEditor = View{...}
let TabFileTree = View{...}
let TabSettings = View{...}
let TabSearch = View{...}
let AppDock = Dock{
    // ... 20+ tab templates ...
}

// Mark the structural UI as permanent
mod.gc.set_static(AppDock)
mod.gc.run()

startup() do #(App::script_component(vm)){
    ui: Root{
        main_window := Window{
            body +: { AppDock{} }
        }
    }
}
// GC now skips all static objects during mark phase
```

Changes:
- Added `mod.gc.set_static(AppDock)` after tree definition
- Added `mod.gc.run()` to clean up construction temporaries
- GC mark phase now skips the entire AppDock graph (objects, strings, arrays, pods, handles)

### Example 3: Render Optimization for Dynamic Content

**Before (re-renders entire UI on every change):**
```
let state = {
    items: []
    selected: -1
    filter_text: ""
}
mod.state = state

startup() do #(App::script_component(vm)){
    ui: Root{
        on_startup: || { ui.main.render() }
        main_window := Window{
            body +: {
                main := View{
                    flow: Down height: Fill
                    on_render: || {
                        // Header
                        RoundedView{
                            width: Fill height: 60
                            new_batch: true
                            draw_bg.color: #1a1a2e
                            Label{text: "Items: " + state.items.len() draw_text.color: #fff}
                        }
                        // Filter input
                        search := TextInput{text: state.filter_text}
                        // Item list
                        for i, item in state.items {
                            if item.name.contains(state.filter_text) {
                                ItemRow{...}
                            }
                        }
                        // Status bar
                        Label{text: "Selected: " + state.selected draw_text.color: #888}
                    }
                }
            }
        }
    }
}
```

**After (targeted renders for each section):**
```
let state = {
    items: []
    selected: -1
    filter_text: ""
}
mod.state = state

startup() do #(App::script_component(vm)){
    ui: Root{
        on_startup: || {
            ui.header_view.render()
            ui.list_view.render()
            ui.status_view.render()
        }
        main_window := Window{
            body +: {
                View{
                    flow: Down height: Fill

                    // Header - only re-renders when item count changes
                    header_view := View{
                        width: Fill height: 60
                        on_render: || {
                            RoundedView{
                                width: Fill height: Fill
                                new_batch: true
                                draw_bg.color: #1a1a2e
                                align: Align{y: 0.5}
                                padding: Inset{left: 16}
                                Label{text: "Items: " + state.items.len() draw_text.color: #fff}
                            }
                        }
                    }

                    // Search input (static, does not need on_render)
                    search := TextInput{text: ""}

                    // List - re-renders on filter or data change
                    list_view := View{
                        width: Fill height: Fill
                        on_render: || {
                            for i, item in state.items {
                                if item.name.contains(state.filter_text) {
                                    ItemRow{...}
                                }
                            }
                        }
                    }

                    // Status - re-renders on selection change
                    status_view := View{
                        width: Fill height: 30
                        on_render: || {
                            Label{text: "Selected: " + state.selected draw_text.color: #888}
                        }
                    }
                }
            }
        }
    }
}

// In event handlers:
// On item added: ui.header_view.render() + ui.list_view.render()
// On filter changed: ui.list_view.render()
// On selection changed: ui.status_view.render()
```

Changes:
- Split monolithic `on_render` into three independent render zones
- Each zone can be re-rendered independently
- Adding an item only re-renders header + list (not status)
- Changing selection only re-renders status (not header or list)
- Typing in filter only re-renders list (not header or status)

### Example 4: PortalList Migration

**Before (renders all 1000 items every frame):**
```
list_view := View{
    flow: Down height: Fill
    on_render: || {
        ScrollYView{
            flow: Down spacing: 2
            for i, item in all_items {
                RoundedView{
                    width: Fill height: Fit
                    new_batch: true
                    padding: 8
                    draw_bg.color: #2a2a3d
                    draw_bg.border_radius: 4.0
                    label := Label{text: item.name draw_text.color: #ddd}
                }
            }
        }
    }
}
```

**After (only visible items rendered):**
```
// Use PortalList with Rust-side Widget for virtualized rendering
// In Splash:
let MyList = #(MyList::register_widget(vm)){
    list := PortalList{
        width: Fill height: Fill
        flow: Down spacing: 2
        scroll_bar: ScrollBar{}
        Item := RoundedView{
            width: Fill height: Fit
            new_batch: true
            padding: 8
            draw_bg.color: #2a2a3d
            draw_bg.border_radius: 4.0
            label := Label{text: "" draw_text.color: #ddd}
        }
    }
}
```

```rust
// In Rust:
impl Widget for MyList {
    fn draw_walk(&mut self, cx: &mut Cx2d, scope: &mut Scope, walk: Walk) -> DrawStep {
        while let Some(item) = self.view.draw_walk(cx, scope, walk).step() {
            if let Some(mut list) = item.borrow_mut::<PortalList>() {
                list.set_item_range(cx, 0, self.items.len());
                while let Some(item_id) = list.next_visible_item(cx) {
                    let widget = list.item(cx, item_id, id!(Item));
                    widget.label(ids!(label)).set_text(cx, &self.items[item_id].name);
                    widget.draw_all(cx, &mut Scope::empty());
                }
            }
        }
        DrawStep::done()
    }
}
```

Changes:
- Replaced manual `for` loop with `PortalList` virtualization
- Only ~20-30 visible items are drawn per frame instead of 1000
- Scroll performance is constant regardless of list size
- Memory usage bounded by visible item count, not total count
