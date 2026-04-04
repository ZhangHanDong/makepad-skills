---
name: makepad-2.0-performance
description: |
  CRITICAL: Use for Makepad 2.0 performance optimization and debugging. Triggers on:
  makepad performance, makepad debug, makepad profiling, makepad gc,
  new_batch, texture_caching, render optimization, draw batching,
  mod.gc, garbage collection, memory, debug logging, troubleshoot,
  ViewOptimize, PortalList, CachedView, render tree,
  invisible text, text disappears, UI freezes, scroll stuttering,
  性能, 调试, 优化, 垃圾回收, 渲染, 批处理, 日志
---

# Makepad 2.0 Performance & Debugging Skill

## 1. Overview

Makepad 2.0 uses a unique rendering pipeline combined with the Splash script VM. Performance depends on understanding three critical subsystems:

1. **Draw Batching** - How Makepad groups GPU draw calls and why `new_batch: true` matters
2. **Garbage Collection** - The Splash VM's mark-sweep GC with per-type-bucket thresholds
3. **Render Triggers** - The `on_render` / `.render()` system that controls when sub-trees rebuild

Unlike traditional retained-mode UI frameworks, Makepad uses an immediate-mode-inspired draw pipeline where widgets emit draw commands into a sorted batch list. Understanding this pipeline is essential for diagnosing invisible text, flickering, and performance regressions.

---

## 2. Draw Batching System

### How It Works

Makepad automatically batches consecutive draw calls that use the **same shader** into a single GPU draw call. This is a major performance optimization, but it has a critical side effect: draw order can be surprising.

```
Draw pipeline (simplified):

Widget tree:          GPU batches (default):

  View (bg shader)      Batch 1: all bg shaders
    Label (text)   -->  Batch 2: all text shaders
  View (bg shader)
    Label (text)        Result: ALL backgrounds draw first,
                                then ALL text draws second
```

When a View has `show_bg: true` AND contains text children, the text can end up **behind** the background because both text draws get batched together into a single draw call that executes before (or after) the background draw calls.

### `new_batch: true`

Setting `new_batch: true` on a View forces Makepad to start a **new draw batch** at that point. This creates a `ViewOptimize::DrawList` internally, which ensures proper draw ordering within that View's subtree.

```
// PROBLEM: Label text is invisible - batched behind the background
RoundedView{
    width: Fill height: Fit
    draw_bg.color: #1e1e2e
    Label{text: "This text is INVISIBLE"}
}

// FIX: new_batch ensures background draws before text
RoundedView{
    width: Fill height: Fit
    new_batch: true
    draw_bg.color: #1e1e2e
    Label{text: "This text is VISIBLE"}
}
```

### When `new_batch: true` Is Required

| Scenario | Required? | Why |
|----------|-----------|-----|
| View with `show_bg: true` containing Labels | YES | Text batches behind background |
| View with hover animator + text children | YES | Hover bg covers text on activation |
| Container of repeated items with backgrounds | YES | Each item and the container need it |
| Transparent View (no `show_bg`) with Labels | NO | No background to overlap |
| View with only non-text children (e.g., icons) | NO | Same shader type - no overlap issue |
| Deeply nested Views each with backgrounds | YES on each | Each background layer needs its own batch |

### Hover Effects and `new_batch`

This is the **number one mistake** with hoverable list items. When a View has `show_bg: true` with a hover animator that transitions from transparent (`#0000`) to opaque on hover, the text disappears on hover because the newly-opaque background covers the batched text.

```
// CORRECT: Hoverable item with new_batch
let HoverItem = View{
    width: Fill height: Fit
    new_batch: true
    show_bg: true
    draw_bg +: {
        color: uniform(#0000)
        color_hover: uniform(#fff2)
        hover: instance(0.0)
    }
    animator: Animator{
        hover: {
            default: {
                from: {all: Forward{duration: 0.1}}
                apply: {draw_bg: {hover: 0.0}}
            }
            on: {
                from: {all: Forward{duration: 0.1}}
                apply: {draw_bg: {hover: 1.0}}
            }
        }
    }
    label := Label{text: "item" draw_text.color: #fff}
}

// Parent container of hover items also needs new_batch
RoundedView{
    flow: Down height: Fit new_batch: true
    draw_bg.color: #2a2a3d
    draw_bg.border_radius: 8.0
    HoverItem{label.text: "First item"}
    HoverItem{label.text: "Second item"}
}
```

