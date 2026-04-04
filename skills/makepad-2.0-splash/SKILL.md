---
name: makepad-2.0-splash
description: |
  CRITICAL: Use for Makepad 2.0 Splash scripting language. Triggers on:
  splash language, makepad script, script_mod!, makepad scripting, splash 脚本,
  makepad 2.0 script, mod.state, on_render, script_eval, streaming evaluation,
  splash syntax, splash vm, let binding, splash functions, hot reload, live reload,
  ScriptModKey, script_mod_overrides, checkpoint, incremental parsing,
  canvas splash, POST splash, fn tick, on_audio, set_text, tab switching,
  音乐播放器, token monitor, driver script, audio API,
  热重载, 脚本引擎, 增量解析
---

# Makepad 2.0 Splash Scripting Language

Splash is Makepad 2.0's core runtime UI scripting language, released February 12, 2026. It replaces the old compile-time `live_design!` macro system with a runtime `script_mod!` macro that enables hot reload, streaming evaluation, and AI-first code generation.

## Core Concepts

### Script Structure

Every Splash script starts with a `use` import and is embedded in Rust via the `script_mod!{}` macro:

```rust
use makepad_widgets::*;

app_main!(App);

script_mod! {
    use mod.prelude.widgets.*

    // let bindings, functions, state, and UI definitions go here

    startup() do #(App::script_component(vm)){
        ui: Root{
            main_window := Window{
                window.inner_size: vec2(800, 600)
                body +: {
                    // UI content
                }
            }
        }
    }
}
```

### Syntax Rules

- **No commas** between properties -- whitespace-delimited
- **No semicolons** -- cleaner syntax optimized for LLM generation
- **Property assignment**: `key: value`
- **Dot-path shorthand**: `draw_bg.color: #f00` (equivalent to `draw_bg +: { color: #f00 }`)
- **Merge operator**: `key +: { ... }` extends parent without replacing
- **Named children**: `name := Widget{...}` (addressable, overridable per-instance)
- **Let bindings**: `let MyTemplate = Widget{...}` (local scope, must be defined before use)
- **Rust binding**: `#(Struct::register_widget(vm))` connects Splash to Rust structs
- **Debug logging**: `~expression` logs value during evaluation

### State Management

State is managed via the `mod.state` object and reactive `on_render` callbacks:

```
// Define state
let state = { counter: 0 }
mod.state = state

// Reactive rendering -- re-runs when .render() is called
main_view := View{
    on_render: ||{
        Label{ text: "Count: " + state.counter }
    }
}
```

### Event Handling

Events are handled both inline in Splash and from Rust:

```
// Inline event handlers in Splash
add_button := Button{
    text: "Add"
    on_click: ||{
        add_todo(ui.todo_input.text(), "")
        ui.todo_input.set_text("")
    }
}

// TextInput return key
todo_input := TextInput{
    on_return: || ui.add_button.on_click()
}

// Startup event
on_startup: ||{
    ui.main_view.render()
}
```

From Rust, use `script_eval!` to execute Splash code:

```rust
impl MatchEvent for App {
    fn handle_actions(&mut self, cx: &mut Cx, actions: &Actions) {
        if self.ui.button(cx, ids!(increment_button)).clicked(actions) {
            script_eval!(cx, {
                mod.state.counter += 1
                ui.main_view.render()
            });
        }
    }
}
```

### Functions

```
fn tag_color(tag) {
    if tag == "dev" theme.color_highlight
    else if tag == "design" theme.color_selection_focus
    else theme.color_highlight
}

fn add_todo(text, tag) {
    todos.push({text: text, tag: tag, done: false})
    ui.todo_list.render()
}
```

### Control Flow

```
// If/else
if todos.len() == 0
    EmptyState{}
else for i, todo in todos {
    TodoItem{ label.text: todo.text }
}

// For loops
for i, item in array {
    Label{ text: item.name }
}

// While
while condition { ... }
```

### HTTP Requests

```
let req = net.HttpRequest{
    url: "https://api.example.com/data"
    method: net.HttpMethod.GET
    headers: {"User-Agent": "MakepadApp/1.0"}
}
net.http_request(req) do net.HttpEvents{
    on_response: |res| {
        let text = res.body.to_string()
        let json = res.body.parse_json()
    }
    on_error: |e| { /* handle error */ }
}
```

