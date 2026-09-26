# Chroma

Chroma is a superset fork of Dear ImGui. It is built on the docking branch (v1.92.9b-docking) and adds core features behind optional compile-time flags, all off by default.

## What is Chroma?

Chroma extends Dear ImGui with carefully designed features that do not interfere with upstream compatibility. Each new capability lives behind an `IMGUI_ENABLE_<FEATURE>` flag. This means you can adopt Chroma features selectively and remain compatible with all existing ImGui ecosystems.

## Planned Features

Chroma's roadmap includes three major features:

1. **Accessibility Tree** (`IMGUI_ENABLE_ACCESSIBILITY`) — Structured accessibility data for screen readers and assistive technologies.
2. **Subpixel Text** (`IMGUI_ENABLE_LCD_TEXT`) — ClearType-style subpixel antialiasing for sharper text rendering.
3. **Text Shaping** (`IMGUI_ENABLE_SHAPING`) — Complex text layout for multi-script, bidirectional, and ligature support.

## Branch Model

- **main** — Tracks upstream at tag `v1.92.9b-docking`. This branch receives only rebased topic branches, never merge commits.
- **upstream-docking** — A mirror of the upstream `docking` branch, updated each release cycle.
- **Topic branches** — One branch per planned feature (e.g., `feature/accessibility`). Each rebases on main during upstream sync.
- **Tags** — Release tags follow the pattern `1.92.9b-chroma.n` (e.g., `1.92.9b-chroma.1`).

## How to Consume Chroma

Add Chroma to your CMake project:

```cmake
add_subdirectory(path/to/chroma)
target_link_libraries(your_target imgui)
```

The headers and namespace remain unchanged. You can also link against the `chroma::imgui` target for consistency.

## Promises

**Parity Promise:** The main branch passes upstream compatibility testing. Any regression detected by the parity job is fixed before release.

**Compatibility Promise:** Ecosystem projects build unmodified:
- imnodes
- ImPlot
- ImGuizmo
- ImGuiColorTextEdit
- Dear ImGui Test Engine

## License

Chroma is licensed under the MIT License. Upstream copyright is retained in LICENSE.txt.

For more information on Dear ImGui, see [upstream documentation](https://github.com/ocornut/imgui/blob/docking/docs/README.md).
