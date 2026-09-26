# ---------------------------------------------------------------------------
# Chroma addition — upstream Dear ImGui ships no CMake build of its own.
#
# Per ADR-0002 ("superset, never diverge"), this file is additive only: it
# builds the unmodified upstream sources as a library and never edits any
# upstream-tracked file. Consumers that already have their own build system
# can keep compiling the .cpp files directly; this target is offered for
# everyone else.
#
# Convention for future core feature flags: each one is an option named
# CHROMA_ENABLE_<FEATURE> that maps to a PUBLIC compile definition named
# IMGUI_ENABLE_<FEATURE>. The two font-backend options below (CHROMA_FREETYPE
# and CHROMA_STB_TRUETYPE) are exceptions to that naming: they map directly to
# upstream's own IMGUI_ENABLE_FREETYPE and IMGUI_ENABLE_STB_TRUETYPE macros,
# so new Chroma feature flags follow the CHROMA_ENABLE_<FEATURE> pattern, not
# the names used for these two.
# ---------------------------------------------------------------------------

cmake_minimum_required(VERSION 3.25)

project(chroma LANGUAGES CXX)

# ---------------------------------------------------------------------------
# Backend options — all OFF by default. Enabling one adds the matching
# backend source(s) to the "imgui" target and links whatever library that
# backend needs. Consumers are responsible for making any such dependency
# target (e.g. SDL3::SDL3, glfw) available before this file is included.
# ---------------------------------------------------------------------------
option(CHROMA_BACKEND_SDL3 "Build the SDL3 platform backend" OFF)
option(CHROMA_BACKEND_SDLGPU3 "Build the SDL_GPU3 renderer backend" OFF)
option(CHROMA_BACKEND_SDLRENDERER3 "Build the SDL_Renderer3 renderer backend" OFF)
option(CHROMA_BACKEND_GLFW_OPENGL3 "Build the GLFW platform backend and the OpenGL3 renderer backend" OFF)

# ---------------------------------------------------------------------------
# Core feature options.
# ---------------------------------------------------------------------------
option(CHROMA_FREETYPE "Build the FreeType-based font atlas builder (misc/freetype)" OFF)
# Only takes effect together with CHROMA_FREETYPE: upstream's own
# imgui_internal.h enables stb_truetype whenever FreeType is off, so this
# option cannot turn stb_truetype off on its own. With CHROMA_FREETYPE OFF,
# leaving this defined would also redefine IMGUI_ENABLE_STB_TRUETYPE against
# upstream's own definition (C4005 on MSVC) for every consumer.
option(CHROMA_STB_TRUETYPE "Enable the stb_truetype font atlas builder (only takes effect together with CHROMA_FREETYPE)" ON)

# ---------------------------------------------------------------------------
# Core library.
# ---------------------------------------------------------------------------
add_library(imgui STATIC
    imgui.cpp
    imgui_draw.cpp
    imgui_tables.cpp
    imgui_widgets.cpp
    imgui_demo.cpp
)
add_library(chroma::imgui ALIAS imgui)

target_include_directories(imgui PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_compile_features(imgui PUBLIC cxx_std_17)

if(CHROMA_STB_TRUETYPE AND CHROMA_FREETYPE)
    target_compile_definitions(imgui PUBLIC IMGUI_ENABLE_STB_TRUETYPE)
endif()

if(CHROMA_FREETYPE)
    find_package(Freetype REQUIRED)
    target_sources(imgui PRIVATE misc/freetype/imgui_freetype.cpp)
    target_include_directories(imgui PRIVATE misc/freetype)
    target_link_libraries(imgui PRIVATE Freetype::Freetype)
    target_compile_definitions(imgui PUBLIC IMGUI_ENABLE_FREETYPE)
endif()

if(CHROMA_BACKEND_SDL3)
    target_sources(imgui PRIVATE backends/imgui_impl_sdl3.cpp)
    target_include_directories(imgui PUBLIC backends)
    target_link_libraries(imgui PUBLIC SDL3::SDL3)
endif()

if(CHROMA_BACKEND_SDLGPU3)
    target_sources(imgui PRIVATE backends/imgui_impl_sdlgpu3.cpp)
    target_include_directories(imgui PUBLIC backends)
    target_link_libraries(imgui PUBLIC SDL3::SDL3)
endif()

if(CHROMA_BACKEND_SDLRENDERER3)
    target_sources(imgui PRIVATE backends/imgui_impl_sdlrenderer3.cpp)
    target_include_directories(imgui PUBLIC backends)
    target_link_libraries(imgui PUBLIC SDL3::SDL3)
endif()

if(CHROMA_BACKEND_GLFW_OPENGL3)
    find_package(glfw3 REQUIRED)
    target_sources(imgui PRIVATE
        backends/imgui_impl_glfw.cpp
        backends/imgui_impl_opengl3.cpp
    )
    target_include_directories(imgui PUBLIC backends)
    target_link_libraries(imgui PUBLIC glfw)
endif()
