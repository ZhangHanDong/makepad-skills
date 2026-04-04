# Splash Scripting Patterns

Common patterns with complete working examples for the Splash scripting language in Makepad 2.0. All examples are based on the actual `examples/counter` and `examples/todo` apps.

---

## 1. Counter App Pattern (State + Render + script_eval)

The simplest complete Splash app demonstrating state management, reactive rendering, and Rust-to-Splash event bridging.

### Splash Script (inside `script_mod!{}`)

```
use mod.prelude.widgets.*

let state = {
    counter: 0
}
mod.state = state

startup() do #(App::script_component(vm)){
    ui: Root{
        on_startup: ||{
            ui.main_view.render()
        }
        main_window := Window{
            window.inner_size: vec2(420, 220)
            body +: {
                main_view := View{
                    width: Fill
                    height: Fill
                    flow: Down
                    spacing: 12
                    align: Center
                    on_render: ||{
                        counter_label := Label{
                            text: "Count: " + state.counter
                            draw_text.text_style.font_size: 24
                        }
                    }
                }
                increment_button := Button{
                    text: "Increment"
                }
            }
        }
    }
}
```

### Rust Boilerplate

```rust
use makepad_widgets::*;

app_main!(App);

// script_mod! { ... } goes here

impl App {
    fn run(vm: &mut ScriptVm) -> Self {
        crate::makepad_widgets::script_mod(vm);
        App::from_script_mod(vm, self::script_mod)
    }
}

#[derive(Script, ScriptHook)]
pub struct App {
    #[live]
    ui: WidgetRef,
}

impl MatchEvent for App {
    fn handle_actions(&mut self, cx: &mut Cx, actions: &Actions) {
        if self.ui.button(cx, ids!(increment_button)).clicked(actions) {
            script_eval!(cx, {
                mod.state.counter += 1
                ui.main_view.render()
            });
        }
    }
}

impl AppMain for App {
    fn handle_event(&mut self, cx: &mut Cx, event: &Event) {
        self.match_event(cx, event);
        self.ui.handle_event(cx, event, &mut Scope::empty());
    }
}
```

### Key Takeaways

- `mod.state` stores application state accessible from both Splash and Rust
- `on_render: ||{ ... }` is a reactive callback that rebuilds children when `.render()` is called
- `script_eval!(cx, { ... })` executes Splash code from Rust event handlers
- `ui.widget_name.render()` triggers a re-render of that widget's `on_render` block
- `on_startup` runs once when the app launches

---

## 2. Todo List Pattern (Templates + For Loops + Events)

A full todo list demonstrating reusable templates, dynamic list rendering, inline events, and array state management.

### Splash Script

