---
name: makepad-troubleshooting
description: Debug and fix common Makepad compilation errors and runtime issues.
---

# Troubleshooting

## Compilation Errors

### Color Format Error

```
error: expected at least one digit in exponent
   --> src/app.rs:280:33
    |
280 |     color: #14141e
    |            ^^^^^^
```

**Cause**: Hex colors ending with `e` are parsed as scientific notation.

**Fix**: Avoid colors ending with `e`:
```rust
// Bad
color: #14141e

// Good
color: #141420
color: #14141f
```

---

### set_text Missing cx Parameter

```
error[E0061]: this method takes 2 arguments but 1 argument was supplied
   --> src/app.rs:477:16
    |
477 |         label.set_text("Hello");
    |               ^^^^^^^^ argument #1 of type `&mut Cx` is missing
```

**Fix**: Always pass `cx` as first argument:
```rust
// Bad
label.set_text("Hello");

// Good
label.set_text(cx, "Hello");
```

---

### Module Path Error

```
error[E0433]: failed to resolve: could not find `makepad_widgets` in the crate root
   --> src/app.rs:467:16
    |
467 |         crate::makepad_widgets::live_design(cx);
    |                ^^^^^^^^^^^^^^^ could not find
```

**Fix**: `makepad_widgets` is an external crate:
```rust
// Bad
crate::makepad_widgets::live_design(cx);

// Good
makepad_widgets::live_design(cx);
```

---

### TextInput Invalid Properties

```
Apply error: no matching field: empty_message
Apply error: no matching field: draw_select
```

**Fix**: Use correct TextInput properties:
```rust
// Bad
amount_input = <TextInput> {
    empty_message: "Enter value"  // doesn't exist
    draw_select: { color: #00ff8844 }  // doesn't exist
}

// Good
amount_input = <TextInput> {
    text: "1000"  // use text for default value

    draw_bg: { color: #1a1a26 }
    draw_text: { color: #00ff88 }
    draw_cursor: { color: #00ff88 }
}
```

---

<!-- Evolution: 2025-01-13 | source: mofa-studio | author: text-selection-fix -->
### TextInput Selection Stealing Focus / Conflicts

**Symptom**: Multiple TextInput widgets cause focus conflicts, selected text appears in wrong fields, or text selection behaves erratically when switching between views or panels.

**Causes**:
1. Hidden TextInputs still receiving events
2. Multiple TextInputs competing for selection state
3. TextInput in conditionally visible views maintaining selection

**Fix 1**: Add visibility checks before processing events
```rust
// In handle_event, check visibility before processing TextInput
fn handle_event(&mut self, cx: &mut Cx, event: &Event, scope: &mut Scope) {
    // Only process events for visible TextInputs
    if self.view.view(id!(text_container)).is_visible() {
        let text_input = self.view.text_input(id!(my_input));
        // Process text input events
    }
}
```

**Fix 2**: Clear selection when hiding TextInput
```rust
// When hiding a panel with TextInput
fn hide_panel(&mut self, cx: &mut Cx) {
    // Clear any active selection first
    self.view.text_input(id!(my_input)).apply_over(cx, live!{
        cursor: { head: 0, tail: 0 }
    });
    self.view.view(id!(panel)).set_visible(cx, false);
    self.view.redraw(cx);
}
```

**Fix 3**: Simplify TextInput definitions - avoid complex nested styling
```rust
// AVOID - complex nested TextInput
my_input = <TextInput> {
    draw_bg: {
        instance focus: 0.0
        fn pixel(self) -> vec4 {
            // Complex shader
        }
    }
    draw_selection: { /* complex */ }
    draw_cursor: { /* complex */ }
}

// BETTER - simple TextInput definition
my_input = <TextInput> {
    width: Fill, height: Fit
    text: ""
    draw_text: {
        text_style: <FONT_REGULAR>{ font_size: 12.0 }
        color: #333
    }
}
```

**Fix 4**: Use separate widget IDs and avoid reusing TextInput templates
```rust
// AVOID - reusing same template across dynamic items
for i in 0..items.len() {
    // Each item uses same text_input template - causes conflicts
}

// BETTER - static unique IDs for each TextInput
input_1 = <TextInput> { /* ... */ }
input_2 = <TextInput> { /* ... */ }
input_3 = <TextInput> { /* ... */ }
```

