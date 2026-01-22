# Makepad Font System Reference

## Architecture

The Makepad font system is located in `draw/src/text/` and provides:

1. **Font Loading**: Load TTF/OTF fonts from files or embedded resources
2. **Text Shaping**: Harfbuzz-based glyph positioning for complex scripts
3. **Glyph Rasterization**: High-quality glyph rendering with SDF
4. **Text Layout**: Multi-line text layout with wrapping
5. **GPU Rendering**: Efficient GPU-based text rendering

## Module Overview

| Module | Purpose |
|--------|---------|
| `font.rs` | Font handle and metrics |
| `font_atlas.rs` | GPU texture atlas management |
| `font_face.rs` | Font face (individual weight/style) |
| `font_family.rs` | Font family (group of faces) |
| `fonts.rs` | Built-in system fonts |
| `glyph_outline.rs` | Glyph vector outline data |
| `glyph_raster_image.rs` | Rasterized glyph images |
| `layouter.rs` | Text layout engine |
| `rasterizer.rs` | Glyph rasterization to atlas |
| `sdfer.rs` | Signed Distance Field generation |
| `selection.rs` | Text selection and cursor |
| `shaper.rs` | Text shaping (harfbuzz) |

## Layouter

```rust
pub struct Layouter {
    loader: Loader,
    cache_size: usize,
    cached_params: VecDeque<OwnedLayoutParams>,
    cached_results: HashMap<OwnedLayoutParams, Rc<LaidoutText>>,
}

impl Layouter {
    /// Create new layouter with settings
    pub fn new(settings: Settings) -> Self;

    /// Get rasterizer for texture atlas access
    pub fn rasterizer(&self) -> &Rc<RefCell<Rasterizer>>;

    /// Check if font family is known
    pub fn is_font_family_known(&self, id: FontFamilyId) -> bool;

    /// Check if font is known
    pub fn is_font_known(&self, id: FontId) -> bool;

    /// Define a font family
    pub fn define_font_family(&mut self, id: FontFamilyId, definition: FontFamilyDefinition);

    /// Define a font
    pub fn define_font(&mut self, id: FontId, definition: FontDefinition);

    /// Get or compute text layout (cached)
    pub fn get_or_layout(&mut self, params: impl LayoutParams) -> Rc<LaidoutText>;
}
```

## Layout Parameters

```rust
/// Owned layout parameters
pub struct OwnedLayoutParams {
    pub text: Substr,          // Text content
    pub spans: Box<[Span]>,    // Style spans
    pub options: LayoutOptions,
}

/// Text span with style
pub struct Span {
    pub style: Style,
    pub len: usize,            // Number of chars this span covers
}

/// Text style
pub struct Style {
    pub font_family_id: FontFamilyId,  // Font family name
    pub font_size_in_pts: f32,         // Size in points
    pub color: Option<Color>,          // Optional color
}

/// Layout options
pub struct LayoutOptions {
    pub max_width_in_lpxs: Option<f32>,  // Max width for wrapping
    pub wrap: bool,                       // Enable word wrap
    pub first_row_indent_in_lpxs: f32,    // First line indent
}
```

## LaidoutText Result

```rust
pub struct LaidoutText {
    pub size_in_lpxs: Size<f32>,  // Total size
    pub rows: Vec<LaidoutRow>,     // Layout rows
}

pub struct LaidoutRow {
    pub glyphs: Vec<LaidoutGlyph>,
    pub baseline_in_lpxs: f32,
    pub ascent_in_lpxs: f32,
    pub descent_in_lpxs: f32,
}

pub struct LaidoutGlyph {
    pub font: Rc<Font>,
    pub id: GlyphId,
    pub offset_in_lpxs: Point<f32>,
    pub advance_in_lpxs: f32,
}
```

## Rasterizer Settings

```rust
pub struct Settings {
    pub loader: loader::Settings,
    pub cache_size: usize,
}

impl Default for Settings {
    fn default() -> Self {
        Self {
            loader: loader::Settings {
                shaper: shaper::Settings { cache_size: 4096 },
                rasterizer: rasterizer::Settings {
                    sdfer: sdfer::Settings {
                        padding: 4,
                        radius: 8.0,
                        cutoff: 0.25,
                    },
                    grayscale_atlas_size: Size::new(4096, 4096),
                    color_atlas_size: Size::new(2048, 2048),
                },
            },
            cache_size: 4096,
        }
    }
}
```

## SDF Settings

```rust
pub struct sdfer::Settings {
    pub padding: u32,   // Padding around glyphs (default: 4)
    pub radius: f32,    // SDF radius (default: 8.0)
    pub cutoff: f32,    // SDF cutoff (default: 0.25)
}
```

## Font Atlas

The font atlas stores rasterized glyphs in GPU textures:

- **Grayscale Atlas**: 4096x4096 for regular glyphs
- **Color Atlas**: 2048x2048 for color glyphs (emoji)
- Uses SDF for resolution-independent rendering
- Automatic packing and allocation

## DSL Integration

### Defining Fonts

```rust
live_design! {
    // Font resource
    FONT_REGULAR = {
        font: { path: dep("crate://self/resources/fonts/Inter-Regular.ttf") }
    }

    FONT_BOLD = {
        font: { path: dep("crate://self/resources/fonts/Inter-Bold.ttf") }
    }

    // Text style preset
    TEXT_STYLE_BODY = {
        font: <FONT_REGULAR>
        font_size: 14.0
        line_spacing: 1.4
    }
}
```

### Using in Widgets

```rust
<Label> {
    text: "Hello World"
    draw_text: {
        text_style: <TEXT_STYLE_BODY> {}
        color: #333333
    }
}
```

### draw_text Properties

```rust
draw_text: {
    // Text style
    text_style: {
        font: { path: dep("...") }
        font_size: 16.0
        line_spacing: 1.5
        letter_spacing: 0.0
    }

    // Colors
    color: #FFFFFF
    color_hover: #CCCCCC

    // Effects
    brightness: 1.0
    curve: 0.0

    // Wrapping
    wrap: Word    // None, Word, Character

    // Instance for animation
    instance hover: 0.0
}
```

## Text Widgets

### Label

Simple single-line or multi-line text:

```rust
<Label> {
    text: "Simple text"
    draw_text: { color: #FFFFFF }
}
```

### TextFlow

Rich text with inline formatting:

```rust
<TextFlow> {
    <Bold> { text: "Bold" }
    <Italic> { text: "Italic" }
    <Link> { text: "Link", href: "..." }
    <Code> { text: "code" }
}
```

### TextInput

Editable text field:

```rust
<TextInput> {
    text: "Editable"
    draw_text: { color: #333333 }
    draw_selection: { color: #0066CC33 }
    draw_cursor: { color: #0066CC }
}
```