```
use mod.prelude.widgets.*

// Vector Icons
let IconCheck = Vector{width: 18 height: 18 viewbox: vec4(0 0 24 24)
    Path{d: "M20 6L9 17L4 12" fill: false stroke: theme.color_highlight stroke_width: 2.5
        stroke_linecap: "round" stroke_linejoin: "round"}
}

let IconClipboard = Vector{width: 40 height: 40 viewbox: vec4(0 0 24 24)
    Path{d: "M9 5H7a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2h-2"
        fill: false stroke: theme.color_label_inner_inactive stroke_width: 1.2
        stroke_linecap: "round" stroke_linejoin: "round"}
}

// Tag color function
fn tag_color(tag) {
    if tag == "dev" theme.color_highlight
    else if tag == "urgent" theme.color_warning
    else if tag == "personal" theme.color_outset_focus
    else theme.color_highlight
}

// Reusable template with named children
let TodoItem = RoundedView{
    width: Fill height: Fit
    padding: theme.mspace_2{left: theme.space_3, right: theme.space_3}
    flow: Right spacing: theme.space_2
    align: Align{y: 0.5}
    draw_bg.color: theme.color_bg_container
    draw_bg.border_radius: 10.0

    check := CheckBox{text: ""}
    label := Label{
        width: Fill
        text: "task"
        draw_text.color: theme.color_label_inner
        draw_text.text_style.font_size: theme.font_size_p
    }
    tag := RoundedView{
        width: Fit height: Fit
        padding: theme.mspace_h_1{left: theme.space_2, right: theme.space_2}
        draw_bg.color: theme.color_bg_highlight_inline
        draw_bg.border_radius: 4.0
        tag_label := Label{
            text: ""
            draw_text.color: theme.color_highlight
            draw_text.text_style.font_size: theme.font_size_code
            draw_text.text_style: theme.font_bold{}
        }
    }
    delete := ButtonFlatter{
        text: "x"
        width: 28 height: 28
        draw_text +: {
            color: theme.color_label_inner_inactive
            text_style +: {font_size: theme.font_size_p}
        }
    }
}

// Empty state display
let EmptyState = View{
    width: Fill height: 260
    align: Center
    flow: Down spacing: theme.space_2
    IconClipboard{}
    Label{text: "No tasks yet" draw_text.color: theme.color_label_inner_inactive
        draw_text.text_style.font_size: theme.font_size_4}
    Label{text: "Add one below to get started"
        draw_text.color: theme.color_label_inner_inactive * 0.8
        draw_text.text_style.font_size: theme.font_size_p}
}

// State (array)
let todos = []
todos.push({text: "Get AI to control UI", tag: "dev", done: true})

// State manipulation functions
fn add_todo(text, tag) {
    todos.push({text: text, tag: tag, done: false})
    ui.todo_list.render()
}

fn toggle_todo(index, checked) {
    todos[index].done = checked
}

fn delete_todo(index) {
    todos.remove(index)
    ui.todo_list.render()
}

fn count_remaining() {
    let n = 0
    for todo in todos {
        if !todo.done { n = n + 1 }
    }
    n
}

// UI -- app structure
let app = startup() do #(App::script_component(vm)){
    ui: Root{
        on_startup: ||{
            ui.todo_list.render()
        }
        main_window := Window{
            pass.clear_color: theme.color_bg_app
            window.inner_size: vec2(520, 720)
            body +: {
                width: Fill height: Fill
                flow: Down spacing: 0
                align: Align{x: 0.5}

                // Add bar with TextInput and Button
                SolidView{
                    width: Fill height: Fit
                    padding: theme.mspace_2{left: theme.space_3 * 2, right: theme.space_3 * 2}
                    draw_bg.color: theme.color_bg_container

                    View{
                        width: Fill height: Fit
                        flow: Right spacing: 10
                        align: Align{y: 0.5}

                        todo_input := TextInput{
                            width: Fill height: 9. * theme.space_1
                            empty_text: "What needs to be done?"
                            on_return: || ui.add_button.on_click()
                        }
                        add_button := Button{
                            text: "+"
                            width: 40 height: 34
                            on_click: ||{
                                let text = ui.todo_input.text()
                                if text != "" {
                                    add_todo(text, "")
                                    ui.todo_input.set_text("")
                                }
                            }
                        }
                    }
                }

                // Dynamic todo list with on_render
                todo_list := ScrollYView{
                    width: Fill height: Fill
                    padding: theme.mspace_2{left: theme.space_3, right: theme.space_3}
                    flow: Down spacing: theme.space_1
                    new_batch: true
                    on_render: ||{
                        if todos.len() == 0
                            EmptyState{}
                        else for i, todo in todos {
                            TodoItem{
                                label.text: todo.text
                                tag.tag_label.text: todo.tag
                                check.active: todo.done
                                check.on_click: |checked| toggle_todo(i, checked)
                                delete.on_click: || delete_todo(i)
                            }
                        }
                    }
                    EmptyState{}
                }

                // Footer with clear button
                SolidView{
                    width: Fill height: Fit
                    padding: theme.mspace_2{left: theme.space_3 * 2, right: theme.space_3 * 2}
                    draw_bg.color: theme.color_app_caption_bar
                    flow: Right
                    align: Align{y: 0.5}

                    status := Label{
                        text: ""
                        draw_text.color: theme.color_label_inner_inactive
                        draw_text.text_style.font_size: theme.font_size_code
                    }
                    Filler{}
                    clear_done := ButtonFlatter{
                        text: "Clear completed"
                        on_click: ||{
                            todos.retain(|todo| !todo.done)
                            ui.todo_list.render()
                        }
                    }
                }
            }
        }
    }
}
app
```

### Key Takeaways

- `let TodoItem = RoundedView{...}` defines a reusable template with named children
- `for i, todo in todos { TodoItem{label.text: todo.text} }` iterates and overrides per-instance
- `check.on_click: |checked| toggle_todo(i, checked)` captures loop variable `i` in closure
- `todos.retain(|todo| !todo.done)` filters array in-place
- `ui.todo_list.render()` triggers re-render after state changes
- `ScrollYView` with `new_batch: true` for scrollable, properly-batched lists

---

## 3. Reusable Template Pattern (Let Bindings with := Children)

Define component-like templates with overridable named children.

