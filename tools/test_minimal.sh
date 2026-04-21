#!/usr/bin/env bash
# Merge two tiny NuSMV fragments and run nuXmv (batch load, no specs).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FIX="${ROOT}/tests/fixtures/minimal"
OUT="${FIX}/_merged_test.smv"

if [[ -z "${NUXMV:-}" ]]; then
  for c in nuXmv nuxmv nuxmv-linux; do
    p="${ROOT}/tools/$c"
    if [[ -x "$p" ]]; then
      NUXMV="$p"
      break
    fi
  done
fi
[[ -n "${NUXMV:-}" ]] || {
  echo "test_minimal: no nuXmv executable in ${ROOT}/tools (nuXmv, nuxmv, nuxmv-linux)" >&2
  exit 1
}

"${ROOT}/tools/merge_smv.sh" "$OUT" "${FIX}/part_a.smv" "${FIX}/part_b.smv"

if ! "$NUXMV" "$OUT" >/tmp/nuxmv_minimal.log 2>&1; then
  echo "test_minimal: nuXmv failed. Log:" >&2
  cat /tmp/nuxmv_minimal.log >&2
  exit 1
fi

echo "test_minimal: OK (merged model runs with nuXmv)"
