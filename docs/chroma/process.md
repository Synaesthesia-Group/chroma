# Upstream Synchronization Process

This document describes how to synchronize Chroma with upstream Dear ImGui during each release cycle.

## Prerequisites

- The upstream remote is named `upstream`.
- The `upstream-docking` branch mirrors the upstream docking branch.
- Each topic branch (feature/accessibility, feature/lcd-text, feature/shaping) is rebased on main.
- Main is an upstream tag (e.g., v1.92.9b-docking) plus Chroma's own added commits.

## Step-by-Step Sync Procedure

### 1. Fetch Upstream Tags and Branches

Fetch the latest tags and branches from upstream:

```bash
git fetch upstream --tags
```

This updates your local upstream-remote-tracking branches and tags.

### 2. Update the upstream-docking Mirror

Update the `upstream-docking` branch to match the latest upstream docking branch:

```bash
git checkout upstream-docking
git reset --hard upstream/docking
git push origin upstream-docking
```

The `upstream-docking` branch is now a mirror of the upstream docking branch.

### 3. Move main to the New Upstream Tag

`main` is never the bare upstream tag. It is the upstream tag plus Chroma's own added commits — the additive files under the allowed paths (`CMakeLists.txt`, `README.md`, `CONTRIBUTING.md`, `CHANGELOG.md`, `scripts/chroma/**`, `docs/chroma/**`, the `.github/workflows/chroma-*.yml` files, `.github/chroma/**`). Move `main` to the new tag by rebasing those commits onto it, not by resetting main to the tag. A reset makes main's tree exactly the bare tag, which has none of those files, and deletes them all from main.

Move `main` before rebasing topic branches onto it (topic branches rebase onto "main at the new upstream tag" in the next step, so main must already be there):

```bash
git checkout main
git rebase --onto <new-upstream-tag> <old-upstream-tag> main
```

This replays only the commits after `<old-upstream-tag>` — Chroma's added commits — onto `<new-upstream-tag>`, so the additive files stay in place.

Bump the pin that `scripts/chroma/parity_check.sh` reads, so the parity job checks against the same tag `main` now sits on:

```bash
echo "<new-upstream-tag>" > scripts/chroma/upstream_tag.txt
git add scripts/chroma/upstream_tag.txt
git commit -m "chroma: bump upstream_tag.txt to <new-upstream-tag>"
```

The rebase rewrites `main`'s history, so a plain `git push origin main` is a non-fast-forward and is rejected. Push with `--force-with-lease` instead — it still refuses if someone else has pushed to `origin/main` since your last fetch, so it will not silently overwrite their work:

```bash
git push origin main --force-with-lease
```

### 4. Rebase Each Topic Branch

For each topic branch (e.g., `feature/accessibility`), rebase it onto main at the new upstream tag.

```bash
git checkout feature/accessibility
git rebase main
```

If there are conflicts, resolve them and continue the rebase. If a feature cannot rebase in a day, remove the topic branch from main until it rebases cleanly, then proceed.

Repeat this for each topic branch: `feature/lcd-text`, `feature/shaping`.

### 5. Run the Parity Job

Run the parity script to detect upstream compatibility regressions. With all Chroma flags off, it preprocesses Chroma's core files and compares the resulting text against upstream — it does not run or compare behavior at runtime (the CI job separately configures and builds the `imgui` CMake target too):

```bash
./scripts/chroma/parity_check.sh
```

If the parity job fails, a regression was introduced. Fix the issue before proceeding.

### 6. Tag the Release

Once all topic branches rebase successfully and parity passes, tag the release:

```bash
git tag 1.92.9b-chroma.1 main
git push origin 1.92.9b-chroma.1
```

Update the version number in the tag name (e.g., chroma.2, chroma.3) for subsequent releases.

## Rollback

If issues are discovered after tagging, create a new tag with an incremented patch number (e.g., `1.92.9b-chroma.2`) rather than retagging. This preserves history.

## Frequency

Synchronize with upstream each time a new upstream docking release is published. During development, ad-hoc syncs are acceptable but less frequent.