### ViewOptimize Internals

The `new_batch` and `texture_caching` properties map to a `ViewOptimize` enum:

```
ViewOptimize::None      - Default. No special draw ordering.
ViewOptimize::DrawList  - Created by new_batch: true. Starts a new DrawList2d.
ViewOptimize::Texture   - Created by texture_caching: true. Renders to offscreen texture.
```

Priority: `texture_caching` takes precedence over `new_batch` if both are set.

---

## 3. Texture Caching

### How It Works

Setting `texture_caching: true` on a View renders its entire child sub-tree to an offscreen GPU texture. On subsequent frames, if nothing in the sub-tree has changed, Makepad can skip re-rendering the children and just blit the cached texture.

```
// Cache a complex but rarely-changing sidebar
sidebar := View{
    width: 280 height: Fill
    texture_caching: true
    flow: Down spacing: 4
    // ... many child widgets ...
}
```

### Pre-Built Cached Views

Makepad provides pre-styled cached views:

| Widget | Description |
|--------|-------------|
| `CachedView` | Texture-cached rectangle container |
| `CachedRoundedView` | Texture-cached rounded rectangle |

### When to Use Texture Caching

**Good candidates:**
- Complex static sidebars or toolbars that rarely change
- Large widget sub-trees with many nested backgrounds and text
- Decorative panels with shader effects

**Bad candidates:**
- Frequently updating views (e.g., animation targets, live data)
- Small simple views (overhead exceeds benefit)
- Views that contain scrolling content (CachedView wraps the whole content, not the viewport)

### Trade-offs

| Benefit | Cost |
|---------|------|
| Reduces per-frame draw call count | Uses GPU memory for cached texture |
| Avoids re-traversing large sub-trees | Texture must be invalidated on change |
| Can eliminate batching issues (the texture resolves draw order) | DPI factor affects texture resolution |

---

## 4. Garbage Collection (mod.gc)

### Architecture

The Splash VM uses a **mark-and-sweep garbage collector** with isolated heaps for different value types:

```
Heap Layout:
  +-- Objects (ScriptObject)    -- Primary allocation type
  +-- Arrays  (ScriptArray)     -- Typed arrays and value arrays
  +-- Strings (ScriptString)    -- Interned strings
  +-- Pods    (ScriptPod)       -- Pod values (vec2, vec3, vec4, etc.)
  +-- Handles (ScriptHandle)    -- Native Rust handles
  +-- Regexes (ScriptRegex)     -- Interned regex patterns
```

### Automatic GC Triggering

The GC uses a **growth-based heuristic** similar to Lua and V8:

- **Growth Factor:** 2x - GC triggers when any heap category doubles since last GC
- **Minimum Thresholds** (to avoid thrashing on small heaps):

| Category | Minimum Before GC Can Trigger |
|----------|-------------------------------|
| Objects  | 1,024 |
| Strings  | 256 |
| Arrays   | 128 |
| Pods     | 128 |
| Handles  | 64 |

GC triggers when: `current_count >= MIN_THRESHOLD AND current_count >= last_gc_count * 2`

### Script API

**`mod.gc.run()`** - Force a GC cycle immediately. Silent (no log output).

**`mod.gc.run_status()`** - Force a GC cycle and print detailed statistics:
```
GC 142us: obj[S:1200 A:340 R:89] arr[S:45 A:12 R:3] str[S:890 A:120 R:15] ...
```
Where S=static (permanent), A=alive (survived), R=removed (freed).

**`mod.gc.set_static(value)`** - Mark a value and its entire reachable object graph as **static**. Static objects:
- Are never collected by GC (permanent)
- Are skipped during GC mark phase (faster GC traversal)
- Cannot be un-marked (irreversible within the VM lifetime)

**`mod.gc.dump_tag(value)`** - Debug tool. Prints internal tag information for an object: type index, static flag, proto chain.

### Best Practices

**Pattern: Static UI Trees**

For large, stable UI tree definitions (like a Dock with many tabs), mark them as static immediately after definition. This is the standard pattern used in the Studio and UIZoo examples:

