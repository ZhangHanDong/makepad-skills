# Moly Widget Patterns

Additional widget patterns from Moly codebase.

## Slot Widget Pattern

A wrapper widget whose content can be replaced at runtime:

```rust
live_design! {
    use link::theme::*;
    use link::widgets::*;

    pub Slot = {{Slot}} {}
}

/// A wrapper widget whose content can be replaced from Rust.
#[derive(Live, Widget)]
pub struct Slot {
    #[wrap]
    wrap: WidgetRef,

    /// The default content defined in DSL
    #[live]
    default: WidgetRef,
}

impl Widget for Slot {
    fn draw_walk(&mut self, cx: &mut Cx2d, scope: &mut Scope, walk: Walk) -> DrawStep {
        self.wrap.draw_walk(cx, scope, walk)
    }

    fn handle_event(&mut self, cx: &mut Cx, event: &Event, scope: &mut Scope) {
        self.wrap.handle_event(cx, event, scope)
    }
}

impl LiveHook for Slot {
    fn after_new_from_doc(&mut self, _cx: &mut Cx) {
        self.wrap = self.default.clone();
    }
}

impl Slot {
    /// Replace the current widget with a new one.
    pub fn replace(&mut self, widget: WidgetRef) {
        self.wrap = widget;
    }

    /// Restore the default/original widget.
    pub fn restore(&mut self) {
        self.wrap = self.default.clone();
    }

    /// Get the current widget.
    pub fn current(&self) -> WidgetRef {
        self.wrap.clone()
    }
}

// Usage in DSL:
live_design! {
    ChatLine = <View> {
        content = <Slot> {
            default: <StandardMessageContent> {}
        }
    }
}

// Runtime replacement:
let slot = self.slot(ids!(content));
slot.replace(custom_widget);  // Replace with custom
slot.restore();               // Restore to default
```

## Conditional Root Wrapper Pattern

Prevent rendering until state is ready:

```rust
#[derive(Live, Widget, LiveHook)]
pub struct MolyRoot {
    #[deref]
    view: View,
}

impl Widget for MolyRoot {
    fn draw_walk(&mut self, cx: &mut Cx2d, scope: &mut Scope, walk: Walk) -> DrawStep {
        // Don't render if Store isn't loaded
        if scope.data.get::<Store>().is_none() {
            return DrawStep::done();
        }
        self.view.draw_walk(cx, scope, walk)
    }

    fn handle_event(&mut self, cx: &mut Cx, event: &Event, scope: &mut Scope) {
        // Don't handle events if Store isn't loaded
        if scope.data.get::<Store>().is_none() {
            return;
        }
        self.view.handle_event(cx, event, scope);
    }
}

// Usage in App:
live_design! {
    App = {{App}} {
        ui: <Window> {
            body = {
                flow: Overlay

                // Loading view shown first
                loading_view = <View> {
                    <Label> { text: "Loading..." }
                }

                // Root only renders when ready
                root = {{MolyRoot}} {
                    // Main app content
                }
            }
        }
    }
}
```

## AdaptiveView Pattern

Responsive layouts for different screen sizes:

```rust
live_design! {
    App = {{App}} {
        ui: <Window> {
            body = {
                root = <View> {
                    root_adaptive_view = <AdaptiveView> {
                        Mobile = {
                            application_pages = <ApplicationPages> {
                                margin: 0  // Full width on mobile
                            }
                        }

                        Desktop = {
                            sidebar_menu = <SidebarMenu> {}
                            application_pages = <ApplicationPages> {
                                margin: {top: 12, right: 12, bottom: 12}
                            }
                        }
                    }
                }
            }
        }
    }
}
```

## Chat Line Variants Pattern

Different styled variants for message types:

```rust
live_design! {
    // Base chat line
    pub ChatLine = <RoundedView> {
        flow: Down,
        height: Fit,
        margin: {left: 10, right: 10}

        message_section = <RoundedView> {
            sender = <Sender> {}
            content_section = <View> {
                content = <Slot> { default: <StandardMessageContent> {} }
            }
        }
        actions_section = <View> {
            actions = <Actions> { visible: false }
        }
    }

    // User message variant
    pub UserLine = <ChatLine> {
        message_section = {
            sender = {
                avatar = {
                    grapheme = {
                        draw_bg: { color: #008F7E }
                    }
                }
            }
        }
    }

    // Bot message variant
    pub BotLine = <ChatLine> {}

    // Loading state variant
    pub LoadingLine = <BotLine> {
        message_section = {
            content_section = <View> {
                loading = <MessageLoading> {}
            }
        }
    }

    // Error variant
    pub ErrorLine = <ChatLine> {
        message_section = {
            draw_bg: {color: #f003}
        }
    }

    // System message variant
    pub SystemLine = <ChatLine> {
        message_section = {
            draw_bg: {color: #e3f2fd}
            sender = {
                name = {text: "System"}
            }
        }
    }
}
```

