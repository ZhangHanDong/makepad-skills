# Moly State Management Patterns

Additional state management patterns from Moly codebase.

## Central Store Pattern

Moly uses a central Store struct containing all application state:

```rust
pub struct Store {
    pub search: Search,
    pub downloads: Downloads,
    pub chats: Chats,
    pub preferences: Preferences,
    pub bot_context: Option<BotContext>,
    moly_client: MolyClient,
    pub provider_syncing_status: ProviderSyncingStatus,
    pub provider_icons: Vec<LiveDependency>,
}
```

## Async Store Initialization

Load store asynchronously, then inject into App:

```rust
use crate::app::app_runner;
use moly_kit::utils::asynchronous::spawn;

impl Store {
    pub fn load_into_app() {
        spawn(async move {
            // Load preferences first
            let preferences = Preferences::load().await;

            // Initialize client
            let server_port = std::env::var("MOLY_SERVER_PORT")
                .ok()
                .and_then(|p| p.parse::<u16>().ok())
                .unwrap_or(8765);

            let moly_client = MolyClient::new(format!("http://localhost:{}", server_port));

            // Load chats with client
            let chats = Chats::load(moly_client.clone()).await;

            // Build store
            let mut store = Self {
                search: Search::new(moly_client.clone()),
                downloads: Downloads::new(moly_client.clone()),
                chats,
                moly_client,
                preferences,
                bot_context: None,
                provider_syncing_status: ProviderSyncingStatus::NotSyncing,
                provider_icons: vec![],
            };

            // Initialize store
            store.init_current_chat();
            store.sync_with_server();
            store.load_preference_connections();

            // Inject into App via UiRunner
            app_runner().defer(move |app, cx, _| {
                app.store = Some(store);
                app.ui.view(id!(body)).set_visible(cx, true);
                cx.redraw_all();
            });
        })
    }
}
```

## App State Check Pattern

Check if store is loaded before processing:

```rust
impl AppMain for App {
    fn handle_event(&mut self, cx: &mut Cx, event: &Event) {
        // Handle UiRunner callbacks
        self.ui_runner().handle(cx, event, &mut Scope::empty(), self);

        if let Event::Startup = event {
            self.ui.view(id!(body)).set_visible(cx, false);
            Store::load_into_app();
        }

        // If store not loaded, only handle Makepad events
        let Some(store) = self.store.as_mut() else {
            self.ui.handle_event(cx, event, &mut Scope::empty());
            return;
        };

        // Hide loading view once store is ready
        self.ui.view(id!(loading_view)).set_visible(cx, false);

        // Pass store through scope
        let scope = &mut Scope::with_data(store);
        self.ui.handle_event(cx, event, scope);
        self.match_event(cx, event);
    }
}
```

## Submodule State Management

Each domain has its own state manager:

```rust
// Search state
pub struct Search {
    client: MolyClient,
    pub featured_models: Vec<Model>,
    pub search_results: Vec<Model>,
    pub current_query: String,
}

impl Search {
    pub fn new(client: MolyClient) -> Self {
        Self {
            client,
            featured_models: vec![],
            search_results: vec![],
            current_query: String::new(),
        }
    }

    pub fn load_featured_models(&mut self) {
        let client = self.client.clone();
        spawn(async move {
            let models = client.get_featured_models().await;
            app_runner().defer(move |app, _, _| {
                let store = app.store.as_mut().unwrap();
                store.search.featured_models = models.unwrap_or_default();
            });
        });
    }

    pub fn handle_action(&mut self, action: &Action) {
        // Handle search-specific actions
    }
}

// Downloads state
pub struct Downloads {
    client: MolyClient,
    pub downloaded_files: Vec<File>,
    pub pending_downloads: Vec<PendingDownload>,
    pending_notifications: Vec<DownloadPendingNotification>,
}

impl Downloads {
    pub fn handle_action(&mut self, action: &Action) {
        // Handle download-specific actions
    }
}
```

