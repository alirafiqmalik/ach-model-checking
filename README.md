
# ACH nuXmv model (paper artifact)

Artifacts for the ACM CCS 2026 paper: "Credit Without Debit: Formal Verification of Banking Payment Systems" by Ali Hamza Malik and Muhammad Taqi Raza (University of Massachusetts Amherst).

This project contains the NuSMV / nuXmv formal models for ACH payment flow along with the scripts for running and compiling the verification results. The results are compiled into a markdown file for easy review of results.

Our empirical evaluation uses real consumer bank accounts owned by members of the research team. Raw account screenshots and transaction logs cannot be shared publicly because they contain personally identifiable financial information. The paper provides the redacted screenshots documenting the user-visible state changes for each CWD instance (A1: creditBLEED Attack, A2: creditMINT Attack, and A3: creditRESET Attack).

## Requirements

- Docker, or macOS / Linux with `bash`, `make`, `python3`, and `diff`.
- nuXmv binaries in `tools/`, included with the paper bundle:
  - Linux (Docker or host): `tools/nuxmv-linux` (executable)
  - macOS without Docker: `tools/nuxmv-mac` (executable)

`docker build` fails if `tools/nuxmv-linux` is missing. Copy the binaries from the artifact bundle, then `chmod +x tools/nuxmv-linux` (and `nuxmv-mac` if you use the host binary).

## Run

From the repo root:

```bash
./run_all_artifact.sh
```

Builds the image and merges the model. Checks run next; outputs go to `output/docker-run-<timestamp>/`.

Without Docker (`tools/nuxmv-linux` on Linux, `tools/nuxmv-mac` on macOS):

```bash
./run_all_artifact.sh --no-docker
```

Outputs go to `output/local-run-<timestamp>/` unless you set a path:

```bash
ARTIFACT_DIR=./output/custom-run ./run_all_artifact.sh --no-docker
```

`make merge` writes `output/_main_model.smv`. Pipeline jobs write logs and `model_stats.md` into the same `output/` tree (one directory per run). The whole `output/` directory is gitignored.

### Docker Desktop resources and Compose

