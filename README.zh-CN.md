# Makepad 的 Claude Skills

[English](./README.md) | [中文](./README.zh-CN.md) | [日本語](./README.ja.md)

[![Version](https://img.shields.io/badge/version-2.1.0-blue.svg)](./skills/.claude-plugin/plugin.json)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](./LICENSE)

用于在 Rust 中使用 [Makepad](https://github.com/makepad/makepad) 框架构建跨平台 UI 应用的 Claude Code Skills。

## 关于 Makepad

[Makepad](https://github.com/makepad/makepad) 是一个用 Rust 编写的新一代 UI 框架，能够构建高性能的跨平台应用。主要特性包括：

- **跨平台**：单一代码库支持桌面端（macOS、Windows、Linux）、移动端（Android、iOS）和 Web（WebAssembly）
- **GPU 加速**：基于自定义着色器的渲染，使用 SDF（有向距离场）绘制
- **实时设计**：可热重载的 `live_design!` DSL，实现快速 UI 开发
- **高性能**：原生编译，无虚拟 DOM，极低的运行时开销

## 关于 Robius

[Project Robius](https://github.com/project-robius) 是一个开源项目，致力于用 Rust 构建功能完整的应用开发框架。使用 Makepad 构建的生产级应用包括：

- **[Robrix](https://github.com/project-robius/robrix)** - Matrix 聊天客户端，展示了实时消息、端到端加密和复杂 UI 模式
- **[Moly](https://github.com/moxin-org/moly)** - AI 模型管理器，展示了数据密集型界面和异步操作

这些 Skills 提取自 Robrix 和 Moly 中使用的模式。

## 安装

### 快速安装（推荐）

使用安装脚本一键完成：

```bash
# 安装到当前项目
curl -fsSL https://raw.githubusercontent.com/project-robius/makepad-skills/main/install.sh | bash

# 安装并启用 hooks
curl -fsSL https://raw.githubusercontent.com/project-robius/makepad-skills/main/install.sh | bash -s -- --with-hooks

# 安装到指定项目
curl -fsSL https://raw.githubusercontent.com/project-robius/makepad-skills/main/install.sh | bash -s -- --target /path/to/project
```

**脚本特性：**
- 自动检测 Rust/Makepad 项目（检查 Cargo.toml）
- 安装前自动备份已有 skills
- `--with-hooks` 复制并配置自我进化 hooks
- `--target` 支持安装到任意项目目录
- 彩色输出，清晰的进度提示

**可用选项：**

| 选项 | 说明 |
|------|------|
| `--target DIR` | 安装到指定目录（默认：当前目录） |
| `--with-hooks` | 启用自我进化 hooks |
| `--branch NAME` | 使用指定分支（默认：main） |
| `--help` | 显示帮助信息 |

### 手动安装

```bash
# 克隆此仓库
git clone https://github.com/project-robius/makepad-skills.git

# 复制到你的项目
cp -r makepad-skills/skills your-project/.claude/skills
```

安装后的项目结构：

```
your-project/
├── .claude/
│   └── skills/
│       ├── .claude-plugin/
│       │   └── plugin.json
│       ├── 00-getting-started/
│       ├── 01-core/
│       ├── 02-components/
│       ├── 03-graphics/
│       │   ├── _base/          # 官方 skills（原子化）
│       │   └── community/      # 社区贡献
│       ├── 04-patterns/
│       │   ├── _base/          # 官方 patterns（原子化）
│       │   └── community/      # 社区贡献
│       ├── 05-deployment/
│       ├── 06-reference/
│       ├── 99-evolution/
│       │   └── templates/      # 贡献模板
│       └── CONTRIBUTING.md
├── src/
└── Cargo.toml
```

更多详情请参阅 [Claude Code Skills 官方文档](https://docs.anthropic.com/en/docs/claude-code/skills)。

## 架构：面向协作的原子化 Skills

### 为什么采用原子化结构？

v2.1 引入了**原子化 skill 结构**，专为协作开发设计：

```
04-patterns/
├── SKILL.md              # 索引文件
├── _base/                # 官方 patterns（编号、原子化）
│   ├── 01-widget-extension.md
│   ├── 02-modal-overlay.md
│   ├── ...
│   └── 14-callout-tooltip.md
└── community/            # 你的贡献
    ├── README.md
    └── {github用户名}-{pattern名称}.md
```

**优势：**
- **无合并冲突**：你的 `community/` 文件永远不会与官方 `_base/` 更新冲突
- **并行开发**：多个用户可以同时贡献
- **清晰归属**：文件名中的 GitHub 用户名提供署名
- **渐进式披露**：SKILL.md 索引 → 单个 pattern 详情

### 自我进化：从开发中沉淀 Skills

自我进化功能允许你捕获开发过程中发现的模式，并添加到 skills 中。

#### 工作原理

1. **开发过程中**：你在使用 Makepad 构建应用时发现有用的模式、着色器或错误解决方案

2. **捕获模式**：让 Claude 保存它：
   ```
   用户：这个 tooltip 定位逻辑很有用，保存为社区 pattern
   Claude：[使用模板创建 community/{用户名}-tooltip-positioning.md]
   ```

3. **自动检测**（启用 hooks 后）：当你遇到并修复错误时，系统可以自动将解决方案捕获到 troubleshooting

#### 启用自我进化 Hooks（可选）

```bash
# 从 99-evolution 复制 hooks 到项目
cp -r your-project/.claude/skills/99-evolution/hooks your-project/.claude/skills/hooks

# 添加执行权限
chmod +x your-project/.claude/skills/hooks/*.sh

# 将 hooks 配置添加到 .claude/settings.json
# 参考 skills/99-evolution/hooks/settings.example.json
```

#### 手动创建 Pattern

直接让 Claude 创建：
```
用户：把我刚才实现的拖拽排序保存为社区 pattern
Claude：我将使用模板创建...
```

Claude 会：
1. 使用 `99-evolution/templates/pattern-template.md` 模板
2. 在 `04-patterns/community/{你的用户名}-drag-drop-reorder.md` 创建文件
3. 填写 frontmatter 和内容

### 社区贡献指南

#### 贡献 Patterns

1. **创建 pattern 文件**：
   ```
   04-patterns/community/{github用户名}-{pattern名称}.md
   ```

2. **使用模板**：从 `99-evolution/templates/pattern-template.md` 复制

3. **必需的 frontmatter**：
   ```yaml
   ---
   name: my-pattern-name
   author: your-github-handle
   source: project-where-you-discovered-this
   date: 2024-01-15
   tags: [tag1, tag2, tag3]
   level: beginner|intermediate|advanced
   ---
   ```

4. **提交 PR** 到主仓库

#### 贡献着色器/效果

1. **创建效果文件**：
   ```
   03-graphics/community/{github用户名}-{效果名称}.md
   ```

2. **使用模板**：从 `99-evolution/templates/shader-template.md` 复制

#### 贡献错误解决方案

1. **创建 troubleshooting 条目**：
   ```
   06-reference/troubleshooting/{错误名称}.md
   ```

2. **使用模板**：从 `99-evolution/templates/troubleshooting-template.md` 复制

#### 与上游同步

保持本地 skills 更新，同时保留你的贡献：

```bash
# 如果你已 fork 仓库
git fetch upstream
git merge upstream/main --no-edit
# 你的 community/ 文件不会与 _base/ 变更冲突
```

#### 晋升路径

高质量的社区贡献可能会被提升到 `_base/`：
- Pattern 广泛有用且经过充分测试
- 文档完整
- 社区反馈积极
- 通过 `author` 字段保留署名

## Skills 概览 (v2.1 原子化结构)

### [00-getting-started](./skills/00-getting-started/SKILL.md) - 项目设置

| 文件 | 描述 | 使用场景 |
|------|------|----------|
| [init.md](./skills/00-getting-started/init.md) | 项目脚手架 | "创建一个新的 Makepad 应用" |
| [project-structure.md](./skills/00-getting-started/project-structure.md) | 目录组织 | "我应该如何组织项目？" |

### [01-core](./skills/01-core/SKILL.md) - 核心开发

| 文件 | 描述 | 使用场景 |
|------|------|----------|
| [layout.md](./skills/01-core/layout.md) | 流式布局、尺寸、间距、对齐 | "排列 UI 元素" |
| [widgets.md](./skills/01-core/widgets.md) | 常用组件、自定义组件 | "如何创建按钮？" |
| [events.md](./skills/01-core/events.md) | 事件处理、命中测试 | "处理点击事件" |
| [styling.md](./skills/01-core/styling.md) | 字体、文本样式、SVG 图标 | "修改字体大小"、"添加图标" |

### [02-components](./skills/02-components/SKILL.md) - 组件库

所有内置组件参考（来自 ui_zoo）：Button、TextInput、Slider、Checkbox、Label、Image、ScrollView、PortalList、PageFlip 等。

### [03-graphics](./skills/03-graphics/SKILL.md) - 图形与动画（原子化）

`_base/` 中包含 14 个独立 skills：

| 类别 | Skills |
|------|--------|
| 着色器基础 | `01-shader-structure`, `02-shader-math` |
| SDF 绘制 | `03-sdf-shapes`, `04-sdf-drawing`, `05-progress-track` |
| 动画 | `06-animator-basics`, `07-easing-functions`, `08-keyframe-animation`, `09-loading-spinner` |
| 视觉效果 | `10-hover-effect`, `11-gradient-effects`, `12-shadow-glow`, `13-disabled-state`, `14-toggle-checkbox` |

另有 `community/` 存放你的自定义效果。

### [04-patterns](./skills/04-patterns/SKILL.md) - 生产模式（原子化）

`_base/` 中包含 14 个独立 patterns：

| 类别 | Patterns |
|------|----------|
| 组件模式 | `01-widget-extension`, `02-modal-overlay`, `03-collapsible`, `04-list-template`, `05-lru-view-cache`, `06-global-registry`, `07-radio-navigation` |
| 数据模式 | `08-async-loading`, `09-streaming-results`, `10-state-machine`, `11-theme-switching`, `12-local-persistence` |
| 高级模式 | `13-tokio-integration`, `14-callout-tooltip` |

另有 `community/` 存放你的自定义 patterns。

### [05-deployment](./skills/05-deployment/SKILL.md) - 构建与打包

构建桌面端（Linux、Windows、macOS）、移动端（Android、iOS）和 Web（WebAssembly）。

### [06-reference](./skills/06-reference/SKILL.md) - 参考资料

| 文件 | 描述 | 使用场景 |
|------|------|----------|
| [troubleshooting.md](./skills/06-reference/troubleshooting.md) | 常见错误及修复 | "Apply error: no matching field" |
| [code-quality.md](./skills/06-reference/code-quality.md) | Makepad 感知的重构 | "简化这段代码" |
| [adaptive-layout.md](./skills/06-reference/adaptive-layout.md) | 桌面/移动端响应式 | "同时支持桌面端和移动端" |

### [99-evolution](./skills/99-evolution/SKILL.md) - 自我改进

| 组件 | 描述 |
|------|------|
| `templates/` | Pattern、shader 和 troubleshooting 模板 |
| `hooks/` | 自动检测和验证 hooks |

## 使用示例

### 创建新项目
```
用户：创建一个名为 "my-app" 的 Makepad 应用，包含一个计数器按钮
Claude：[使用 00-getting-started 搭建项目，使用 01-core 实现按钮/计数器]
```

### 添加 Tooltip
```
用户：添加一个悬停时显示用户信息的 tooltip
Claude：[使用 04-patterns/_base/14-callout-tooltip.md 获取完整实现]
```

### 保存自定义 Pattern
```
用户：把这个无限滚动实现保存为社区 pattern
Claude：[创建 04-patterns/community/yourhandle-infinite-scroll.md]
```

### 修复编译错误
```
用户：遇到 "no matching field: font" 错误
Claude：[使用 06-reference/troubleshooting.md 识别正确的 text_style 语法]
```

## 你可以构建什么

使用这些 Skills，Claude 可以帮助你：

- 使用正确的结构初始化新的 Makepad 项目
- 使用 `live_design!` DSL 创建自定义组件
- 处理事件和用户交互
- 编写 GPU 着色器实现视觉效果
- 实现流畅的动画
- 使用 async/tokio 管理应用状态
- 构建响应式的桌面端/移动端布局
- 为所有平台打包应用
- **捕获并分享**你在开发过程中发现的模式

## 基于这些 Skills 构建的项目

使用 makepad-skills 和 Claude Code 创建的真实项目：

| 项目 | 描述 | 耗时 |
|------|------|------|
| [makepad-skills-demo](https://github.com/ZhangHanDong/makepad-skills-demo) | 汇率转换应用示例 | 约 20 分钟 |
| [makepad-component](https://github.com/ZhangHanDong/makepad-component) | 可复用的 Makepad 组件库 | - |

### makepad-skills-demo 截图

<p align="center">
  <img src="./assets/skill-app-demo.jpg" width="60%" alt="汇率转换应用" />
</p>

### makepad-component 截图

<p align="center">
  <img src="./assets/mc1.png" width="45%" alt="组件 1" />
  <img src="./assets/mc2.png" width="45%" alt="组件 2" />
</p>
<p align="center">
  <img src="./assets/mc3.png" width="45%" alt="组件 3" />
  <img src="./assets/mc4.png" width="45%" alt="组件 4" />
</p>

## 资源

- [Makepad 仓库](https://github.com/makepad/makepad)
- [Makepad 示例](https://github.com/makepad/makepad/tree/main/examples)
- [Project Robius](https://github.com/project-robius)
- [Robrix](https://github.com/project-robius/robrix)
- [Moly](https://github.com/moxin-org/moly)

## 许可证

MIT
