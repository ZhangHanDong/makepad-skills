# Action Patterns Reference

Additional action patterns from Robrix codebase.

## Selection Action Pattern

```rust
#[derive(Clone, Debug, DefaultNone)]
pub enum RoomsListAction {
    /// A room was selected
    Selected(SelectedRoom),
    /// An invite was accepted, convert InviteScreen to RoomScreen
    InviteAccepted { room_name_id: RoomNameId },
    None,
}

// In RoomsList widget
fn handle_item_click(&mut self, cx: &mut Cx, scope: &mut Scope, room_id: &RoomId) {
    let selected_room = SelectedRoom::JoinedRoom {
        room_name_id: self.get_room_name(room_id),
    };

    cx.widget_action(
        self.widget_uid(),
        &scope.path,
        RoomsListAction::Selected(selected_room),
    );
}

// In App::handle_actions
if let RoomsListAction::Selected(selected_room) = action.as_widget_action().cast() {
    self.app_state.selected_room = Some(selected_room);
    self.update_header(cx, &selected_room);
    self.ui.redraw(cx);
    continue;
}
```

## Modal Action Pattern

```rust
#[derive(Debug, Clone)]
pub enum ModalAction {
    Open { kind: ModalKind },
    Close { was_internal: bool },
}

pub enum ModalKind {
    Confirmation { title: String, message: String },
    Input { title: String, placeholder: String },
}

// Opening modal from anywhere
cx.action(ModalAction::Open {
    kind: ModalKind::Confirmation {
        title: "Delete?".to_string(),
        message: "This cannot be undone.".to_string(),
    },
});

// In App::handle_actions
match action.downcast_ref() {
    Some(ModalAction::Open { kind }) => {
        self.ui.my_modal(ids!(modal_inner)).set_kind(cx, kind.clone());
        self.ui.modal(ids!(modal_container)).open(cx);
        continue;
    }
    Some(ModalAction::Close { was_internal }) => {
        if *was_internal {
            self.ui.modal(ids!(modal_container)).close(cx);
        }
        continue;
    }
    _ => {}
}
```

## Result Action Pattern

For async operation results:

```rust
#[derive(Debug)]
pub enum JoinRoomResultAction {
    Joined { room_id: OwnedRoomId },
    Failed { room_id: OwnedRoomId, error: Error },
}

// In async task
let result_action = match client.join_room_by_id(&room_id).await {
    Ok(_room) => JoinRoomResultAction::Joined { room_id },
    Err(e) => JoinRoomResultAction::Failed { room_id, error: e },
};
Cx::post_action(result_action);

// In App::handle_actions (NOT widget action!)
if let Some(result) = action.downcast_ref::<JoinRoomResultAction>() {
    match result {
        JoinRoomResultAction::Joined { room_id } => {
            self.show_notification(cx, "Room joined!");
            self.navigate_to_room(cx, room_id);
        }
        JoinRoomResultAction::Failed { room_id, error } => {
            self.show_error(cx, &format!("Failed to join: {}", error));
        }
    }
    continue;
}
```

## Tooltip Action Pattern

```rust
#[derive(Clone, DefaultNone)]
pub enum TooltipAction {
    HoverIn { text: String, widget_rect: Rect, options: TooltipOptions },
    HoverOut,
    None,
}

// In widget that shows tooltip
fn handle_event(&mut self, cx: &mut Cx, event: &Event, scope: &mut Scope) {
    match event.hits(cx, self.view.area()) {
        Hit::FingerHoverIn(_) => {
            let rect = self.view.area().rect(cx);
            cx.widget_action(
                self.widget_uid(),
                &scope.path,
                TooltipAction::HoverIn {
                    text: self.tooltip_text.clone(),
                    widget_rect: rect,
                    options: TooltipOptions::default(),
                },
            );
        }
        Hit::FingerHoverOut(_) => {
            cx.widget_action(
                self.widget_uid(),
                &scope.path,
                TooltipAction::HoverOut,
            );
        }
        _ => {}
    }
}

// In App::handle_actions
match action.as_widget_action().cast() {
    TooltipAction::HoverIn { text, widget_rect, options } => {
        self.ui.tooltip(ids!(app_tooltip))
            .show_with_options(cx, &text, widget_rect, options);
        continue;
    }
    TooltipAction::HoverOut => {
        self.ui.tooltip(ids!(app_tooltip)).hide(cx);
        continue;
    }
    _ => {}
}
```

## Navigation Action Pattern

```rust
#[derive(Debug)]
pub enum AppStateAction {
    RoomFocused(SelectedRoom),
    FocusNone,
    NavigateToRoom {
        room_to_close: Option<OwnedRoomId>,
        destination_room: BasicRoomDetails,
    },
    RoomLoadedSuccessfully(RoomNameId),
}

// Usage
cx.action(AppStateAction::NavigateToRoom {
    room_to_close: Some(current_room_id.clone()),
    destination_room: new_room_details,
});
```

## State Synchronization Action

For keeping state in sync across widgets:

```rust
#[derive(Debug, Clone)]
pub enum SyncAction {
    SelectedItemChanged(ItemId),
    FilterChanged(String),
    SortChanged(SortOrder),
}

// Emitting from source widget
fn on_selection_change(&mut self, cx: &mut Cx, scope: &mut Scope, item_id: ItemId) {
    cx.widget_action(
        self.widget_uid(),
        &scope.path,
        SyncAction::SelectedItemChanged(item_id),
    );
}

// Multiple widgets can listen and react
// In DetailView:
if let SyncAction::SelectedItemChanged(item_id) = action.as_widget_action().cast() {
    self.load_item_details(cx, item_id);
}

// In SidePanel:
if let SyncAction::SelectedItemChanged(item_id) = action.as_widget_action().cast() {
    self.highlight_item(cx, item_id);
}
```