```
// Define a large widget tree
let AppDock = Dock{
    // ... tabs, splitters, content templates ...
    TabEditor := TabEditor{}
    TabFileTree := TabFileTree{}
    TabSettings := TabSettings{}
}

// Mark the entire tree as static - it will never be GC'd
mod.gc.set_static(AppDock)

// Run GC immediately to clean up any temporaries from tree construction
mod.gc.run()

// Now start the app
startup() do #(App::script_component(vm)){
    ui: Root{
        main_window := Window{
            body +: {
                // ... use AppDock here ...
            }
        }
    }
}
```

**Pattern: Dynamic Content**

For dynamic content (lists, user-generated items, chat messages), let the automatic GC handle cleanup:

```
// Dynamic data - no need to call mod.gc manually
var todos = []

fn add_todo(text) {
    todos.push({text: text done: false})
    ui.main_view.render()
    // Automatic GC will clean up old unreachable objects
}

fn delete_todo(index) {
    todos.splice(index, 1)
    ui.main_view.render()
    // Old todo object becomes unreachable, will be collected automatically
}
```

**Pattern: Periodic Manual GC for Long-Running Apps**

For apps that create and destroy many objects (e.g., chat applications with streaming responses):

```
var message_count = 0

fn on_new_message(msg) {
    messages.push(msg)
    message_count += 1

    // Every 100 messages, run GC to reclaim temporary parsing objects
    if message_count % 100 == 0 {
        mod.gc.run()
    }

    ui.message_list.render()
}
```

### GC Mark Phase Details

The mark phase traverses from roots:
1. Type check prototypes
2. Type defaults objects
3. Pod type defaults and objects
4. Root objects (held by Rust via `ScriptObjectRef`)
5. Root arrays (held by Rust via `ScriptArrayRef`)
6. Root handles (held by Rust via `ScriptHandleRef`)
7. Thread stacks (all live values on VM execution stacks)
8. Thread scopes
9. Method call contexts
10. Loop source values
11. Trap error/return/bail values
12. Script body scopes and tokenizer string literals
13. Native type table objects

Static objects are skipped during traversal since they only reference other static values.

---

## 5. Render Optimization

### The `on_render` / `.render()` System

Makepad 2.0 uses a pull-based rendering model for dynamic content. The `on_render` callback on a View only executes when `.render()` is called on that View.

```
// Define a reactive view
counter_view := View{
    on_render: || {
        Label{
            text: "Count: " + state.counter
            draw_text.color: #fff
        }
    }
}

// In event handler - only re-render what changed
fn increment() {
    state.counter += 1
    ui.counter_view.render()   // Only this view re-renders
}
```

### Rules for Efficient Rendering

1. **NEVER call `.render()` unnecessarily** - Each call completely rebuilds that sub-tree's widget output.

2. **Render only affected sub-trees** - If only a list changed, render only the list view, not the entire UI.

3. **Avoid rendering in tight loops** - Batch state changes, then render once:
```
// BAD: renders 100 times
for i in 0..100 {
    items[i].value = compute(i)
    ui.item_list.render()    // WASTEFUL - rebuilds list 100 times
}

// GOOD: render once after all changes
for i in 0..100 {
    items[i].value = compute(i)
}
ui.item_list.render()        // Render once with all changes applied
```

4. **Use `on_startup` for initial render** - Trigger the first render when the app starts:
```
ui: Root{
    on_startup: || {
        ui.main_view.render()
    }
    main_window := Window{
        body +: {
            main_view := View{
                on_render: || {
                    // ... dynamic content ...
                }
            }
        }
    }
}
```

### Render Scope

When `.render()` is called on a View, only that View's `on_render` callback executes. Child Views with their own `on_render` callbacks will NOT automatically re-render unless their `.render()` is also called (or they are reconstructed by the parent's `on_render`).

---

## 6. Debug Logging

### Rust-Side Logging

Use the `log!` macro from Makepad's error log system:

```rust
use makepad_widgets::*;

// In Rust code
log!("Button clicked, counter = {}", self.counter);
log!("Widget action: {:?}", action);
```

### Script-Side Logging

In Splash scripts, you can use `log()` or string interpolation for debugging:

