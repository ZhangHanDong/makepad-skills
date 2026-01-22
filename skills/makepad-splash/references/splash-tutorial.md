# Makepad Splash Language Tutorial

> Based on SPLASH_TUTORIAL_EN.md from Makepad source code

## Introduction

Splash is Makepad's dynamic scripting language designed for AI-assisted workflows and rapid prototyping. It allows runtime code execution for dynamic UI generation and automation.

## Getting Started

### Embedding in Rust

```rust
use makepad_widgets::*;

// Use script! macro to embed Splash code
script!{
    fn main() {
        console.log("Hello from Splash!");
    }
}
```

### Runtime Execution

```rust
impl App {
    fn execute_script(&mut self, cx: &mut Cx, code: &str) {
        cx.eval(code);
    }
}
```

## Language Basics

### Variables

```splash
// Immutable binding
let x = 10;

// Mutable binding
let mut y = 20;
y = 30;

// Types are inferred
let name = "Makepad";        // String
let count = 42;              // Number
let active = true;           // Boolean
let items = [1, 2, 3];       // Array
let config = { a: 1, b: 2 }; // Object
```

### Operators

```splash
// Arithmetic
let sum = a + b;
let diff = a - b;
let prod = a * b;
let quot = a / b;
let rem = a % b;

// Comparison
a == b   // Equal
a != b   // Not equal
a < b    // Less than
a <= b   // Less or equal
a > b    // Greater than
a >= b   // Greater or equal

// Logical
a && b   // And
a || b   // Or
!a       // Not

// String concatenation
let msg = "Hello, " + name;
```

### Functions

```splash
// Function definition
fn add(a, b) {
    return a + b;
}

// Arrow function
let multiply = (a, b) => a * b;

// No return (void)
fn log_message(msg) {
    console.log(msg);
}
```

### Control Flow

```splash
// If-else
if condition {
    // ...
} else if other_condition {
    // ...
} else {
    // ...
}

// Match (switch)
match value {
    1 => console.log("one"),
    2 => console.log("two"),
    _ => console.log("other"),
}

// For loop
for i in 0..10 {
    console.log(i);
}

for item in items {
    console.log(item);
}

// While loop
while condition {
    // ...
}

// Loop with break
loop {
    if done {
        break;
    }
}
```

## Built-in APIs

### Console

```splash
console.log("Info message");
console.warn("Warning message");
console.error("Error message");
console.debug("Debug message");
```

### HTTP Requests

```splash
// GET request
let response = http.get("https://api.example.com/data");
console.log(response.status);
console.log(response.body);

// POST request
let response = http.post("https://api.example.com/data", {
    headers: {
        "Content-Type": "application/json"
    },
    body: {
        name: "test",
        value: 123
    }
});

// Parse JSON response
let data = response.json();
```

### Timers

```splash
// Timeout (one-time)
timer.set(1000, fn() {
    console.log("1 second elapsed");
});

// Interval (repeating)
let interval_id = timer.interval(500, fn() {
    console.log("tick");
});

// Clear timer
timer.clear(interval_id);

// Delay (async)
await timer.delay(2000);
console.log("After 2 seconds");
```

### UI Interaction

```splash
// Access widget by ID
let button = ui.widget("my_button");

// Set properties
button.set_text("Click Me");
button.set_visible(true);
button.set_enabled(false);

// Get properties
let text = button.get_text();
let visible = button.is_visible();

// Event handlers
button.on_click(fn() {
    console.log("Clicked!");
});

// Create widgets dynamically
let view = ui.create("View");
view.set_width("Fill");
view.set_height("Fit");

let label = ui.create("Label");
label.set_text("Dynamic Label");
view.add_child(label);
```

## Async/Await

```splash
// Async function
async fn fetch_user(id) {
    let response = await http.get("https://api.example.com/users/" + id);
    return response.json();
}

// Call async function
fetch_user(123).then(fn(user) {
    console.log("Got user: " + user.name);
}).catch(fn(error) {
    console.error("Failed: " + error);
});

// Or with await
async fn main() {
    let user = await fetch_user(123);
    console.log(user.name);
}
```

## Arrays

```splash
let items = [1, 2, 3, 4, 5];

// Access
let first = items[0];
let last = items[items.length - 1];

// Methods
items.push(6);           // Add to end
items.pop();             // Remove from end
items.shift();           // Remove from start
items.unshift(0);        // Add to start

// Iteration
for item in items {
    console.log(item);
}

// Map
let doubled = items.map(fn(x) => x * 2);

// Filter
let even = items.filter(fn(x) => x % 2 == 0);

// Reduce
let sum = items.reduce(fn(acc, x) => acc + x, 0);
```

## Objects

```splash
let person = {
    name: "Alice",
    age: 30,
    greet: fn() {
        console.log("Hello, I'm " + this.name);
    }
};

// Access
console.log(person.name);
console.log(person["age"]);

// Modify
person.name = "Bob";
person.email = "bob@example.com";

// Methods
person.greet();

// Iteration
for key in person {
    console.log(key + ": " + person[key]);
}
```

## Error Handling

```splash
// Try-catch
try {
    let result = risky_operation();
    console.log(result);
} catch error {
    console.error("Error: " + error.message);
}

// Throw error
fn validate(value) {
    if value < 0 {
        throw "Value must be positive";
    }
}
```

## AI Workflow Example

```splash
// Dynamic form generation for AI
async fn create_ai_form(prompt) {
    // AI generates form spec
    let response = await http.post("https://ai.api/generate", {
        body: { prompt: prompt }
    });

    let spec = response.json();

    // Create form dynamically
    let form = ui.create("View");
    form.set_flow("Down");
    form.set_padding(20);

    for field in spec.fields {
        let row = ui.create("View");
        row.set_flow("Right");

        let label = ui.create("Label");
        label.set_text(field.label);
        row.add_child(label);

        let input = ui.create("TextInput");
        input.set_placeholder(field.placeholder);
        row.add_child(input);

        form.add_child(row);
    }

    let submit = ui.create("Button");
    submit.set_text(spec.submit_text);
    submit.on_click(fn() {
        // Handle form submission
    });
    form.add_child(submit);

    return form;
}

// Usage
create_ai_form("Create a contact form").then(fn(form) {
    ui.root().add_child(form);
});
```

## Best Practices

1. **Use Rust for performance**: Splash is for flexibility, not speed
2. **Keep scripts small**: Large scripts should be Rust code
3. **Handle errors**: Always use try-catch for risky operations
4. **Clean up timers**: Clear intervals when no longer needed
5. **Validate input**: Check data from external sources
