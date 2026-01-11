---
name: makepad-code-quality
description: Makepad-aware code simplification and quality improvement. Understands Makepad-specific patterns that must NOT be simplified.
model: opus
---

# Makepad Code Quality

This guide helps you simplify and refactor Makepad code safely, understanding which patterns must be preserved.

## Core Principle

> **"Not all code that looks simplifiable should be simplified."**

In Makepad development, many patterns exist because of:
- Borrow checker constraints
- Widget lifecycle requirements
- live_design! macro limitations
- Unicode/grapheme correctness
- Cross-platform compatibility
- Performance optimization

---

## DO NOT Simplify (Makepad-Specific Patterns)

### 1. Borrow Checker Workarounds

These temporary variables exist to avoid borrow conflicts:

```rust
// ❌ DON'T simplify this:
let toggle_code: Option<String> = {
    let items = self.get_items();
    items.first().cloned()
};  // borrow ends here
if let Some(code) = toggle_code {
    self.toggle_item(&code);  // now safe to mutate
}

// ❌ INTO this (will cause borrow error):
if let Some(code) = self.get_items().first() {
    self.toggle_item(&code);  // ERROR: cannot borrow mutably
}
```

**Rule**: If you see a pattern like `let x = { ... };` followed by usage of `x`, it likely exists to end a borrow scope. Keep it.

### 2. Grapheme-Based Text Operations

Never simplify grapheme operations to char operations:

```rust
// ❌ DON'T simplify this:
use unicode_segmentation::UnicodeSegmentation;
text.graphemes(true).count()

// ❌ INTO this (breaks CJK and emoji):
text.chars().count()
```

**Rule**: Any code using `.graphemes(true)` is intentionally handling Unicode correctly. Never replace with `.chars()` or `.len()`.

### 3. Explicit cx Parameter Passing

The `cx` parameter must be explicitly passed:

```rust
// ❌ DON'T think this is redundant:
label.set_text(cx, "text");
label.redraw(cx);

// ❌ DON'T try to "simplify" by removing cx
```

**Rule**: `cx: &mut Cx` is the Makepad context and must always be passed explicitly.

### 4. Separate redraw() Calls

Redraw calls after state changes are intentional:

```rust
// ❌ DON'T remove redraw thinking it's automatic:
self.counter += 1;
self.ui.label(id!(counter)).set_text(cx, &format!("{}", self.counter));
self.ui.redraw(cx);  // KEEP THIS
```

**Rule**: Always keep explicit `redraw(cx)` calls after UI updates.

### 5. Widget Lifecycle Attributes

These attributes serve specific purposes:

```rust
#[derive(Live, LiveHook, Widget)]
pub struct MyWidget {
    #[deref] view: View,        // Required for Widget delegation
    #[live] color: Vec4,        // DSL-configurable, hot-reloadable
    #[rust] counter: i32,       // Runtime-only state
    #[animator] animator: Animator,  // Animation state
}
```

**Rule**: Never remove or change `#[deref]`, `#[live]`, `#[rust]`, `#[animator]` attributes.

### 6. Timer Storage Pattern

Timer must be stored as a field:

```rust
// ❌ DON'T remove timer field thinking it's unused:
#[rust] refresh_timer: Timer,

fn handle_startup(&mut self, cx: &mut Cx) {
    self.refresh_timer = cx.start_interval(1.0);  // Must store result
}
```

**Rule**: `Timer` returned from `cx.start_interval()` must be stored, or timer won't work.

### 7. Platform-Specific Code

Conditional compilation blocks must remain separate:

```rust
// ❌ DON'T try to "combine" these:
#[cfg(target_os = "macos")]
{
    self.setup_macos_features(cx);
}

#[cfg(target_os = "windows")]
{
    self.setup_windows_features(cx);
}
```

**Rule**: `#[cfg(...)]` blocks are platform-specific and should remain explicit.

### 8. live_design! Macro Syntax

DSL has specific formatting requirements:

```rust
// ❌ DON'T "simplify" DSL structure:
live_design! {
    MyButton = <Button> {
        width: Fit
        height: 40
        padding: {left: 16, right: 16}

        draw_bg: {
            color: #2196F3
        }

        draw_text: {
            text_style: { font_size: 14.0 }
            color: #fff
        }
    }
}

// ❌ INTO single-line "compact" form
```

