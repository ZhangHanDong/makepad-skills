# Pattern 16: Hover Effect with Instance Variables

<!-- Evolution: 2025-01-13 | source: mofa-studio | author: hover-effect-fix -->

Implement reliable hover effects on custom View widgets using shader instance variables.

## Problem

Direct color changes via `apply_over` don't work on RoundedView or View templates. When you try to change background colors dynamically for hover/selected states, the visual doesn't update even though the code executes.

## Solution

Use a custom shader with `instance` variables instead of direct color properties. This pattern is used by Makepad's built-in widgets like SectionHeader.

## live_design!

```rust
live_design! {
    use link::theme::*;
    use link::widgets::*;

    // Custom item with hover/selected effects
    HoverableItem = <View> {
        width: Fill, height: Fit
        padding: {left: 16, right: 16, top: 12, bottom: 12}
        show_bg: true
        cursor: Hand
        flow: Right
        align: {x: 0.0, y: 0.5}

        draw_bg: {
            // Instance variables - can be updated via apply_over
            instance hover: 0.0
            instance selected: 0.0
            instance dark_mode: 0.0

            fn pixel(self) -> vec4 {
                // Light mode colors
                let light_normal = (WHITE);
                let light_hover = #DAE6F9;     // Light blue hover
                let light_selected = #DBEAFE;   // Blue selected

                // Dark mode colors
                let dark_normal = (SLATE_800);
                let dark_hover = #334155;       // Slate-700
                let dark_selected = #1E3A5F;    // Blue-ish selected

                // Pick colors based on dark mode
                let normal = mix(light_normal, dark_normal, self.dark_mode);
                let hover_color = mix(light_hover, dark_hover, self.dark_mode);
                let selected_color = mix(light_selected, dark_selected, self.dark_mode);

                // Calculate final color: selected takes priority, then hover
                let base = mix(normal, hover_color, self.hover);
                return mix(base, selected_color, self.selected);
            }
        }

        // Child widgets go here
        item_label = <Label> {
            width: Fill
            draw_text: {
                text_style: <FONT_REGULAR>{ font_size: 12.0 }
                color: #383A40
            }
            text: "Item"
        }
    }
}
```

## Rust Implementation

```rust
impl Widget for MyWidget {
    fn handle_event(&mut self, cx: &mut Cx, event: &Event, scope: &mut Scope) {
        self.view.handle_event(cx, event, scope);

        // Define item paths
        let items = [
            ids!(item_1),
            ids!(item_2),
            ids!(item_3),
        ];

        // Handle hover for each item
        for (i, path) in items.iter().enumerate() {
            let item = self.view.view(*path);
            let area = item.area();

            match event.hits(cx, area) {
                Hit::FingerHoverIn(_) => {
                    // Check if this item is selected
                    let is_selected = self.selected_index == Some(i);
                    if !is_selected {
                        // Apply hover effect via instance variable
                        self.view.view(*path).apply_over(cx, live!{
                            draw_bg: { hover: 1.0 }
                        });
                        self.view.redraw(cx);
                    }
                }
                Hit::FingerHoverOut(_) => {
                    let is_selected = self.selected_index == Some(i);
                    if !is_selected {
                        // Remove hover effect
                        self.view.view(*path).apply_over(cx, live!{
                            draw_bg: { hover: 0.0 }
                        });
                        self.view.redraw(cx);
                    }
                }
                _ => {}
            }
        }
    }
}
```

## Selection Handling

```rust
impl MyWidget {
    fn select_item(&mut self, cx: &mut Cx, index: usize) {
        let items = [ids!(item_1), ids!(item_2), ids!(item_3)];

        // Reset all items
        for path in &items {
            self.view.view(*path).apply_over(cx, live!{
                draw_bg: { selected: 0.0, hover: 0.0 }
            });
        }

        // Apply selection to chosen item
        if index < items.len() {
            self.view.view(items[index]).apply_over(cx, live!{
                draw_bg: { selected: 1.0 }
            });
        }

        self.selected_index = Some(index);
        self.view.redraw(cx);
    }
}
```

## Dark Mode Support

```rust
impl MyWidgetRef {
    pub fn update_dark_mode(&self, cx: &mut Cx, dark_mode: f64) {
        if let Some(mut inner) = self.borrow_mut() {
            let items = [ids!(item_1), ids!(item_2), ids!(item_3)];

            for path in &items {
                inner.view.view(*path).apply_over(cx, live!{
                    draw_bg: { dark_mode: (dark_mode) }
                });
            }

            inner.view.redraw(cx);
        }
    }
}
```

## Key Points

1. **Use `<View>` not `<RoundedView>`** - Custom shaders work better with base View
2. **Instance variables** - Declare with `instance name: default_value`
3. **mix() function** - Use for smooth interpolation between states
4. **Priority order** - Selected should override hover (check order in shader)
5. **Always redraw** - Call `redraw(cx)` after `apply_over`

## Why This Works

- Instance variables are per-draw-call GPU values
- `apply_over` with instance variables directly updates shader uniforms
- Direct `color` property changes don't propagate to the GPU correctly on templates
- This matches how Makepad's built-in widgets handle hover states

## Common Mistakes

```rust
// WRONG - direct color won't update visually
self.view.view(path).apply_over(cx, live!{
    draw_bg: { color: #ff0000 }  // ❌ No effect
});

// CORRECT - instance variable updates work
self.view.view(path).apply_over(cx, live!{
    draw_bg: { hover: 1.0 }  // ✅ Works
});
```

## References

- [Troubleshooting: apply_over Color Not Working](../../06-reference/troubleshooting.md#apply_over-color-not-working-on-roundedviewview-templates)
- [Theme Switching Pattern](_base/11-theme-switching.md)