---

### Font Field Not Found

```
Apply error: no matching field: font
WARNING: encountered empty font family
```

**Cause**: The `font:` property doesn't exist. Makepad uses `text_style:` with theme fonts.

**Fix**: Use `text_style` with inline properties or theme font inheritance:
```rust
// WRONG - font property doesn't exist
<Label> {
    draw_text: {
        font: "path/to/font.ttf"  // ❌ Error: no matching field
        font_size: 14.0           // ❌ Error: no matching field
    }
}

// CORRECT - Option 1: inline text_style
<Label> {
    draw_text: {
        text_style: { font_size: 12.0 }
        color: #000
    }
}

// CORRECT - Option 2: inherit from theme font
<Label> {
    draw_text: {
        text_style: <THEME_FONT_REGULAR>{ font_size: 12.0 }
        color: #000
    }
}
```

**Available Theme Fonts**:
```rust
// Import in live_design!
use link::theme::*;

// Theme font options:
THEME_FONT_LABEL     // Default label font
THEME_FONT_REGULAR   // Regular weight
THEME_FONT_BOLD      // Bold weight
THEME_FONT_ITALIC    // Italic style
THEME_FONT_BOLD_ITALIC
THEME_FONT_CODE      // Monospace for code
```

---

### Button Invalid Properties

```
Apply error: no matching field: color_pressed
```

**Fix**: Button's draw_bg doesn't have `color_pressed`:
```rust
// Bad
draw_bg: {
    color: #2a2a38
    color_hover: #3a3a4a
    color_pressed: #00ff8855  // doesn't exist
}

// Good
draw_bg: {
    color: #2a2a38
    color_hover: #3a3a4a
    // Use animator for pressed state instead
}
```

---

### WidgetRef Method Not Found

```
error[E0599]: no method named `rounded_view` found for struct `WidgetRef`
```

**Fix**: Use `view()` for all View-based widgets:
```rust
// Bad
self.ui.rounded_view(id!(my_panel))

// Good
self.ui.view(id!(my_panel))
```

---

### Timer Method Not Found

```
error[E0599]: no method named `timer_id` found for struct `Timer`
```

**Fix**: Don't check timer_id, handle directly:
```rust
// Bad
fn handle_timer(&mut self, cx: &mut Cx, event: &TimerEvent) {
    if event.timer_id == self.my_timer.timer_id() {
        // ...
    }
}

// Good
fn handle_timer(&mut self, cx: &mut Cx, _event: &TimerEvent) {
    // Handle directly - timer events come to the app that started them
    self.on_timer_tick(cx);
}
```

---

## Borrow Checker Issues

### Immutable/Mutable Borrow Conflict

```
error[E0502]: cannot borrow `*self` as mutable because it is also borrowed as immutable
    |
    |     let items = self.get_items();  // immutable borrow
    |                 ---- immutable borrow occurs here
    |     self.modify_item(&code);       // mutable borrow - conflict!
    |     ^^^^^^^^^^^^^^^^^^^ mutable borrow occurs here
```

**Fix**: Separate borrow scopes:
```rust
// Bad
let sorted = self.get_sorted_items();
for item in sorted.iter() {
    self.toggle_item(item);  // Conflict!
}

// Good - collect first, then modify
let item_to_toggle: Option<String> = {
    let sorted = self.get_sorted_items();
    sorted.first().cloned()
};  // Immutable borrow ends here

if let Some(item) = item_to_toggle {
    self.toggle_item(&item);  // Now safe
}
```

### Pattern for Action Handling

```rust
// Bad - borrow conflict in action handling
for (i, card_id) in card_ids.iter().enumerate() {
    let card = self.ui.view(*card_id);
    if card.button(id!(fav_btn)).clicked(&actions) {
        self.toggle_favorite(&currencies[i].code);  // Conflict!
    }
}

// Good - collect action first, then handle
let mut toggle_code: Option<String> = None;
{
    let sorted_currencies = self.get_sorted_currencies();
    for (i, card_id) in card_ids.iter().enumerate() {
        if i < sorted_currencies.len() {
            let card = self.ui.view(*card_id);
            if card.button(id!(fav_btn)).clicked(&actions) {
                toggle_code = Some(sorted_currencies[i].code.to_string());
                break;
            }
        }
    }
}  // Borrow ends

if let Some(code) = toggle_code {
    self.toggle_favorite(&code);
    self.update_cards(cx);
}
```

