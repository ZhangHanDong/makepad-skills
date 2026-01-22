# Moly Action Patterns

Additional action patterns from Moly codebase.

## Store-Based Action Handling

Moly uses a central Store that handles its own actions:

```rust
#[derive(Clone, DefaultNone, Debug)]
pub enum StoreAction {
    Search(String),
    ResetSearch,
    Sort(SortCriteria),
    None,
}

impl Store {
    pub fn handle_action(&mut self, action: &Action) {
        self.search.handle_action(action);
        self.downloads.handle_action(action);

        if let Some(_) = action.downcast_ref::<DownloadFileAction>() {
            self.update_downloads();
        }
    }
}

// In App::handle_actions:
impl MatchEvent for App {
    fn handle_actions(&mut self, cx: &mut Cx, actions: &Actions) {
        for action in actions.iter() {
            // Forward all actions to Store
            self.store.as_mut().unwrap().handle_action(action);

            // Handle app-level actions
            match action.cast() {
                StoreAction::Search(keywords) => {
                    self.store.as_mut().unwrap().search.load_search_results(keywords);
                }
                StoreAction::ResetSearch => {
                    self.store.as_mut().unwrap().search.load_featured_models();
                }
                _ => {}
            }
        }
    }
}
```

## Domain-Specific Action Enums

Organize actions by domain:

```rust
// Chat domain actions
#[derive(Clone, DefaultNone, Debug)]
pub enum ChatAction {
    StartWithoutEntity,
    Start(BotId),
    ChatSelected(ChatID),
    None,
}

// Download domain actions
#[derive(Clone, DefaultNone, Debug)]
pub enum DownloadAction {
    Play(FileID),
    Pause(FileID),
    Cancel(FileID),
    None,
}

// Navigation actions
#[derive(Clone, DefaultNone, Debug)]
pub enum NavigationAction {
    NavigateToProviders,
    NavigateToMyModels,
    None,
}

// Popup actions
#[derive(Clone, DefaultNone, Debug)]
pub enum DownloadNotificationPopupAction {
    ActionLinkClicked,
    CloseButtonClicked,
    None,
}
```

## Timer-Based Retry Pattern

Using timers for retry logic:

```rust
#[derive(Live, LiveHook)]
pub struct App {
    #[live]
    pub ui: WidgetRef,

    #[rust]
    timer: Timer,

    #[rust]
    retry_attempts: usize,

    #[rust]
    pending_file_id: Option<FileID>,
}

impl AppMain for App {
    fn handle_event(&mut self, cx: &mut Cx, event: &Event) {
        // Check if timer fired
        if self.timer.is_event(event).is_some() {
            if let Some(file_id) = &self.pending_file_id {
                // Retry the operation
                self.store.as_mut().unwrap().downloads.retry(file_id);
                self.ui.redraw(cx);
            }
        }

        // ... rest of event handling
    }
}

impl App {
    fn start_retry_timeout(&mut self, cx: &mut Cx, file: File) {
        match self.retry_attempts {
            0 => {
                self.timer = cx.start_timeout(15.0);
                self.retry_attempts += 1;
            }
            1 => {
                self.timer = cx.start_timeout(30.0);
                self.retry_attempts += 1;
            }
            2 => {
                self.timer = cx.start_timeout(60.0);
                self.retry_attempts += 1;
            }
            _ => {
                // Max retries reached
                self.show_error(cx, &file);
                self.retry_attempts = 0;
            }
        }
    }
}
```

## Radio Button Navigation Pattern

Using radio buttons for tab navigation:

