---
name: makepad-patterns
description: Reusable patterns for Makepad widget development, data management, and async architecture.
globs: _base/*.md, community/*.md
---

# Patterns

Proven patterns for building robust Makepad applications.

## Widget Patterns

| Pattern | Description |
|---------|-------------|
| [Widget Extension](_base/01-widget-extension.md) | Extend widgets with helper traits |
| [Modal Overlay](_base/02-modal-overlay.md) | Popup dialogs and modals |
| [Collapsible](_base/03-collapsible.md) | Expandable sections |
| [List Template](_base/04-list-template.md) | Dynamic lists with iteration |
| [LRU View Cache](_base/05-lru-view-cache.md) | Cached view recycling |
| [Global Registry](_base/06-global-registry.md) | Singleton pattern for actions |
| [Radio Navigation](_base/07-radio-navigation.md) | Tab/panel selection |

## Data Patterns

| Pattern | Description |
|---------|-------------|
| [Async Loading](_base/08-async-loading.md) | Background data fetching |
| [Streaming Results](_base/09-streaming-results.md) | Incremental data display |
| [State Machine](_base/10-state-machine.md) | UI state management |
| [Theme Switching](_base/11-theme-switching.md) | Dynamic theming |
| [Local Persistence](_base/12-local-persistence.md) | File-based storage |

## Advanced Patterns

| Pattern | Description |
|---------|-------------|
| [Tokio Integration](_base/13-tokio-integration.md) | Async runtime architecture |
| [Callout Tooltip](_base/14-callout-tooltip.md) | Context-aware tooltips |
| [Hover Effect](_base/16-hover-effect.md) | Reliable hover states with instance variables |

## Community Patterns

| Pattern | Description |
|---------|-------------|
| [Custom 3D Widget](community/custom-3d-widget.md) | Reusable widget with custom GPU rendering (DrawMesh, geometry) |

See [community/](community/) for more community-contributed patterns.

To contribute your own pattern, use the template at [99-evolution/templates/pattern-template.md](../99-evolution/templates/pattern-template.md).

## Pattern Selection Guide

### For UI State

- **Simple toggle**: Use widget instance variables
- **Multiple states**: Use [State Machine](_base/10-state-machine.md)
- **Mutually exclusive**: Use [Radio Navigation](_base/07-radio-navigation.md)

### For Data

- **One-time fetch**: Use [Async Loading](_base/08-async-loading.md)
- **Incremental display**: Use [Streaming Results](_base/09-streaming-results.md)
- **Persist settings**: Use [Local Persistence](_base/12-local-persistence.md)

### For Performance

- **Large lists**: Use [List Template](_base/04-list-template.md)
- **Heavy views**: Use [LRU View Cache](_base/05-lru-view-cache.md)
- **Background work**: Use [Tokio Integration](_base/13-tokio-integration.md)

### For Custom Rendering

- **3D widgets**: Use [Custom 3D Widget](community/custom-3d-widget.md)
- **Custom geometry**: Create GeometryFields implementation with unique instance_id
- **Multiple meshes**: Use template pattern to share shaders across DrawMesh instances

## References

- [Robrix](https://github.com/project-robius/robrix) - Matrix chat client
- [Moly](https://github.com/moxin-org/moly) - AI model manager