```
fn handle_click() {
    let value = compute_something()
    // Log values during development
    log("computed value: " + value)
}
```

### GC Status Logging

Use `mod.gc.run_status()` to get a detailed breakdown of GC activity:

```
// Output example:
// GC 142us: obj[S:1200 A:340 R:89] arr[S:45 A:12 R:3] str[S:890 A:120 R:15]
//           hdl[S:8 A:2 R:0] pod[S:200 A:45 R:10] rex[S:3 A:0 R:0]
```

Fields:
- **Time** (142us) - GC cycle duration in microseconds
- **S** (Static) - Objects permanently marked, never collected
- **A** (Alive) - Objects that survived this GC cycle
- **R** (Removed) - Objects freed in this cycle

### Tag Debugging

For deep debugging of specific objects, use `mod.gc.dump_tag(value)`:

```
let my_widget = View{...}
mod.gc.dump_tag(my_widget)
// Output: obj 4523 type_index=Some(12) is_static=false proto=Some(89) ...
```

---

## 7. Common Performance Issues & Fixes

| Issue | Cause | Fix |
|-------|-------|-----|
| Text invisible | Missing `new_batch` | Add `new_batch: true` to parent View with `show_bg: true` |
| Text disappears on hover | Batch overlap during hover animation | Add `new_batch: true` to the hoverable View |
| UI freezes / stutters | Excessive `.render()` calls | Batch state changes, render only changed sub-trees |
| Memory growing unbounded | GC not running or large static leaks | Use `mod.gc.set_static()` for stable trees, let auto GC handle dynamic content |
| Slow initial load | Large script evaluation at startup | Split into modules, use lazy loading patterns |
| Scroll stuttering | Too many items rendering | Use `PortalList` for virtualized rendering |
| Hover not responding | View missing `show_bg: true` | Views need `show_bg: true` to receive mouse events for hover |
| Widget not found at runtime | Wrong naming operator | Use `:=` (not `:`) for named/addressable children |
| Style overrides not applying | Missing merge operator | Use `+:` to merge properties, not `:` which replaces entirely |
| Layout collapsed to zero | Missing `height: Fit` | All containers need explicit `height: Fit` or a fixed height |

---

## 8. PortalList for Large Lists

### Why PortalList

`PortalList` virtualizes rendering -- only items visible in the viewport are drawn. This is **mandatory** for lists with 100+ items. Without it, all items are drawn every frame regardless of visibility.

### Script-Side PortalList (with on_render)

For Splash-driven lists, define the PortalList with templates and use `on_render`:

```
list := PortalList{
    width: Fill height: Fill
    flow: Down spacing: 4
    scroll_bar: ScrollBar{}
    Item := View{
        width: Fill height: Fit
        padding: 8
        new_batch: true
        draw_bg.color: #2a2a3d
        label := Label{text: "" draw_text.color: #ddd}
    }
}
```

### Rust-Side PortalList (with Widget trait)

For Rust-driven rendering, implement the Widget trait:

```rust
impl Widget for MyList {
    fn draw_walk(&mut self, cx: &mut Cx2d, scope: &mut Scope, walk: Walk) -> DrawStep {
        while let Some(item) = self.view.draw_walk(cx, scope, walk).step() {
            if let Some(mut list) = item.borrow_mut::<PortalList>() {
                list.set_item_range(cx, 0, self.items.len());

                while let Some(item_id) = list.next_visible_item(cx) {
                    let template = id!(Item);
                    let item = list.item(cx, item_id, template);
                    item.label(ids!(label)).set_text(cx, &self.items[item_id].text);
                    item.draw_all(cx, &mut Scope::empty());
                }
            }
        }
        DrawStep::done()
    }
}
```

### FlatList vs PortalList

| Feature | FlatList | PortalList |
|---------|----------|------------|
| Virtualization | No | Yes |
| Suitable for | < 100 items | Any number of items |
| Memory usage | All items in memory | Only visible items |
| Scroll performance | Degrades with count | Constant |

---

## 9. ViewOptimize Options Summary

| Property | ViewOptimize Value | Effect |
|----------|-------------------|--------|
| (default) | `None` | Standard batched drawing |
| `new_batch: true` | `DrawList` | New draw batch, proper draw ordering |
| `texture_caching: true` | `Texture` | Render children to offscreen texture |
| `visible: false` | N/A | Skip rendering entirely |