Streaming responses use `is_streaming: true` with `on_stream` and `on_complete` callbacks.

### HTML Parsing

```
let doc = html_string.parse_html()
doc.query("p")              // all <p> elements
doc.query("#main")           // by id
doc.query("p.bold")          // by class
doc.query("div > p")         // direct children
doc.query("p[0]").text       // text content
doc.query("a@href")          // attribute value
```

### Streaming Evaluation

Splash's parser supports checkpoint-based incremental parsing, designed for AI/LLM streaming code generation:

```rust
// Rust API for streaming evaluation
vm.eval_with_append_source(script_mod, &code, NIL.into())
```

This enables real-time UI updates as code is generated token-by-token, without requiring a complete script before evaluation.

### Hot Reload & Script Mod Tracking

Splash scripts support hot reload via the `--hot` flag. The VM tracks each `script_mod!` block with a unique `ScriptModKey` (file, line, column):

```rust
// Internal: ScriptModKey uniquely identifies a script_mod! block
ScriptModKey { file: "src/app.rs", line: 5, col: 1 }

// Runtime substitution via overrides
ScriptCode::script_mod_overrides  // HashMap of ScriptModKey -> updated source
```

**How hot reload works:**
1. File watcher (`makepad_live_reload_core`) detects source file changes
2. `script_mod!` blocks are extracted from Rust source (handles raw strings, comments, char literals)
3. Rust placeholder counts (`#(...)`) are tracked -- adding/removing placeholders requires full rebuild
4. Validated script mods are applied via `script_mod_overrides`
5. IP-to-location mapping provides source maps for error reporting (fallback to nearest token for synthetic opcodes)

**ScriptSource variants:**
- `ScriptSource::Mod` -- Standard module evaluation (startup)
- `ScriptSource::Streaming` -- Incremental streaming evaluation (AI/LLM)

## Critical Layout Rules

1. **Always set `height: Fit` on containers** -- default `height: Fill` causes invisible UI (0px height)
2. **Use `width: Fill` on the root container** -- never fixed pixel width at the top level
3. **Set `new_batch: true`** on any View with `show_bg: true` that contains text children
4. **Use `:=` for named children** in templates -- without it, text overrides fail silently
5. **`draw_bg.border_radius` takes a float**, not an Inset -- `draw_bg.border_radius: 16.0`
6. **Use styled Views** (`RoundedView`, `SolidView`) instead of raw `View{show_bg: true}`

## Widget Reference

Core containers: `View`, `SolidView`, `RoundedView`, `RectView`, `RoundedShadowView`, `CircleView`, `GradientXView`, `GradientYView`, `ScrollXYView`, `ScrollXView`, `ScrollYView`

Text: `Label`, `H1`-`H4`, `P`, `TextBox`, `TextInput`, `LinkLabel`, `Markdown`, `Html`

Controls: `Button`, `ButtonFlat`, `ButtonFlatter`, `CheckBox`, `Toggle`, `RadioButton`, `Slider`, `DropDown`

Layout: `Splitter`, `FoldHeader`, `Hr`, `Vr`, `Filler`

Lists: `PortalList`, `FlatList`

Navigation: `Modal`, `Tooltip`, `PopupNotification`, `SlidePanel`, `ExpandablePanel`, `PageFlip`, `StackNavigation`

Dock: `Dock`, `DockSplitter`, `DockTabs`, `DockTab`

Media: `Image`, `Icon`, `LoadingSpinner`, `Vector`, `MathView`, `MapView`

## Canvas: Rendering Splash from Claude Code

Makepad Canvas (`tools/canvas/`) is a standalone app that renders Splash code received via HTTP/WS. Used by Claude Code for visual output.

### HTTP API (recommended for sending Splash)
```bash
PORT=$(cat /tmp/makepad-canvas.port)

# Full render
curl -s -X POST "http://127.0.0.1:$PORT/splash" -d 'View{width:Fill height:Fit Label{text:"Hello"}}'

# Streaming render
curl -s -X POST "http://127.0.0.1:$PORT/splash/stream"                    # begin
curl -s -X POST "http://127.0.0.1:$PORT/splash/stream" -d 'View{...'      # append
curl -s -X POST "http://127.0.0.1:$PORT/splash/end"                       # end

# Clear
curl -s -X POST "http://127.0.0.1:$PORT/clear"
```

