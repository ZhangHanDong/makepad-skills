---
name: makepad-reference
description: Reference materials for Makepad development including troubleshooting, code quality guidelines, and responsive layout patterns.
---

# Makepad Reference

This category provides reference materials for debugging, code quality, and advanced layout patterns.

## Quick Navigation

| Topic | File | Use When |
|-------|------|----------|
| [Troubleshooting](./troubleshooting.md) | Common errors and fixes | Build fails, runtime errors |
| [Code Quality](./code-quality.md) | Makepad-aware refactoring | Simplifying code safely |
| [Adaptive Layout](./adaptive-layout.md) | Desktop/mobile responsive | Cross-platform layouts |

## Common Issues Quick Reference

| Error | Quick Fix |
|-------|-----------|
| `no matching field: font` | Use `text_style: <THEME_FONT_*>{}` |
| Color parse error (ends in `e`) | Change last digit (e.g., `#14141e` → `#14141f`) |
| `set_text` missing argument | Add `cx` as first argument |
| UI not updating | Call `redraw(cx)` after changes |
| Widget not found | Check ID spelling, use `ids!()` for paths |

## Debug Tips

```bash
# Run with line info for better error messages
MAKEPAD=lines cargo +nightly run
```

```rust
// Add logging
log!("Value: {:?}", my_value);
log!("State: {} / {}", self.counter, self.is_loading);
```

## Resources

- [Makepad Repository](https://github.com/makepad/makepad)
- [Robrix](https://github.com/project-robius/robrix) - Production reference
- [Moly](https://github.com/moxin-org/moly) - Production reference
