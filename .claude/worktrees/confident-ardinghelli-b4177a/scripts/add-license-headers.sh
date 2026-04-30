#!/usr/bin/env bash
#
# Adds a PolyForm Noncommercial 1.0.0 license header to every .swift file
# in the project. Idempotent: skips files that already contain the header.
#
# Usage:
#   ./scripts/add-license-headers.sh         # dry-run, lists files that would change
#   ./scripts/add-license-headers.sh --write # actually modify files
#
# Run from the repository root.

set -euo pipefail

WRITE=0
if [[ "${1:-}" == "--write" ]]; then
  WRITE=1
fi

HEADER_MARKER="Licensed under PolyForm Noncommercial 1.0.0"

HEADER=$'// Dawny\n// Copyright (c) 2025-2026 Florian Schneider. All rights reserved.\n// Licensed under PolyForm Noncommercial 1.0.0 \xe2\x80\x94 see LICENSE in the repository root.\n\n'

DIRS=("App" "DawnyTests")

changed=0
skipped=0
total=0

for dir in "${DIRS[@]}"; do
  if [[ ! -d "$dir" ]]; then
    continue
  fi
  while IFS= read -r -d '' file; do
    total=$((total + 1))
    # Idempotency: only check the first ~10 lines for the marker.
    if head -n 10 "$file" | grep -qF "$HEADER_MARKER"; then
      skipped=$((skipped + 1))
      continue
    fi

    if [[ "$WRITE" -eq 1 ]]; then
      tmp="$(mktemp)"
      printf '%s' "$HEADER" > "$tmp"
      cat "$file" >> "$tmp"
      mv "$tmp" "$file"
    fi
    changed=$((changed + 1))
    echo "  [$([[ $WRITE -eq 1 ]] && echo 'WROTE' || echo 'WOULD WRITE')] $file"
  done < <(find "$dir" -type f -name "*.swift" -print0)
done

echo
echo "Summary: $total Swift files scanned, $changed updated, $skipped already had the header."

if [[ "$WRITE" -ne 1 ]]; then
  echo "Dry run. Re-run with --write to apply changes."
fi