### WS Event Listening (for receiving click events)
```bash
# Long-lived WS connection receives button click events as JSON
mkfifo /tmp/ws_fifo; (sleep 99999 > /tmp/ws_fifo &)
websocat ws://127.0.0.1:$PORT < /tmp/ws_fifo > /tmp/canvas_events &

# Events arrive as: {"event":"click","widget":"btn_name"}
```

### Interactive Buttons
Use `name := Button{...}` to create clickable buttons. The `name` is sent in click events:
```
View{width:Fill height:Fit flow:Right spacing:12
  btn_save := Button{text:"Save"}
  btn_cancel := Button{text:"Cancel"}
}
```
When clicked: `{"event":"click","widget":"btn_save"}`

### Vector Animations in Splash
```
// Pulsing dot (loop_:true = indefinite, NOT "indefinite"!)
Vector{width:16 height:16
  Circle{cx:8 cy:8 r:6 fill:#x44ddaa opacity:Tween{from:0.3 to:1.0 dur:1.5 loop_:true}}
}

// Moving dot with color change
Vector{width:Fill height:30
  Path{d:"M 20 15 L 400 15" stroke:#x222244 stroke_width:1.}
  Circle{cx:Tween{from:20 to:400 dur:3.0 loop_:true} cy:15 r:4 fill:Tween{from:#x44ddaa to:#xffaa44 dur:3.0 loop_:true}}
}
```

### Canvas Splash Syntax (CRITICAL -- differs from script_mod!)

When generating Splash for Canvas HTTP rendering (`POST /splash`), use these EXACT patterns. Canvas Splash syntax differs from `script_mod!` macro context in several critical ways:

**1. Properties use dot-path inline, NOT nested blocks:**
```
// WRONG -- nested block syntax does not render backgrounds
RoundedView{height: Fit draw_bg: { color: #x1a1a2e border_radius: 8.0 } }

// CORRECT -- dot-path inline
RoundedView{width: Fill height: Fit draw_bg.color: #x1a1a2e draw_bg.radius: 8.}
```

**2. Border radius is `draw_bg.radius`, NOT `draw_bg.border_radius`:**
```
// WRONG
draw_bg.border_radius: 8.0

// CORRECT
draw_bg.radius: 8.
```

**3. Padding uses explicit `Inset{}` type with trailing-dot floats:**
```
// WRONG -- bare number or nested block
padding: 20
padding: { top: 20 bottom: 20 }

// CORRECT
padding: Inset{left: 20. right: 20. top: 16. bottom: 16.}
```

**4. Align uses explicit `Align{}` type:**
```
// WRONG
align: { y: 0.5 }

// CORRECT
align: Align{y: 0.5}
align: Center
```

**5. Float values use trailing dot:**
```
// WRONG       // CORRECT
8.0            8.
16.0           16.
0.5            0.5
```

**6. `SolidView` and `RoundedView` do NOT need `show_bg: true` or `new_batch: true`** -- they render backgrounds out of the box.

**7. Use `--data-binary` for multi-line Splash via curl** -- plain `-d` strips newlines.

### Proven Canvas Dashboard Template

Source: `tools/canvas/examples/token-dashboard.splash`

```
SolidView{width: Fill height: Fit draw_bg.color: #x0c0c18 flow: Down padding: Inset{left: 32. right: 32. top: 24. bottom: 24.} spacing: 20

    // Title
    Label{text: "Dashboard Title" draw_text.color: #xeeeeff draw_text.text_style.font_size: 20}

    // Card row
    View{width: Fill height: Fit flow: Right spacing: 16
        RoundedView{width: Fill height: Fit draw_bg.color: #x161628 draw_bg.radius: 8. padding: Inset{left: 20. right: 20. top: 16. bottom: 16.} flow: Down spacing: 6
            Label{text: "Metric Name" draw_text.color: #x888899 draw_text.text_style.font_size: 10}
            Label{text: "Value" draw_text.color: #xcc66ff draw_text.text_style.font_size: 28}
        }
    }

    // Horizontal bar chart row
    View{width: Fill height: Fit flow: Right spacing: 8 align: Align{y: 0.5}
        Label{text: "Label" width: 100 draw_text.color: #xbbbbbb draw_text.text_style.font_size: 10}
        RoundedView{width: 200 height: 12 draw_bg.color: #xf44336 draw_bg.radius: 2.}
        Label{text: "200" draw_text.color: #x777777 draw_text.text_style.font_size: 10}
    }

    // Vertical bar chart (bars bottom-aligned)
    View{width: Fill height: 130 flow: Right spacing: 2 align: Align{y: 1.0}
        View{width: Fill height: Fit flow: Down align: Center spacing: 4
            RoundedView{width: 14 height: 80 draw_bg.color: #x7733cc draw_bg.radius: 2.}
            Label{text: "Mon" draw_text.color: #x444455 draw_text.text_style.font_size: 7}
        }
    }
}
```