## Provider Syncing Status

Track background sync state:

```rust
#[derive(Clone, Debug, PartialEq)]
pub enum ProviderSyncingStatus {
    NotSyncing,
    Syncing(ProviderSyncing),
    Synced,
}

#[derive(Clone, Debug, PartialEq)]
pub struct ProviderSyncing {
    pub current: u32,
    pub total: u32,
}

// In Store
pub fn sync_with_server(&mut self) {
    if !self.is_server_enabled() {
        return;
    }

    let client = self.moly_client.clone();
    spawn(async move {
        let Ok(()) = client.test_connection().await else {
            return;
        };

        app_runner().defer(|app, _, _| {
            let store = app.store.as_mut().unwrap();
            store.downloads.load_downloaded_files();
            store.downloads.load_pending_downloads();
            store.search.load_featured_models();
        });
    });
}
```

## Chat State Management

Chat state with current chat tracking:

```rust
pub struct Chats {
    client: MolyClient,
    chats: HashMap<ChatID, RefCell<Chat>>,
    current_chat_id: Option<ChatID>,
    pub providers: HashMap<String, Provider>,
}

impl Chats {
    pub fn set_current_chat(&mut self, chat_id: Option<ChatID>) {
        // Deselect previous
        if let Some(prev_id) = self.current_chat_id {
            if let Some(chat) = self.chats.get(&prev_id) {
                chat.borrow_mut().is_selected = false;
            }
        }

        // Select new
        if let Some(id) = chat_id {
            if let Some(chat) = self.chats.get(&id) {
                chat.borrow_mut().is_selected = true;
            }
        }

        self.current_chat_id = chat_id;
    }

    pub fn get_chat_by_id(&self, id: ChatID) -> Option<&RefCell<Chat>> {
        self.chats.get(&id)
    }

    pub fn get_last_selected_chat_id(&self) -> Option<ChatID> {
        self.current_chat_id
    }
}
```

## Preferences Persistence

Load/save user preferences:

```rust
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct Preferences {
    pub providers_preferences: Vec<ProviderPreference>,
    pub last_selected_chat_id: Option<ChatID>,
    // ... other preferences
}

impl Preferences {
    pub async fn load() -> Self {
        let path = preferences_path();

        match tokio::fs::read_to_string(&path).await {
            Ok(json) => serde_json::from_str(&json).unwrap_or_default(),
            Err(e) if e.kind() == std::io::ErrorKind::NotFound => {
                Self::default()
            }
            Err(e) => {
                error!("Failed to load preferences: {}", e);
                Self::default()
            }
        }
    }

    pub fn save(&self) {
        let preferences = self.clone();
        spawn(async move {
            let json = serde_json::to_string_pretty(&preferences).unwrap();
            if let Err(e) = tokio::fs::write(preferences_path(), json).await {
                error!("Failed to save preferences: {}", e);
            }
        });
    }
}
```

## Store Action Forwarding

Forward actions to appropriate handlers:

```rust
impl Store {
    pub fn handle_action(&mut self, action: &Action) {
        // Forward to submodules
        self.search.handle_action(action);
        self.downloads.handle_action(action);

        // Handle download completion
        if action.downcast_ref::<DownloadFileAction>().is_some() {
            self.update_downloads();
        }
    }

    fn update_downloads(&mut self) {
        let completed_ids = self.downloads.refresh_downloads_data();

        // Refresh provider models if downloads completed
        if !completed_ids.is_empty() {
            if let Some(provider) = self.get_server_provider() {
                if provider.enabled {
                    self.chats.test_provider_and_fetch_models(
                        &provider.url,
                        &mut self.provider_syncing_status,
                    );
                }
            }
        }

        // Update search results with download state
        for file_id in completed_ids {
            self.search.update_downloaded_file_in_search_results(&file_id, true);
        }
    }
}
```
