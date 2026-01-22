# State Structures Reference

Common state structure patterns from Robrix.

## Window Geometry State

```rust
#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct WindowGeomState {
    /// Window width and height
    pub inner_size: (f64, f64),
    /// Window x and y position
    pub position: (f64, f64),
    /// Whether window is maximized/fullscreen
    pub is_fullscreen: bool,
}
```

## Room/Item Info Structures

```rust
/// UI-related info about a joined room
#[derive(Debug)]
pub struct JoinedRoomInfo {
    /// Displayable name (includes room ID for fallback)
    pub room_name_id: RoomNameId,
    /// Number of unread messages
    pub num_unread_messages: u64,
    /// Number of unread mentions
    pub num_unread_mentions: u64,
    /// Canonical alias for this room
    pub canonical_alias: Option<OwnedRoomAliasId>,
    /// Alternative aliases
    pub alt_aliases: Vec<OwnedRoomAliasId>,
    /// Room tags (favourite, low_priority, etc.)
    pub tags: Tags,
    /// Latest message timestamp and preview text
    pub latest: Option<(MilliSecondsSinceUnixEpoch, String)>,
    /// Room avatar (image bytes or first character)
    pub avatar: FetchedRoomAvatar,
    /// Whether room has been paginated at least once
    pub has_been_paginated: bool,
    /// Whether room is currently selected in UI
    pub is_selected: bool,
    /// Whether this is a direct message room
    pub is_direct: bool,
    /// Whether room is tombstoned (replaced by successor)
    pub is_tombstoned: bool,
}
```

## Invite State Machine

```rust
/// State of a pending invite
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
pub enum InviteState {
    /// Waiting for user to accept or decline
    #[default]
    WaitingOnUserInput,
    /// Waiting for server response to join
    WaitingForJoinResult,
    /// Waiting for server response to leave
    WaitingForLeaveResult,
    /// Invite accepted, waiting for room to appear
    WaitingForJoinedRoom,
    /// Invite declined, room was left
    RoomLeft,
}

/// Info about an invited room
pub struct InvitedRoomInfo {
    pub room_name_id: RoomNameId,
    pub canonical_alias: Option<OwnedRoomAliasId>,
    pub alt_aliases: Vec<OwnedRoomAliasId>,
    pub room_avatar: FetchedRoomAvatar,
    pub inviter_info: Option<InviterInfo>,
    pub latest: Option<(MilliSecondsSinceUnixEpoch, String)>,
    pub invite_state: InviteState,
    pub is_selected: bool,
    pub is_direct: bool,
}
```

## User Profile State

```rust
#[derive(Clone, Debug)]
pub struct UserProfile {
    pub user_id: OwnedUserId,
    pub username: Option<String>,
    pub avatar_state: AvatarState,
}

#[derive(Clone, Debug)]
pub enum AvatarState {
    /// Avatar URL unknown yet
    Unknown,
    /// Avatar URL known (None = no avatar set)
    Known(Option<OwnedMxcUri>),
    /// Avatar image data loaded
    Loaded(Arc<[u8]>),
    /// Failed to load avatar
    Failed,
}

/// Profile with room context
#[derive(Clone, Debug)]
pub struct UserProfileAndRoomId {
    pub user_profile: UserProfile,
    pub room_id: OwnedRoomId,
}
```

## Filter/Display State

```rust
/// Active display filter for a list
pub struct RoomDisplayFilter {
    /// Filter function
    filter_fn: Box<dyn Fn(&RoomInfo) -> bool>,
    /// Sort function
    sort_fn: SortFn,
    /// Filter keywords
    keywords: String,
}

/// Filter criteria configuration
pub struct RoomFilterCriteria {
    pub include_direct: bool,
    pub include_regular: bool,
    pub include_invited: bool,
    pub space_filter: Option<OwnedRoomId>,
}
```

## Per-Widget State

```rust
/// State for the room input bar
#[derive(Default, Debug)]
pub struct RoomInputBarState {
    /// Currently composing message
    pub draft: String,
    /// Message being replied to
    pub reply_to: Option<ReplyInfo>,
    /// Message being edited
    pub editing: Option<EditInfo>,
    /// Typing indicator active
    pub is_typing: bool,
}

/// State for timeline display
pub struct TimelineState {
    /// All timeline items
    pub items: Vector<Arc<TimelineItem>>,
    /// Items drawn in last frame (for caching)
    pub drawn_items: RangeSet<usize>,
    /// Scroll position
    pub scroll_offset: f64,
    /// Whether we've hit the start of timeline
    pub fully_paginated_back: bool,
    /// Whether we've hit the end (live) of timeline
    pub fully_paginated_forward: bool,
}
```

## Global Singleton Pattern

```rust
use std::sync::Mutex;

/// Global client singleton
static CLIENT: Mutex<Option<Client>> = Mutex::new(None);

pub fn get_client() -> Option<Client> {
    CLIENT.lock().unwrap().clone()
}

pub fn set_client(client: Client) {
    *CLIENT.lock().unwrap() = Some(client);
}

pub fn clear_client() {
    *CLIENT.lock().unwrap() = None;
}

/// Global user ID cache
static CURRENT_USER_ID: Mutex<Option<OwnedUserId>> = Mutex::new(None);

pub fn current_user_id() -> Option<OwnedUserId> {
    CURRENT_USER_ID.lock().unwrap().clone()
}
```

## Per-Item State Storage

```rust
use std::collections::HashMap;

/// Store per-room joined details
static ALL_JOINED_ROOMS: Mutex<HashMap<OwnedRoomId, JoinedRoomDetails>> =
    Mutex::new(HashMap::new());

struct JoinedRoomDetails {
    room_id: OwnedRoomId,
    timeline: Arc<Timeline>,
    update_sender: crossbeam_channel::Sender<TimelineUpdate>,
    subscriber_task: JoinHandle<()>,
    event_handlers: Option<EventHandlerDropGuard>,
}

impl Drop for JoinedRoomDetails {
    fn drop(&mut self) {
        // Cleanup when room is closed
        self.subscriber_task.abort();
        drop(self.event_handlers.take());
    }
}
```