### Canvas Tips
- **HTTP for splash, WS for events** — most reliable pattern
- **Vector shape properties**: `fill`, `stroke`, `stroke_width` — NOT `draw_bg.*`
- **CJK/Chinese text**: Supported in both body text and code blocks. CodeEditor uses double-width columns for CJK characters (fixed 2026-03-23). Theme `font_code` includes LXGWWenKai as Chinese fallback.
- **Large POST bodies**: Canvas supports up to 512KB HTTP body
- **Pub/sub broadcast**: All connected WS clients receive click events
- **Health check**: Use `GET /ping` (NOT `/health`)
- **Monitor toggle**: `/tmp/canvas-monitor-active` flag file controls statusline auto-refresh. Canvas sidebar has a toggle button.

### Compiled vs Eval: Two Fundamentally Different Widget Creation Paths

Understanding this distinction is CRITICAL for debugging any Splash eval issue:

```
Compiled path (script_mod!, examples, studio):
  parse → compile → execute → create_widget
    → script_apply(FULL type default object with all vec + map entries)
    → on_after_apply(value = full object) ✓  ← ScriptHook runs
    → Templates registered, #[live] fields populated from type default

Eval path (POST /splash, Splash.set_text):
  parse → eval → create_widget_from_prototype
    → script_apply(EVAL VALUE ONLY, e.g. {body: "..."})
    → on_after_apply: SKIPPED (is_eval() guard in TextFlow/Markdown)
    → Templates NOT registered, #[live] fields use defaults (not type default)
```

| Aspect | Compiled (`script_mod!`) | Eval (`set_text`) |
|--------|------------------------|-------------------|
| Widget creation | Full Rust + ScriptVm init | ScriptVm eval string only |
| `on_after_apply` | Called with full type default | **NOT called** |
| Type default vec (named children) | Fully inherited | May lose entries in proto copy |
| Type default map (properties) | Applied to `#[live]` fields | **Only eval value applied** |
| Template registration | Via ScriptHook during apply | Must be done lazily in draw_walk |
| `ScrollYView` | Works | **Renders blank** — use `View` |

**Fix pattern for eval-path issues**: Implement lazy initialization in `draw_walk` that detects missing state and looks up the type default via `cx.with_vm(|vm| vm.bx.heap.type_default_for_object(...))`. This is how Markdown's code_block template inheritance was fixed.

### Splash Eval Pitfalls (CRITICAL -- learned 2026-03-23)

These issues only affect widgets created via Splash runtime eval (`POST /splash`, `Splash.set_text()`), NOT compiled `script_mod!` widgets:

**1. `ScrollYView` does NOT work in Splash eval -- renders blank**
```
// WRONG -- Splash eval renders nothing
ScrollYView{ width: Fill height: Fill flow: Down
    Label{ text: "invisible" }
}

// CORRECT -- use View, Canvas wraps it in its own ScrollYView
View{ width: Fill height: Fit flow: Down
    Label{ text: "visible" }
}
```

**2. `on_after_apply` / `ScriptHook` is NOT called for eval-created widgets**

When Splash eval creates a widget (e.g. `Markdown{body: "..."}`), the `ScriptHook::on_after_apply` callback is never invoked. Any initialization that depends on `on_after_apply` must have a fallback path (e.g. lazy init in `draw_walk`).

**3. Type default properties are NOT fully inherited in eval path**

When `set_type_default()` overrides a widget type with extra properties (like `use_code_block_widget: true`) or named children (like `code_block := View{...}`), instances created via Splash eval may not inherit these. The `#[live]` fields only get values from the eval apply value (e.g. `{body: "..."}`), not the full type default.

**Workaround**: Check for missing state in `draw_walk` and look up the type default via `vm.bx.heap.type_default_for_object()`.

**4. Type default vec entries (named children) may not copy to instances**

