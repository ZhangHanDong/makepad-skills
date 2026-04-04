# Splash Language Reference

Complete reference for the Splash scripting language in Makepad 2.0. Splash is a runtime UI scripting language -- no commas between properties, no semicolons, whitespace-delimited.

---

## Script Structure

Every Splash script must start with a `use` statement to bring widgets into scope:

```
use mod.prelude.widgets.*

// All widgets (View, Label, Button, etc.) are now available
View{
    flow: Down
    height: Fit
    padding: 20
    Label{text: "Hello world"}
}
```

Without `use mod.prelude.widgets.*`, widget names will not be found.

### Embedding in Rust

Splash code is embedded in Rust via `script_mod!{}`:

```rust
use makepad_widgets::*;

app_main!(App);

script_mod! {
    use mod.prelude.widgets.*

    // Splash code here

    startup() do #(App::script_component(vm)){
        ui: Root{
            main_window := Window{
                window.inner_size: vec2(800, 600)
                body +: {
                    // UI content
                }
            }
        }
    }
}
```

For apps using the theme system:

```rust
impl App {
    fn run(vm: &mut ScriptVm) -> Self {
        crate::makepad_widgets::theme_mod(vm);
        script_eval!(vm, {
            mod.theme = mod.themes.light
        });
        crate::makepad_widgets::widgets_mod(vm);
        App::from_script_mod(vm, self::script_mod)
    }
}
```

---

## Let Bindings

Define reusable widget templates with `let`. Bindings are local to the current scope and must be defined **before** the places where they are used.

```
// Simple template (style overrides only)
let MyHeader = Label{
    draw_text.color: #fff
    draw_text.text_style.font_size: 16
}

// Template with per-instance named children (MUST use :=)
let MyCard = RoundedView{
    width: Fill height: Fit
    padding: 15 flow: Down spacing: 8
    draw_bg.color: #334
    draw_bg.border_radius: 8.0
    title := Label{text: "default" draw_text.color: #fff draw_text.text_style.font_size: 16}
    body := Label{text: "" draw_text.color: #aaa}
}

// Instantiate and override
View{
    flow: Down height: Fit spacing: 12 padding: 20
    MyCard{title.text: "First Card" body.text: "Content here"}
    MyCard{title.text: "Second Card" body.text: "More content"}
}
```

---

## Property Syntax

### Assignment

```
key: value
```

### Dot-path Shorthand

```
draw_bg.color: #f00
// equivalent to:
draw_bg +: { color: #f00 }
```

### Merge Operator

The `+:` operator extends/merges with the parent definition instead of replacing it entirely:

```
// Replaces entire draw_bg:
draw_bg: { color: #fff }

// Merges -- only overrides color, keeps other draw_bg properties:
draw_bg +: { color: #fff }
```

### Named Children (`:=` Operator)

Children inside a template that you want to override per-instance MUST be declared with `:=`:

```
let TodoItem = View{
    width: Fill height: Fit
    flow: Right spacing: 8
    check := CheckBox{text: ""}
    label := Label{text: "task" draw_text.color: #ddd}
    Filler{}
    tag := Label{text: "" draw_text.color: #888}
}

// Override named children with dot-path syntax:
TodoItem{label.text: "Walk the dog" tag.text: "personal"}
```

**CRITICAL**: Using `label:` (colon) instead of `label :=` (colon-equals) makes the child static and non-addressable. Overrides fail silently.

**Named children inside anonymous containers are UNREACHABLE.** Every container in the path from root to the child must have a `:=` name:

```
let Item = View{
    flow: Right
    texts := View{                           // named with :=
        flow: Down
        label := Label{text: "default"}
    }
}
Item{texts.label.text: "new text"}           // full path through named containers
```

### Inherit + Override

Use inheritance syntax to take a base value but override specific fields:

```
padding: theme.mspace_1{left: theme.space_2}   // takes mspace_1 but overrides left
```

---

## Colors

```
#f00                          // RGB short
#ff0000                       // RGB full
#ff0000ff                     // RGBA
#0000                         // transparent black
vec4(1.0 0.0 0.0 1.0)        // explicit RGBA
```

### Hex Color Escape (`#x` prefix)

