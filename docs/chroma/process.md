# Upstream Synchronization Process

This document describes how to synchronize Chroma with upstream Dear ImGui during each release cycle.

## Prerequisites

- The upstream remote is named `upstream`.
- The `upstream-docking` branch mirrors the upstream docking branch.
- Each topic branch (feature/accessibility, feature/lcd-text, feature/shaping) is rebased on main.
- Main branch is always at an upstream tag (e.g., v1.92.9b-docking).

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

### 3. Rebase Each Topic Branch

For each topic branch (e.g., `feature/accessibility`), rebase it onto main at the new upstream tag.

```bash
git checkout feature/accessibility
git rebase main
```

If there are conflicts, resolve them and continue the rebase. If a feature cannot rebase in a day, merge it to main before proceeding.

Repeat this for each topic branch: `feature/lcd-text`, `feature/shaping`.

### 4. Run the Parity Job

Run the parity script to detect upstream compatibility regressions. The parity job builds Chroma with all flags off and compares behavior against upstream:

```bash
./scripts/chroma/parity.sh
```

If the parity job fails, a regression was introduced. Fix the issue before proceeding.

### 5. Tag the Release

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
