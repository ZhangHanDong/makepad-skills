# Moly API Integration Patterns

Patterns for integrating external APIs with Makepad (OpenAI, MCP, etc.) - complementary to Matrix SDK patterns.

## OpenAI Client Pattern

```rust
use async_stream::stream;
use reqwest::header::{HeaderMap, HeaderName};
use std::sync::Arc;

use crate::utils::asynchronous::{BoxPlatformSendFuture, BoxPlatformSendStream};
use crate::utils::sse::parse_sse;

pub struct OpenAIClient {
    endpoint: String,
    api_key: Option<String>,
    http_client: reqwest::Client,
}

impl OpenAIClient {
    pub fn new(endpoint: String, api_key: Option<String>) -> Self {
        Self {
            endpoint,
            api_key,
            http_client: reqwest::Client::new(),
        }
    }

    /// Fetch available models
    pub fn bots(&self) -> BoxPlatformSendFuture<'static, Result<Vec<Bot>, Error>> {
        let url = format!("{}/models", self.endpoint);
        let client = self.http_client.clone();
        let api_key = self.api_key.clone();

        Box::pin(async move {
            let mut request = client.get(&url);

            if let Some(key) = api_key {
                request = request.bearer_auth(key);
            }

            let response = request.send().await?;
            let models: Models = response.json().await?;

            Ok(models.data.into_iter().map(|m| Bot {
                id: BotId::new(&m.id),
                name: m.id,
            }).collect())
        })
    }

    /// Stream chat completion
    pub fn stream(
        &self,
        bot: &BotId,
        messages: Vec<Message>,
    ) -> BoxPlatformSendStream<'static, StreamItem> {
        let url = format!("{}/chat/completions", self.endpoint);
        let client = self.http_client.clone();
        let api_key = self.api_key.clone();
        let model = bot.id().to_string();

        Box::pin(stream! {
            // Build request body
            let body = serde_json::json!({
                "model": model,
                "messages": messages,
                "stream": true,
            });

            // Send request
            let mut request = client.post(&url)
                .header("Content-Type", "application/json")
                .body(body.to_string());

            if let Some(key) = api_key {
                request = request.bearer_auth(key);
            }

            let response = match request.send().await {
                Ok(r) => r,
                Err(e) => {
                    yield StreamItem::Error(e.into());
                    return;
                }
            };

            if !response.status().is_success() {
                yield StreamItem::Error(format!("HTTP {}", response.status()).into());
                return;
            }

            // Process SSE stream
            let mut stream = response.bytes_stream();
            let mut buffer = String::new();

            while let Some(chunk) = stream.next().await {
                match chunk {
                    Ok(bytes) => {
                        buffer.push_str(&String::from_utf8_lossy(&bytes));

                        // Parse SSE events from buffer
                        for event in parse_sse(&mut buffer) {
                            if event.data == "[DONE]" {
                                yield StreamItem::Done;
                                return;
                            }

                            match serde_json::from_str::<StreamResponse>(&event.data) {
                                Ok(response) => {
                                    if let Some(content) = response.delta_content() {
                                        yield StreamItem::Chunk(content);
                                    }
                                }
                                Err(e) => {
                                    yield StreamItem::Error(e.into());
                                }
                            }
                        }
                    }
                    Err(e) => {
                        yield StreamItem::Error(e.into());
                        return;
                    }
                }
            }
        })
    }
}

pub enum StreamItem {
    Chunk(String),
    Done,
    Error(Error),
}
```

## SSE Parsing Utility

```rust
pub struct SseEvent {
    pub event: Option<String>,
    pub data: String,
}

/// Parse SSE events from a buffer, removing consumed data
pub fn parse_sse(buffer: &mut String) -> Vec<SseEvent> {
    let mut events = Vec::new();

    while let Some(end) = buffer.find("\n\n") {
        let event_str = buffer.drain(..=end + 1).collect::<String>();

        let mut event = SseEvent {
            event: None,
            data: String::new(),
        };

        for line in event_str.lines() {
            if let Some(data) = line.strip_prefix("data: ") {
                event.data.push_str(data);
            } else if let Some(evt) = line.strip_prefix("event: ") {
                event.event = Some(evt.to_string());
            }
        }

        if !event.data.is_empty() {
            events.push(event);
        }
    }

    events
}
```

## Client Integration with UI

```rust
use moly_kit::utils::asynchronous::spawn;
use futures::StreamExt;

impl ChatWidget {
    fn send_message(&mut self, cx: &mut Cx, message: String) {
        let client = self.client.clone();
        let bot_id = self.current_bot.clone();
        let messages = self.build_message_history();

        // Start streaming
        self.set_state(cx, ChatState::Streaming);

        spawn(async move {
            let mut stream = client.stream(&bot_id, messages);

            while let Some(item) = stream.next().await {
                match item {
                    StreamItem::Chunk(text) => {
                        // Defer UI update to main thread
                        chat_runner().defer_with_redraw(move |widget, cx, _| {
                            widget.append_text(cx, &text);
                        });
                    }
                    StreamItem::Done => {
                        chat_runner().defer_with_redraw(move |widget, cx, _| {
                            widget.set_state(cx, ChatState::Idle);
                        });
                    }
                    StreamItem::Error(e) => {
                        chat_runner().defer_with_redraw(move |widget, cx, _| {
                            widget.show_error(cx, &e.to_string());
                            widget.set_state(cx, ChatState::Error);
                        });
                    }
                }
            }
        });
    }
}
```

