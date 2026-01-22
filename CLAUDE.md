# Makepad Skills - Claude Instructions

## Skill Routing

For Makepad/Robius/MolyKit questions, route based on keywords:

### Makepad Core

| Keywords | Skill |
|----------|-------|
| getting started, app structure, `live_design!`, `app_main!` | makepad-basics |
| DSL syntax, inheritance, prototype, `<Widget>`, `Foo = { }` | makepad-dsl |
| layout, width, height, Flow, Walk, Size, Padding, Alignment | makepad-layout |
| View, Button, Label, TextInput, Image, ScrollView, widget | makepad-widgets |
| event, action, Hit, FingerDown, KeyDown, handle_event | makepad-event-action |
| animation, animator, state, transition, hover, pressed | makepad-animation |
| shader, draw_bg, Sdf2d, GPU, pixel, GLSL | makepad-shaders |
| platform, macOS, Windows, Linux, iOS, Android, WASM | makepad-platform |
| font, text, glyph, typography, text layout | makepad-font |
| splash, script, dynamic, AI, scripting | makepad-splash |

### Robius Patterns

| Keywords | Skill |
|----------|-------|
| app architecture, Tokio, async/sync, runtime | robius-app-architecture |
| widget patterns, reusable, apply_over, TextOrImage | robius-widget-patterns |
| custom action, MatchEvent, handle_actions, cx.widget_action | robius-event-action |
| AppState, persistence, Scope::with_data, save/load state | robius-state-management |
| Matrix SDK, sliding sync, timeline, MatrixRequest | robius-matrix-integration |

### MolyKit

| Keywords | Skill |
|----------|-------|
| AI chat, BotClient, OpenAI, LLM, SSE streaming | molykit |
| PlatformSend, spawn(), ThreadToken, cross-platform async | molykit |
| Chat widget, Messages, PromptInput, Avatar | molykit |

## Usage Examples

### Makepad Basics
```
User: "How do I create a Makepad app?"
-> Load: makepad-basics
-> Answer with app_main!, live_design!, AppMain trait
```

### Layout Questions
```
User: "How do I center a widget in Makepad?"
-> Load: makepad-layout
-> Answer with Flow, align, Width::Fill, Height::Fill
```

### Event Handling
```
User: "How do I handle button clicks in Makepad?"
-> Load: makepad-event-action
-> Answer with Hit::FingerUp, cx.widget_action, Actions
```

### Robius App Architecture
```
User: "How does Robrix handle async Matrix operations?"
-> Load: robius-app-architecture + robius-matrix-integration
-> Answer with submit_async_request, MatrixRequest, Cx::post_action
```

### MolyKit Integration
```
User: "How do I implement SSE streaming in Makepad?"
-> Load: molykit
-> Answer with BotClient, BoxPlatformSendStream, parse_sse
```

## Key Patterns

### Makepad Widget Definition
```rust
#[derive(Live, LiveHook, Widget)]
pub struct MyWidget {
    #[deref] view: View,
    #[live] property: f64,
    #[rust] internal_state: State,
    #[animator] animator: Animator,
}
```

### Robius Async Pattern
```rust
// UI -> Async
submit_async_request(MatrixRequest::SendMessage { ... });

// Async -> UI
Cx::post_action(MessageSentAction { ... });
SignalToUI::set_ui_signal();
```

### MolyKit Cross-Platform Async
```rust
// Platform-agnostic spawning
spawn(async move {
    let result = fetch_data().await;
    Cx::post_action(DataReady(result));
    SignalToUI::set_ui_signal();
});
```

## Default Project Settings

When creating Makepad projects:

```toml
[package]
edition = "2024"

[dependencies]
makepad-widgets = "0.6"

[features]
default = []
nightly = ["makepad-widgets/nightly"]
```

## Source Codebases

For deeper reference, check these codebases:

- **Makepad**: `/path/to/makepad` - Framework source
- **Robrix**: `/path/to/robrix` - Matrix client example
- **Moly**: `/path/to/moly` - AI chat example
- **MolyKit**: `/path/to/moly/moly-kit` - AI chat toolkit
