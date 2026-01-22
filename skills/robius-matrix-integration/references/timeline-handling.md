# Timeline Handling Reference

Patterns for Matrix timeline subscription and display.

## Timeline Setup

```rust
async fn setup_room_timeline(
    room: &Room,
    room_id: OwnedRoomId,
) -> Result<JoinedRoomDetails> {
    // Build timeline with options
    let timeline = room
        .timeline_builder()
        .build()
        .await?;

    let timeline = Arc::new(timeline);

    // Create update channel
    let (update_sender, update_receiver) = crossbeam_channel::unbounded();

    // Spawn subscriber task
    let subscriber_task = spawn_timeline_subscriber(
        room_id.clone(),
        timeline.clone(),
        update_sender.clone(),
    );

    Ok(JoinedRoomDetails {
        room_id,
        timeline,
        timeline_update_sender: update_sender,
        timeline_subscriber_handler_task: subscriber_task,
        typing_notice_subscriber: None,
    })
}

fn spawn_timeline_subscriber(
    room_id: OwnedRoomId,
    timeline: Arc<Timeline>,
    sender: crossbeam_channel::Sender<TimelineUpdate>,
) -> JoinHandle<()> {
    tokio::spawn(async move {
        let (initial_items, mut stream) = timeline.subscribe().await;

        // Send initial items
        if sender.send(TimelineUpdate::NewItems {
            new_items: initial_items,
            changed_indices: BTreeSet::new(),
            is_append: false,
        }).is_err() {
            return;  // Receiver dropped
        }
        SignalToUI::set_ui_signal();

        // Process stream updates
        while let Some(diffs) = stream.next().await {
            for diff in diffs {
                let update = match diff {
                    VectorDiff::Append { values } => {
                        TimelineUpdate::NewItems {
                            new_items: values,
                            changed_indices: BTreeSet::new(),
                            is_append: true,
                        }
                    }
                    VectorDiff::PushFront { value } => {
                        TimelineUpdate::NewItems {
                            new_items: Vector::unit(value),
                            changed_indices: BTreeSet::new(),
                            is_append: false,
                        }
                    }
                    VectorDiff::Set { index, value } => {
                        let mut changed = BTreeSet::new();
                        changed.insert(index);
                        TimelineUpdate::NewItems {
                            new_items: Vector::unit(value),
                            changed_indices: changed,
                            is_append: false,
                        }
                    }
                    VectorDiff::Clear => {
                        TimelineUpdate::NewItems {
                            new_items: Vector::new(),
                            changed_indices: BTreeSet::new(),
                            is_append: false,
                        }
                    }
                    _ => continue,
                };

                if sender.send(update).is_err() {
                    return;  // Receiver dropped
                }
                SignalToUI::set_ui_signal();
            }
        }
    })
}
```

## Pagination

```rust
/// Direction of pagination
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PaginationDirection {
    /// Load older events
    Backwards,
    /// Load newer events (focused mode only)
    Forwards,
}

async fn paginate_timeline(
    timeline: Arc<Timeline>,
    direction: PaginationDirection,
    num_events: u16,
    sender: crossbeam_channel::Sender<TimelineUpdate>,
) {
    // Notify UI pagination started
    sender.send(TimelineUpdate::PaginationRunning(direction)).unwrap();
    SignalToUI::set_ui_signal();

    let result = match direction {
        PaginationDirection::Backwards => {
            timeline.paginate_backwards(num_events).await
        }
        PaginationDirection::Forwards => {
            timeline.paginate_forwards(num_events).await
        }
    };

    let update = match result {
        Ok(fully_paginated) => TimelineUpdate::PaginationIdle {
            fully_paginated,
            direction,
        },
        Err(error) => TimelineUpdate::PaginationError {
            error,
            direction,
        },
    };

    sender.send(update).unwrap();
    SignalToUI::set_ui_signal();
}
```

## Timeline Item Processing

