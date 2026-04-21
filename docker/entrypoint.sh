#!/usr/bin/env bash
set -euo pipefail
set -o pipefail
cd /work

export NUXMV="${NUXMV:-/work/tools/nuxmv-linux}"
[[ -x "$NUXMV" ]] || { echo "entrypoint: missing executable NUXMV=$NUXMV" >&2; exit 1; }

mkdir -p /artifacts

make NUXMV="$NUXMV" merge check-merge
cp -f _main_model.smv /artifacts/_main_model.smv

fail=0
case "${VERIFY_MODE:-quick}" in
  quick)
    mkdir -p logs
    ./run_local.sh || fail=1
    ;;
  full)
    mkdir -p logs
    make NUXMV="$NUXMV" verify 2>&1 | tee /artifacts/nuxmv-verify-full.log || fail=1
    ;;
  merge-only)
    echo "VERIFY_MODE=merge-only: skipped nuXmv checks" | tee /artifacts/verify-skipped.txt
    ;;
  *)
    echo "Unknown VERIFY_MODE=${VERIFY_MODE} (use quick|full|merge-only)" >&2
    exit 1
    ;;
esac

if [[ -d logs ]]; then
  rm -rf /artifacts/logs
  cp -a logs /artifacts/logs || true
fi

echo "Artifacts written under /artifacts (mounted from host)." | tee /artifacts/done.txt
exit "$fail"