```
use mod.prelude.widgets.*

// Card template with title and body
let InfoCard = RoundedView{
    width: Fill height: Fit
    padding: 16 flow: Down spacing: 6
    draw_bg.color: #2a2a3d
    draw_bg.border_radius: 8.0
    new_batch: true
    title := Label{text: "Title" draw_text.color: #fff draw_text.text_style.font_size: 14}
    body := Label{text: "Body" draw_text.color: #aaa draw_text.text_style.font_size: 11}
}

// List item with multiple named parts
let ListItem = View{
    width: Fill height: Fit
    padding: Inset{top: 8 bottom: 8 left: 12 right: 12}
    flow: Right spacing: 10
    align: Align{y: 0.5}
    icon := Icon{
        draw_icon.color: #0ff
        icon_walk: Walk{width: 20 height: 20}
    }
    texts := View{
        width: Fill height: Fit
        flow: Down spacing: 2
        title := Label{text: "" draw_text.color: #fff draw_text.text_style.font_size: 12}
        subtitle := Label{text: "" draw_text.color: #888 draw_text.text_style.font_size: 10}
    }
    badge := Label{text: "" draw_text.color: #666 draw_text.text_style.font_size: 9}
}

// Usage -- override any named child property
View{
    flow: Down height: Fit spacing: 10 padding: 20
    InfoCard{title.text: "Welcome" body.text: "Getting started with Makepad"}
    InfoCard{title.text: "Settings" body.text: "Configure your preferences"}

    ListItem{
        texts.title.text: "Documents"
        texts.subtitle.text: "3 files"
        badge.text: "NEW"
    }
}
```

### Rules for Templates

1. **Use `:=` for all children you want to override** -- `label :=`, `title :=`, `body :=`
2. **Named children inside unnamed Views are unreachable** -- name every container in the path
3. **Override with dot-path syntax** -- `Item{texts.title.text: "new value"}`
4. **Templates are local scope** -- define with `let` before use

---

## 4. HTTP Request Pattern (GET, POST, Streaming)

### Search and Display Results

```
use mod.prelude.widgets.*

let results = []

fn do_search(query) {
    let req = net.HttpRequest{
        url: "https://html.duckduckgo.com/html/?q=" + query
        method: net.HttpMethod.GET
        headers: {"User-Agent": "MakepadApp/1.0"}
    }
    net.http_request(req) do net.HttpEvents{
        on_response: |res| {
            let doc = res.body.to_string().parse_html()
            let links = doc.query("a.result__a").array()
            let snippets = doc.query("a.result__snippet").array()
            results = []
            for link, i in links {
                results.push({
                    title: link.text
                    url: link.attr("href")
                    snippet: if i < snippets.len() snippets[i].text else ""
                })
            }
            ui.results_view.render()
        }
        on_error: |e| {
            // handle error
        }
    }
}

// ... inside startup() UI definition:
search_input := TextInput{
    width: Fill height: Fit
    empty_text: "Search..."
    on_return: || do_search(ui.search_input.text())
}

results_view := ScrollYView{
    width: Fill height: Fill
    flow: Down spacing: 8
    on_render: ||{
        for i, result in results {
            RoundedView{
                width: Fill height: Fit
                padding: 12 flow: Down spacing: 4
                draw_bg.color: #2a2a3d
                draw_bg.border_radius: 6.0
                new_batch: true
                Label{text: result.title draw_text.color: #4af
                    draw_text.text_style.font_size: 12}
                Label{text: result.snippet draw_text.color: #aaa
                    draw_text.text_style.font_size: 10}
            }
        }
    }
}
```

### POST with JSON

```
fn submit_data(name, email) {
    let req = net.HttpRequest{
        url: "https://api.example.com/users"
        method: net.HttpMethod.POST
        headers: {"Content-Type": "application/json"}
        body: {name: name, email: email}.to_json()
    }
    net.http_request(req) do net.HttpEvents{
        on_response: |res| {
            let data = res.body.parse_json()
            // handle response
        }
        on_error: |e| { /* handle error */ }
    }
}
```

### Streaming Response (LLM-style)

```
fn stream_chat(prompt) {
    let req = net.HttpRequest{
        url: "https://api.example.com/chat"
        method: net.HttpMethod.POST
        is_streaming: true
        headers: {"Content-Type": "application/json" "Authorization": "Bearer TOKEN"}
        body: {prompt: prompt, stream: true}.to_json()
    }
    var accumulated = ""
    net.http_request(req) do net.HttpEvents{
        on_stream: |res| {
            accumulated += res.body.to_string()
            // Update UI incrementally
            ui.response_view.render()
        }
        on_complete: |res| {
            // Stream finished
        }
        on_error: |e| { /* handle error */ }
    }
}
```

