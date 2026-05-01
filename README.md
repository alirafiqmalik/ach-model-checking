# ACH nuXmv model (paper artifact)

This repo holds a **split NuSMV / nuXmv model** of ACH-style payment flow. Scripts merge the parts, then run **nuXmv** checks and write a short **Markdown** report.

## What you need

- **Docker** (simplest), **or** macOS / Linux with `bash`, `make`, `python3`, and `diff`.
- **nuXmv** binaries in `tools/`, included with the paper bundle:
  - Linux (Docker or host): `tools/nuxmv-linux` (executable)
  - macOS without Docker: `tools/nuxmv-mac` (executable)

> [!NOTE]
> If `tools/nuxmv-linux` is missing, `docker build` fails. Copy the binaries from the artifact bundle, then `chmod +x tools/nuxmv-linux` (and `nuxmv-mac` if you use it).

## Run everything (recommended)

From the repo root:

```bash
./run_all_artifact.sh
```

This **builds** the image, **merges** the model, runs checks, and copies outputs to a new folder under `artifacts/docker-run-<timestamp>/`.

**Without Docker** (uses `tools/nuxmv-linux` on Linux or `tools/nuxmv-mac` on macOS):

```bash
./run_all_artifact.sh --no-docker
```

Outputs go to `artifacts/local-run-<timestamp>/` unless you set a path:

```bash
ARTIFACT_DIR=./my-out ./run_all_artifact.sh --no-docker
```

### Verification modes

Set **`VERIFY_MODE`** before the command:

| Value        | What it does |
| ------------ | ------------ |
| `quick`      | Default. Three **IC3** invariant checks (one log per spec). Faster than full. |
| `full`       | Runs `make verify` (verbose nuXmv on the merged model). |
| `merge-only` | Merge only; skips nuXmv. Still writes `model_stats.md` where possible. |

Example:

```bash
VERIFY_MODE=full ./run_all_artifact.sh --no-docker
```

## Read the results

After a run, open the **artifact directory** (printed at the end).

| File / folder        | Meaning |
| -------------------- | ------- |
| `_main_model.smv`    | Single merged model (same as repo merge output). |
| `model_stats.md`     | Model size (vars, BDD / FSM lines) and, if logs exist, a short **IC3** summary from the verifier. |
| `logs/`              | Copy of run logs (quick / full layout). |
| `done.txt`           | Confirms the container or script finished. |
| `verify-skipped.txt` | Present only if `VERIFY_MODE=merge-only`. |
| `nuxmv-verify-full.log` | Only for **`VERIFY_MODE=full`**: full console log from `make verify`. |

**Quick mode logs:** under `logs/…/`, files like `spec-0-INV.log`, `spec-1-INV.log`, `spec-2-INV.log`. The driver also prints a **summary** to the terminal. In each log, search for lines that say an invariant **is true**, **is false**, or mention a **counterexample**. **True** means nuXmv did not report a counterexample for that check (see the tool docs for limits).

**`timing.tsv`:** one line per spec job with elapsed seconds (wall time per check).

> [!TIP]
> If a log has no clear verdict line, open the full `spec-*-INV.log` and read the end of the file; nuXmv prints the result there.

## Makefile (manual steps)

| Target        | Action |
| ------------- | ------ |
| `make merge`  | Build `_main_model.smv` from `models/*.smv`. |
| `make check-merge` | Ensures merge output matches joining the parts in order. |
| `make smoke`  | Loads merged model and flattens (fast sanity check). |
| `make test`   | Tiny merge + nuXmv batch (needs a `tools/` nuXmv binary). |
| `make clean`  | Removes generated merge files. |

## Repo layout

- **`models/`** — SMV fragments (types, originator, ODFI, operator, RDFI, receiver, specs in `99_main.smv`).
- **`tools/`** — `merge_smv.sh`, stats script, nuXmv binaries (you add these from the artifact).
- **`run_all_artifact.sh`** — One entry point for merge, checks, and stats (name matches the paper scripts).
