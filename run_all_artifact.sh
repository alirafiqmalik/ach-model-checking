#!/usr/bin/env bash
# Single entry point for ACM CCS artifacts: merge, verify (optional), Markdown model stats.
#
# Usage:
#   ./run_all_artifact.sh                     # Docker (default): build image, run merge+verify+stats
#   ./run_all_artifact.sh --no-docker         # Host: pick tools/nuxmv-linux (Linux) or tools/nuxmv-mac (macOS)
#
# Env: IMAGE_NAME (default ach-model:nuxmv)  DOCKER_PLATFORM (default linux/amd64)
#      VERIFY_MODE=quick|full|merge-only     ARTIFACT_DIR (optional explicit output directory)
#
# Internal (container): ./run_all_artifact.sh --inside-docker
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="${IMAGE_NAME:-ach-model:nuxmv}"
PLATFORM="${DOCKER_PLATFORM:-linux/amd64}"
VERIFY_MODE="${VERIFY_MODE:-quick}"
INSIDE_DOCKER=0
USE_DOCKER=1
ARTIFACT_DIR=""

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
  make -C "$ROOT" NUXMV="$NUXMV" merge check-merge
}

run_verify_quick() {
  local LOGDIR="$1"
  mkdir -p "$LOGDIR"
  local JOBS="${JOBS:-${SLURM_CPUS_PER_TASK:-9}}"
  local MODEL="$ROOT/_main_model.smv"
  local VERB="${VERB:-2}"
  local -a GIDX=(0 1 2)
  local N_SPEC=${#GIDX[@]}
  local fail=0

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

  for ((w = 0; w < N_SPEC; w += JOBS)); do
    local -a pids=()
    for ((i = w; i < w + JOBS && i < N_SPEC; i++)); do
      (run_one "$i" "${GIDX[$i]}") &
      pids+=("$!")
    done
    for pid in "${pids[@]}"; do wait "$pid" || fail=1; done
  done

  {
    for ((i = 0; i < N_SPEC; i++)); do
      cat "$LOGDIR/timing.$i.tsv"
    done
  } >"$LOGDIR/timing.tsv"

  echo "=== summary ==="
  local i f verdict
  for ((i = 0; i < N_SPEC; i++)); do
    f="${LOGDIR}/spec-${i}-INV.log"
    if [[ -f "$f" ]]; then
      verdict=$(grep -m1 -E "is true|is false|no counterexample|as demonstrated|invariant .* is TRUE|invariant .* is FALSE|-- specification .* is|counterexample" "$f" | head -1 || true)
      echo "[$i INV] ${verdict:-(no verdict; inspect $f)}"
    fi
  done
  echo "logs: ${LOGDIR}/spec-*-INV.log"
  return "$fail"
}

run_stats() {
  local out_md="$1"
  local logdir="${2:-}"
  (
    cd "$ROOT"
    if [[ -n "$logdir" ]]; then
      python3 "$ROOT/tools/nuxmv_model_stats.py" _main_model.smv --nuxmv "$NUXMV" --output "$out_md" --log-dir "$logdir"
    else
      python3 "$ROOT/tools/nuxmv_model_stats.py" _main_model.smv --nuxmv "$NUXMV" --output "$out_md"
    fi
  )
}

artifact_copy_logs() {
  local dest="$1"
  local src="$2"
  if [[ -d "$src" ]]; then
    rm -rf "$dest/logs"
    cp -a "$src" "$dest/logs" || true
  fi
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
  cp -f "$ROOT/_main_model.smv" "$ART/_main_model.smv"

  local fail=0
  local LOGROOT="$ROOT/logs"
  case "${VERIFY_MODE}" in
    quick)
      mkdir -p "$LOGROOT"
      local LOGDIR="$LOGROOT/job-$(date +%Y%m%d-%H%M%S)-$$"
      mkdir -p "$LOGDIR"
      run_verify_quick "$LOGDIR" || fail=1
      run_stats "$ART/model_stats.md" "$LOGDIR" || true
      artifact_copy_logs "$ART" "$LOGROOT"
      ;;
    full)
      mkdir -p "$LOGROOT"
      local LOGDIR="$LOGROOT/job-$(date +%Y%m%d-%H%M%S)-$$"
      mkdir -p "$LOGDIR"
      if ! make -C "$ROOT" NUXMV="$NUXMV" verify 2>&1 | tee "$ART/nuxmv-verify-full.log"; then
        fail=1
      fi
      run_stats "$ART/model_stats.md" "$LOGDIR" || true
      artifact_copy_logs "$ART" "$LOGROOT"
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
  local ART="${ARTIFACT_DIR:-$ROOT/artifacts/local-run-${STAMP}}"
  mkdir -p "$ART"
  cd "$ROOT"

  run_merge
  cp -f "$ROOT/_main_model.smv" "$ART/_main_model.smv"

  local fail=0
  local LOGROOT="$ROOT/logs"
  case "${VERIFY_MODE}" in
    quick)
      mkdir -p "$LOGROOT"
      local LOGDIR="$LOGROOT/job-${STAMP}-$$"
      mkdir -p "$LOGDIR"
      run_verify_quick "$LOGDIR" || fail=1
      run_stats "$ART/model_stats.md" "$LOGDIR" || true
      artifact_copy_logs "$ART" "$LOGROOT"
      ;;
    full)
      mkdir -p "$LOGROOT"
      local LOGDIR="$LOGROOT/job-${STAMP}-$$"
      mkdir -p "$LOGDIR"
      if ! make -C "$ROOT" NUXMV="$NUXMV" verify 2>&1 | tee "$ART/nuxmv-verify-full.log"; then
        fail=1
      fi
      run_stats "$ART/model_stats.md" "$LOGDIR" || true
      artifact_copy_logs "$ART" "$LOGROOT"
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
  local ART="${ARTIFACT_DIR:-$ROOT/artifacts/docker-run-${STAMP}}"
  mkdir -p "$ART"

  echo "Building ${IMAGE_NAME} (platform ${PLATFORM})..."
  docker build --platform "$PLATFORM" -t "$IMAGE_NAME" "$ROOT"

  echo "Running container; VERIFY_MODE=${VERIFY_MODE}; artifacts -> $ART"
  docker run --rm --platform "$PLATFORM" \
    -e VERIFY_MODE="${VERIFY_MODE}" \
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