Even though `copy_type_default_vec` exists, the vec entries from `set_type_default()` may lose entries between registration and instance creation. The auto-proto vec copy in `new_with_proto_impl` copies from the direct proto, which may have fewer entries than the type_default.

**5. Nested `Markdown{}` inside Splash works but needs type default templates**

When Canvas overrides `mod.widgets.Markdown` with `code_block := View{CodeView{...}}`, and Splash eval creates `Markdown{body: "..."}`, the code_block template is NOT automatically available. The fix (in `widgets/src/markdown.rs`) lazily looks up the type default at draw time and registers missing templates.

---

## Debugging Splash

### Command-Line Flags

| Flag | Description |
|------|-------------|
| `--hot` | Enable hot reload: watches `script_mod!` source files and auto-refreshes UI on save. Only reloads Splash DSL; Rust changes need recompilation. |
| `--stdin-loop` | Studio mode: communicates with Makepad Studio via stdin/websocket. Used internally by Studio. |

### Print Debugging

`std.println()` / `std.print()` are the primary debugging tools. Output goes to both terminal and Studio's Log View:

```
std.println("debug: state.counter = " + state.counter)
```

The `~expression` debug log syntax also prints values during evaluation:
```
~state.counter    // prints the value of state.counter during eval
```

### Makepad Studio Integration

Studio can run Splash scripts directly from the **Run List** panel (looks for `makepad.splash` in project root). Script errors appear in the **Log View** with file path and error details.

When running under Studio, Splash scripts get a `hub` module:

| API | Description |
|-----|-------------|
| `hub.run(env, cmd, args)` | Launch subprocess from Splash |
| `hub.set_run_items(items)` | Register runnable items in Studio's Run List |
| `hub.studio_ip` | Studio's WebSocket address |

### Current Limitations

- **No breakpoint debugging** -- Splash VM does not support breakpoints or stepping
- **No AST dump flag** -- Inspecting parse results requires adding logs in Rust source (`script/`)
- **Print-based debugging** -- `std.println()` and `~expr` are the primary debugging tools

---

## File References

- Full language manual: `splash.md` (2559 lines)
- Migration guide: `AGENTS.md` (815 lines)
- Counter example: `examples/counter/src/app.rs`
- Todo example: `examples/todo/src/app.rs`
- Detailed reference: `skills/makepad-2.0-splash/references/splash-language-reference.md`
- Patterns guide: `skills/makepad-2.0-splash/references/splash-scripting-patterns.md`

---

## Practical Splash Lessons (learned 2026-03-31, from building Vox voice input app)

### Lesson 1: `instance` Fields Cannot Be Added in `+:` Blocks

The most critical Splash limitation. Adding `instance my_var: 0.5` inside a `draw_bg +: { }` block causes a runtime error: **"cannot push to frozen vec"**.

```
// WRONG — runtime crash
draw_bg +: {
    instance hover: 0.0          // CRASH: cannot push to frozen vec
    pixel: fn() { ... }
}

// CORRECT — override pixel function only, use built-in variables
draw_bg +: {
    pixel: fn() {
        let t = self.draw_pass.time    // built-in, always available
        return Pal.premul(vec4(t, 0.0, 0.0, 1.0))
    }
}
```

**Workarounds:**
- Use `self.draw_pass.time` for time-based animation
- Use `self.pos`, `self.rect_size` (always available)
- For custom instance variables, create a Rust `DrawQuad` subtype (see makepad-2.0-shaders skill)
- Use `LoadingSpinner` widget for simple animated indicators

### Lesson 2: Transparent Floating Window Recipe

Creating a truly transparent overlay window requires **three** things:

```
my_window := Window{
    show_caption_bar: false
    window.transparent: true             // 1. Window-level transparency
    pass.clear_color: #x00000000         // 2. Render pass clear to fully transparent
    body +: {
        // 3. Do NOT set draw_bg on body — it overrides transparency
        View{
            width: Fill height: Fill
            // Only visible elements show; rest is see-through
        }
    }
}
```

**Common mistakes:**
- Setting only `window.transparent: true` — window stays opaque (gray background)
- Setting `draw_bg.color: #x00000000` on body — does NOT make it transparent, just black
- Must also configure as floating panel from Rust: `MacosWindowConfig::floating_panel()` + `Borderless`

**Reference implementation:** Makepad `tools/canvas/src/app.rs` uses this exact pattern.

