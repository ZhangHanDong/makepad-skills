# Canvas Splash Patterns — Lessons from Real-World Development

Hard-won lessons from building the Claude Code Monitor and Music Player apps on Canvas.
These patterns apply to **any Splash code rendered via Canvas** (HTTP/WS `POST /splash`).

---

## Architecture: POST Once, Drive Internally

### The Golden Rule

**POST the Splash code ONCE. All interaction and state changes happen inside Splash.**

```
driver.sh:  gather data → generate Splash code → POST /splash once → EXIT
Splash:     on_click handles interaction / fn tick() drives timers / set_text updates labels
```

### Why NOT Loop-POST

Every `POST /splash` rebuilds the entire widget tree:
1. Destroys all existing Views, Buttons, Labels
2. Creates new widgets with new UIDs
3. Triggers full redraw cycle
4. `uid_map` for event routing gets invalidated

If you POST every 3-5 seconds, Canvas CPU hits 100% and the window freezes.

### Correct Pattern: Data Snapshot + Internal Logic

```bash
# driver.sh — runs once, gathers data, generates Splash, POSTs, exits
DATA=$(jq ... session.jsonl)
cat > /tmp/splash.tmp <<EOF
let state = { tab: "a" elapsed: 0 }

fn show_a() {
    state.tab = "a"
    ui.label.set_text("Content A: $DATA_A")
}

fn tick() {
    state.elapsed = state.elapsed + 1
    ui.timer.set_text("" + state.elapsed)
}

View{...}
EOF
curl -s -X POST "$API/splash" --data-binary @/tmp/splash.tmp
```

Re-run the driver script to refresh data. This replaces the Splash once (not in a loop).

---

## Tab Switching Without on_render

### Problem: `set_visible()` Does NOT Work in Splash

`set_visible()` is a Rust-only method. Calling it from Splash silently does nothing.

```splash
// WRONG — silently fails
ui.tab_a.set_visible(true)
ui.tab_b.set_visible(false)
```

### Problem: `on_render` Not Called on Initial Load

`on_render:` only fires when you call `ui.view.render()`. On first load, the view is empty.

```splash
// WRONG — content_view is empty until someone calls render()
content_view := View{
    on_render: ||{
        Label{text: "Hello"}
    }
}
```

### Solution: Static Layout + `set_text()` for All Dynamic Content

Put ALL possible UI elements in the layout statically. Give them `:=` names. Use `set_text()` to update their content per tab.

```splash
let state = { tab: "session" }

fn show_session() {
    state.tab = "session"
    ui.c1_title.set_text("Input")
    ui.c1_value.set_text("12.3K")
    ui.c2_title.set_text("Output")
    ui.c2_value.set_text("45.6K")
    ui.detail.set_text("Human: 42 | Assistant: 67")
}

fn show_stats() {
    state.tab = "stats"
    ui.c1_title.set_text("Today In")
    ui.c1_value.set_text("1.2M")
    ui.c2_title.set_text("Today Out")
    ui.c2_value.set_text("3.4M")
    ui.detail.set_text("Week: 10M in / 30M out")
}

// Static layout — cards and labels are always present
View{width: Fill height: Fit flow: Right spacing: 12
    RoundedView{...
        c1_title := Label{text: "Input" ...}
        c1_value := Label{text: "12.3K" ...}
    }
    RoundedView{...
        c2_title := Label{text: "Output" ...}
        c2_value := Label{text: "45.6K" ...}
    }
}
detail := Label{text: "..." ...}
```

---

## Timer Pattern: `fn tick()`

Splash widget auto-detects `fn tick()` in the code and starts a 1-second interval timer.

```splash
let state = { elapsed: 0 }

fn fmt_elapsed() {
    let t = state.elapsed
    let h = 0
    while t >= 3600 { h = h + 1  t = t - 3600 }
    let m = 0
    while t >= 60 { m = m + 1  t = t - 60 }
    let s = t
    let hh = if h < 10 { "0" + h } else { "" + h }
    let mm = if m < 10 { "0" + m } else { "" + m }
    let ss = if s < 10 { "0" + s } else { "" + s }
    hh + ":" + mm + ":" + ss
}

fn tick() {
    state.elapsed = state.elapsed + 1
    ui.timer_label.set_text(fmt_elapsed())
}
```

**Key**: `fn tick()` is called EVERY second. Keep it cheap — only `set_text()` calls, no heavy computation.

---

## Audio Callback: `fn on_audio()`

Canvas injects audio state as global variables and calls `fn on_audio()` ~10 times per second when audio is playing.

### Available Globals (injected by Canvas)

| Variable | Type | Description |
|----------|------|-------------|
| `_playing` | bool | Is audio currently playing |
| `_pos` | f64 | Current playback position (seconds, float) |
| `_dur` | f64 | Total duration (seconds, float) |
| `_amp` | f64 | Current RMS amplitude (0.0–1.0) |
| `_b0`–`_b15` | f64 | 16-band FFT spectrum (0.0–1.0 each) |