When hex colors contain the letter `e` adjacent to digits (which could be misinterpreted as scientific notation), use the `#x` prefix:

```
// Need #x prefix (contain 'e' adjacent to digits):
fill: #x2ecc71
fill: #x1e1e2e
fill: #x4466ee

// Fine without #x (no 'e' issue):
fill: #ff4444
fill: #00ff00
```

### Color Arithmetic

```
theme.color_label_inner_inactive * 0.8    // darken by 20%
```

---

## Sizing (Size Enum)

```
width: Fill                   // Fill available space (default)
width: Fit                    // Shrink to content
width: 200                    // Fixed 200px (bare number = Fixed)
width: Fill{min: 100 max: 500}
width: Fit{max: Abs(300)}
height: Fill  height: Fit  height: 100
```

---

## Layout

### Flow (direction children are laid out)

```
flow: Right                   // default, left-to-right (no wrap)
flow: Down                    // top-to-bottom
flow: Overlay                 // stacked on top of each other
flow: Flow.Right{wrap: true}  // wrapping horizontal
flow: Flow.Down{wrap: true}   // wrapping vertical
```

### Spacing, Padding, Margin

```
spacing: 10                            // gap between children
padding: 15                            // uniform padding (bare number)
padding: Inset{top: 5 bottom: 5 left: 10 right: 10}
margin: Inset{top: 2 bottom: 2 left: 5 right: 5}
margin: 0.                             // uniform zero
```

### Alignment

```
align: Center                 // Align{x: 0.5 y: 0.5}
align: HCenter                // Align{x: 0.5 y: 0.0}
align: VCenter                // Align{x: 0.0 y: 0.5}
align: TopLeft                // Align{x: 0.0 y: 0.0}
align: Align{x: 1.0 y: 0.0}  // top-right
align: Align{x: 0.0 y: 0.5}  // center-left
```

### Clipping

```
clip_x: true                  // default
clip_y: true                  // default
clip_x: false                 // overflow visible
```

---

## Control Flow

### If/Else

```
if condition {
    Label{text: "true branch"}
} else {
    Label{text: "false branch"}
}

// Single-expression form (no braces):
if todos.len() == 0
    EmptyState{}
else for i, todo in todos {
    TodoItem{label.text: todo.text}
}
```

### For Loops

```
for i, item in array {
    Label{text: item.name}
}

for todo in todos {
    if !todo.done { n = n + 1 }
}
```

### While Loops

```
while condition {
    // body
}
```

---

## Functions

```
fn name(params) {
    body
}

// Examples:
fn tag_color(tag) {
    if tag == "dev" theme.color_highlight
    else if tag == "urgent" theme.color_warning
    else theme.color_highlight
}

fn add_todo(text, tag) {
    todos.push({text: text, tag: tag, done: false})
    ui.todo_list.render()
}

fn count_remaining() {
    let n = 0
    for todo in todos {
        if !todo.done { n = n + 1 }
    }
    n
}
```

---

## State Management

### Defining State

```
// Object literal state
let state = {
    counter: 0
}
mod.state = state

// Array state
let todos = []
todos.push({text: "First task", tag: "dev", done: false})
```

### Reactive Rendering with `on_render`

The `on_render` callback runs every time `.render()` is called on the widget. It rebuilds children dynamically:

```
main_view := View{
    on_render: ||{
        Label{text: "Count: " + state.counter}
    }
}
```

Trigger re-renders with:

```
ui.main_view.render()
```

### Widget Referencing

```
ui.widget_name.render()       // trigger re-render
ui.widget_name.text()         // get text content (TextInput)
ui.widget_name.set_text("")   // set text content
ui.widget_name.on_click()     // programmatically trigger click
```

---

## Event Handling

### Inline Events in Splash

```
// Button click
add_button := Button{
    text: "Add"
    on_click: ||{
        let text = ui.todo_input.text()
        if text != "" {
            add_todo(text, "")
            ui.todo_input.set_text("")
        }
    }
}

// TextInput return key
todo_input := TextInput{
    on_return: || ui.add_button.on_click()
}

// CheckBox toggle (receives checked state)
check := CheckBox{
    on_click: |checked| toggle_todo(i, checked)
}

// Startup event
on_startup: ||{
    ui.main_view.render()
}
```