---

## Apply Errors

### Property Not Found

```
Apply error: no matching field: some_property
```

**Causes & Fixes**:

1. **Typo in property name** - Check spelling
2. **Wrong widget type** - Verify the widget supports that property
3. **Property in wrong section** - Move to correct section

```rust
// Bad - color in wrong place
<Button> {
    color: #ff0000  // Button doesn't have top-level color
}

// Good
<Button> {
    draw_bg: {
        color: #ff0000
    }
}
```

---

### Wrong Value Type

```
Apply error: expected number, found string
```

**Fix**: Use correct value types:
```rust
// Bad
width: "100"
padding: "16"

// Good
width: 100
padding: 16
```

---

## Shader Issues

### Instance Variable Not Updating

**Symptom**: Set instance variable with `set_uniform()` but shader doesn't change.

**Cause**: `set_uniform()` is for uniform variables, not instance variables.

**Fix**: Use `apply_over()` for instance variables:
```rust
// Bad - doesn't work for instance variables
self.draw_bg.set_uniform(cx, id!(progress), &[0.5]);

// Good - use apply_over for instance variables
self.draw_bg.apply_over(cx, live! {
    progress: (0.5)
});
```

---

<!-- Evolution: 2025-01-13 | source: mofa-studio | author: hover-effect-fix -->
### apply_over Color Not Working on RoundedView/View Templates

**Symptom**: Call `apply_over(cx, live!{ draw_bg: { color: (new_color) } })` on a RoundedView or View template widget, but the visual color never changes.

**Cause**: Direct `color` property changes via `apply_over` don't work reliably on widget templates. The issue occurs when trying to dynamically change background colors for hover/selected states.

**What Doesn't Work**:
```rust
// WRONG - This will NOT update the visual appearance
CustomItem = <RoundedView> {
    show_bg: true
    draw_bg: {
        border_radius: 0
        color: (WHITE)
    }
}

// In Rust - color never visually changes despite code executing
self.view.view(path).apply_over(cx, live!{
    draw_bg: { color: (hover_color) }  // ❌ No visual effect
});
```

**Fix**: Use a custom shader with `instance` variables instead of direct color:
```rust
// CORRECT - Use instance variables in custom shader
CustomItem = <View> {
    show_bg: true
    draw_bg: {
        instance hover: 0.0
        instance selected: 0.0
        instance dark_mode: 0.0

        fn pixel(self) -> vec4 {
            let normal = mix((WHITE), (SLATE_800), self.dark_mode);
            let hover_color = mix(#DAE6F9, #334155, self.dark_mode);
            let selected_color = mix(#DBEAFE, #1E3A5F, self.dark_mode);

            let base = mix(normal, hover_color, self.hover);
            return mix(base, selected_color, self.selected);
        }
    }
}

// In Rust - this WORKS
self.view.view(path).apply_over(cx, live!{
    draw_bg: { hover: 1.0 }  // ✅ Visual effect works
});
```

**Note**: This pattern is the same as how SectionHeader and other Makepad widgets implement hover effects.

---

### Shader If-Branch Not Working

**Symptom**: `if` statement in shader produces unexpected results or no effect.

**Cause**: GPU shaders handle branching differently; if-branches can cause issues.

**Fix**: Use `step()` and `mix()` instead of if-branches:
```rust
// Bad - if branch in shader may not work correctly
fn pixel(self) -> vec4 {
    if self.progress > 0.5 {
        return #ff0000;
    } else {
        return #0000ff;
    }
}

// Good - use step() for conditional logic
fn pixel(self) -> vec4 {
    let red = #ff0000;
    let blue = #0000ff;
    let condition = step(0.5, self.progress);  // 1.0 if progress >= 0.5, else 0.0
    return mix(blue, red, condition);
}
```

---

## Runtime Issues

### UI Not Updating

**Symptom**: Called `set_text()` but nothing changes.

