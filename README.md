
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

Compose outputs default to `output/compose-run/`; set `ARTIFACT_DIR` to a fresh host directory for each retained run. `VERIFY_MODE`, `BMC_K`, `SKIP_INVAR`, `SKIP_CTL`, `PHI2_ENGINE` and `PHI2_BMC_K` are also forwarded. The existing `./run_all_artifact.sh` Docker command remains available; Compose resource limits apply when using Compose. See [Compose CPU and memory limits](https://docs.docker.com/reference/compose-file/services/).

### Verification modes

Set `VERIFY_MODE` before the command:

| Value        | What it does                                                                  |
| ------------ | ----------------------------------------------------------------------------- |
| `quick`      | Default. IC3 on Φ1/Φ3, incremental BMC on Φ2, then BMC on each `SPEC EF`. Writes the property sheet. |
| `full`       | Runs `make verify` (verbose nuXmv on the merged model).                       |
| `merge-only` | Merge only; skips nuXmv. Still writes `model_stats.md` where possible.        |

Example:

```bash
VERIFY_MODE=full ./run_all_artifact.sh --no-docker
```

The default quick run uses incremental BMC for the per-account verification-cycle Φ2 invariant:

```bash
./run_all_artifact.sh --no-docker
```

`PHI2_ENGINE` defaults to `bmc`, with `PHI2_BMC_K=60`. Set `PHI2_ENGINE=ic3` to use IC3 for Φ2 instead. The engine option changes only the checking algorithm. Both engines check the declared Φ2 property directly on the model, without an auxiliary query or search restrictions. A BMC counterexample conclusively refutes Φ2. No counterexample through `PHI2_BMC_K` is only bounded-inconclusive, not a safety proof. Φ1/Φ3 still use IC3, and all EF checks retain their existing method and `BMC_K` bound. The same options work with Docker and Compose.

## Results

The script prints the artifact directory when it finishes. In quick mode, `spec-1-INV.log` is written during the initial invariant stage, so the Φ2 trace can be inspected while the EF reachability checks continue.

| File / folder           | Meaning                                                                                      |
| ----------------------- | -------------------------------------------------------------------------------------------- |
| `_main_model.smv`       | Single merged model (same as `output/_main_model.smv`).                                      |
| `model_stats.md`        | Model size plus a table of every Invar and `EF` property when logs exist.                     |
| `spec-*-INV.log`        | Quick-mode invariant logs (IC3 for Φ1/Φ3; incremental BMC for Φ2 by default).             |
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

To rerun invariants while retaining completed EF logs for the **same merged model**:

```bash
SKIP_CTL=1 ARTIFACT_DIR=./output/local-run-<timestamp> ./run_all_artifact.sh --no-docker
```

Use either skip option only when the retained logs and `_main_model.smv` belong to the current model. Start a fresh artifact directory after changing the model. `SKIP_CTL=1` rejects a missing or mismatched saved model and missing CTL logs or timings. These options reuse existing results; they do not rerun skipped checks.

## Expected results

Reference results from nuXmv 2.1.0 are saved in [`local-run-20261029-artifact-reviews`](saved-reference-results/local-run-20261029-artifact-reviews/model_stats.md). The normal native command used the defaults `PHI2_ENGINE=bmc`, `PHI2_BMC_K=60`, `BMC_K=50` and `JOBS=9`: Φ1/Φ3 use IC3, Φ2 uses incremental BMC on the declared per-account verification-cycle invariant, and all 37 EF checks use the existing `een-sorensson` method. These engines and bounds match the current defaults.

All 40 checks completed in one uninterrupted normal run; see [run configuration and audit](saved-reference-results/local-run-20261029-artifact-reviews/RUN.txt). Timings are individual job wall times under concurrent load. The four bounded-inconclusive EF results do not establish unreachability.

| # | Kind | Formula | Result | Time (s) |
| --- | --- | --- | --- | --- |
| 0 | CTL | EF orig_0.fsm_state = linked_ok | true | 3 |
| 1 | CTL | EF orig_0.fsm_state = link_failed | true | 122 |
| 2 | CTL | EF orig_0.md_state = md_confirmed | true | 80 |
| 3 | CTL | EF orig_0.md_state = md_failed | true | 6 |
| 4 | CTL | EF orig_0.tx_0.payment_state = rejected | true | 15 |
| 5 | CTL | EF orig_0.tx_0.payment_state = returned | true | 44 |
| 6 | CTL | EF orig_0.tx_0.payment_state = reversed | false | 1 |
| 7 | CTL | EF orig_0.fsm_state = reversing | true | 324 |
| 8 | CTL | EF recv_0.fsm_state = auth_granted | true | 1 |
| 9 | CTL | EF recv_0.fsm_state = auth_revoked_state | true | 1 |
| 10 | CTL | EF recv_0.fsm_state = confirmed_md | inconclusive | 1349 |
| 11 | CTL | EF recv_0.fsm_state = rejected_md | inconclusive | 1310 |
| 12 | CTL | EF recv_0.fsm_state = notified_return | false | 1 |
| 13 | CTL | EF recv_0.fsm_state = account_state_changed | true | 1 |
| 14 | CTL | EF odfi_i.fsm_state = tps_verified | false | 1 |
| 15 | CTL | EF odfi_i.fsm_state = tps_rejected | inconclusive | 2678 |
| 16 | CTL | EF odfi_i.fsm_state = validation_rejected | true | 5 |
| 17 | CTL | EF odfi_i.fsm_state = operator_acked | true | 16 |
| 18 | CTL | EF odfi_i.fsm_state = link_acked | true | 1 |
| 19 | CTL | EF odfi_i.u3_batch_reject | true | 6 |
| 20 | CTL | EF odfi_i.u3_flag_entries | true | 6 |
| 21 | CTL | EF ach_i.fsm_state = data_rejected_batch | true | 19 |
| 22 | CTL | EF ach_i.fsm_state = data_rejected_entry | true | 20 |
| 23 | CTL | EF ach_i.fsm_state = forwarded_ack | true | 8 |
| 24 | CTL | EF rdfi_i.fsm_state = settled_state | true | 24 |
| 25 | CTL | EF rdfi_i.fsm_state = returning | true | 24 |
| 26 | CTL | EF rdfi_i.fsm_state = reversed_state | false | 1 |
| 27 | CTL | EF rdfi_i.selected_return_code = R16 | true | 52 |
| 28 | CTL | EF rdfi_i.selected_return_code = R29 | inconclusive | 559 |
| 29 | CTL | EF env_i.window_count = 3 | true | 39 |
| 30 | CTL | EF env_i.phase = ph_return_closed | true | 4 |
| 31 | CTL | EF g.n_credits_micro > 0 | true | 58 |
| 32 | CTL | EF g.n_credits_small > 0 | true | 71 |
| 33 | CTL | EF g.n_credits_large > 0 | true | 72 |
| 34 | CTL | EF g.n_debits_micro > 0 | true | 70 |
| 35 | CTL | EF g.n_debits_small > 0 | true | 72 |
| 36 | CTL | EF g.n_debits_large > 0 | true | 39 |
| 37 | Invar | (((phi1_ok_tx0 & phi1_ok_tx1) & phi1_ok_tx2) & phi1_ok_tx3) | false | 13 |
| 38 | Invar | (((orig_0.verification_cycle_complete -> orig_0.verification_credits = orig_0.verification_debits) & (orig_1.verification_cycle_complete -> orig_1.verification_credits = orig_1.verification_debits)) & (g.cycle_complete -> g.n_credits_regular = g.n_debits_regular)) | false | 33 |
| 39 | Invar | ((((resource_released_tx0 -> env_i.return_window_expired) & (resource_released_tx1 -> env_i.return_window_expired)) & (resource_released_tx2 -> env_i.return_window_expired)) & (resource_released_tx3 -> env_i.return_window_expired)) | false | 9 |

### Paper properties and attack witnesses

The three `INVARSPEC`s are Φ1–Φ3. Their unified indices are 37–39 after the 37 CTL reachability properties. An unrestricted invariant counterexample need not contain every step of the corresponding paper attack.

For micro-deposit linking, each Originator submits a MICRO credit and its recovery debit to the same freely selected `link_target_r`. The two local slots record membership in this verification cycle. Entry outcomes still follow the existing Operator and RDFI transitions: neither successful settlement nor a debit return is prescribed. After credit settlement, the provider links and keeps that verification account active until the pair is terminal.

Φ2 checks settled-credit/debit equality separately for each provider's linked-account verification cycle, before the return window closes. A history latch records that this account was linked, so leaving the linking state cannot erase the obligation. This replaces the previous global MICRO aggregation, which could match a credit against an unrelated provider's or account's debit. Regular-class balance retains the existing global-cycle condition. This is a specification and verification-protocol correction, not just a change of search engine. It does not assert global MICRO balance for arbitrary manual/web-linked payments.

The normal command checks this Φ2 directly and saves its counterexample as `spec-1-INV.log`. The saved trace has 30 states: Originator 1, Receiver 1, credit settlement at 21, confirmation at 22, linkage at 23, and debit return `R16` at 30. The other Originator submits nothing. No additional creditMINT query, fixed account selection, return-code constraint, private helper, or extra command is used. The source retains both Originators and both Receivers.

This provider policy abstracts the Receiver confirmation exchange; the separate ODFI TPS handshake remains outside that abstraction. The model covers one verification pair per provider. Repeated-cycle amplification remains empirical.

| Paper | Attack | Invar # | Log | Interpretation |
| --- | --- | --- | --- | --- |
| Φ1 | A1: creditBLEED | 37 | spec-0-INV.log | Authorization at submission and throughout the pipeline, plus the existing RDFI/return predicate. A full provisional-debit/R16 sequence requires a targeted witness. |
| Φ2 | A2: creditMINT | 38 | spec-1-INV.log | Per-provider, per-account verification-cycle imbalance after linkage. The saved ordinary Φ2 trace shows the creditMINT sequence. |
| Φ3 | A3: creditRESET | 39 | spec-2-INV.log | Issuer card posting makes resources available before the return window expires. |

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
- `saved-reference-results/`: completed reference run for the current model, with logs, timings, statistics and provenance.