### Events from Rust with `script_eval!`

```rust
if self.ui.button(cx, ids!(increment_button)).clicked(actions) {
    script_eval!(cx, {
        mod.state.counter += 1
        ui.main_view.render()
    });
}
```

---

## HTTP Requests

### GET Request

```
let req = net.HttpRequest{
    url: "https://html.duckduckgo.com/html/?q=rust+programming"
    method: net.HttpMethod.GET
    headers: {"User-Agent": "MakepadApp/1.0"}
}
net.http_request(req) do net.HttpEvents{
    on_response: |res| {
        let text = res.body.to_string()
        let json = res.body.parse_json()
        // res.status_code -- HTTP status (200, 404, etc.)
    }
    on_error: |e| {
        // e.message
    }
}
```

### POST Request with JSON Body

```
let req = net.HttpRequest{
    url: "https://api.example.com/data"
    method: net.HttpMethod.POST
    headers: {"Content-Type": "application/json"}
    body: {key: "value" count: 42}.to_json()
}
net.http_request(req) do net.HttpEvents{
    on_response: |res| { /* ... */ }
    on_error: |e| { /* ... */ }
}
```

### Streaming Response

```
let req = net.HttpRequest{
    url: "https://api.example.com/stream"
    method: net.HttpMethod.POST
    is_streaming: true
    body: {stream: true}.to_json()
}
var total = ""
net.http_request(req) do net.HttpEvents{
    on_stream: |res| {
        total += res.body.to_string()         // called per chunk
    }
    on_complete: |res| {
        // stream finished
    }
    on_error: |e| { /* ... */ }
}
```

### HttpMethod Values

`net.HttpMethod.GET`, `POST`, `PUT`, `DELETE`, `HEAD`, `PATCH`, `OPTIONS`

---

## HTML Parsing

Call `.parse_html()` on any string to get a queryable HTML document.

### Querying Elements

```
let doc = html_string.parse_html()

doc.query("p")                // all <p> elements
doc.query("p[0]")             // first <p> element
doc.query("#main")            // element with id "main"
doc.query("p.bold")           // <p> with class "bold"
doc.query("div > p")          // direct children
doc.query("div p")            // descendants
doc.query("div > *")          // all direct children (wildcard)
doc.query("div").query("p")   // chained queries
```

### Extracting Data

```
doc.query("p[0]").text         // text content: "Hello"
doc.query("div@class")        // attribute value: "box"
doc.query("div@id")           // attribute value: "main"
doc.query("p.text")           // array of text from all <p>
doc.query("p@class")          // array of class attrs from all <p>
```

### Properties on HTML Handles

```
handle.length                  // number of matched elements
handle.text                    // text content (concatenated)
handle.html                    // reconstructed HTML string
handle.attr("name")            // attribute value (string or nil)
handle.array()                 // convert to array of element handles
```

### Iterating Results

```
let items = doc.query("a.result__a").array()
for item, i in items {
    let title = item.text
    let href = item.attr("href")
}
```

---

## View Widgets (Containers)

All inherit from `ViewBase`. Default: no background.

| Widget | Background | Shape |
|--------|-----------|-------|
| `View` | none | -- |
| `SolidView` | flat color | rectangle |
| `RoundedView` | color | rounded rect |
| `RoundedAllView` | color | per-corner radius (vec4) |
| `RoundedXView` | color | left/right radius (vec2) |
| `RoundedYView` | color | top/bottom radius (vec2) |
| `RectView` | color | rectangle with border |
| `RectShadowView` | color+shadow | rectangle |
| `RoundedShadowView` | color+shadow | rounded rect |
| `CircleView` | color | circle |
| `HexagonView` | color | hexagon |
| `GradientXView` | horizontal gradient | rectangle |
| `GradientYView` | vertical gradient | rectangle |
| `CachedView` | texture-cached | rectangle |
| `CachedRoundedView` | texture-cached | rounded rect |

Scrollable: `ScrollXYView`, `ScrollXView`, `ScrollYView`

### View Properties