```rust
fn process_timeline_item(item: &TimelineItem) -> ProcessedItem {
    match item.kind() {
        TimelineItemKind::Event(event_item) => {
            process_event_item(event_item)
        }
        TimelineItemKind::Virtual(virtual_item) => {
            process_virtual_item(virtual_item)
        }
    }
}

fn process_event_item(event: &EventTimelineItem) -> ProcessedItem {
    match event.content() {
        TimelineItemContent::Message(msg) => {
            process_message(msg, event)
        }
        TimelineItemContent::RedactedMessage => {
            ProcessedItem::Redacted
        }
        TimelineItemContent::Sticker(sticker) => {
            ProcessedItem::Sticker(sticker.clone())
        }
        TimelineItemContent::MembershipChange(change) => {
            ProcessedItem::Membership(change.clone())
        }
        TimelineItemContent::ProfileChange(change) => {
            ProcessedItem::ProfileChange(change.clone())
        }
        TimelineItemContent::OtherState(state) => {
            ProcessedItem::State(state.clone())
        }
        _ => ProcessedItem::Unsupported,
    }
}

fn process_message(msg: &MsgLikeContent, event: &EventTimelineItem) -> ProcessedItem {
    match msg.kind() {
        MsgLikeKind::Regular(content) => {
            match content.msgtype() {
                MessageType::Text(text) => {
                    ProcessedItem::Text {
                        body: text.body.clone(),
                        formatted: text.formatted.clone(),
                    }
                }
                MessageType::Image(image) => {
                    ProcessedItem::Image {
                        source: image.source.clone(),
                        info: image.info.clone(),
                    }
                }
                MessageType::Video(video) => {
                    ProcessedItem::Video {
                        source: video.source.clone(),
                        info: video.info.clone(),
                    }
                }
                MessageType::Audio(audio) => {
                    ProcessedItem::Audio {
                        source: audio.source.clone(),
                        info: audio.info.clone(),
                    }
                }
                MessageType::File(file) => {
                    ProcessedItem::File {
                        source: file.source.clone(),
                        info: file.info.clone(),
                    }
                }
                MessageType::Location(location) => {
                    ProcessedItem::Location {
                        body: location.body.clone(),
                        geo_uri: location.geo_uri.clone(),
                    }
                }
                _ => ProcessedItem::Unsupported,
            }
        }
        MsgLikeKind::Emote(emote) => {
            ProcessedItem::Emote {
                body: emote.body.clone(),
            }
        }
        MsgLikeKind::Notice(notice) => {
            ProcessedItem::Notice {
                body: notice.body.clone(),
            }
        }
    }
}
```

## Sending Messages

```rust
async fn send_message(
    timeline: Arc<Timeline>,
    room_id: OwnedRoomId,
    message: RoomMessageEventContent,
    replied_to: Option<Reply>,
) {
    let result = if let Some(reply) = replied_to {
        timeline.send_reply(message, reply, ForwardThread::Yes).await
    } else {
        timeline.send(message.into()).await
    };

    match result {
        Ok(()) => {
            log!("Message sent to room {}", room_id);
        }
        Err(e) => {
            error!("Failed to send message: {}", e);
            enqueue_popup_notification(PopupItem {
                message: format!("Failed to send: {}", e),
                kind: PopupKind::Error,
                auto_dismissal_duration: None,
            });
        }
    }
}

async fn edit_message(
    timeline: Arc<Timeline>,
    event_id: TimelineEventItemId,
    new_content: EditedContent,
    sender: crossbeam_channel::Sender<TimelineUpdate>,
) {
    let result = timeline.edit(&event_id, new_content).await;

    sender.send(TimelineUpdate::MessageEdited {
        timeline_event_id: event_id,
        result,
    }).unwrap();
    SignalToUI::set_ui_signal();
}
```

## Media Handling

```rust
async fn fetch_media(
    client: &Client,
    media_request: MediaRequestParameters,
    on_fetched: OnMediaFetchedFn,
    destination: MediaCacheEntryRef,
    update_sender: Option<crossbeam_channel::Sender<TimelineUpdate>>,
) {
    let result = client.media().get_media_content(&media_request, true).await;

    on_fetched(
        &destination,
        media_request,
        result,
        update_sender,
    );
    SignalToUI::set_ui_signal();
}

// Callback function signature
pub type OnMediaFetchedFn = fn(
    &Mutex<MediaCacheEntry>,
    MediaRequestParameters,
    matrix_sdk::Result<Vec<u8>>,
    Option<crossbeam_channel::Sender<TimelineUpdate>>,
);
```

## Event Subscriptions

```rust
async fn subscribe_to_typing_notices(
    room: &Room,
    room_id: OwnedRoomId,
    sender: crossbeam_channel::Sender<TimelineUpdate>,
) -> EventHandlerDropGuard {
    let client = room.client();

    client.add_room_event_handler(&room_id, move |event: SyncTypingEvent| {
        let typing_user_ids: Vec<_> = event.content.user_ids.iter().cloned().collect();

        sender.send(TimelineUpdate::TypingUsers(typing_user_ids)).ok();
        SignalToUI::set_ui_signal();

        async {}
    })
}
```
