#!/usr/bin/env bash
# Merge the SMV parts, run nuXmv, write model_stats.md.
#
# Usage:
#   ./run_all_artifact.sh                     # Docker (default): build image, run merge+verify+stats
#   ./run_all_artifact.sh --no-docker         # Host: pick tools/nuxmv-linux (Linux) or tools/nuxmv-mac (macOS)
#
# Env: IMAGE_NAME (default ach-model:nuxmv)  DOCKER_PLATFORM (default linux/amd64)
#      VERIFY_MODE=quick|full|merge-only     ARTIFACT_DIR (optional per-run directory under output/)
#      SKIP_INVAR=1  reuse existing spec-*-INV.log; only run EF BMC
#      BMC_K         BMC bound for EF checks (default 50)
#
# Internal (container): ./run_all_artifact.sh --inside-docker
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="${IMAGE_NAME:-ach-model:nuxmv}"
PLATFORM="${DOCKER_PLATFORM:-linux/amd64}"
VERIFY_MODE="${VERIFY_MODE:-quick}"
INSIDE_DOCKER=0
USE_DOCKER=1
ARTIFACT_DIR="${ARTIFACT_DIR:-}"
OUTPUT_ROOT="${OUTPUT_ROOT:-$ROOT/output}"
MERGED_MODEL="${MERGED_MODEL:-$OUTPUT_ROOT/_main_model.smv}"

usage() {
  sed -n '1,20p' "$0" | sed 's/^# \{0,1\}//'
}

detect_nuxmv() {
  if [[ -n "${NUXMV:-}" && -x "${NUXMV}" ]]; then
    return 0
  fi
  case "$(uname -s)" in
    Linux)
      NUXMV="$ROOT/tools/nuxmv-linux"
      ;;
    Darwin)
      NUXMV="$ROOT/tools/nuxmv-mac"
      ;;
    *)
      echo "Unsupported host OS for --no-docker: $(uname -s)" >&2
      exit 1
      ;;
  esac
  if [[ ! -x "$NUXMV" ]]; then
    echo "nuXmv not found or not executable: $NUXMV (set NUXMV=)" >&2
    exit 1
  fi
  export NUXMV
}

run_merge() {
  make -C "$ROOT" NUXMV="$NUXMV" OUTPUT_DIR="$OUTPUT_ROOT" merge check-merge
}