```
width: Fill              // Size: Fill | Fit | <number>
height: Fit              // CRITICAL: default Fill breaks in Fit containers
flow: Down               // Flow: Right | Down | Overlay | Flow.Right{wrap: true}
spacing: 10              // gap between children
padding: 15              // Inset or bare number
margin: 0.               // Inset or bare number
align: Center            // Align preset or Align{x: y:}
show_bg: true            // enable background drawing (false by default)
visible: true
new_batch: true          // REQUIRED on Views with show_bg containing text
cursor: MouseCursor.Hand
grab_key_focus: true
clip_x: true
clip_y: true
```

### draw_bg Properties

```
draw_bg +: {
    color: instance(#334)
    color_2: instance(vec4(-1))
    border_size: uniform(1.0)
    border_radius: uniform(5.0)
    border_color: instance(#888)
    shadow_color: instance(#0007)
    shadow_radius: uniform(10.0)
    shadow_offset: uniform(vec2(0 0))
}
```

### Draw Batching (`new_batch: true`)

Makepad batches same-shader widgets into one GPU draw call. Without `new_batch: true`, text can render behind backgrounds.

**When to use:**
- Any View with `show_bg: true` that contains Labels or text
- Hoverable items with animator + background
- Parent containers of repeated items with backgrounds
- Whenever text appears invisible despite correct color

---

## Text Widgets

### Label

```
Label{text: "Hello"}
Label{
    width: Fit height: Fit
    draw_text.color: #fff
    draw_text.text_style.font_size: 12
    text: "Styled"
}
```

**Label does NOT support `animator` or `cursor`.** To make hoverable text, wrap a Label in a View with animator.

**Default text color is WHITE.** For light themes, always set `draw_text.color` explicitly.

### Label Variants

`Label`, `Labelbold`, `LabelGradientX`, `LabelGradientY`, `TextBox`, `P`, `Pbold`

### Headings

```
H1{text: "Title"}         // font_size_1
H2{text: "Subtitle"}      // font_size_2
H3{text: "Section"}       // font_size_3
H4{text: "Subsection"}    // font_size_4
```

### draw_text Properties

```
draw_text +: {
    color: #fff
    color_2: uniform(vec4(-1))
    text_style: theme.font_regular{font_size: 11}
}
```

Available fonts: `theme.font_regular`, `theme.font_bold`, `theme.font_italic`, `theme.font_bold_italic`, `theme.font_code`, `theme.font_icons`

### TextInput

```
TextInput{width: Fill height: Fit empty_text: "Placeholder"}
TextInputFlat{width: Fill height: Fit empty_text: "Type here"}
TextInput{is_password: true empty_text: "Password"}
TextInput{is_read_only: true}
TextInput{is_numeric_only: true}
```

---

## Button Widgets

```
Button{text: "Standard"}
ButtonFlat{text: "Flat"}
ButtonFlatter{text: "Minimal"}

// Customize colors
ButtonFlat{
    text: "Custom"
    draw_bg +: {
        color: uniform(#336)
        color_hover: uniform(#449)
        color_down: uniform(#225)
    }
    draw_text +: { color: #fff }
}
```

---

## Toggle Widgets

```
CheckBox{text: "Enable"}
CheckBoxFlat{text: "Flat style"}
Toggle{text: "Dark mode"}
ToggleFlat{text: "Flat toggle"}
RadioButton{text: "Option A"}
RadioButtonFlat{text: "Option A"}
```

---

## Input Widgets

### Slider

```
Slider{width: Fill text: "Volume" min: 0.0 max: 100.0 default: 50.0}
SliderMinimal{text: "Value" min: 0.0 max: 1.0 step: 0.01 precision: 2}
```

### DropDown

```
DropDown{labels: ["Option A" "Option B" "Option C"]}
DropDownFlat{labels: ["Small" "Medium" "Large"]}
```

---

## Media Widgets

### Image

```
Image{width: 200 height: 150 fit: ImageFit.Stretch}
// ImageFit: Stretch | Horizontal | Vertical | Smallest | Biggest | Size
```

### Icon

```
Icon{
    draw_icon.svg: crate_resource("self://resources/icons/my_icon.svg")
    draw_icon.color: #0ff
    icon_walk: Walk{width: 32 height: 32}
}
```

