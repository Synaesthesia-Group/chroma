#!/usr/bin/env bash
#
# scripts/chroma/parity_check.sh
#
# Checks the "superset, never diverge" rule from ADR-0002 for the files
# listed below: with every Chroma feature flag OFF, the core translation units
# preprocess byte-identically to upstream, and the headers keep every upstream
# line in the same order (a line superset). It does not check every file in
# the repository, and it does not by itself enforce the additive-paths-only
# rule from ADR-0002.
#
# It checks two things against a temporary worktree of the pinned tag:
#
#   1. Core translation units (imgui.cpp, imgui_draw.cpp, imgui_tables.cpp,
#      imgui_widgets.cpp, imgui_demo.cpp) preprocess to byte-identical output
#      in the fork and in upstream, using identical compiler flags. Line
#      markers are stripped, so only real token differences count.
#   2. The shared headers (imgui.h, imgui_internal.h, imconfig.h) only ever
#      ADD lines relative to upstream. Every line in the upstream header must
#      appear in the fork header, in the same order (upstream is a
#      subsequence of the fork). The fork may insert new lines anywhere; it
#      may not remove, reorder or edit an existing upstream line.
#
# Usage:
#   scripts/chroma/parity_check.sh
#
# The pinned tag is read from scripts/chroma/upstream_tag.txt. The tag must
# already exist locally (e.g. `git fetch upstream tag <tag>`) — this script
# does not fetch.
#
# Exit status is non-zero on any difference, with a message identifying
# which file and what kind of difference. On success it prints one PASS line
# naming the tag and the fork's HEAD commit.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TAG_FILE="$SCRIPT_DIR/upstream_tag.txt"

CORE_TUS=(imgui.cpp imgui_draw.cpp imgui_tables.cpp imgui_widgets.cpp imgui_demo.cpp)
SUPERSET_HEADERS=(imgui.h imgui_internal.h imconfig.h)

if [[ ! -f "$TAG_FILE" ]]; then
  echo "parity_check: missing $TAG_FILE" >&2
  exit 1
fi

UPSTREAM_TAG="$(command tr -d '[:space:]' < "$TAG_FILE")"
if [[ -z "$UPSTREAM_TAG" ]]; then
  echo "parity_check: $TAG_FILE is empty" >&2
  exit 1
fi

cd "$ROOT_DIR"

if ! git rev-parse -q --verify "refs/tags/${UPSTREAM_TAG}" >/dev/null; then
  echo "parity_check: tag '${UPSTREAM_TAG}' not found locally." >&2
  echo "  Fetch it first, e.g.: git fetch upstream tag ${UPSTREAM_TAG}" >&2
  exit 1
fi

git worktree prune >/dev/null 2>&1 || true

TMP_DIR="$(command mktemp -d "${TMPDIR:-/tmp}/chroma-parity.XXXXXX")"
WORKTREE_DIR="$TMP_DIR/upstream-${UPSTREAM_TAG}"

cleanup() {
  git worktree remove --force "$WORKTREE_DIR" >/dev/null 2>&1 || true
  command rm -rf "$TMP_DIR"
}
trap cleanup EXIT

if ! git worktree add --quiet --detach "$WORKTREE_DIR" "refs/tags/${UPSTREAM_TAG}" \
    2>"$TMP_DIR/worktree.err"; then
  echo "parity_check: failed to create a worktree for ${UPSTREAM_TAG}:" >&2
  command cat "$TMP_DIR/worktree.err" >&2
  exit 1
fi

CXX="${CXX:-g++}"
fail=0

# --- 1. core translation units: byte-identical after preprocessing -------