```rust
impl MatchEvent for App {
    fn handle_actions(&mut self, cx: &mut Cx, actions: &Actions) {
        let mut navigate_to_chat = false;
        let mut navigate_to_settings = false;
        let mut navigate_to_providers = false;

        // Create radio button set
        let radio_button_set = self.ui.radio_button_set(ids!(
            sidebar_menu.chat_tab,
            sidebar_menu.settings_tab,
            sidebar_menu.providers_tab,
        ));

        // Check which tab was selected
        if let Some(selected_tab) = radio_button_set.selected(cx, actions) {
            match selected_tab {
                0 => navigate_to_chat = true,
                1 => navigate_to_settings = true,
                2 => navigate_to_providers = true,
                _ => {}
            }
        }

        // Process other actions...
        for action in actions.iter() {
            // Auto-select chat tab when starting a new chat
            if let ChatAction::Start(_) = action.cast() {
                let chat_button = self.ui.radio_button(id!(chat_tab));
                chat_button.select(cx, &mut Scope::empty());
            }

            // Handle navigation action from anywhere
            if let NavigationAction::NavigateToProviders = action.cast() {
                let providers_button = self.ui.radio_button(id!(providers_tab));
                providers_button.select(cx, &mut Scope::empty());
                navigate_to_providers = true;
            }
        }

        // Execute navigation after processing all actions
        if navigate_to_providers {
            self.navigate_to(cx, id!(providers_frame));
        } else if navigate_to_chat {
            self.navigate_to(cx, id!(chat_frame));
        } else if navigate_to_settings {
            self.navigate_to(cx, id!(settings_frame));
        }
    }
}
```

## External Link Action Pattern

Handle link clicks to open external URLs:

```rust
use markdown::MarkdownAction;

impl MatchEvent for App {
    fn handle_actions(&mut self, cx: &mut Cx, actions: &Actions) {
        for action in actions.iter() {
            // Handle markdown link clicks
            if let MarkdownAction::LinkNavigated(url) = action.as_widget_action().cast() {
                // Open external link using robius-open
                let _ = robius_open::Uri::new(&url).open();
            }
        }
    }
}
```

## Conditional Feature Actions

Platform-specific action handling:

```rust
impl MatchEvent for App {
    fn handle_actions(&mut self, cx: &mut Cx, actions: &Actions) {
        let radio_button_set;

        // Different tab sets for different platforms
        #[cfg(not(target_arch = "wasm32"))]
        {
            radio_button_set = self.ui.radio_button_set(ids!(
                sidebar_menu.chat_tab,
                sidebar_menu.local_tab,
                sidebar_menu.mcp_tab,      // MCP only on native
                sidebar_menu.providers_tab,
            ));
            // Show MCP tab on native
            self.ui.view(id!(sidebar_menu.mcp_tab_container))
                .set_visible(cx, true);
        }

        #[cfg(target_arch = "wasm32")]
        {
            radio_button_set = self.ui.radio_button_set(ids!(
                sidebar_menu.chat_tab,
                sidebar_menu.local_tab,
                sidebar_menu.providers_tab,
            ));
            // Hide MCP tab on WASM
            self.ui.view(id!(sidebar_menu.mcp_tab_container))
                .set_visible(cx, false);
        }

        if let Some(selected_tab) = radio_button_set.selected(cx, actions) {
            #[cfg(not(target_arch = "wasm32"))]
            match selected_tab {
                0 => self.navigate_to(cx, id!(chat_frame)),
                1 => self.navigate_to(cx, id!(local_frame)),
                2 => self.navigate_to(cx, id!(mcp_frame)),
                3 => self.navigate_to(cx, id!(providers_frame)),
                _ => {}
            }

            #[cfg(target_arch = "wasm32")]
            match selected_tab {
                0 => self.navigate_to(cx, id!(chat_frame)),
                1 => self.navigate_to(cx, id!(local_frame)),
                2 => self.navigate_to(cx, id!(providers_frame)),
                _ => {}
            }
        }
    }
}
```

## UiRunner Event Handling

Using UiRunner in AppMain:

```rust
impl AppMain for App {
    fn handle_event(&mut self, cx: &mut Cx, event: &Event) {
        // Handle UiRunner deferred callbacks first
        self.ui_runner()
            .handle(cx, event, &mut Scope::empty(), self);

        // Handle startup
        if let Event::Startup = event {
            self.ui.view(id!(body)).set_visible(cx, false);
            Store::load_into_app();  // Async store loading
        }

        // Early return if store not loaded
        let Some(store) = self.store.as_mut() else {
            self.ui.handle_event(cx, event, &mut Scope::empty());
            return;
        };

        // Pass store through scope
        let scope = &mut Scope::with_data(store);
        self.ui.handle_event(cx, event, scope);
        self.match_event(cx, event);
    }
}

// The UiRunner accessor
pub fn app_runner() -> UiRunner<App> {
    UiRunner::new(0)  // 0 is reserved for AppMain implementor
}
```
