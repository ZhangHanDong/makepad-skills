# Matrix Client Reference

Client setup, login, and session management patterns.

## Login Flow

### Login Types

```rust
pub enum LoginRequest {
    /// Login with username/password
    LoginByPassword(LoginByPassword),
    /// Login via SSO completed
    LoginBySSOSuccess(Client, ClientSessionPersisted),
    /// Login with CLI args (testing)
    LoginByCli,
    /// Query available login types for homeserver
    HomeserverLoginTypesQuery(String),
}

pub struct LoginByPassword {
    pub user_id: String,
    pub password: String,
    pub homeserver: Option<String>,
}
```

### Login Implementation

```rust
async fn login(
    login_request: LoginRequest,
) -> Result<(Client, Option<String>)> {
    match login_request {
        LoginRequest::LoginByPassword(creds) => {
            let (client, session) = build_client(&creds.homeserver, app_data_dir()).await?;

            let login_result = client
                .matrix_auth()
                .login_username(&creds.user_id, &creds.password)
                .initial_device_display_name("my-app-device")
                .send()
                .await?;

            if client.matrix_auth().logged_in() {
                log!("Logged in successfully.");

                // Save session for future restoration
                if let Err(e) = persistence::save_session(&client, session).await {
                    error!("Failed to save session: {e}");
                }

                // Notify UI of success
                enqueue_rooms_list_update(RoomsListUpdate::Status {
                    status: format!("Logged in as {}. Loading rooms...", creds.user_id)
                });

                Ok((client, None))
            } else {
                bail!("Login failed: {:?}", login_result);
            }
        }

        LoginRequest::LoginBySSOSuccess(client, session) => {
            if let Err(e) = persistence::save_session(&client, session).await {
                error!("Failed to save session: {e:?}");
            }
            Ok((client, None))
        }
        // ...
    }
}
```

### Session Restoration

```rust
async fn try_restore_session() -> Result<Option<(Client, String)>> {
    let session_path = app_data_dir().join("session.json");

    let session: ClientSessionPersisted = match tokio::fs::read_to_string(&session_path).await {
        Ok(json) => serde_json::from_str(&json)?,
        Err(e) if e.kind() == std::io::ErrorKind::NotFound => {
            return Ok(None);
        }
        Err(e) => return Err(e.into()),
    };

    // Rebuild client from saved session
    let client = Client::builder()
        .homeserver_url(&session.homeserver)
        .sqlite_store(&session.db_path, Some(&session.passphrase))
        .sliding_sync_version_builder(VersionBuilder::DiscoverNative)
        .build()
        .await?;

    // Check if still logged in
    if !client.logged_in() {
        log!("Session expired, need to re-login");
        return Ok(None);
    }

    // Get sync token if available
    let sync_token = client.sync_token().await;

    Ok(Some((client, sync_token.unwrap_or_default())))
}
```

## Room List Service

```rust
async fn setup_room_list_service(client: &Client) -> Result<RoomListService> {
    let room_list_service = client
        .room_list_service()
        .all_rooms()
        .await?;

    // Configure filters
    room_list_service.apply_input(
        RoomListInput::Visible {
            ranges: vec![0..20],  // Initial visible range
        }
    ).await?;

    Ok(room_list_service)
}

async fn subscribe_to_room_list(room_list_service: RoomListService) {
    let mut rooms_stream = room_list_service.entries();

    while let Some(room_list_entries) = rooms_stream.next().await {
        for entry in room_list_entries {
            match entry {
                RoomListEntry::Filled(room_id) => {
                    // Room became available
                    if let Some(room) = client.get_room(&room_id) {
                        let room_info = build_room_info(&room).await;
                        enqueue_rooms_list_update(RoomsListUpdate::AddJoinedRoom(room_info));
                    }
                }
                RoomListEntry::Empty | RoomListEntry::Invalidated(_) => {
                    // Room removed or invalidated
                }
            }
        }
    }
}
```

## Sync Service

```rust
async fn run_sync_service(client: Client) -> Result<()> {
    let sync_service = SyncService::builder(client.clone())
        .build()
        .await?;

    // Start syncing
    sync_service.start().await;

    // Monitor sync state
    let mut state_stream = sync_service.state();
    while let Some(state) = state_stream.next().await {
        match state {
            SyncServiceState::Running => {
                log!("Sync running");
            }
            SyncServiceState::Terminated => {
                log!("Sync terminated");
                break;
            }
            SyncServiceState::Error => {
                error!("Sync error");
            }
            _ => {}
        }
    }

    Ok(())
}
```

## Logout Flow

```rust
async fn logout_with_state_machine(is_desktop: bool) -> Result<()> {
    let Some(client) = get_client() else {
        return Ok(());
    };

    // 1. Notify UI logout is starting
    Cx::post_action(LogoutAction::LogoutStarted);

    // 2. Stop sync service
    if let Some(sync_service) = get_sync_service() {
        sync_service.stop().await?;
    }

    // 3. Clear all room state
    {
        let mut rooms = ALL_JOINED_ROOMS.lock().unwrap();
        rooms.clear();  // Drop will abort background tasks
    }

    // 4. Clear UI state (posted action, handled on UI thread)
    let notify = Arc::new(Notify::new());
    Cx::post_action(LogoutAction::ClearAppState {
        on_clear_appstate: notify.clone(),
    });
    SignalToUI::set_ui_signal();

    // 5. Wait for UI to clear state
    notify.notified().await;

    // 6. Logout from server
    client.matrix_auth().logout().await?;

    // 7. Clear client
    clear_client();

    // 8. Delete session file
    tokio::fs::remove_file(app_data_dir().join("session.json")).await.ok();

    // 9. Notify UI logout complete
    Cx::post_action(LogoutAction::LogoutSuccess);
    SignalToUI::set_ui_signal();

    Ok(())
}
```

## Global Client Access

```rust
static CLIENT: Mutex<Option<Client>> = Mutex::new(None);
static CURRENT_USER_ID: Mutex<Option<OwnedUserId>> = Mutex::new(None);

pub fn get_client() -> Option<Client> {
    CLIENT.lock().unwrap().clone()
}

pub fn set_client(client: Client) {
    let user_id = client.user_id().map(|u| u.to_owned());
    *CLIENT.lock().unwrap() = Some(client);
    *CURRENT_USER_ID.lock().unwrap() = user_id;
}

pub fn clear_client() {
    *CLIENT.lock().unwrap() = None;
    *CURRENT_USER_ID.lock().unwrap() = None;
}

pub fn current_user_id() -> Option<OwnedUserId> {
    CURRENT_USER_ID.lock().unwrap().clone()
}
```