**Fix**: Call `redraw()` after updates:
```rust
// Bad
label.set_text(cx, "New text");

// Good
label.set_text(cx, "New text");
label.redraw(cx);

// Or redraw entire UI
self.ui.redraw(cx);
```

---

### Widget Not Found

**Symptom**: `self.ui.label(id!(my_label))` returns empty widget.

**Causes**:

1. **ID mismatch** - Check spelling in live_design
2. **Wrong parent** - Widget might be nested
3. **Not in view hierarchy** - Widget not visible

**Fix**:
```rust
// If widget is nested
let parent = self.ui.view(id!(parent_view));
let label = parent.label(id!(my_label));

// Or use path
self.ui.label(ids!(parent_view.my_label))
```

---

### Network Request Not Firing

**Symptom**: `handle_network_responses` never called.

**Fix**: Check request ID and ensure proper setup:
```rust
// Request
fn fetch_data(&mut self, cx: &mut Cx) {
    let url = "https://api.example.com/data".to_string();
    let request = HttpRequest::new(url, HttpMethod::GET);
    cx.http_request(live_id!(my_request), request);  // Use live_id!
}

// Response - check same ID
fn handle_network_responses(&mut self, cx: &mut Cx, responses: &NetworkResponsesEvent) {
    for event in responses {
        if event.request_id == live_id!(my_request) {  // Same ID
            match &event.response {
                NetworkResponse::HttpResponse(response) => {
                    if let Some(body) = response.get_string_body() {
                        // Handle response
                    }
                }
                NetworkResponse::HttpRequestError(err) => {
                    log!("Error: {:?}", err);
                }
                _ => {}
            }
        }
    }
}
```

---

### Timer Not Working

**Symptom**: `handle_timer` never called.

**Fix**: Store timer reference and start correctly:
```rust
#[derive(Live, LiveHook)]
pub struct App {
    #[live] ui: WidgetRef,
    #[rust] my_timer: Timer,  // Must store the timer
}

impl MatchEvent for App {
    fn handle_startup(&mut self, cx: &mut Cx) {
        self.my_timer = cx.start_interval(1.0);  // Store result
    }

    fn handle_timer(&mut self, cx: &mut Cx, _event: &TimerEvent) {
        // Timer callback
    }
}
```

---

## Performance Issues

### Excessive Redraws

**Symptom**: UI stutters or high CPU usage.

**Fix**: Only redraw what's needed:
```rust
// Bad - redraw everything
self.ui.redraw(cx);

// Good - redraw specific widget
self.ui.label(id!(my_label)).redraw(cx);

// Good - batch updates then redraw once
self.update_multiple_labels(cx);
self.ui.view(id!(labels_container)).redraw(cx);
```

---

### apply_over Performance

**Symptom**: Slow updates when using apply_over.

**Fix**: Batch apply_over calls:
```rust
// Bad - multiple apply_over calls
for item in items {
    self.ui.label(id!(label)).apply_over(cx, live!{
        draw_text: { color: (color) }
    });
}

// Good - update once, redraw once
self.update_all_items(cx);
self.ui.redraw(cx);
```

---

## Tooltip Issues

### Tooltip Not Showing

**Symptom**: Called `show()` but tooltip doesn't appear.

**Causes & Fixes**:

1. **Missing action handler in app** - Tooltip actions must be handled globally:
```rust
// In app.rs handle_event or handle_actions
for action in cx.actions() {
    match action.as_widget_action().cast() {
        TooltipAction::HoverIn { text, widget_rect, options } => {
            self.ui.callout_tooltip(ids!(app_tooltip))
                .show_with_options(cx, &text, widget_rect, options);
        }
        TooltipAction::HoverOut => {
            self.ui.callout_tooltip(ids!(app_tooltip)).hide(cx);
        }
        _ => {}
    }
}
```

2. **Tooltip not in layout** - Add global tooltip to app root:
```rust
live_design! {
    App = {{App}} {
        ui: <Root> {
            main_content = <View> { /* app content */ }
            app_tooltip = <CalloutTooltip> {}  // Must be after main content
        }
    }
}
```