The reference host has 16 logical CPUs and 15 GiB of RAM. A complete run can take hours, depending on the model, hardware and concurrent jobs. In Docker Desktop, inspect **Settings → Resources → Advanced** and allocate enough CPUs and memory for the container limits below, leaving memory for the host. With the WSL 2 backend, configure the WSL VM allocation instead. See [Docker Desktop resource settings](https://docs.docker.com/desktop/settings-and-maintenance/settings/#resources).

The optional Compose service defaults to 4 CPUs, an 8 GiB memory limit and 3 concurrent checker jobs. These are configurable starting values, not a measured minimum requirement. Reduce `JOBS` when memory is constrained; increasing the container limit cannot increase Docker Desktop's VM allocation.

```bash
ARTIFACT_CPUS=4 ARTIFACT_MEMORY=8g JOBS=3 docker compose config
ARTIFACT_CPUS=4 ARTIFACT_MEMORY=8g JOBS=3 docker compose run --build --rm artifact
```

Compose outputs default to `output/compose-run/`; set `ARTIFACT_DIR` to a fresh host directory for each retained run. `VERIFY_MODE`, `BMC_K` and `SKIP_INVAR` are also forwarded. The existing `./run_all_artifact.sh` Docker command remains available; Compose resource limits apply when using Compose. See [Compose CPU and memory limits](https://docs.docker.com/reference/compose-file/services/).

### Verification modes

Set `VERIFY_MODE` before the command:

| Value        | What it does                                                                  |
| ------------ | ----------------------------------------------------------------------------- |
| `quick`      | Default. IC3 on Φ1–Φ3, then BMC on each `SPEC EF`. Writes the property sheet. |
| `full`       | Runs `make verify` (verbose nuXmv on the merged model).                       |
| `merge-only` | Merge only; skips nuXmv. Still writes `model_stats.md` where possible.        |

Example:

```bash
VERIFY_MODE=full ./run_all_artifact.sh --no-docker
```

## Results

The script prints the artifact directory when it finishes.

| File / folder           | Meaning                                                                                      |
| ----------------------- | -------------------------------------------------------------------------------------------- |
| `_main_model.smv`       | Single merged model (same as `output/_main_model.smv`).                                      |
| `model_stats.md`        | Model size plus a table of every Invar and `EF` property when logs exist.                     |
| `spec-*-INV.log`        | Quick-mode IC3 logs (written in the run directory, not a separate `logs/` tree).             |
| `spec-*-CTL.log`        | BMC logs for each `EF p` (k-induction of `!(p)`).                                             |
| `done.txt`              | Confirms the container or script finished.                                                   |
| `verify-skipped.txt`    | Present only if `VERIFY_MODE=merge-only`.                                                    |
| `nuxmv-verify-full.log` | Only for `VERIFY_MODE=full`: full console log from `make verify`.                            |

Quick mode writes `spec-{0,1,2}-INV.log` and `spec-*-CTL.log`. The driver prints a terminal summary. In an INV log, search for invariant is true, is false, or a counterexample. For an IC3 invariant, true is a proof and false is a counterexample. A false verdict precedes its trace, so it need not be the final line. Progress messages alone are not a verdict.

CTL logs decide `EF p` by BMC of `!(p)` (bound `BMC_K`, default 50). A counterexample is a witness, so `!(p)` false means the executability property is true. A proved true `!(p)` makes `EF p` false; no proof or counterexample through the bound is inconclusive, not evidence of unreachability.

`timing.tsv` is one line per INV job (local index, unified index, seconds). `timing.ctl.tsv` is the same for EF jobs.

To add EF logs to an existing INV run without repeating Φ1–Φ3:

```bash
SKIP_INVAR=1 ARTIFACT_DIR=./output/local-run-<timestamp> ./run_all_artifact.sh --no-docker
```

## Expected results

`VERIFY_MODE=quick` on a 16-thread, 15 GiB machine. Φ1–Φ3 are IC3 (false: the A1: creditBLEED, A2: creditMINT, and A3: creditRESET attacks). Each `EF` row is BMC of `!(p)` with `k=50`: true is a witness, false is unreachable, inconclusive means no proof or counterexample inside the bound. INV jobs run in parallel (wall clock is Φ2, about 48 minutes). EF jobs run after that.

| # | Kind | Formula | Result | Time (s) |
| --- | --- | --- | --- | --- |
| 0 | CTL | EF orig_0.fsm_state = linked_ok | true | 2 |
| 1 | CTL | EF orig_0.fsm_state = link_failed | true | 95 |
| 2 | CTL | EF orig_0.md_state = md_confirmed | inconclusive | 1262 |
| 3 | CTL | EF orig_0.md_state = md_failed | true | 4 |
| 4 | CTL | EF orig_0.tx_0.payment_state = rejected | true | 14 |
| 5 | CTL | EF orig_0.tx_0.payment_state = returned | true | 44 |
| 6 | CTL | EF orig_0.tx_0.payment_state = reversed | false | 1 |
| 7 | CTL | EF orig_0.fsm_state = reversing | true | 318 |
| 8 | CTL | EF recv_0.fsm_state = auth_granted | true | 1 |
| 9 | CTL | EF recv_0.fsm_state = auth_revoked_state | true | 0 |
| 10 | CTL | EF recv_0.fsm_state = confirmed_md | inconclusive | 967 |
| 11 | CTL | EF recv_0.fsm_state = rejected_md | inconclusive | 927 |
| 12 | CTL | EF recv_0.fsm_state = notified_return | false | 0 |
| 13 | CTL | EF recv_0.fsm_state = account_state_changed | true | 0 |
| 14 | CTL | EF odfi_i.fsm_state = tps_verified | false | 0 |
| 15 | CTL | EF odfi_i.fsm_state = tps_rejected | inconclusive | 2169 |
| 16 | CTL | EF odfi_i.fsm_state = validation_rejected | true | 7 |
| 17 | CTL | EF odfi_i.fsm_state = operator_acked | true | 15 |
| 18 | CTL | EF odfi_i.fsm_state = link_acked | true | 1 |
| 19 | CTL | EF odfi_i.u3_batch_reject | true | 5 |
| 20 | CTL | EF odfi_i.u3_flag_entries | true | 5 |
| 21 | CTL | EF ach_i.fsm_state = data_rejected_batch | true | 19 |
| 22 | CTL | EF ach_i.fsm_state = data_rejected_entry | true | 20 |
| 23 | CTL | EF ach_i.fsm_state = forwarded_ack | true | 6 |
| 24 | CTL | EF rdfi_i.fsm_state = settled_state | true | 24 |
| 25 | CTL | EF rdfi_i.fsm_state = returning | true | 24 |
| 26 | CTL | EF rdfi_i.fsm_state = reversed_state | false | 1 |
| 27 | CTL | EF rdfi_i.selected_return_code = R16 | true | 27 |
| 28 | CTL | EF rdfi_i.selected_return_code = R29 | true | 30 |
| 29 | CTL | EF env_i.window_count = 3 | true | 25 |
| 30 | CTL | EF env_i.phase = ph_return_closed | true | 5 |
| 31 | CTL | EF g.n_credits_micro > 0 | true | 43 |
| 32 | CTL | EF g.n_credits_small > 0 | true | 40 |
| 33 | CTL | EF g.n_credits_large > 0 | true | 42 |
| 34 | CTL | EF g.n_debits_micro > 0 | false | 6 |
| 35 | Invar | phi1_ok_tx0 & phi1_ok_tx1 & phi1_ok_tx2 & phi1_ok_tx3 | false | 222 |
| 36 | Invar | cycle_complete -> (n_credits_micro = n_debits_micro & n_credits_regular = n_debits_regular) | false | 2888 |
| 37 | Invar | resource_released_tx* -> return_window_expired | false | 6 |

### Paper attacks

Paper Φ1–Φ3 are the three `INVARSPEC`s. `show_property` numbers them 35–37 because the CTL `EF`s come first. Each is false; the counterexample is in that INV log.

| Paper | Attack | Invar # | Log | Name | CEX |
| --- | --- | --- | --- | --- | --- |
| Φ1 | A1: creditBLEED Attack | 35 | spec-0-INV.log | Continuous Authorization | ODFI provisional debit + R16 |
| Φ2 | A2: creditMINT Attack | 36 | spec-1-INV.log | Zero-Sum Invariant | MICRO credit settled vs matching MICRO debit R08/R16, settled counts unequal |
| Φ3 | A3: creditRESET Attack | 37 | spec-2-INV.log | Settlement Finality | issuer card posting with `resource_available` while the return window is still open |

## Makefile

| Target             | Action                                                    |
| ------------------ | --------------------------------------------------------- |
| `make merge`       | Build `output/_main_model.smv` from `models/*.smv`.       |
| `make check-merge` | Ensures merge output matches joining the parts in order.  |
| `make smoke`       | Loads merged model and flattens (fast sanity check).      |
| `make test`        | Tiny merge + nuXmv batch (needs a `tools/` nuXmv binary). |
| `make clean`       | Removes generated merge files (not the rest of `output/`). |

## Layout

- `models/`: SMV fragments (types, originator, ODFI, operator, RDFI, receiver, specs in `99_main.smv`).
- `tools/`: `merge_smv.sh`, stats script, nuXmv binaries (from the artifact bundle).
- `run_all_artifact.sh`: merge, checks, and stats (name matches the paper scripts).
- `output/`: gitignored merge product and per-run logs/stats.
- `saved-reference-results/`: committed snapshot of a known-good job run.