---

## 5. HTML Parsing Pattern (Search + Extract)

### Parse and Query HTML

```
fn parse_page(html_string) {
    let doc = html_string.parse_html()

    // Query by tag
    let paragraphs = doc.query("p")

    // Query by class
    let highlights = doc.query("span.highlight")

    // Query by id
    let main = doc.query("#main-content")

    // Nested query
    let nav_links = doc.query("nav").query("a")

    // Extract text and attributes
    let items = doc.query("a.result__a").array()
    for item, i in items {
        let title = item.text
        let href = item.attr("href")
        results.push({title: title, url: href})
    }
}
```

### Full Search + Parse + Display

```
fn search_and_display(query) {
    let req = net.HttpRequest{
        url: "https://html.duckduckgo.com/html/?q=" + query
        method: net.HttpMethod.GET
        headers: {"User-Agent": "MakepadApp/1.0"}
    }
    net.http_request(req) do net.HttpEvents{
        on_response: |res| {
            let doc = res.body.to_string().parse_html()

            // Extract results using CSS-like selectors
            let links = doc.query("a.result__a").array()
            let snippets = doc.query("a.result__snippet").array()

            results = []
            for link, i in links {
                results.push({
                    title: link.text
                    url: link.attr("href")
                    snippet: if i < snippets.len() snippets[i].text else ""
                })
            }
            ui.results_view.render()
        }
        on_error: |e| { /* handle */ }
    }
}
```

---

## 6. Hoverable Item Pattern (View with Animator Wrapping Label)

Label does NOT support animator. Wrap it in a View to get hover effects. Always set `new_batch: true` on both the item and the parent container.

```
use mod.prelude.widgets.*

let HoverItem = View{
    width: Fill height: Fit
    padding: 8
    cursor: MouseCursor.Hand
    new_batch: true
    show_bg: true
    draw_bg +: {
        color: uniform(#0000)
        color_hover: uniform(#fff2)
        hover: instance(0.0)
        pixel: fn(){
            return Pal.premul(self.color.mix(self.color_hover, self.hover))
        }
    }
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
    label := Label{text: "item" draw_text.color: #fff}
}

// Parent container ALSO needs new_batch
RoundedView{
    width: 300 height: Fit
    padding: 10 flow: Down spacing: 4
    new_batch: true
    draw_bg.color: #222
    draw_bg.border_radius: 5.0
    Label{text: "Todo Items" draw_text.color: #fff}
    HoverItem{label.text: "Walk the dog"}
    HoverItem{label.text: "Do laundry"}
    HoverItem{label.text: "Buy groceries"}
}
```

### Key Points

- `show_bg: true` enables background rendering
- `draw_bg +: { ... }` defines custom shader with `instance(0.0)` for hover state
- `pixel: fn()` custom shader mixes between normal and hover colors
- **CRITICAL**: `Pal.premul()` wraps the return value for correct alpha blending
- `new_batch: true` on BOTH the item AND the parent prevents text vanishing on hover
- `cursor: MouseCursor.Hand` changes cursor on hover
- Animator `hover` group drives `draw_bg.hover` between 0.0 and 1.0

---

## 7. Theme-Aware Styling Pattern

Use `theme.*` variables for consistent, theme-respecting styling across light and dark modes.

### Colors

```
// Background colors
draw_bg.color: theme.color_bg_app              // app background
draw_bg.color: theme.color_bg_container         // card/panel background
draw_bg.color: theme.color_app_caption_bar      // header/footer bar
draw_bg.color: theme.color_bg_highlight         // subtle highlight
draw_bg.color: theme.color_fg_app               // foreground/toolbar

// Text colors
draw_text.color: theme.color_label_inner        // primary text
draw_text.color: theme.color_label_inner_inactive  // secondary/muted text
draw_text.color: theme.color_highlight          // accent/link text
draw_text.color: theme.color_white              // white text
draw_text.color: theme.color_warning            // warning text
draw_text.color: theme.color_error              // error text
```

### Typography

