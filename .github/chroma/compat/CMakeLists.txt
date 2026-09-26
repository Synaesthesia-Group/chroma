# ---------------------------------------------------------------------------
# .github/chroma/compat/CMakeLists.txt
#
# Proves the "superset, never diverge" rule from ADR-0002 from the other
# direction: real, independently-maintained Dear ImGui extensions must
# compile, unmodified, against this fork's core sources. This is a
# standalone CMake project (not part of the root build) driven by the
# chroma-compat workflow (.github/workflows/chroma-compat.yml).
#
# Five extensions are built here:
#   - imnodes                 (Nelarius/imnodes)
#   - ImPlot                  (epezent/implot)
#   - ImGuizmo                (CedricGuillemet/ImGuizmo)
#   - ImGuiColorTextEdit      (BalazsJako/ImGuiColorTextEdit)
#   - Dear ImGui Test Engine  (ocornut/imgui_test_engine)
#
# Each one's source is fetched with FetchContent, pinned to a commit hash
# (not a branch or tag, so this project keeps building the exact same
# upstream snapshot until someone deliberately re-pins it). Each
# extension's own build system is deliberately NOT invoked -- their
# CMakeLists.txt/vcxproj files assume things (vcpkg, example apps, their
# own copy of Dear ImGui) that do not apply here. Instead, FetchContent is
# used only to populate the source tree, and this file compiles the small,
# known set of files that make up each extension's actual library into a
# static target linked against chroma::imgui, the target the root
# CMakeLists.txt defines.
# ---------------------------------------------------------------------------

cmake_minimum_required(VERSION 3.25)

