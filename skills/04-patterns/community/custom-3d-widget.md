# Custom 3D Widget Pattern

Create reusable widgets with custom GPU rendering (DrawMesh, 3D geometry).

## Problem

You have monolithic rendering code and want to refactor it into an embeddable, reusable widget that:
- Can be instantiated multiple times
- Exposes a clean API for control
- Emits actions for parent components
- Handles its own input (mouse, keyboard)

## Solution Structure

### 1. Library Crate Structure

Separate rendering primitives from the widget:

```
src/
  lib.rs           # Module exports + live_design registration
  mesh.rs          # DrawMesh, GeometryMesh3D, MeshData
  robot_view.rs    # RobotView widget
```

**lib.rs** - Register all live_design modules:
```rust
use makepad_widgets::*;

pub mod mesh;
pub mod robot_view;

pub fn live_design(cx: &mut Cx) {
    mesh::live_design(cx);
    robot_view::live_design(cx);
}
```

### 2. Custom Geometry Class

For custom 3D rendering, create a GeometryFields implementation:

```rust
/// Counter for unique geometry IDs (required for multiple instances)
static GEOMETRY_COUNTER: std::sync::atomic::AtomicU64 =
    std::sync::atomic::AtomicU64::new(0);

#[derive(Live, LiveRegister, Clone)]
pub struct GeometryMesh3D {
    #[rust] pub geometry_ref: Option<GeometryRef>,
    #[rust] pub mesh_data: Option<MeshData>,
    #[rust] pub instance_id: u64,  // Unique per instance
}

impl GeometryMesh3D {
    pub fn new_empty() -> Self {
        let id = GEOMETRY_COUNTER.fetch_add(1, std::sync::atomic::Ordering::SeqCst);
        Self {
            geometry_ref: None,
            mesh_data: None,
            instance_id: id,
        }
    }
}

impl GeometryFields for GeometryMesh3D {
    fn geometry_fields(&self, fields: &mut Vec<GeometryField>) {
        fields.push(GeometryField { id: live_id!(geom_pos), ty: ShaderTy::Vec3 });
        fields.push(GeometryField { id: live_id!(geom_id), ty: ShaderTy::Float });
        fields.push(GeometryField { id: live_id!(geom_normal), ty: ShaderTy::Vec3 });
        fields.push(GeometryField { id: live_id!(geom_uv), ty: ShaderTy::Vec2 });
    }

    fn get_geometry_id(&self) -> Option<GeometryId> {
        self.geometry_ref.as_ref().map(|gr| gr.0.geometry_id())
    }

    fn live_type_check(&self) -> LiveType {
        LiveType::of::<Self>()
    }
}
```

### 3. Custom DrawShader

```rust
#[derive(Live, LiveRegister)]
#[repr(C)]
pub struct DrawMesh {
    #[rust] pub many_instances: Option<ManyInstances>,
    #[live] pub geometry: GeometryMesh3D,
    #[deref] pub draw_vars: DrawVars,
    #[live] pub color: Vec4,
}

impl LiveHook for DrawMesh {
    fn before_apply(&mut self, cx: &mut Cx, apply: &mut Apply, index: usize, nodes: &[LiveNode]) {
        self.draw_vars.before_apply_init_shader(cx, apply, index, nodes, &self.geometry);
    }

    fn after_apply(&mut self, cx: &mut Cx, apply: &mut Apply, index: usize, nodes: &[LiveNode]) {
        self.draw_vars.after_apply_update_self(cx, apply, index, nodes, &self.geometry);
    }
}

impl DrawMesh {
    /// Create instance with separate geometry (for multiple drawers)
    pub fn new_for_link(_cx: &mut Cx, mesh_data: MeshData, template: &DrawMesh) -> Self {
        let mut geom = GeometryMesh3D::new_empty();
        geom.mesh_data = Some(mesh_data);

        DrawMesh {
            many_instances: None,
            geometry: geom,
            draw_vars: template.draw_vars.clone(),
            color: vec4(1.0, 0.65, 0.1, 1.0),
        }
    }

    pub fn init_link_geometry(&mut self, cx: &mut Cx) {
        if let Some(mesh_data) = self.geometry.mesh_data.take() {
            self.geometry.upload_mesh_data(cx, mesh_data);
        }
        self.draw_vars.after_apply_update_self(
            cx,
            &mut Apply::from(ApplyFrom::UpdateFromDoc { file_id: Default::default() }),
            0, &[], &self.geometry
        );
    }

    pub fn draw(&mut self, cx: &mut Cx2d) {
        if let Some(mi) = &mut self.many_instances {
            mi.instances.extend_from_slice(self.draw_vars.as_slice());
        } else if self.draw_vars.can_instance() {
            let new_area = cx.add_instance(&self.draw_vars);
            self.draw_vars.area = cx.update_area_refs(self.draw_vars.area, new_area);
        }
    }

    pub fn begin_many_instances(&mut self, cx: &mut Cx2d) {
        self.many_instances = cx.begin_many_instances(&self.draw_vars);
    }

    pub fn end_many_instances(&mut self, cx: &mut Cx2d) {
        if let Some(mi) = self.many_instances.take() {
            let new_area = cx.end_many_instances(mi);
            self.draw_vars.area = cx.update_area_refs(self.draw_vars.area, new_area);
        }
    }
}
```

### 4. Widget Definition with Actions

