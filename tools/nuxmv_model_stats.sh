#!/usr/bin/env bash
# Forwards to nuxmv_model_stats.py. run_all_artifact.sh calls the Python file.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
exec python3 "$ROOT/tools/nuxmv_model_stats.py" "$@"