## CommandTextInput Pattern

Text input with attached action buttons:

```rust
live_design! {
    pub PromptInput = {{PromptInput}} <CommandTextInput> {
        send_icon: dep("crate://self/resources/send.svg"),
        stop_icon: dep("crate://self/resources/stop.svg"),

        persistent = {
            center = {
                left = {
                    attach = <Button> { visible: false }
                }
                text_input = {
                    empty_text: "Start typing...",
                }
                right = {
                    audio = <Button> { visible: false }
                    submit = <Button> {
                        // Circular submit button
                    }
                }
            }
            bottom = {
                attachments = <AttachmentList> {}
            }
        }
    }
}

#[derive(Live, Widget)]
pub struct PromptInput {
    #[deref]
    deref: CommandTextInput,

    #[live]
    pub send_icon: LiveValue,

    #[live]
    pub stop_icon: LiveValue,

    #[rust]
    pub task: Task,  // Send or Stop

    #[rust]
    pub interactivity: Interactivity,

    #[rust]
    pub bot_capabilities: Option<BotCapabilities>,
}

impl PromptInput {
    fn update_button_visibility(&mut self, cx: &mut Cx) {
        let can_attach = self.bot_capabilities
            .as_ref()
            .map(|c| c.accepts_images())
            .unwrap_or(false);

        self.button(ids!(attach)).set_visible(cx, can_attach);
    }
}
```

## Popup Notification Pattern

Global popup notifications:

```rust
live_design! {
    App = {{App}} {
        ui: <Window> {
            body = {
                flow: Overlay

                // Main content
                main_content = <View> { }

                // Popups overlay
                download_popup = <PopupNotification> {
                    content: {
                        popup_download_notification = <DownloadNotificationPopup> {}
                    }
                }

                server_popup = <PopupNotification> {
                    content: {
                        popup_server = <ServerPopup> {}
                    }
                }
            }
        }
    }
}

// Opening/closing popups from actions:
if let ServerPopupAction::CloseButtonClicked = action.cast() {
    self.ui.popup_notification(id!(server_popup)).close(cx);
}

if let ServerAction::Unreachable = action.cast() {
    self.ui.popup_notification(id!(server_popup)).open(cx);
}
```

## Sidebar Navigation Pattern

Tab-based navigation with radio buttons:

```rust
live_design! {
    SidebarMenu = <RoundedView> {
        width: 90, height: Fill,
        flow: Down, spacing: 15.0,
        padding: { top: 40, bottom: 20 },
        align: {x: 0.5, y: 0.5},

        logo = <Image> { }

        chat_tab = <SidebarMenuButton> {
            animator: {active = {default: on}}
            text: "Chat",
        }
        settings_tab = <SidebarMenuButton> {
            text: "Settings",
        }

        <HorizontalFiller> {}

        providers_tab = <SidebarMenuButton> {
            text: "Providers",
        }
    }
}

// Handle tab selection:
impl App {
    fn handle_actions(&mut self, cx: &mut Cx, actions: &Actions) {
        let radio_set = self.ui.radio_button_set(ids!(
            sidebar_menu.chat_tab,
            sidebar_menu.settings_tab,
            sidebar_menu.providers_tab,
        ));

        if let Some(selected) = radio_set.selected(cx, actions) {
            match selected {
                0 => self.navigate_to(cx, id!(chat_frame)),
                1 => self.navigate_to(cx, id!(settings_frame)),
                2 => self.navigate_to(cx, id!(providers_frame)),
                _ => {}
            }
        }
    }

    fn navigate_to(&mut self, cx: &mut Cx, target: &[LiveId]) {
        // Hide all frames
        self.ui.widget(id!(chat_frame)).set_visible(cx, false);
        self.ui.widget(id!(settings_frame)).set_visible(cx, false);
        self.ui.widget(id!(providers_frame)).set_visible(cx, false);

        // Show target frame
        self.ui.widget(target).set_visible(cx, true);
    }
}
```