```rust
#[derive(Clone, Debug, DefaultNone)]
pub enum RobotViewAction {
    None,
    JointChanged { joint_idx: usize, angle: f32 },
    AnimationToggled(bool),
}

#[derive(Live, LiveHook, Widget)]
pub struct RobotView {
    #[redraw] #[live] draw_bg: DrawQuad,
    #[live] show_bg: bool,
    #[redraw] #[live] draw_mesh: DrawMesh,  // Template for creating link drawers
    #[walk] walk: Walk,
    #[layout] layout: Layout,

    // Camera state
    #[rust] camera_distance: f64,
    #[rust] camera_yaw: f64,
    #[rust] camera_pitch: f64,
    #[rust] is_dragging: bool,

    // Widget state
    #[rust] initialized: bool,
    #[rust] robot: Option<Robot>,
    #[rust] link_drawers: Vec<DrawMesh>,  // One per robot link
    #[rust] original_meshes: Vec<MeshData>,

    // Config
    #[rust] urdf_path: String,
    #[rust] assets_dir: String,
    #[rust] area: Area,
}
```

### 5. Widget Implementation

```rust
impl Widget for RobotView {
    fn handle_event(&mut self, cx: &mut Cx, event: &Event, scope: &mut Scope) {
        // Handle keyboard input
        if let Event::KeyDown(ke) = event {
            match ke.key_code {
                KeyCode::ArrowUp => {
                    // Modify state
                    // Emit action for parent
                    cx.widget_action(
                        self.widget_uid(),
                        &scope.path,
                        RobotViewAction::JointChanged { joint_idx: 0, angle: 0.0 }
                    );
                    self.redraw(cx);
                }
                _ => {}
            }
        }

        // Handle mouse for camera orbit
        match event.hits(cx, self.area) {
            Hit::FingerDown(fe) => {
                self.is_dragging = true;
                self.last_mouse = fe.abs;
            }
            Hit::FingerMove(fe) if self.is_dragging => {
                let delta = fe.abs - self.last_mouse;
                self.camera_yaw += delta.x * 0.01;
                self.redraw(cx);
            }
            Hit::FingerScroll(se) => {
                self.camera_distance *= 1.0 - se.scroll.y * 0.01;
                self.redraw(cx);
            }
            _ => {}
        }
    }

    fn draw_walk(&mut self, cx: &mut Cx2d, _scope: &mut Scope, walk: Walk) -> DrawStep {
        cx.begin_turtle(walk, self.layout);

        // Draw background
        if self.show_bg {
            self.draw_bg.draw_abs(cx, cx.turtle().rect());
        }

        // Lazy initialization
        if !self.initialized {
            self.initialized = true;
            self.init_robot(cx.cx);
        }

        // Draw all meshes with transforms
        if let Some(ref robot) = self.robot {
            for (i, drawer) in self.link_drawers.iter_mut().enumerate() {
                let transform = self.compute_transform(i);
                drawer.update_transformed_geometry(cx.cx, &self.original_meshes[i], &transform);
                drawer.begin_many_instances(cx);
                drawer.draw(cx);
                drawer.end_many_instances(cx);
            }
        }

        cx.end_turtle_with_area(&mut self.area);
        DrawStep::done()
    }
}
```

### 6. Ref Helper Methods

Expose API through the generated Ref type:

```rust
impl RobotViewRef {
    pub fn reload_robot(&self, cx: &mut Cx, urdf_path: &str, assets_dir: &str) {
        if let Some(mut inner) = self.borrow_mut() {
            inner.reload_robot(cx, urdf_path, assets_dir);
        }
    }

    pub fn set_joint_angles(&self, cx: &mut Cx, angles: &[f32]) {
        if let Some(mut inner) = self.borrow_mut() {
            inner.set_joint_angles(cx, angles);
        }
    }

    pub fn get_joint_angles(&self) -> Vec<f32> {
        if let Some(inner) = self.borrow() {
            inner.get_joint_angles()
        } else {
            vec![]
        }
    }

    pub fn reset_view(&self, cx: &mut Cx) {
        if let Some(mut inner) = self.borrow_mut() {
            inner.reset_view(cx);
        }
    }
}
```

### 7. Using the Widget

**In app's live_design:**
```rust
live_design! {
    use link::theme::*;
    use link::widgets::*;
    use my_lib::robot_view::RobotView;

    App = {{App}} {
        ui: <Window> {
            body = <View> {
                robot_view = <RobotView> {}
            }
        }
    }
}
```

**In app's LiveRegister:**
```rust
impl LiveRegister for App {
    fn live_register(cx: &mut Cx) {
        makepad_widgets::live_design(cx);
        my_lib::live_design(cx);  // Register library's live_design
    }
}
```

**Handle actions from widget:**
```rust
let actions = cx.capture_actions(|cx| {
    self.view.handle_event(cx, event, scope);
});

for action in &actions {
    match action.as_widget_action().cast::<RobotViewAction>() {
        RobotViewAction::JointChanged { joint_idx, angle } => {
            self.update_status(cx);
        }
        _ => {}
    }
}
```

## Key Patterns

1. **Unique geometry per drawer**: Use atomic counter for instance_id in GeometryFingerprint
2. **Template pattern**: Create new DrawMesh from template's draw_vars (shares shader)
3. **Lazy initialization**: Initialize resources in draw_walk when first drawn
4. **Action emission**: Use `cx.widget_action()` for parent communication
5. **Area tracking**: Store area in widget, return with `end_turtle_with_area`
6. **Ref helper methods**: Wrap borrow/borrow_mut for clean external API

## Gotchas

- **Z-order with overlays**: Custom 3D rendering conflicts with Modal/DropDown (see troubleshooting)
- **Multiple geometries**: Each DrawMesh needs unique GeometryFingerprint via instance_id
- **Shader compilation**: Geometry must exist at after_apply time (use default cube)
- **Transform updates**: Call `after_apply_update_self` after geometry changes

## References

- [urdf-rerun-test](examples/urdf-rerun-test) - URDF robot viewer implementation
- [Makepad draw source](https://github.com/makepad/makepad/tree/main/draw)