for tu in "${CORE_TUS[@]}"; do
  fork_file="$ROOT_DIR/$tu"
  upstream_file="$WORKTREE_DIR/$tu"

  if [[ ! -f "$fork_file" ]]; then
    echo "FAIL: $tu is missing from the fork." >&2
    fail=1
    continue
  fi
  if [[ ! -f "$upstream_file" ]]; then
    echo "FAIL: $tu is missing from upstream ${UPSTREAM_TAG} (unexpected)." >&2
    fail=1
    continue
  fi

  fork_pp="$TMP_DIR/fork-$tu.i"
  upstream_pp="$TMP_DIR/upstream-$tu.i"

  if ! "$CXX" -E -P -std=c++17 -I"$ROOT_DIR" "$fork_file" \
      > "$fork_pp" 2>"$TMP_DIR/fork-$tu.err"; then
    echo "FAIL: preprocessing fork/$tu failed:" >&2
    command cat "$TMP_DIR/fork-$tu.err" >&2
    fail=1
    continue
  fi
  if ! "$CXX" -E -P -std=c++17 -I"$WORKTREE_DIR" "$upstream_file" \
      > "$upstream_pp" 2>"$TMP_DIR/upstream-$tu.err"; then
    echo "FAIL: preprocessing upstream/$tu failed:" >&2
    command cat "$TMP_DIR/upstream-$tu.err" >&2
    fail=1
    continue
  fi

  if ! command diff -u "$upstream_pp" "$fork_pp" > "$TMP_DIR/diff-$tu.txt"; then
    echo "FAIL: $tu preprocesses differently from upstream ${UPSTREAM_TAG} with every Chroma flag off." >&2
    echo "  --- diff (upstream vs fork), first 40 lines ---" >&2
    command head -n 40 "$TMP_DIR/diff-$tu.txt" >&2
    fail=1
  fi
done

# --- 2. shared headers: upstream must be a subsequence of the fork -------

is_superset() {
  # $1 = upstream file, $2 = fork file.
  # Succeeds iff every line of $1 occurs in $2, in the same relative order
  # (a single forward scan — upstream is a subsequence of fork). The fork
  # may insert new lines anywhere; it may not drop, reorder or edit one.
  python3 - "$1" "$2" <<'PYEOF'
import sys

upstream_path, fork_path = sys.argv[1], sys.argv[2]

with open(upstream_path, "r", encoding="utf-8", errors="surrogateescape") as f:
    upstream_lines = f.readlines()
with open(fork_path, "r", encoding="utf-8", errors="surrogateescape") as f:
    fork_lines = f.readlines()

i = 0
n = len(fork_lines)
for lineno, line in enumerate(upstream_lines, start=1):
    while i < n and fork_lines[i] != line:
        i += 1
    if i >= n:
        sys.stderr.write(
            "upstream line %d is missing, reordered, or changed: %r\n"
            % (lineno, line.rstrip("\n"))
        )
        sys.exit(1)
    i += 1
sys.exit(0)
PYEOF
}

for hdr in "${SUPERSET_HEADERS[@]}"; do
  fork_file="$ROOT_DIR/$hdr"
  upstream_file="$WORKTREE_DIR/$hdr"

  if [[ ! -f "$fork_file" ]]; then
    echo "FAIL: $hdr is missing from the fork." >&2
    fail=1
    continue
  fi
  if [[ ! -f "$upstream_file" ]]; then
    echo "FAIL: $hdr is missing from upstream ${UPSTREAM_TAG} (unexpected)." >&2
    fail=1
    continue
  fi

  if ! is_superset "$upstream_file" "$fork_file" 2>"$TMP_DIR/superset-$hdr.err"; then
    echo "FAIL: $hdr is not a pure superset of upstream ${UPSTREAM_TAG}:" >&2
    command cat "$TMP_DIR/superset-$hdr.err" >&2
    fail=1
  fi
done

if [[ "$fail" -ne 0 ]]; then
  echo "parity_check: FAILED against upstream ${UPSTREAM_TAG}." >&2
  exit 1
fi

FORK_HEAD="$(git -C "$ROOT_DIR" rev-parse --short HEAD)"
echo "PASS: fork HEAD ${FORK_HEAD} has parity with upstream ${UPSTREAM_TAG}."