**Rule**: Keep live_design! blocks formatted with clear structure and whitespace.

---

## DO Simplify (Safe Improvements)

### 1. Redundant Clone/To_String

When ownership is not needed:

```rust
// ✅ CAN simplify:
let name = self.user.name.clone();
println!("{}", name);

// ✅ TO:
println!("{}", self.user.name);
```

### 2. Unnecessary Intermediate Variables

When borrow is not an issue:

```rust
// ✅ CAN simplify:
let x = 5;
let y = x + 10;
let z = y * 2;
result = z;

// ✅ TO:
result = (5 + 10) * 2;
```

### 3. Repeated Widget Lookups

Within same scope:

```rust
// ✅ CAN simplify:
self.ui.label(id!(my_label)).set_text(cx, "Hello");
self.ui.label(id!(my_label)).set_visible(true);
self.ui.label(id!(my_label)).redraw(cx);

// ✅ TO:
let label = self.ui.label(id!(my_label));
label.set_text(cx, "Hello");
label.set_visible(true);
label.redraw(cx);
```

### 4. Verbose Match Statements

When if-let is clearer:

```rust
// ✅ CAN simplify:
match self.state {
    Some(ref s) => {
        process(s);
    }
    None => {}
}

// ✅ TO:
if let Some(ref s) = self.state {
    process(s);
}
```

### 5. Duplicate Code in Branches

Extract common code:

```rust
// ✅ CAN simplify:
if condition {
    self.setup_common();
    self.setup_a();
    self.ui.redraw(cx);
} else {
    self.setup_common();
    self.setup_b();
    self.ui.redraw(cx);
}

// ✅ TO:
self.setup_common();
if condition {
    self.setup_a();
} else {
    self.setup_b();
}
self.ui.redraw(cx);
```

---

## Auto-Decision Matrix

| Pattern Type | Action | Confirm? |
|-------------|--------|----------|
| Borrow scope block `let x = {...};` | **Keep** | No |
| `.graphemes(true)` usage | **Keep** | No |
| `cx` parameter passing | **Keep** | No |
| `redraw(cx)` calls | **Keep** | No |
| `#[live]`/`#[rust]`/`#[deref]` | **Keep** | No |
| Timer storage pattern | **Keep** | No |
| `#[cfg(...)]` blocks | **Keep** | No |
| Cache `Option<(key,...)>` | **Keep** | No |
| Pure math simplification | Simplify | No |
| Obvious redundant clone | Simplify | No |
| Repeated widget lookup | Simplify | No |
| **Uncertain / Edge case** | **Ask** | **Yes** |

---

## Red Flags (Patterns to Investigate)

| Pattern | Likely Reason | Action |
|---------|--------------|--------|
| `let x = { ... };` block | Borrow scope | Keep unless proven safe |
| `.graphemes(true)` | Unicode correctness | Never simplify |
| `#[rust]` field | Runtime state | Keep, check usage |
| `Option<(String, ...)>` field | Cache pattern | Keep |
| Separate `#[cfg(...)]` blocks | Platform code | Keep separate |
| `cx.start_interval()` stored | Timer pattern | Must keep storage |
| `redraw(cx)` after update | UI refresh | Keep |

---

## Summary

| Category | Simplify? | Reason |
|----------|-----------|--------|
| Borrow scope blocks | ❌ No | Borrow checker |
| Grapheme operations | ❌ No | Unicode correctness |
| `cx` parameters | ❌ No | Makepad requirement |
| `redraw()` calls | ❌ No | UI lifecycle |
| Widget attributes | ❌ No | Macro requirements |
| Cache patterns | ❌ No | Performance |
| Platform `#[cfg]` | ❌ No | Cross-platform |
| Timer storage | ❌ No | Required for timer |
| Pure math/logic | ✅ Yes | Safe to simplify |
| Redundant clones | ✅ Yes | Safe to simplify |
| Repeated lookups | ✅ Yes | Safe to simplify |
| Verbose matches | ✅ Yes | Safe to simplify |