### Pattern

```splash
fn on_audio() {
    ui.time_cur.set_text(fmt_time(_pos))
    ui.time_end.set_text(fmt_time(_dur))
    if _playing { ui.play_btn.set_text("Pause") }
    else { ui.play_btn.set_text("Play") }
}
```

### Float-to-Integer for Time Display

`_pos` and `_dur` are floats (e.g., `123.456`). Splash has no `floor()` or `round()`. Use a while-loop to truncate:

```splash
fn fmt_time(secs) {
    // Truncate float to integer
    let total = 0
    while total < secs { total = total + 1 }
    if total > secs { total = total - 1 }
    // Now total is an integer
    let m = 0
    while total >= 60 { m = m + 1  total = total - 60 }
    let s = total
    let ms = if m < 10 { "0" + m } else { "" + m }
    let ss = if s < 10 { "0" + s } else { "" + s }
    ms + ":" + ss
}
```

---

## Button Events: Splash on_click vs HTTP Event Bridge

### Splash `on_click:` — WORKS Reliably

Buttons defined in Splash with `on_click:` handlers work perfectly for internal state changes:

```splash
play_btn := Button{text: "Play" ...
    on_click: ||{
        if state.playing { state.playing = false }
        else { state.playing = true }
        refresh()
    }
}
```

### HTTP Event Bridge (`GET /event`) — UNRELIABLE for Dynamic Splash

The HTTP event bridge routes `ButtonAction::Clicked` from Splash buttons through `uid_map` lookup. This is **unreliable** because:

1. Each `POST /splash` rebuilds widget tree → new UIDs
2. `uid_map` rebuilds on next `Draw` event → may be stale
3. Events during splash rebuild are lost

**Rule**: Use `on_click:` for ALL button interactions. Never depend on `GET /event` for Splash buttons.

### Special Button Names for Audio Control

Canvas app.rs routes these button names to audio API automatically (via uid_map when it works):

- `play_btn` or `audio_toggle` → toggle play/pause
- `audio_stop` → stop playback

But since uid_map is unreliable for Splash buttons, audio control should be done via HTTP API from the driver script, not via Splash button names.

---

## Splash Script API Reference (Available Methods)

### Works in Splash

| Method | Description |
|--------|-------------|
| `ui.widget.set_text("...")` | Update Label/Button text |
| `ui.widget.text()` | Read current text |
| `ui.view.render()` | Trigger `on_render:` callback |
| `ui.button.on_click()` | Programmatically trigger click |

### Does NOT Work in Splash (Rust-Only)

| Method | Description | Workaround |
|--------|-------------|------------|
| `set_visible(bool)` | Show/hide widget | Use `on_render` + conditional, or `set_text` |
| `set_active(bool)` | Enable/disable | Use state variable + visual feedback |
| `redraw()` | Force redraw | Use `render()` instead |
| `configure_macos_window()` | Platform config | Set from Rust `handle_startup` |

---

## Full-Script Mode vs View-Children Mode

Splash widget auto-detects the mode based on the first non-whitespace token:

### Full-Script Mode (starts with `let`, `fn`, or `mod.`)

```splash
let state = { count: 0 }
fn tick() { state.count = state.count + 1 }
View{...}
```

Prefix added: `use mod.prelude.widgets.*\n` (just imports, no wrapping View)

### View-Children Mode (starts with lowercase property or widget)

```splash
flow: Down spacing: 10
Label{text: "Hello"}
Button{text: "Click"}
```

Prefix added: `use mod.prelude.widgets.*View{height:Fit, ` (wraps in View)

**Key**: View-children mode's default `flow` is `Right` (horizontal). Add `flow: Down` explicitly for vertical layout.

---

## Common Mistakes Summary

| Mistake | Symptom | Fix |
|---------|---------|-----|
| Loop-POST splash | 100% CPU, window freezes | POST once, use `set_text`/`on_click` internally |
| `set_visible()` in Splash | Silently ignored | Use `set_text` or `on_render` conditional |
| `on_render` without initial `render()` | Empty view on load | Put initial content statically, use `on_render` only for dynamic updates |
| Float in time display | "01:23.456789" | Truncate with while loop before formatting |
| `!expr` for boolean negation | Parse error | Use `if x { false } else { true }` |
| `math.floor()` | Not available | Use while loop to truncate |
| Missing `flow: Down` in View-children mode | Horizontal layout | Add `flow: Down` explicitly |
| Depending on HTTP event bridge | Events lost/unreliable | Use `on_click:` handlers in Splash |
| `width: Fill` on Button | Hit-test may fail | Use fixed `width: 80 height: 36` |
