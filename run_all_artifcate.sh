#!/usr/bin/env bash
# Full Docker run: build image, merge model, run checks, copy logs/results into ./artifacts/...
# Usage: ./run_all_artifcate.sh
# Env:   IMAGE_NAME (default ach-model:nuxmv) VERIFY_MODE=quick|full|merge-only ARTIFACT_DIR (optional explicit path)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="${IMAGE_NAME:-ach-model:nuxmv}"
PLATFORM="${DOCKER_PLATFORM:-linux/amd64}"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker not found in PATH; install Docker Desktop or the Docker engine." >&2
  exit 1
fi

STAMP="$(date +%Y%m%d-%H%M%S)"
ARTIFACT_DIR="${ARTIFACT_DIR:-$ROOT/artifacts/docker-run-${STAMP}}"
mkdir -p "$ARTIFACT_DIR"

echo "Building ${IMAGE_NAME} (platform ${PLATFORM})..."
docker build --platform "$PLATFORM" -t "$IMAGE_NAME" "$ROOT"

echo "Running container; VERIFY_MODE=${VERIFY_MODE:-quick}; artifacts -> $ARTIFACT_DIR"
docker run --rm --platform "$PLATFORM" \
  -e VERIFY_MODE="${VERIFY_MODE:-quick}" \
  -v "$ARTIFACT_DIR:/artifacts" \
  "$IMAGE_NAME"

echo "Done. Logs and merged model: $ARTIFACT_DIR"