**Priority:** If both `texture_caching` and `new_batch` are set, `texture_caching` wins (becomes `ViewOptimize::Texture`).

---

## 10. Debugging Checklist

### UI Not Showing

- [ ] Check `height: Fit` on all containers (default `height: Fill` inside a `Fit` parent = 0 height)
- [ ] Check `width: Fill` on root container (never use fixed pixel width on outermost element)
- [ ] Verify `use mod.prelude.widgets.*` is at the top of the script

### Text Invisible

- [ ] Add `new_batch: true` to any View with `show_bg: true` that contains text
- [ ] Check `draw_text.color` is not transparent or same as background
- [ ] Verify the Label is a direct or properly-batched child

### Text Disappears on Hover

- [ ] Add `new_batch: true` to the hoverable View
- [ ] Ensure the container of hoverable items also has `new_batch: true`

### Clicks Not Working

- [ ] Check `:=` vs `:` -- use `:=` for named/dynamic children you reference
- [ ] Verify `show_bg: true` is set for Views that need mouse events
- [ ] Check `grab_key_focus` if keyboard events are needed

### Widget Not Found

- [ ] Verify `#(WidgetName::register_widget(vm))` registration in script_mod
- [ ] Check that `crate::makepad_widgets::script_mod(vm)` is called before custom registrations
- [ ] Verify widget crate is a dependency in Cargo.toml

### Script Errors

- [ ] Use `log()` to debug values during execution
- [ ] Use `mod.gc.run_status()` to check heap statistics
- [ ] Use `mod.gc.dump_tag(value)` to inspect object internals

### Style Not Applying

- [ ] Use `+:` merge operator for extending existing styles: `draw_bg +: { color: #fff }`
- [ ] Use `:` only when you want to fully replace a property
- [ ] Check dot-path syntax: `draw_bg.color: #fff` is shorthand for `draw_bg +: { color: #fff }`

---

## 11. Profiling with Studio

Makepad Studio includes a built-in profiler for monitoring application performance.

### Studio Remote Protocol

Studio can connect to running applications and provide:
- **Screenshots** - Capture current frame state
- **Widget Tree Dumps** - Inspect the live widget hierarchy
- **Widget Queries** - Find specific widgets by ID
- **Performance Monitoring** - Frame times, draw call counts

### Using Studio for Performance Debugging

1. Start Studio remote:
```bash
cargo run -p cargo-makepad --release -- studio --studio=127.0.0.1:8001
```

2. Run your app through Studio:
```json
{"Run":{"mount":"makepad","process":"makepad-example-myapp","args":[]}}
```

3. Capture widget tree to identify render structure:
```json
{"WidgetTreeDump":{"build_id":BUILD_ID}}
```

4. Take screenshots to verify visual state:
```json
{"Screenshot":{"build_id":BUILD_ID}}
```

### Identifying Hot Render Paths

- Use `WidgetTreeDump` to see how many widgets are in the tree
- Look for deeply nested View hierarchies that could benefit from `texture_caching`
- Identify repeated items that should use `PortalList` instead of manual loops
- Check for Views with `new_batch: true` that might not need it (each new batch = new draw list)

---

## 12. Quick Reference Card

### Performance Properties on View

```
// Force new GPU draw batch (fixes text-behind-background)
new_batch: true

// Cache children to GPU texture (reduces draw calls for stable subtrees)
texture_caching: true

// Hide without removing from tree (skip rendering entirely)
visible: false
```

### GC API

```
mod.gc.set_static(value)    // Mark value tree as permanent
mod.gc.run()                // Force GC cycle (silent)
mod.gc.run_status()         // Force GC cycle with log output
mod.gc.dump_tag(value)      // Debug: print object tag info
```

### Render API

```
ui.widget_name.render()     // Trigger on_render for specific widget
```

### GC Thresholds (Automatic Trigger)

```
Objects:  >= 1024 AND >= 2x since last GC
Strings:  >= 256  AND >= 2x since last GC
Arrays:   >= 128  AND >= 2x since last GC
Pods:     >= 128  AND >= 2x since last GC
Handles:  >= 64   AND >= 2x since last GC
```