3. **Widget rect not available** - Ensure widget has been drawn:
```rust
// Bad - rect may be zero before first draw
let rect = self.draw_bg.area().rect(cx);

// Good - check if rect is valid
let rect = self.draw_bg.area().rect(cx);
if rect.size.x > 0.0 && rect.size.y > 0.0 {
    cx.widget_action(uid, path, TooltipAction::HoverIn { ... });
}
```

---

### Tooltip Arrow Points Wrong Direction

**Symptom**: Arrow doesn't point at target widget.

**Cause**: `target_pos` and `target_size` instance variables not set.

**Fix**: Pass all required shader instance variables:
```rust
tooltip.apply_over(cx, live! {
    content: {
        rounded_view = {
            draw_bg: {
                tooltip_pos: (tooltip_position)      // Tooltip top-left
                target_pos: (widget_rect.pos)        // Target top-left
                target_size: (widget_rect.size)      // Target dimensions
                callout_position: (callout_angle)    // 0/90/180/270
                expected_dimension_x: (tooltip_size.x)
            }
        }
    }
});
```

---

### Tooltip Goes Off Screen

**Symptom**: Tooltip appears partially outside window.

**Fix**: Implement edge detection with fallback:
```rust
fn calculate_position(
    options: &CalloutTooltipOptions,
    widget_rect: Rect,
    tooltip_size: DVec2,
    screen_size: DVec2,
) -> (DVec2, f64) {
    let mut pos = DVec2::default();
    let mut angle = 0.0;

    match options.position {
        TooltipPosition::Bottom => {
            pos.y = widget_rect.pos.y + widget_rect.size.y;
            // Flip if would go off bottom
            if pos.y + tooltip_size.y > screen_size.y {
                pos.y = widget_rect.pos.y - tooltip_size.y;
                angle = 180.0;  // Change arrow direction
            }
        }
        // ... other directions
    }

    // Clamp to screen bounds
    pos.x = pos.x.max(0.0).min(screen_size.x - tooltip_size.x);
    pos.y = pos.y.max(0.0).min(screen_size.y - tooltip_size.y);

    (pos, angle)
}
```

---

### Tooltip Flickers on Hover

**Symptom**: Tooltip appears and disappears rapidly.

**Cause**: Tooltip itself triggers HoverOut on target.

**Fix**: Handle both `FingerHoverIn` and `FingerHoverOver`:
```rust
match event.hits(cx, self.draw_bg.area()) {
    Hit::FingerHoverIn(_) | Hit::FingerHoverOver(_) => {
        // Both events should show tooltip
        cx.widget_action(uid, path, TooltipAction::HoverIn { ... });
    }
    Hit::FingerHoverOut(_) => {
        cx.widget_action(uid, path, TooltipAction::HoverOut);
    }
    _ => {}
}
```

---

### Tooltip Shows With Zero Size

**Symptom**: Tooltip appears as tiny dot or invisible.

**Cause**: `expected_dimension_x` is 0, shader skips drawing.

**Fix**: Get tooltip size after setting text:
```rust
pub fn show_with_options(&mut self, cx: &mut Cx, text: &str, ...) {
    let mut tooltip = self.view.tooltip(ids!(tooltip));

    // 1. Set text first
    tooltip.set_text(cx, text);

    // 2. Then get dimensions (text affects size)
    let tooltip_size = tooltip.view(ids!(rounded_view)).area().rect(cx).size;

    // 3. Check if size is valid
    if tooltip_size.x == 0.0 {
        // May need to wait for layout
        log!("Warning: tooltip size is zero");
        return;
    }

    // 4. Apply with valid dimensions
    tooltip.apply_over(cx, live! {
        content: { rounded_view = { draw_bg: {
            expected_dimension_x: (tooltip_size.x)
        }}}
    });
}
```

---

### Tooltip Persists After Widget Removed

**Symptom**: Tooltip stays visible after navigating away.

**Fix**: Hide tooltip on navigation/cleanup:
```rust
// When changing views
fn navigate_to(&mut self, cx: &mut Cx, screen: Screen) {
    // Hide any active tooltip first
    self.ui.callout_tooltip(ids!(app_tooltip)).hide(cx);

    // Then navigate
    self.current_screen = screen;
    self.ui.redraw(cx);
}
```

---

## Widget Overlay Issues