### Lesson 3: Property Names That Don't Exist

Splash **silently ignores** unknown properties. These caused us real debugging time:

| Wrong | Correct | Notes |
|-------|---------|-------|
| `password: true` | `is_password: true` | TextInput password mode |
| `color: #fff` on LoadingSpinner | (not supported) | LoadingSpinner has no `color` property |
| `window.backdrop: Vibrancy` | Works, but needs `transparent: true` too | Backdrop alone doesn't make window transparent |

### Lesson 4: Emoji Rendering

Makepad's text renderer supports **some** emoji but not all:

| Works | Doesn't Work |
|-------|-------------|
| 🎙 🔍 🔄 | ✨ ⏳ |

If an emoji shows as a box or garbage character, try a different one. Stick to basic emoji from the BMP (Basic Multilingual Plane).

### Lesson 5: `width: Fit` + Large `border_radius` = Spiky Shape

`RoundedView` with `border_radius: 28.0` on a `height: 56` capsule produces **diamond-shaped** ends instead of half-circles. The underlying `sdf.box()` formula breaks when `radius >= min(w,h)/2`.

**Fix:** Use a custom SDF capsule shader instead of `RoundedView`:

```
View{
    show_bg: true
    draw_bg +: {
        pixel: fn() {
            let r = self.rect_size.y * 0.5
            let px = self.pos.x * self.rect_size.x
            let py = self.pos.y * self.rect_size.y
            let cx = clamp(px, r, max(r, self.rect_size.x - r))
            let d = length(vec2(px - cx, py - self.rect_size.y * 0.5)) - r
            let alpha = 1.0 - smoothstep(-1.0, 1.0, d)
            return Pal.premul(vec4(0.1, 0.1, 0.18, alpha * 0.82))
        }
    }
}
```

### Lesson 6: Multi-Window App — Window Visibility Control

Windows declared in `script_mod!` auto-show on startup. Makepad `WindowRef` has no `close()`/`open()` method.

**Working pattern:** Declare windows at normal size. Use `configure_window()` to bring to front when needed.

```rust
// Show: configure_window triggers makeKeyAndOrderFront on macOS
let settings = self.ui.window(cx, ids!(settings_window));
settings.configure_window(cx, dvec2(480.0, 560.0), dvec2(500.0, 200.0), false, "Settings".into());

// Hide: resize to 1x1 (no close/minimize on WindowRef)
let capsule = self.ui.window(cx, ids!(capsule_window));
capsule.resize(cx, dvec2(1.0, 1.0));
```

**Note:** `reposition(cx, dvec2(-9999, -9999))` does NOT reliably hide macOS floating panels.

### Lesson 7: `new_batch: true` and Widget Z-Order

Adding a `LoadingSpinner` (or any child widget with its own draw shader) inside a custom-shader View can cause **bleed-through at the edges** — the child widget draws outside the parent's SDF mask.

**Fix:** Either:
1. Draw animation in the parent's own pixel shader (no child widget z-order issues)
2. Use `clip_x: true` + `clip_y: true` on the parent (may not fully solve it)

### Lesson 8: Continuous Redraw for Time-Based Shader Animation

`self.draw_pass.time` in a shader only advances when the widget is redrawn. Without explicit redraw, time freezes.

```rust
fn handle_next_frame(&mut self, cx: &mut Cx, _e: &NextFrameEvent) {
    if self.inner.state != STATE_IDLE {
        // Redraw the WINDOW (not just the view) to update draw_pass.time
        self.ui.widget(cx, ids!(my_window)).redraw(cx);
        self.inner.next_frame = cx.new_next_frame();
    }
}
```

**Key:** Redraw the `Window` widget, not just the inner View. The draw pass time is per-window.

### Lesson 9: `#[rust]` Fields with Complex Types in Script-Derived Structs

`#[derive(Script, ScriptHook)]` structs can only have `#[rust]` fields whose types implement `Default`. For complex non-Default types (channels, handles, etc.), wrap them in an `Inner` struct:

```rust
#[derive(Default)]
struct Inner {
    timer: Timer,
    rx: Option<crossbeam_channel::Receiver<u64>>,
    handle: Option<SomeNonDefaultHandle>,
}

#[derive(Script, ScriptHook)]
pub struct App {
    #[live] ui: WidgetRef,
    #[rust] inner: Inner,    // Single Default-able wrapper
}
```
