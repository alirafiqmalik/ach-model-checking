# nuXmv model merge + verification (Linux/x86_64; bundled tools/nuxmv-linux).
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
  && apt-get install -y --no-install-recommends make bash ca-certificates diffutils python3 \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /work

COPY Makefile ./
COPY run_all_artifact.sh ./
COPY models ./models
COPY tools/merge_smv.sh tools/nuxmv-linux tools/nuxmv_model_stats.py ./tools/
RUN chmod +x tools/nuxmv-linux tools/merge_smv.sh run_all_artifact.sh

ENV NUXMV=/work/tools/nuxmv-linux
ENV VERIFY_MODE=quick
ENV ARTIFACT_DIR=/artifacts

COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
