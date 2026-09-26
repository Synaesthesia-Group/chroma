# Changelog

## 1.92.9b-chroma.1 (unreleased)

- Main branch at upstream tag `v1.92.9b-docking`.
- CMake target `chroma::imgui` for consistent integration.
- Parity script to detect upstream compatibility regressions.
- Parity CI job that runs `parity_check.sh` and builds the `imgui` CMake target (it runs no upstream tests).
- Compatibility CI job to verify ecosystem projects build unmodified.

## Release Notes

Chroma releases follow the upstream version scheme with a `-chroma.n` suffix. The first release, 1.92.9b-chroma.1, establishes the parity and compatibility baseline. Future releases will track upstream tags and include new features behind optional flags.
