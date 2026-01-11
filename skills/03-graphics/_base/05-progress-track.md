---
name: progress-track
author: robius
source: makepad-docs
date: 2024-01-01
tags: [sdf, progress, slider, track]
level: intermediate
---

# Progress & Track Shapes

Progress bars, sliders, and partial fills.

## Progress Bar with Partial Fill

Use `step()` instead of `if` for conditional fill:

```rust
draw_bg: {
    instance progress: 0.0  // 0.0 to 1.0

    fn pixel(self) -> vec4 {
        let sdf = Sdf2d::viewport(self.pos * self.rect_size);
        let sz = self.rect_size;
        let r = sz.y * 0.5;

        // Draw track (background capsule)
        sdf.circle(r, r, r);
        sdf.rect(r, 0.0, sz.x - sz.y, sz.y);
        sdf.circle(sz.x - r, r, r);

        let track_color = #e2e8f0;
        let fill_color = #3b82f6;

        sdf.fill(track_color);

        // Calculate fill region using step()
        let fill_end = sz.x * self.progress;
        let px = self.pos.x * sz.x;
        let in_fill = step(px, fill_end);

        // Draw fill shape
        let sdf2 = Sdf2d::viewport(self.pos * self.rect_size);
        sdf2.circle(r, r, r);
        sdf2.rect(r, 0.0, sz.x - sz.y, sz.y);
        sdf2.circle(sz.x - r, r, r);
        sdf2.fill(fill_color);

        return mix(sdf.result, sdf2.result, in_fill * sdf2.result.w);
    }
}
```

## Range Slider Track

For a slider with start and end values:

```rust
draw_track: {
    instance progress_start: 0.0
    instance progress_end: 0.0

    fn pixel(self) -> vec4 {
        let sdf = Sdf2d::viewport(self.pos * self.rect_size);
        let sz = self.rect_size;
        let r = sz.y * 0.5;

        // Draw track capsule
        sdf.circle(r, r, r);
        sdf.rect(r, 0.0, sz.x - sz.y, sz.y);
        sdf.circle(sz.x - r, r, r);
        sdf.fill(#e2e8f0);

        // Calculate fill region between start and end
        let fill_start = sz.x * self.progress_start;
        let fill_end = sz.x * self.progress_end;
        let px = self.pos.x * sz.x;

        // Pixel is in fill if: start <= px <= end
        let in_fill = step(fill_start, px) * step(px, fill_end);

        // Draw fill
        let sdf2 = Sdf2d::viewport(self.pos * self.rect_size);
        sdf2.circle(r, r, r);
        sdf2.rect(r, 0.0, sz.x - sz.y, sz.y);
        sdf2.circle(sz.x - r, r, r);
        sdf2.fill(#3b82f6);

        return mix(sdf.result, sdf2.result, in_fill * sdf2.result.w);
    }
}
```

## Usage Example

```rust
live_design! {
    ProgressBar = {{ProgressBar}} {
        width: Fill, height: 8
        show_bg: true
        draw_bg: {
            instance progress: 0.5
            // ... shader code above
        }
    }
}
```

Update progress in Rust:

```rust
impl ProgressBar {
    pub fn set_progress(&mut self, cx: &mut Cx, value: f64) {
        self.draw_bg.apply_over(cx, live!{
            progress: (value)
        });
        self.redraw(cx);
    }
}
```

## When to Use

- Use for progress bars, loading indicators
- Use for slider tracks with highlighted regions
- Use `step()` for GPU-friendly conditional rendering
- Use dual SDF for overlaid fill regions
