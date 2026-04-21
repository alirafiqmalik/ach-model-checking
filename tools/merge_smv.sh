#!/usr/bin/env bash
# Concatenate SMV fragments in order into one file (Option 1: explicit merge).
# Usage: merge_smv.sh <output.smv> <part1.smv> [part2.smv ...]
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "usage: $0 <output.smv> <part1.smv> [part2.smv ...]" >&2
  exit 1
fi

out=$1
shift

# Plain concatenation (no extra separators) so merged text matches a single source file.
: >"$out"
for f in "$@"; do
  if [[ ! -f "$f" ]]; then
    echo "merge_smv: missing file: $f" >&2
    exit 1
  fi
  cat "$f" >>"$out"
done
