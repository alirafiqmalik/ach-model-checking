#!/usr/bin/env bash
# Run nuXmv IC3 checks for INVAR specs 0–2 on ./_main_model.smv; logs under ./logs/.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
mkdir -p logs
LOGDIR="logs/job-local-$(date +%Y%m%d-%H%M%S)-$$"
mkdir -p "$LOGDIR"

JOBS="${JOBS:-${SLURM_CPUS_PER_TASK:-9}}"
MODEL="./_main_model.smv"
NUXMV="${NUXMV:-./tools/nuXmv}"
VERB="${VERB:-2}"
GIDX=(0 1 2)
N_SPEC=${#GIDX[@]}

[[ -f "$MODEL" ]] || { echo "missing $MODEL (run from repo root)" >&2; exit 1; }
[[ -x "$NUXMV" ]] || command -v "$NUXMV" >/dev/null || {
  echo "nuXmv not executable: $NUXMV (set NUXMV to a full path)" >&2
  exit 1
}

RUN_LOG="${LOGDIR}/run-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$RUN_LOG") 2>&1
echo "run log: $RUN_LOG  LOGDIR=$LOGDIR  NUXMV=$NUXMV  VERB=$VERB  JOBS=$JOBS"

run_one() {
  local i="$1" gidx="$2"
  local out="${LOGDIR}/spec-${i}-INV.log"
  local cmds="${LOGDIR}/cmds-${i}-INV.txt"
  cat > "$cmds" <<EOF
set on_failure_script_quits
read_model -i $MODEL
flatten_hierarchy
encode_variables
build_boolean_model
go_msat
check_invar_ic3 -n $gidx
quit
EOF
  "$NUXMV" -v "$VERB" -source "$cmds" >"$out" 2>&1
}

fail=0
for ((w = 0; w < N_SPEC; w += JOBS)); do
  pids=()
  for ((i = w; i < w + JOBS && i < N_SPEC; i++)); do
    (run_one "$i" "${GIDX[$i]}") &
    pids+=("$!")
  done
  for pid in "${pids[@]}"; do wait "$pid" || fail=1; done
done

echo "=== summary ==="
for ((i = 0; i < N_SPEC; i++)); do
  f="${LOGDIR}/spec-${i}-INV.log"
  if [[ -f "$f" ]]; then
    verdict=$(grep -m1 -E "is true|is false|no counterexample|as demonstrated|invariant .* is TRUE|invariant .* is FALSE|-- specification .* is|counterexample" "$f" | head -1 || true)
    echo "[$i INV] ${verdict:-(no verdict; inspect $f)}"
  fi
done
echo "logs: ${LOGDIR}/spec-*-INV.log"
exit "$fail"