run_verify_quick() {
  local LOGDIR="$1"
  mkdir -p "$LOGDIR"
  local JOBS="${JOBS:-${SLURM_CPUS_PER_TASK:-9}}"
  local MODEL="$MERGED_MODEL"
  local VERB="${VERB:-2}"
  local BMC_K="${BMC_K:-50}"
  local fail=0

  # check_invar_ic3 -n uses show_property unified indices (CTL SPECs first,
  # then Invar). Discover indices; do not assume Invar is 0, 1, 2.
  local prop_cmds="${LOGDIR}/cmds-show_property.txt"
  local prop_out="${LOGDIR}/show_property.txt"
  cat >"$prop_cmds" <<EOF
set on_failure_script_quits
read_model -i $MODEL
flatten_hierarchy
show_property
quit
EOF
  if ! "$NUXMV" -source "$prop_cmds" >"$prop_out" 2>&1; then
    echo "error: show_property failed (see $prop_out)" >&2
    return 1
  fi
  local -a GIDX=()
  mapfile -t GIDX < <(awk '
    /^[0-9]+[[:space:]]*:/ { idx = $1 + 0; have = 1 }
    /^[[:space:]]*\[Invar/ { if (have) print idx }
  ' "$prop_out")
  if [[ ${#GIDX[@]} -eq 0 && "${SKIP_INVAR:-0}" != "1" ]]; then
    echo "error: show_property found no Invar properties in $MODEL (see $prop_out)" >&2
    return 1
  fi
  if [[ ${#GIDX[@]} -gt 0 && ${#GIDX[@]} -ne 3 ]]; then
    echo "warning: expected 3 Invar properties (Φ1/Φ2/Φ3), found ${#GIDX[@]}: ${GIDX[*]}" >&2
  fi
  echo "Invar indices from show_property: ${GIDX[*]:-none} (log spec-i-INV.log is the i-th Invar; check_invar_ic3 -n uses the unified index)"
  local N_SPEC=${#GIDX[@]}

  local -a CTL_GIDX=() CTL_ATOM=()
  local gidx formula
  while IFS=$'\t' read -r gidx formula; do
    CTL_GIDX+=("$gidx")
    CTL_ATOM+=("${formula#EF }")
  done < <(awk '
    /^[0-9]+[[:space:]]*:/ {
      idx = $1 + 0
      rest = $0
      sub(/^[0-9]+[[:space:]]*:/, "", rest)
      gsub(/^[ \t]+|[ \t]+$/, "", rest)
      formula = rest
    }
    /^[[:space:]]*\[CTL/ { print idx "\t" formula }
  ' "$prop_out")
  echo "CTL properties: ${#CTL_GIDX[@]} (BMC of !(p), k=${BMC_K})"

  run_one() {
    local i="$1" gidx="$2"
    local out="${LOGDIR}/spec-${i}-INV.log"
    local cmds="${LOGDIR}/cmds-${i}-INV.txt"
    local t0="$SECONDS"
    cat >"$cmds" <<EOF
set on_failure_script_quits
read_model -i $MODEL
flatten_hierarchy
encode_variables
build_boolean_model
go_msat
check_invar_ic3 -n $gidx
quit
EOF
    if ! "$NUXMV" -v "$VERB" -source "$cmds" >"$out" 2>&1; then
      printf '%s\t%s\t%s\n' "$i" "$gidx" "$((SECONDS - t0))" >"$LOGDIR/timing.$i.tsv"
      return 1
    fi
    printf '%s\t%s\t%s\n' "$i" "$gidx" "$((SECONDS - t0))" >"$LOGDIR/timing.$i.tsv"
  }

  run_one_ctl() {
    local i="$1" gidx="$2" atom="$3"
    local out="${LOGDIR}/spec-${i}-CTL.log"
    local cmds="${LOGDIR}/cmds-${i}-CTL.txt"
    local t0="$SECONDS"
    cat >"$cmds" <<EOF
set on_failure_script_quits
read_model -i $MODEL
flatten_hierarchy
encode_variables
build_boolean_model
go_bmc
check_invar_bmc -a een-sorensson -p "!(${atom})" -k $BMC_K
quit
EOF
    "$NUXMV" -v "$VERB" -source "$cmds" >"$out" 2>&1 || true
    printf '%s\t%s\t%s\n' "$i" "$gidx" "$((SECONDS - t0))" >"$LOGDIR/timing.ctl.$i.tsv"
  }

  if [[ "${SKIP_INVAR:-0}" == "1" ]]; then
    echo "SKIP_INVAR=1: keeping existing spec-*-INV.log"
  else
    for ((w = 0; w < N_SPEC; w += JOBS)); do
      local -a pids=()
      for ((i = w; i < w + JOBS && i < N_SPEC; i++)); do
        (run_one "$i" "${GIDX[$i]}") &
        pids+=("$!")
      done
      for pid in "${pids[@]}"; do wait "$pid" || fail=1; done
    done
  fi

  local N_CTL=${#CTL_GIDX[@]}
  for ((w = 0; w < N_CTL; w += JOBS)); do
    local -a pids=()
    for ((i = w; i < w + JOBS && i < N_CTL; i++)); do
      (run_one_ctl "$i" "${CTL_GIDX[$i]}" "${CTL_ATOM[$i]}") &
      pids+=("$!")
    done
    for pid in "${pids[@]}"; do wait "$pid" || fail=1; done
  done

  {
    for ((i = 0; i < N_SPEC; i++)); do
      [[ -f "$LOGDIR/timing.$i.tsv" ]] && cat "$LOGDIR/timing.$i.tsv"
    done
  } >"$LOGDIR/timing.tsv"
  {
    for ((i = 0; i < N_CTL; i++)); do
      [[ -f "$LOGDIR/timing.ctl.$i.tsv" ]] && cat "$LOGDIR/timing.ctl.$i.tsv"
    done
  } >"$LOGDIR/timing.ctl.tsv"

  echo "=== summary ==="
  local i f verdict
  for ((i = 0; i < N_SPEC; i++)); do
    f="${LOGDIR}/spec-${i}-INV.log"
    if [[ -f "$f" ]]; then
      # Final -- invariant/-- specification is true/false is the verdict.
      # Bound-k "no proof or counterexample" is IC3 progress only.
      verdict=$(grep -iE -- '-- (invariant|specification) .* is (true|false)' "$f" | tail -1 || true)
      if [[ -z "$verdict" ]]; then
        verdict=$(grep -E -- 'no proof or counterexample found with bound [0-9]+' "$f" | tail -1 || true)
        if [[ -n "$verdict" ]]; then
          verdict="inconclusive: ${verdict}"
        fi
      fi
      echo "[$i INV] ${verdict:-(no verdict; inspect $f)}"
    fi
  done
  for ((i = 0; i < N_CTL; i++)); do
    f="${LOGDIR}/spec-${i}-CTL.log"
    if [[ -f "$f" ]]; then
      verdict=$(grep -iE -- '-- (invariant|specification) .* is (true|false)' "$f" | tail -1 || true)
      echo "[$i CTL] ${verdict:-(no verdict; inspect $f)}"
    fi
  done
  echo "logs: ${LOGDIR}/spec-*-INV.log ${LOGDIR}/spec-*-CTL.log"
  return "$fail"
}

run_stats() {
  local out_md="$1"
  local logdir="${2:-}"
  (
    cd "$ROOT"
    if [[ -n "$logdir" ]]; then
      python3 "$ROOT/tools/nuxmv_model_stats.py" "$MERGED_MODEL" --nuxmv "$NUXMV" --output "$out_md" --log-dir "$logdir"
    else
      python3 "$ROOT/tools/nuxmv_model_stats.py" "$MERGED_MODEL" --nuxmv "$NUXMV" --output "$out_md"
    fi
  )
}

run_inside_docker() {
  cd "$ROOT"
  NUXMV="${NUXMV:-$ROOT/tools/nuxmv-linux}"
  [[ -x "$NUXMV" ]] || {
    echo "missing nuXmv: $NUXMV" >&2
    exit 1
  }
  export NUXMV
  local ART="${ARTIFACT_DIR:-/artifacts}"
  mkdir -p "$ART"

  run_merge
  cp -f "$MERGED_MODEL" "$ART/_main_model.smv"

  local fail=0
  case "${VERIFY_MODE}" in
    quick)
      run_verify_quick "$ART" || fail=1
      run_stats "$ART/model_stats.md" "$ART" || true
      ;;
    full)
      if ! make -C "$ROOT" NUXMV="$NUXMV" OUTPUT_DIR="$OUTPUT_ROOT" verify 2>&1 | tee "$ART/nuxmv-verify-full.log"; then
        fail=1
      fi
      run_stats "$ART/model_stats.md" "$ART" || true
      ;;
    merge-only)
      echo "VERIFY_MODE=merge-only: skipped nuXmv checks" | tee "$ART/verify-skipped.txt"
      run_stats "$ART/model_stats.md" "" || true
      ;;
    *)
      echo "Unknown VERIFY_MODE=${VERIFY_MODE} (use quick|full|merge-only)" >&2
      exit 1
      ;;
  esac

  echo "Artifacts written under ${ART} (mounted from host)." | tee "$ART/done.txt"
  exit "$fail"
}

run_host_no_docker() {
  detect_nuxmv
  local STAMP
  STAMP="$(date +%Y%m%d-%H%M%S)"
  local ART="${ARTIFACT_DIR:-$OUTPUT_ROOT/local-run-${STAMP}}"
  mkdir -p "$ART"
  cd "$ROOT"

  run_merge
  cp -f "$MERGED_MODEL" "$ART/_main_model.smv"

  local fail=0
  case "${VERIFY_MODE}" in
    quick)
      run_verify_quick "$ART" || fail=1
      run_stats "$ART/model_stats.md" "$ART" || true
      ;;
    full)
      if ! make -C "$ROOT" NUXMV="$NUXMV" OUTPUT_DIR="$OUTPUT_ROOT" verify 2>&1 | tee "$ART/nuxmv-verify-full.log"; then
        fail=1
      fi
      run_stats "$ART/model_stats.md" "$ART" || true
      ;;
    merge-only)
      echo "VERIFY_MODE=merge-only: skipped nuXmv checks" | tee "$ART/verify-skipped.txt"
      run_stats "$ART/model_stats.md" "" || true
      ;;
    *)
      echo "Unknown VERIFY_MODE=${VERIFY_MODE}" >&2
      exit 1
      ;;
  esac

  echo "Done. Artifacts -> $ART"
  exit "$fail"
}

run_host_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    echo "docker not found in PATH; install Docker Desktop or use --no-docker." >&2
    exit 1
  fi
  local STAMP
  STAMP="$(date +%Y%m%d-%H%M%S)"
  local ART="${ARTIFACT_DIR:-$OUTPUT_ROOT/docker-run-${STAMP}}"
  mkdir -p "$ART"

  echo "Building ${IMAGE_NAME} (platform ${PLATFORM})..."
  docker build --platform "$PLATFORM" -t "$IMAGE_NAME" "$ROOT"

  echo "Running container; VERIFY_MODE=${VERIFY_MODE}; artifacts -> $ART"
  docker run --rm --platform "$PLATFORM" \
    -e VERIFY_MODE="${VERIFY_MODE}" \
    -e SKIP_INVAR="${SKIP_INVAR:-}" \
    -e ARTIFACT_DIR=/artifacts \
    -v "$ART:/artifacts" \
    "$IMAGE_NAME"

  echo "Done. Logs, merged model, stats: $ART"
}

# --- argv ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --inside-docker)
      INSIDE_DOCKER=1
      shift
      ;;
    --no-docker)
      USE_DOCKER=0
      shift
      ;;
    --artifact-dir)
      ARTIFACT_DIR="$2"
      shift 2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1 (try --help)" >&2
      exit 1
      ;;
  esac
done

if [[ -n "${ARTIFACT_DIR}" && "$INSIDE_DOCKER" -eq 0 && "$USE_DOCKER" -eq 1 ]]; then
  export ARTIFACT_DIR
fi

if [[ "$INSIDE_DOCKER" -eq 1 ]]; then
  run_inside_docker
fi

if [[ "$USE_DOCKER" -eq 1 ]]; then
  run_host_docker
else
  run_host_no_docker
fi