### Vector (SVG-like Drawing)

```
Vector{width: 200 height: 200 viewbox: vec4(0 0 200 200)
    Rect{x: 10 y: 10 w: 80 h: 60 rx: 5 ry: 5 fill: #f80}
    Circle{cx: 150 cy: 50 r: 30 fill: #08f}
    Path{d: "M 10 10 L 100 100 Z" fill: #f00 stroke: #000 stroke_width: 2}
    Group{opacity: 0.7 transform: Rotate{deg: 15}
        Rect{x: 20 y: 20 w: 60 h: 60 fill: #f00}
    }
}
```

### MathView (LaTeX)

```
MathView{text: "x = \\frac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}" font_size: 14.0}
```

### MapView

**CRITICAL**: Must use fixed pixel height. Never `Fit` or `Fill`.

```
MapView{width: Fill height: 500 dark_theme: true}
```

---

## Layout Widgets

### Dividers

```
Hr{}     // horizontal rule
Vr{}     // vertical rule
```

### Filler (Spacer)

```
Filler{}   // View{width: Fill height: Fill}
```

Do NOT use `Filler{}` next to a `width: Fill` sibling in `flow: Right` -- they split space 50/50.

### Splitter

```
Splitter{
    axis: SplitterAxis.Horizontal
    align: SplitterAlign.FromA(250.0)
    a := left_panel
    b := right_panel
}
```

### FoldHeader

```
FoldHeader{
    header: View{height: Fit
        flow: Right align: Align{y: 0.5} spacing: 8
        FoldButton{}
        Label{text: "Section Title"}
    }
    body: View{height: Fit
        flow: Down padding: Inset{left: 23} spacing: 8
    }
}
```

---

## List Widgets

### PortalList (Virtualized)

```
list := PortalList{
    width: Fill height: Fill
    flow: Down
    scroll_bar: ScrollBar{}
    Item := View{
        width: Fill height: Fit
        title := Label{text: ""}
    }
}
```

### FlatList (Non-virtualized)

```
FlatList{
    width: Fill height: Fill
    flow: Down
    Item := View{height: Fit ...}
}
```

---

## Animator

Drives `instance()` variables over time for hover effects, transitions, and animations.

**Supports animator**: `View`, `SolidView`, `RoundedView`, `Button`, `ButtonFlat`, `ButtonFlatter`, `CheckBox`, `Toggle`, `RadioButton`, `LinkLabel`, `TextInput`, `ScrollXView`, `ScrollYView`, `ScrollXYView`

**Does NOT support animator**: `Label`, `H1`--`H4`, `P`, `Image`, `Icon`, `Slider`, `DropDown`, `Splitter`, `Hr`, `Filler`

### Structure

```
animator: Animator{
    hover: {
        default: @off
        off: AnimatorState{
            from: {all: Forward {duration: 0.15}}
            apply: {draw_bg: {hover: 0.0}}
        }
        on: AnimatorState{
            from: {all: Forward {duration: 0.15}}
            apply: {draw_bg: {hover: 1.0}}
        }
    }
}
```

### Play Types

```
Forward {duration: 0.2}                  // play once forward
Snap                                      // instant
Reverse {duration: 0.2, end: 1.0}       // play in reverse
Loop {duration: 1.0, end: 1000000000.0}  // repeat forward
BounceLoop {duration: 1.0, end: 1.0}    // bounce back and forth
```

### Ease Functions

`Linear`, `InQuad`, `OutQuad`, `InOutQuad`, `InCubic`, `OutCubic`, `InOutCubic`, `InSine`, `OutSine`, `InOutSine`, `InExp`, `OutExp`, `InOutExp`, `InElastic`, `OutElastic`, `InOutElastic`, `InBack`, `OutBack`, `InOutBack`, `InBounce`, `OutBounce`, `InOutBounce`, `ExpDecay{...}`, `Bezier{...}`

---

## Shader System

### Instance vs Uniform

```
draw_bg +: {
    hover: instance(0.0)          // per-draw-call, animatable
    color: uniform(#fff)           // shared across instances
    tex: texture_2d(float)         // texture sampler
}
```

### Pixel Shader