### DropDown Popup Not Appearing (Z-Order Conflict)

**Symptom**: DropDown button works but popup menu never appears, or Modal doesn't display over content.

**Cause**: Custom 3D rendering (using `DrawMesh`, `draw_3d_shape`, or `draw_abs`) draws directly to the GPU framebuffer, bypassing Makepad's overlay layer system. This causes:
- DropDown popup menus (which use `PopupMenuGlobal` on an overlay layer) to be drawn under the 3D content
- Modal dialogs to be invisible behind 3D viewports

**Affected widgets**:
- `DropDown` - popup uses `Overlay` layer
- `Modal` - content rendered on overlay
- `PopupMenu` - same overlay system
- Any widget using `PopupMenuGlobal`

**Workaround**: Hide the 3D viewport when showing overlay widgets:

```rust
// When opening modal - hide 3D viewport
if self.view.button(id!(open_btn)).clicked(&actions) {
    self.view.view(id!(viewport)).set_visible(cx, false);  // Hide 3D content
    self.view.modal(id!(my_modal)).open(cx);
}

// Robot selection - use buttons inside modal instead of dropdown
if self.view.button(id!(my_modal.robot_btn)).clicked(&actions) {
    // Handle selection
    self.view.modal(id!(my_modal)).close(cx);
    self.view.view(id!(viewport)).set_visible(cx, true);  // Restore 3D content
}

// Modal dismissed (click outside or Escape)
if self.view.modal(id!(my_modal)).dismissed(&actions) {
    self.view.view(id!(viewport)).set_visible(cx, true);  // Restore 3D content
}
```

**Alternative**: Use Buttons or RadioButtons instead of DropDown for selection when 3D content is present.

**Note**: Even placing a DropDown inside a Modal doesn't help - the nested overlay still conflicts with the 3D rendering. Use buttons for selection in modals over 3D viewports.

---

## Debugging Tips

### Enable Debug Output

```bash
# Run with line info for better error messages
MAKEPAD=lines cargo +nightly run
```

### Use log! Macro

```rust
log!("Value: {:?}", my_value);
log!("State: {} / {}", self.counter, self.is_loading);
```

### Check Event Flow

```rust
impl MatchEvent for App {
    fn handle_actions(&mut self, cx: &mut Cx, actions: &Actions) {
        log!("Actions received: {}", actions.len());

        if self.ui.button(id!(my_btn)).clicked(&actions) {
            log!("Button clicked!");
        }
    }
}
```

---

## Quick Reference

| Error Type | Common Cause | Quick Fix |
|------------|--------------|-----------|
| Color parse error | Color ends in `e` | Change last digit |
| Missing argument | `set_text` needs `cx` | Add `cx` parameter |
| Module not found | Wrong crate path | Use `makepad_widgets::` |
| No matching field: font | Using `font:` property | Use `text_style: <THEME_FONT_*>{}` |
| Empty font family | Missing text_style | Add `text_style: <THEME_FONT_REGULAR>{}` |
| No matching field | Property doesn't exist | Check widget docs |
| Borrow conflict | Mixed mutable/immutable | Separate borrow scopes |
| UI not updating | Missing redraw | Call `redraw(cx)` |
| Widget not found | Wrong ID or path | Check live_design IDs |
| Timer not firing | Timer not stored | Store in `#[rust]` field |
| Instance var not updating | Using set_uniform | Use apply_over instead |
| Shader if-branch fails | GPU branching issue | Use step()/mix() instead |
| Tooltip not showing | Missing action handler | Add TooltipAction handler in app |
| Tooltip arrow wrong | Missing target_pos/size | Pass all shader instance vars |
| Tooltip off screen | No edge detection | Implement position fallback |
| Tooltip flickers | Only HoverIn handled | Handle HoverIn + HoverOver |
| Tooltip zero size | Getting size before text | Set text first, then get size |
| DropDown not opening | Z-order conflict with 3D | Hide 3D viewport, use buttons |
| Modal invisible | Custom GPU drawing on top | set_visible(cx, false) on 3D view |
| apply_over color no effect | Direct color on templates | Use instance variables in shader |
| TextInput focus conflicts | Hidden inputs receiving events | Add visibility checks, clear selection |
