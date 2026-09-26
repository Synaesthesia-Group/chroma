# Chroma Feature Flags

Chroma extends Dear ImGui through optional compile-time flags. All flags default to off, ensuring backward compatibility.

Enable a flag for every translation unit, not just the ones that happen to define it before including `imgui.h`: set it in `imconfig.h` (or via `IMGUI_USER_CONFIG`), or use the matching CMake option (e.g. `CHROMA_ENABLE_<FEATURE>`), which adds the definition as a `PUBLIC` compile definition on the `imgui` target so every consumer gets it. Defining the flag in only one `.cpp` file before including `imgui.h` disagrees with the already-compiled `imgui.cpp` and every other translation unit — an ODR violation that can produce struct-layout mismatches and other undefined behavior.

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