## MCP (Model Context Protocol) Integration

```rust
pub struct McpManager {
    servers: HashMap<String, McpServer>,
    tools: HashMap<String, Tool>,
}

impl McpManager {
    pub async fn connect_server(&mut self, config: McpServerConfig) -> Result<()> {
        let server = McpServer::connect(&config).await?;

        // Fetch available tools
        let tools = server.list_tools().await?;

        for tool in tools {
            self.tools.insert(tool.name.clone(), tool);
        }

        self.servers.insert(config.name, server);
        Ok(())
    }

    pub async fn call_tool(
        &self,
        tool_name: &str,
        arguments: serde_json::Value,
    ) -> Result<ToolResult> {
        let tool = self.tools.get(tool_name)
            .ok_or_else(|| Error::ToolNotFound(tool_name.to_string()))?;

        // Find server that provides this tool
        for server in self.servers.values() {
            if server.has_tool(tool_name) {
                return server.call_tool(tool_name, arguments).await;
            }
        }

        Err(Error::NoServerForTool(tool_name.to_string()))
    }
}
```

## Tool Approval Flow

```rust
live_design! {
    ToolApprovalActions = <View> {
        spacing: 5,
        approve = <Button> {
            text: "Approve",
            draw_bg: {color: #4CAF50}
        }
        deny = <Button> {
            text: "Deny",
            draw_bg: {color: #f44336}
        }
    }

    pub ToolLine = <ChatLine> {
        message_section = {
            draw_bg: {color: #fff3e0}
            sender = {
                name = {text: "Permission Request"}
            }
            content_section = {
                tool_actions = <ToolApprovalActions> { visible: false }
            }
        }
    }
}

#[derive(Clone, DefaultNone, Debug)]
pub enum ToolApprovalAction {
    Approved { tool_call_id: String },
    Denied { tool_call_id: String },
    None,
}

impl ToolLine {
    fn handle_event(&mut self, cx: &mut Cx, event: &Event, scope: &mut Scope) {
        self.view.handle_event(cx, event, scope);

        if self.button(ids!(approve)).clicked(cx) {
            cx.widget_action(
                self.widget_uid(),
                &scope.path,
                ToolApprovalAction::Approved {
                    tool_call_id: self.tool_call_id.clone(),
                },
            );
        }

        if self.button(ids!(deny)).clicked(cx) {
            cx.widget_action(
                self.widget_uid(),
                &scope.path,
                ToolApprovalAction::Denied {
                    tool_call_id: self.tool_call_id.clone(),
                },
            );
        }
    }
}
```

## MolyClient Pattern (Local Server)

```rust
#[derive(Clone)]
pub struct MolyClient {
    address: String,
    http_client: reqwest::Client,
    connected: Arc<AtomicBool>,
}

impl MolyClient {
    pub fn new(address: String) -> Self {
        Self {
            address,
            http_client: reqwest::Client::new(),
            connected: Arc::new(AtomicBool::new(false)),
        }
    }

    pub fn address(&self) -> &str {
        &self.address
    }

    pub fn is_connected(&self) -> bool {
        self.connected.load(Ordering::Relaxed)
    }

    pub async fn test_connection(&self) -> Result<()> {
        let url = format!("{}/health", self.address);

        match self.http_client.get(&url).send().await {
            Ok(response) if response.status().is_success() => {
                self.connected.store(true, Ordering::Relaxed);
                Ok(())
            }
            Ok(response) => {
                self.connected.store(false, Ordering::Relaxed);
                Cx::post_action(MolyClientAction::ServerUnreachable);
                Err(format!("Server returned {}", response.status()).into())
            }
            Err(e) => {
                self.connected.store(false, Ordering::Relaxed);
                Cx::post_action(MolyClientAction::ServerUnreachable);
                Err(e.into())
            }
        }
    }

    pub async fn get_featured_models(&self) -> Result<Vec<Model>> {
        let url = format!("{}/api/v1/models/featured", self.address);
        let response = self.http_client.get(&url).send().await?;
        let models: Vec<Model> = response.json().await?;
        Ok(models)
    }

    pub async fn download_file(&self, model: Model, file: File) -> Result<()> {
        // ... download implementation
    }
}

#[derive(Clone, DefaultNone, Debug)]
pub enum MolyClientAction {
    ServerUnreachable,
    None,
}
```

## BotContext for Multi-Provider Support

```rust
pub struct BotContext {
    providers: HashMap<String, Box<dyn BotProvider>>,
    current_provider: Option<String>,
}

pub trait BotProvider: Send + Sync {
    fn bots(&self) -> BoxPlatformSendFuture<'static, Result<Vec<Bot>, Error>>;

    fn stream(
        &self,
        bot: &BotId,
        messages: Vec<Message>,
    ) -> BoxPlatformSendStream<'static, StreamItem>;
}

impl BotContext {
    pub fn add_provider(&mut self, name: String, provider: Box<dyn BotProvider>) {
        self.providers.insert(name, provider);
    }

    pub fn set_current(&mut self, name: &str) {
        if self.providers.contains_key(name) {
            self.current_provider = Some(name.to_string());
        }
    }

    pub fn current(&self) -> Option<&dyn BotProvider> {
        self.current_provider.as_ref()
            .and_then(|name| self.providers.get(name))
            .map(|p| p.as_ref())
    }
}
```