```
draw_bg +: {
    pixel: fn() {
        let sdf = Sdf2d.viewport(self.pos * self.rect_size)
        sdf.box(0. 0. self.rect_size.x self.rect_size.y 4.0)
        sdf.fill(#f00)
        return sdf.result
    }
}
```

**CRITICAL**: When returning a color directly (not via `sdf.result`), premultiply alpha with `Pal.premul()`:

```
pixel: fn() {
    return Pal.premul(self.color.mix(self.color_hover, self.hover))
}
```

### SDF Primitives

`sdf.circle(cx cy radius)`, `sdf.rect(x y w h)`, `sdf.box(x y w h border_radius)`, `sdf.hexagon(cx cy radius)`, `sdf.hline(y half_height)`

### SDF Drawing

`sdf.fill(color)`, `sdf.fill_keep(color)`, `sdf.stroke(color width)`, `sdf.stroke_keep(color w)`, `sdf.glow(color width)`, `sdf.clear(color)`

---

## Theme Variables

### Spacing

`theme.space_1`, `theme.space_2`, `theme.space_3`

### Inset Presets

`theme.mspace_1`, `theme.mspace_2`, `theme.mspace_3` (uniform)
`theme.mspace_h_1`, `theme.mspace_h_2`, `theme.mspace_h_3` (horizontal)
`theme.mspace_v_1`, `theme.mspace_v_2`, `theme.mspace_v_3` (vertical)

### Key Colors

`theme.color_bg_app`, `theme.color_fg_app`, `theme.color_bg_container`, `theme.color_bg_even`, `theme.color_bg_odd`, `theme.color_text`, `theme.color_text_hl`, `theme.color_label_inner`, `theme.color_label_outer`, `theme.color_highlight`, `theme.color_white`, `theme.color_black`, `theme.color_error`, `theme.color_warning`, `theme.color_panic`, `theme.color_selection_focus`, `theme.color_shadow`, `theme.color_app_caption_bar`

Color variants: `_hover`, `_down`, `_focus`, `_active`, `_disabled`, `_inactive`

### Typography

Font sizes: `theme.font_size_1` through `theme.font_size_4`, `theme.font_size_p`, `theme.font_size_code`, `theme.font_size_base`

Fonts: `theme.font_regular`, `theme.font_bold`, `theme.font_italic`, `theme.font_bold_italic`, `theme.font_code`, `theme.font_icons`

---

## Enums Reference

### MouseCursor

`Default`, `Hand`, `Arrow`, `Text`, `Move`, `Wait`, `Help`, `NotAllowed`, `Crosshair`, `Grab`, `Grabbing`, `NResize`, `EResize`, `SResize`, `WResize`, `NsResize`, `EwResize`, `ColResize`, `RowResize`, `Hidden`

Usage: `cursor: MouseCursor.Hand`

### ImageFit

`Stretch`, `Horizontal`, `Vertical`, `Smallest`, `Biggest`, `Size`

### SplitterAxis

`Horizontal`, `Vertical`

### SplitterAlign

`FromA(250.0)`, `FromB(200.0)`, `Weighted(0.5)`

---

## Critical Rules Summary

1. **Always `height: Fit` on containers** -- default `Fill` causes invisible 0px UI
2. **Always `width: Fill` on root container** -- never fixed pixel width at top level
3. **`new_batch: true`** on any View with `show_bg: true` that contains text
4. **`:=` for named children** in templates -- without it, overrides fail silently
5. **`draw_bg.border_radius` is a float** -- `16.0`, not an Inset
6. **Use styled Views** (`RoundedView`, `SolidView`) instead of raw `View{show_bg: true}`
7. **Default text color is WHITE** -- set `draw_text.color` explicitly for light themes
8. **No commas between properties** -- whitespace-delimited
9. **Strings use double quotes only** -- no single quotes, no backticks
10. **Use commas in `vec2()`/`vec4()` when values are negative** to avoid subtraction ambiguity
11. **Shader function args are space-separated** -- `sdf.box(0. 0. 100. 100. 5.0)`
12. **Label does NOT support animator** -- wrap in a View for hover effects
13. **Resources**: `crate_resource("self://relative/path")`
14. **`let` bindings must be defined before use** -- they are local scope
