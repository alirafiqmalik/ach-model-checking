[← Artifact README](../README.md)

# Reference results

This snapshot records the ordinary native Linux run with nuXmv 2.1.0.

Contents

- [Provenance](#provenance)
- [Results](#results)
- [creditMINT witness](#creditmint-witness)
- [Inventory and integrity](#inventory-and-integrity)

## Provenance

[local-run-20261029-artifact-reviews/RUN.txt](local-run-20261029-artifact-reviews/RUN.txt) records one uninterrupted `./run_all_artifact.sh --no-docker` run: `JOBS=9`, `PHI2_ENGINE=bmc`, `PHI2_BMC_K=60`, `BMC_K=50`, with no skip flags or auxiliary queries.

Model SHA256: `521cb55953c68f38e4c3587381f686a29af489727405b0d78bdd66ed2a3b568d`. Timings are individual job wall times under concurrent load, not universal runtime guarantees.

## Results

All three invariants are violated; four EF searches remain bounded-inconclusive.

<p align="center">
  <img src="../docs/assets/results-overview.svg" alt="Verdicts and wall times of all 40 property checks in the reference run" width="100%">
</p>

| # | Kind | Formula | Result | Wall seconds | Trace states |
| --- | --- | --- | --- | --- | --- |
| 0 | CTL | `EF orig_0.fsm_state = linked_ok` | true | 3 | 8 |
| 1 | CTL | `EF orig_0.fsm_state = link_failed` | true | 122 | 27 |
| 2 | CTL | `EF orig_0.md_state = md_confirmed` | true | 80 | 22 |
| 3 | CTL | `EF orig_0.md_state = md_failed` | true | 6 | 11 |
| 4 | CTL | `EF orig_0.tx_0.payment_state = rejected` | true | 15 | 14 |
| 5 | CTL | `EF orig_0.tx_0.payment_state = returned` | true | 44 | 21 |
| 6 | CTL | `EF orig_0.tx_0.payment_state = reversed` | false | 1 | 0 |
| 7 | CTL | `EF orig_0.fsm_state = reversing` | true | 324 | 31 |
| 8 | CTL | `EF recv_0.fsm_state = auth_granted` | true | 1 | 3 |
| 9 | CTL | `EF recv_0.fsm_state = auth_revoked_state` | true | 1 | 3 |
| 10 | CTL | `EF recv_0.fsm_state = confirmed_md` | inconclusive | 1349 | 0 |
| 11 | CTL | `EF recv_0.fsm_state = rejected_md` | inconclusive | 1310 | 0 |
| 12 | CTL | `EF recv_0.fsm_state = notified_return` | false | 1 | 0 |
| 13 | CTL | `EF recv_0.fsm_state = account_state_changed` | true | 1 | 2 |
| 14 | CTL | `EF odfi_i.fsm_state = tps_verified` | false | 1 | 0 |
| 15 | CTL | `EF odfi_i.fsm_state = tps_rejected` | inconclusive | 2678 | 0 |
| 16 | CTL | `EF odfi_i.fsm_state = validation_rejected` | true | 5 | 11 |
| 17 | CTL | `EF odfi_i.fsm_state = operator_acked` | true | 16 | 16 |
| 18 | CTL | `EF odfi_i.fsm_state = link_acked` | true | 1 | 5 |
| 19 | CTL | `EF odfi_i.u3_batch_reject` | true | 6 | 11 |
| 20 | CTL | `EF odfi_i.u3_flag_entries` | true | 6 | 11 |
| 21 | CTL | `EF ach_i.fsm_state = data_rejected_batch` | true | 19 | 17 |
| 22 | CTL | `EF ach_i.fsm_state = data_rejected_entry` | true | 20 | 17 |
| 23 | CTL | `EF ach_i.fsm_state = forwarded_ack` | true | 8 | 12 |
| 24 | CTL | `EF rdfi_i.fsm_state = settled_state` | true | 24 | 18 |
| 25 | CTL | `EF rdfi_i.fsm_state = returning` | true | 24 | 18 |
| 26 | CTL | `EF rdfi_i.fsm_state = reversed_state` | false | 1 | 0 |
| 27 | CTL | `EF rdfi_i.selected_return_code = R16` | true | 52 | 19 |
| 28 | CTL | `EF rdfi_i.selected_return_code = R29` | inconclusive | 559 | 0 |
| 29 | CTL | `EF env_i.window_count = 3` | true | 39 | 19 |
| 30 | CTL | `EF env_i.phase = ph_return_closed` | true | 4 | 9 |
| 31 | CTL | `EF g.n_credits_micro > 0` | true | 58 | 21 |
| 32 | CTL | `EF g.n_credits_small > 0` | true | 71 | 22 |
| 33 | CTL | `EF g.n_credits_large > 0` | true | 72 | 22 |
| 34 | CTL | `EF g.n_debits_micro > 0` | true | 70 | 22 |
| 35 | CTL | `EF g.n_debits_small > 0` | true | 72 | 22 |
| 36 | CTL | `EF g.n_debits_large > 0` | true | 39 | 22 |
| 37 | Invar | `(((phi1_ok_tx0 & phi1_ok_tx1) & phi1_ok_tx2) & phi1_ok_tx3)` | false | 13 | 10 |
| 38 | Invar | `(((orig_0.verification_cycle_complete -> orig_0.verification_credits = orig_0.verification_debits) & (orig_1.verification_cycle_complete -> orig_1.verification_credits = orig_1.verification_debits)) & (g.cycle_complete -> g.n_credits_regular = g.n_debits_regular))` | false | 33 | 30 |
| 39 | Invar | `((((resource_released_tx0 -> env_i.return_window_expired) & (resource_released_tx1 -> env_i.return_window_expired)) & (resource_released_tx2 -> env_i.return_window_expired)) & (resource_released_tx3 -> env_i.return_window_expired))` | false | 9 | 9 |

Trace states are taken from `audit.json`; zero means no trace recorded.

## creditMINT witness

The ordinary Φ2 counterexample has 30 states. Originator 1 selects Receiver 1: credit settles at state 21, confirmation occurs at 22, linkage at 23, and the recovery debit returns R16 at 30.

<p align="center">
  <img src="../docs/assets/phi2-creditmint-trace.svg" alt="Swimlane timeline of the 30-state Phi2 creditMINT counterexample" width="100%">
</p>

The account is `DEBIT_BLOCKED`. The verification cycle has one settled MICRO credit and zero settled MICRO debits; the other Originator submits nothing. No prior manual/web link or auxiliary search constraint selects this sequence.

## Inventory and integrity

| File | Purpose |
| --- | --- |
| `RUN.txt` | Configuration and provenance |
| `SHA256SUMS` | Snapshot checksums |
| `_main_model.smv` | Checked model |
| `audit.json` | Verdicts, trace lengths and hashes |
| `cmds-*.txt` | Executed nuXmv scripts |
| `spec-*.log` | Property logs and traces |
| `timing*.tsv` | Per-job and aggregate timings |
| `runner.log` | Runner console output |
| `show_property.txt` | Unified property listing |
| `model_stats.md` | Model statistics and property sheet |

From the repository root:

```bash
cd saved-reference-results/local-run-20261029-artifact-reviews
sha256sum -c SHA256SUMS
```

All 129 entries pass. To compare a new run, first compare merged-model hashes and engine/bound settings, then compare each unified property index and verdict. Inspect traces for semantic differences; solver-selected witnesses and timings may differ. Regenerate command scripts with the runner: saved commands retain the original absolute paths.

## See also

[Models](../models/README.md) · [Pipeline](../docs/verification-pipeline.md) · [Properties](../docs/properties.md) · [Reference results](../saved-reference-results/README.md) · [Tools](../tools/README.md)
