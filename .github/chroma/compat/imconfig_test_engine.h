// .github/chroma/compat/imconfig_test_engine.h
//
// IMGUI_USER_CONFIG override used only by the chroma-compat CI project
// (.github/chroma/compat/CMakeLists.txt) to build Dear ImGui Test Engine
// against this fork.
//
// Per ADR-0002 ("superset, never diverge"), the fork's own imconfig.h at
// the repository root is never edited. Test Engine's own template
// (imgui_test_engine/imgui_te_imconfig.h upstream) says to "replicate or
// #include" its define into your imconfig -- this file does that instead,
// by including the real imconfig.h unmodified and adding the one extra
// define Test Engine needs on top of it. It is wired in purely through
// CMake (target_compile_definitions(... IMGUI_USER_CONFIG=...)), so no
// upstream-tracked file changes.
#pragma once

#include "../../../imconfig.h"

// Compile Dear ImGui with the Test Engine hooks.
// (Value-less define, to match the style of other defines in core Dear ImGui.)
#define IMGUI_ENABLE_TEST_ENGINE