```
// Font sizes
draw_text.text_style.font_size: theme.font_size_1   // largest heading
draw_text.text_style.font_size: theme.font_size_2   // heading
draw_text.text_style.font_size: theme.font_size_3   // subheading
draw_text.text_style.font_size: theme.font_size_4   // small heading
draw_text.text_style.font_size: theme.font_size_p   // body/paragraph
draw_text.text_style.font_size: theme.font_size_code // code/monospace

// Font faces
draw_text.text_style: theme.font_regular{}
draw_text.text_style: theme.font_bold{font_size: theme.font_size_2}
draw_text.text_style: theme.font_italic{}
draw_text.text_style: theme.font_code{}
```

### Spacing

```
// Uniform spacing
padding: theme.mspace_1     // small
padding: theme.mspace_2     // medium
padding: theme.mspace_3     // large

// Horizontal-only spacing
padding: theme.mspace_h_1
padding: theme.mspace_h_2

// Override specific sides
padding: theme.mspace_2{left: theme.space_3, right: theme.space_3}

// Gap between children
spacing: theme.space_1      // small
spacing: theme.space_2      // medium
spacing: theme.space_3      // large
```

### Complete Theme-Aware Card

```
let ThemeCard = RoundedView{
    width: Fill height: Fit
    padding: theme.mspace_2{left: theme.space_3, right: theme.space_3}
    flow: Down spacing: theme.space_1
    draw_bg.color: theme.color_bg_container
    draw_bg.border_radius: theme.corner_radius
    new_batch: true

    title := Label{
        text: "Title"
        draw_text.color: theme.color_label_inner
        draw_text.text_style: theme.font_bold{font_size: theme.font_size_3}
    }
    body := Label{
        text: "Body"
        draw_text.color: theme.color_label_inner_inactive
        draw_text.text_style.font_size: theme.font_size_p
    }
}
```

### Setting the Theme

In Rust, set light or dark theme before loading widgets:

```rust
impl App {
    fn run(vm: &mut ScriptVm) -> Self {
        crate::makepad_widgets::theme_mod(vm);
        script_eval!(vm, {
            mod.theme = mod.themes.light    // or mod.themes.dark
        });
        crate::makepad_widgets::widgets_mod(vm);
        App::from_script_mod(vm, self::script_mod)
    }
}
```

---

## 8. Cross-Module Sharing via mod Object

The `mod` object is a shared namespace accessible from both Splash scripts and Rust code.

### Storing State on mod

```
// In script_mod!
let state = {
    counter: 0
    user: {name: "" logged_in: false}
    items: []
}
mod.state = state
```

### Accessing from Rust with script_eval!

```rust
// Read and modify state from Rust
script_eval!(cx, {
    mod.state.counter += 1
    mod.state.user.name = #("Alice")    // #() interpolates Rust values
    ui.main_view.render()
});
```

### Sharing Functions

```
// Define utility functions accessible across the module
fn format_count(n) {
    if n == 0 "No items"
    else if n == 1 "1 item"
    else n + " items"
}

// Use from on_render or event handlers
on_render: ||{
    Label{text: format_count(todos.len())}
}
```

### Sharing Between script_mod! and script_eval!

Variables defined at the top level of `script_mod!` are accessible from `script_eval!`:

```
// script_mod!
let todos = []
fn add_todo(text, tag) {
    todos.push({text: text, tag: tag, done: false})
    ui.todo_list.render()
}

// From Rust:
script_eval!(cx, {
    add_todo("New task from Rust", "dev")
});
```

### mod.state Pattern (Recommended)

Store all shared state on `mod.state` for clarity:

```
// Define
let state = {
    counter: 0
    theme: "dark"
    settings: {sound: true, notifications: false}
}
mod.state = state

// Access from anywhere
mod.state.counter += 1
mod.state.theme = "light"

// From Rust
script_eval!(cx, {
    mod.state.counter = #(new_value)
    ui.main_view.render()
});
```

---

## Pattern Summary

| Pattern | Key Elements | When to Use |
|---------|-------------|-------------|
| Counter | `mod.state`, `on_render`, `script_eval!` | Simple state + reactive UI |
| Todo List | `let` templates, `for` loops, inline events | Lists with CRUD operations |
| Reusable Template | `let` + `:=` children, dot-path overrides | Component-like reuse |
| HTTP Request | `net.http_request`, callbacks | API calls, search |
| HTML Parsing | `.parse_html()`, `.query()` | Scraping, content extraction |
| Hoverable Item | `View` + `animator` + `new_batch` | Interactive list items |
| Theme-Aware | `theme.*` variables | Consistent cross-theme styling |
| Cross-Module | `mod.state`, `script_eval!` | Rust-Splash data sharing |