project(chroma_compat LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include(FetchContent)

# ---------------------------------------------------------------------------
# This fork's own core library, built unmodified from the root
# CMakeLists.txt (three directories up from here).
# ---------------------------------------------------------------------------
if(NOT TARGET chroma::imgui)
    add_subdirectory(
        "${CMAKE_CURRENT_SOURCE_DIR}/../../.."
        "${CMAKE_CURRENT_BINARY_DIR}/chroma-core"
    )
endif()

# Dear ImGui Test Engine needs IMGUI_ENABLE_TEST_ENGINE compiled into core
# Dear ImGui itself (it adds hook call sites that are no-ops unless the
# engine is actually attached at runtime). Since there is a single shared
# "imgui" target here, that define is applied to it directly rather than
# by editing the fork's own imconfig.h -- see imconfig_test_engine.h,
# which includes that imconfig.h unmodified and adds only this one define.
target_compile_definitions(imgui PUBLIC
    "IMGUI_USER_CONFIG=\"${CMAKE_CURRENT_SOURCE_DIR}/imconfig_test_engine.h\""
)

# Each FetchContent_Declare below sets SOURCE_SUBDIR to a path that does
# not exist in the fetched repository. This is the documented way to make
# FetchContent_MakeAvailable() populate the source tree without also
# running add_subdirectory() on the extension's own (irrelevant, in this
# case) CMakeLists.txt.
set(_chroma_compat_no_subdir "chroma-compat/do-not-build-upstream-cmake")

# ---------------------------------------------------------------------------
# imnodes (Nelarius/imnodes)
# ---------------------------------------------------------------------------
FetchContent_Declare(imnodes
    GIT_REPOSITORY https://github.com/Nelarius/imnodes.git
    GIT_TAG        eb36902c892548ef94f88f51ad7e7c9c7058a71c # master @ 2026-09-26, pinned
    SOURCE_SUBDIR  "${_chroma_compat_no_subdir}"
)
FetchContent_MakeAvailable(imnodes)

add_library(imnodes STATIC
    "${imnodes_SOURCE_DIR}/imnodes.cpp"
)
target_include_directories(imnodes PUBLIC "${imnodes_SOURCE_DIR}")
target_link_libraries(imnodes PUBLIC chroma::imgui)

# ---------------------------------------------------------------------------
# ImPlot (epezent/implot)
# ---------------------------------------------------------------------------
FetchContent_Declare(implot
    GIT_REPOSITORY https://github.com/epezent/implot.git
    GIT_TAG        09e2ba71766e25d88053a2173936c9d1043bae42 # master @ 2026-09-26, pinned
    SOURCE_SUBDIR  "${_chroma_compat_no_subdir}"
)
FetchContent_MakeAvailable(implot)

add_library(implot STATIC
    "${implot_SOURCE_DIR}/implot.cpp"
    "${implot_SOURCE_DIR}/implot_items.cpp"
)
target_include_directories(implot PUBLIC "${implot_SOURCE_DIR}")
target_link_libraries(implot PUBLIC chroma::imgui)

# ---------------------------------------------------------------------------
# ImGuizmo (CedricGuillemet/ImGuizmo)
# ---------------------------------------------------------------------------
FetchContent_Declare(imguizmo
    GIT_REPOSITORY https://github.com/CedricGuillemet/ImGuizmo.git
    GIT_TAG        18cef5e031d8c6973d80284c67f60549fafd78c1 # master @ 2026-09-26, pinned
    SOURCE_SUBDIR  "${_chroma_compat_no_subdir}"
)
FetchContent_MakeAvailable(imguizmo)

add_library(imguizmo STATIC
    "${imguizmo_SOURCE_DIR}/src/ImGuizmo.cpp"
)
target_include_directories(imguizmo PUBLIC "${imguizmo_SOURCE_DIR}/src")
target_link_libraries(imguizmo PUBLIC chroma::imgui)

# ---------------------------------------------------------------------------
# ImGuiColorTextEdit (BalazsJako/ImGuiColorTextEdit)
# ---------------------------------------------------------------------------
FetchContent_Declare(imguicolortextedit
    GIT_REPOSITORY https://github.com/BalazsJako/ImGuiColorTextEdit.git
    GIT_TAG        ca2f9f1462e3b60e56351bc466acda448c5ea50d # master @ 2026-09-26, pinned
    SOURCE_SUBDIR  "${_chroma_compat_no_subdir}"
)
FetchContent_MakeAvailable(imguicolortextedit)

add_library(imguicolortextedit STATIC
    "${imguicolortextedit_SOURCE_DIR}/TextEditor.cpp"
)
target_include_directories(imguicolortextedit PUBLIC "${imguicolortextedit_SOURCE_DIR}")
target_link_libraries(imguicolortextedit PUBLIC chroma::imgui)

# ---------------------------------------------------------------------------
# Dear ImGui Test Engine (ocornut/imgui_test_engine)
#
# Built with the std::thread coroutine implementation, so it needs no
# platform-specific fiber/ucontext backend on any of the three CI runners.
# ---------------------------------------------------------------------------
FetchContent_Declare(imguitestengine
    GIT_REPOSITORY https://github.com/ocornut/imgui_test_engine.git
    GIT_TAG        9d6b7f812d5a4c00c6ee4d2f237153d40667a800 # main @ 2026-09-26, pinned
    SOURCE_SUBDIR  "${_chroma_compat_no_subdir}"
)
FetchContent_MakeAvailable(imguitestengine)

set(IMGUI_TEST_ENGINE_DIR "${imguitestengine_SOURCE_DIR}/imgui_test_engine")

add_library(imgui_test_engine STATIC
    "${IMGUI_TEST_ENGINE_DIR}/imgui_capture_tool.cpp"
    "${IMGUI_TEST_ENGINE_DIR}/imgui_te_context.cpp"
    "${IMGUI_TEST_ENGINE_DIR}/imgui_te_coroutine.cpp"
    "${IMGUI_TEST_ENGINE_DIR}/imgui_te_engine.cpp"
    "${IMGUI_TEST_ENGINE_DIR}/imgui_te_exporters.cpp"
    "${IMGUI_TEST_ENGINE_DIR}/imgui_te_perftool.cpp"
    "${IMGUI_TEST_ENGINE_DIR}/imgui_te_ui.cpp"
    "${IMGUI_TEST_ENGINE_DIR}/imgui_te_utils.cpp"
)
target_include_directories(imgui_test_engine PUBLIC "${IMGUI_TEST_ENGINE_DIR}")
target_compile_definitions(imgui_test_engine PUBLIC
    IMGUI_TEST_ENGINE_ENABLE_COROUTINE_STDTHREAD_IMPL=1
)
target_link_libraries(imgui_test_engine PUBLIC chroma::imgui)
