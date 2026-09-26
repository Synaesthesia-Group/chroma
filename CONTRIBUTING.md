# Contributing to Chroma

Chroma is a superset fork of Dear ImGui. When contributing, please follow these guidelines to maintain compatibility and quality.

## Core Principles

**Superset, Never Diverge.** Chroma adds features on top of upstream, it does not modify or remove them. Every new core feature must live behind an `IMGUI_ENABLE_<FEATURE>` flag that defaults to off. This ensures that existing ImGui code runs unchanged.

## Workflow

1. **Fork upstream first.** Propose features to upstream Dear ImGui before implementing them in Chroma. Open a PR upstream for each feature.
2. **Topic branches.** Each planned feature lives on its own branch rebased against main, one branch per feature.
3. **Parity and compatibility.** Before release, the parity job must pass. All ecosystem projects (imnodes, ImPlot, ImGuizmo, ImGuiColorTextEdit, Dear ImGui Test Engine) must build unmodified.

## Commit Messages

Each commit message must end with the following line:

```
Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
```

Use normal English prose in commit messages. Write clearly and concisely.

## Code Review

Core changes require review by two named reviewers. During development, a single reviewer (SeamusMullan) may approve interim changes.

## Upstream Synchronization

Each release cycle:

1. Fetch upstream tags and branches.
2. Update the `upstream-docking` mirror to match upstream.
3. Move `main` to the new upstream tag by rebasing Chroma's added commits onto it (`git rebase --onto <new-upstream-tag> <old-upstream-tag> main`), then bump `scripts/chroma/upstream_tag.txt` to the new tag, commit that change, and push `main` with `--force-with-lease`. Do not `git reset --hard` main onto the tag — that deletes Chroma's added files. See `docs/chroma/process.md` for the full command sequence.
4. Rebase each topic branch onto the new main.
5. Run the parity job to detect regressions.
6. Tag the release as `1.92.9b-chroma.n`.

If a topic branch cannot rebase in a day, it must be merged to main before proceeding.

## Scope Restrictions

You may add new files in these paths:
- Root README.md, CONTRIBUTING.md, CHANGELOG.md, CMakeLists.txt
- scripts/chroma/**
- docs/chroma/**
- .github/workflows/chroma-*.yml
- .github/chroma/**

You may NOT edit any file that exists in upstream at tag v1.92.9b-docking. This rule is structural; it enforces the superset constraint.
