#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PATCH="${PATCH:-$ROOT/patches/0001-add-rocmfp4-to-llama-cpp-mtp.patch}"
TARGET="${1:-}"

if [[ -z "$TARGET" ]]; then
    echo "usage: scripts/apply-rocmfp4.sh /path/to/llama.cpp" >&2
    exit 2
fi

if ! git -C "$TARGET" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "error: target is not a git checkout: $TARGET" >&2
    exit 2
fi

if [[ ! -f "$PATCH" ]]; then
    echo "error: patch not found: $PATCH" >&2
    exit 2
fi

echo "Checking ROCmFP4 patch against: $TARGET"
git -C "$TARGET" apply --check "$PATCH"

echo "Applying ROCmFP4 patch"
git -C "$TARGET" apply "$PATCH"

echo "Done. Next:"
echo "  cd $TARGET"
echo "  env JOBS=16 scripts/build-strix-rocmfp4-mtp.sh"
