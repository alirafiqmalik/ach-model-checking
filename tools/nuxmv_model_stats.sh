#!/usr/bin/env bash
# Deprecated wrapper: use tools/nuxmv_model_stats.py (invoked from run_all_artifcate.sh).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
exec python3 "$ROOT/tools/nuxmv_model_stats.py" "$@"
