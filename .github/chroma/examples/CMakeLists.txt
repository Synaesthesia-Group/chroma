# ---------------------------------------------------------------------------
# .github/chroma/examples/CMakeLists.txt
#
# Builds three of upstream's own example applications, unmodified, against
# this fork's SDL3, SDL_GPU3, SDL_Renderer3 and GLFW+OpenGL3 backends. This
# is a standalone CMake project (not part of the root build) driven by the
# chroma-examples workflow (.github/workflows/chroma-examples.yml). It
# exists because upstream's own build.yml workflow is disabled on this
# fork -- its Test jobs clone imgui_test_engine at `master`, which does not
# compile against the v1.92.9b-docking baseline this fork tracks -- so this
# is now the only CI coverage proving the backends Chroma cares about still
# build, on all three operating systems Dear ImGui itself supports.
#
# SDL3 is fetched with FetchContent, pinned to a release tag (not a branch,
# so this project keeps building the exact same upstream release until
# someone deliberately re-pins it) and built as a static library. GLFW is
# expected to already be on the system (installed by the workflow via apt
# or brew) and is located with find_package(), matching what the root
# CMakeLists.txt itself expects a consumer to provide.
#
# The CHROMA_BACKEND_* options that select which backends the root
# CMakeLists.txt's "imgui" target builds are passed on the command line
# that configures this project (see the workflow), not hard-coded here, so
# a single copy of this file works for every leg of the workflow's matrix.
# CHROMA_BACKEND_GLFW_OPENGL3 is left OFF on windows (see the workflow),
# which is what keeps the GLFW example out of the windows build below.
# ---------------------------------------------------------------------------

cmake_minimum_required(VERSION 3.25)

project(chroma_examples LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include(FetchContent)

# ---------------------------------------------------------------------------
# SDL3, built as a static library so the example executables carry no SDL3
# runtime dependency. SDL_TEST_LIBRARY is off because nothing here
# exercises SDL's own test suite.
# ---------------------------------------------------------------------------
set(SDL_TEST_LIBRARY OFF CACHE BOOL "" FORCE)
set(SDL_SHARED OFF CACHE BOOL "" FORCE)
set(SDL_STATIC ON CACHE BOOL "" FORCE)

FetchContent_Declare(SDL3
    GIT_REPOSITORY https://github.com/libsdl-org/SDL.git
    GIT_TAG        f5e5f6588921eed3d7d048ce43d9eb1ff0da0ffc # release-3.2.30, pinned
)
FetchContent_MakeAvailable(SDL3)

# ---------------------------------------------------------------------------
# GLFW + OpenGL, only when that backend is requested (the ubuntu and macos
# legs of the workflow's matrix; left off on windows). Provided by the
# system (libglfw3-dev via apt, glfw via brew) and located the same way the
# root CMakeLists.txt's own find_package(glfw3 REQUIRED) call expects.
# find_package(OpenGL) matches upstream's own example Makefile, which links
# -lGL on Linux and the OpenGL framework on macOS.
# ---------------------------------------------------------------------------
if(CHROMA_BACKEND_GLFW_OPENGL3)
    find_package(glfw3 REQUIRED)
    find_package(OpenGL REQUIRED)
endif()

# ---------------------------------------------------------------------------
# This fork's own core library, built unmodified from the root
# CMakeLists.txt (three directories up from here). SDL3::SDL3 above and,
# when requested, the glfw target above are already defined, satisfying
# what the root CMakeLists.txt expects a consumer to provide before its
# backend options are turned on.
# ---------------------------------------------------------------------------
if(NOT TARGET chroma::imgui)
    add_subdirectory(
        "${CMAKE_CURRENT_SOURCE_DIR}/../../.."
        "${CMAKE_CURRENT_BINARY_DIR}/chroma-core"
    )
endif()

set(_chroma_examples_dir "${CMAKE_CURRENT_SOURCE_DIR}/../../../examples")

add_executable(example_sdl3_sdlgpu3
    "${_chroma_examples_dir}/example_sdl3_sdlgpu3/main.cpp"
)
target_link_libraries(example_sdl3_sdlgpu3 PRIVATE chroma::imgui SDL3::SDL3)

add_executable(example_sdl3_sdlrenderer3
    "${_chroma_examples_dir}/example_sdl3_sdlrenderer3/main.cpp"
)
target_link_libraries(example_sdl3_sdlrenderer3 PRIVATE chroma::imgui SDL3::SDL3)

if(CHROMA_BACKEND_GLFW_OPENGL3)
    add_executable(example_glfw_opengl3
        "${_chroma_examples_dir}/example_glfw_opengl3/main.cpp"
    )
    target_link_libraries(example_glfw_opengl3 PRIVATE chroma::imgui glfw OpenGL::GL)
endif()
