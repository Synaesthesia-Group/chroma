# Chroma parity check

`parity_check.sh` checks the "superset, never diverge" rule from ADR-0002
for the files it covers: with every Chroma feature flag OFF, the 5 core
translation units and `imgui.h`, `imgui_internal.h` and `imconfig.h` must
match upstream Dear ImGui at the pinned tag exactly (see "What it checks"
below for the precise file list). It does not check every file in the
repository, and it does not by itself enforce the additive-paths-only rule
from ADR-0002.

## Usage

```bash
scripts/chroma/parity_check.sh
```

No arguments. It reads the pinned tag from `upstream_tag.txt`, so run it
from anywhere inside the repository (or point at the script directly, as
above). Requires `git`, `g++` (or set `CXX` to another C++ compiler) and
`python3` on `PATH`. The pinned tag must already exist locally — the script
does not fetch:

```bash
git fetch upstream tag "$(cat scripts/chroma/upstream_tag.txt)"
```

Exit status is `0` and a single `PASS: ...` line on success. On failure, it
exits non-zero and prints which file differs and how.

## What it checks

1. **Core translation units** — `imgui.cpp`, `imgui_draw.cpp`,
   `imgui_tables.cpp`, `imgui_widgets.cpp`, `imgui_demo.cpp`. Each is run
   through the C++ preprocessor only (`-E -P -std=c++17`, line markers
   stripped) in the fork and in a temporary `git worktree` of the pinned
   upstream tag, with identical flags, and the two outputs are diffed.
   Code behind a Chroma flag that defaults OFF is invisible to this check
   by design — the preprocessor strips the disabled block before the diff
   ever runs, which is the intended flags-off parity. Any difference that
   remains with every flag OFF fails the check. A comment-only edit also
   passes, as it should, since comments do not survive preprocessing.

2. **Shared headers** — `imgui.h`, `imgui_internal.h`, `imconfig.h`. These
   are allowed to gain new declarations but never to lose or change an
   existing one, so the check is on the raw text, not the preprocessed
   output: every line of the upstream header must appear in the fork's
   header, in the same relative order. That is, upstream must be a
   line-by-line subsequence of the fork. The fork can insert new lines
   anywhere; it cannot remove, reorder or edit one of upstream's lines.

## Updating the pinned tag

Bump `upstream_tag.txt` to the new upstream tag (it must already be fetched
from the `upstream` remote) and re-run the script. A failure at that point
is expected to surface real upstream changes to reconcile, not a bug in the
check itself.
