# Chroma Feature Flags

Chroma extends Dear ImGui through optional compile-time flags. All flags default to off, ensuring backward compatibility. Enable a flag by defining it before including `imgui.h`.

## IMGUI_ENABLE_ACCESSIBILITY

**Status:** Planned

Provides structured accessibility tree data for screen readers and assistive technologies. This flag enables collection of semantic information about UI elements, their relationships, and their states.

When enabled, accessibility data is available through the core ImGui API.

## IMGUI_ENABLE_LCD_TEXT

**Status:** Planned

Enables subpixel text rendering using ClearType-style antialiasing. This produces sharper text on LCD displays by rendering separate color channels for each pixel.

When enabled, text rendering uses subpixel information to improve visual clarity.

## IMGUI_ENABLE_SHAPING

**Status:** Planned

Enables complex text layout and shaping for multi-script text, bidirectional text, and ligature support. This flag turns on HarfBuzz integration for proper text rendering in diverse scripts.

When enabled, text is shaped before rendering, supporting scripts like Arabic, Devanagari, and others.
