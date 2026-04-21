#!/usr/bin/env bash
# Run nuXmv non-interactively: build model and print BDD / FSM / usage stats.
# Usage: ./tools/nuxmv_model_stats.sh [path/to/model.smv]
# Env: NUXMV=/path/to/nuXmv (default: tools/nuXmv then tools/nuxmv under repo root)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODEL="${1:-$ROOT/_main_model.smv}"
NUXMV="${NUXMV:-}"
if [[ -z "$NUXMV" ]]; then
  for c in "$ROOT/tools/nuXmv" "$ROOT/tools/nuxmv"; do
    if [[ -x "$c" ]]; then NUXMV="$c"; break; fi
  done
fi
[[ -n "$NUXMV" ]] || { echo "nuXmv not found under $ROOT/tools (set NUXMV=)" >&2; exit 1; }
[[ -f "$MODEL" ]] || { echo "model not found: $MODEL" >&2; exit 1; }

cmd="$(mktemp "${TMPDIR:-/tmp}/nuxmv-stats.XXXXXX")"
trap 'rm -f "$cmd"' EXIT
cat >"$cmd" <<'EOF'
go
print_bdd_stats
print_fsm_stats
show_vars
print_usage
quit
EOF

echo "=== nuXmv model stats ===" >&2
echo "binary: $NUXMV" >&2
echo "model:  $MODEL" >&2
echo "=========================" >&2
"$NUXMV" -source "$cmd" "$MODEL"