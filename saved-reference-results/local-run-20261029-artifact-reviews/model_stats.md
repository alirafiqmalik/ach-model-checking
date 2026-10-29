# nuXmv model statistics

- nuXmv: `/home/ahm/Desktop/project/artifacts-eval/acm-ccs-ach-payments/eval_review/source-ach-model-checking/tools/nuxmv-linux`
- Model: `/home/ahm/Desktop/project/artifacts-eval/acm-ccs-ach-payments/eval_review/source-ach-model-checking/output/_main_model.smv`

## Static (after `go`)

| Metric | Value |
| --- | --- |
| nuXmv exit code (static batch) | 0 |
| Number of Frozen Variables | 0 |
| Number of Input Variables | 11 |
| Number of State Variables | 197 |
| Number of bits (summary) | 417 (0 frozen, 15 input, 402 state) |
| Memory in use | 115345816 |
| Number of BDD variables | 820 |
| Number of LIVE BDD and ADD nodes | 2735350 |
| Peak number of nodes | 2782906 |
| Total number of nodes allocated | 2942491 |
| BDD cluster sizes (forward schedule) | cluster 1 : size 1124; cluster 2 : size 15568; cluster 3 : size 1086; cluster 4 : size 4877; cluster 5 : size 1148; cluster 6 : size 1478; cluster 7 : size 1123; cluster 8 : size 1307; cluster 9 : size 12596; cluster 10 : size 1087; cluster 11 : size 4877; cluster 12 : size 1149; cluster 13 : size 1478; cluster 14 : size 1123; cluster 15 : size 1307; cluster 16 : size 23856; cluster 17 : size 1037; cluster 18 : size 626; cluster 19 : size 1599; cluster 20 : size 1175; cluster 21 : size 4797; cluster 22 : size 2140; cluster 23 : size 1102; cluster 24 : size 135; cluster 25 : size 3725; cluster 26 : size 8244; cluster 27 : size 23285; cluster 28 : size 4046; cluster 29 : size 2267; cluster 30 : size 761 |
| BDD nodes representing init set of states | 391 |
| BDD nodes representing input constraints | 1 |
| BDD nodes representing state constraints | 380700 |
| BDD nodes allocated (usage) | 2782077 |

## Properties

CTL `EF p` is BMC of `!(p)`: a counterexample means the executability property is true.

| # | Kind | Name | Formula | Result | Time (s) | Log |
| --- | --- | --- | --- | --- | --- | --- |
| 0 | CTL |  | EF orig_0.fsm_state = linked_ok | true | 3.000 | spec-0-CTL.log |
| 1 | CTL |  | EF orig_0.fsm_state = link_failed | true | 122.000 | spec-1-CTL.log |
| 2 | CTL |  | EF orig_0.md_state = md_confirmed | true | 80.000 | spec-2-CTL.log |
| 3 | CTL |  | EF orig_0.md_state = md_failed | true | 6.000 | spec-3-CTL.log |
| 4 | CTL |  | EF orig_0.tx_0.payment_state = rejected | true | 15.000 | spec-4-CTL.log |
| 5 | CTL |  | EF orig_0.tx_0.payment_state = returned | true | 44.000 | spec-5-CTL.log |
| 6 | CTL |  | EF orig_0.tx_0.payment_state = reversed | false | 1.000 | spec-6-CTL.log |
| 7 | CTL |  | EF orig_0.fsm_state = reversing | true | 324.000 | spec-7-CTL.log |
| 8 | CTL |  | EF recv_0.fsm_state = auth_granted | true | 1.000 | spec-8-CTL.log |
| 9 | CTL |  | EF recv_0.fsm_state = auth_revoked_state | true | 1.000 | spec-9-CTL.log |
| 10 | CTL |  | EF recv_0.fsm_state = confirmed_md | inconclusive | 1349.000 | spec-10-CTL.log |
| 11 | CTL |  | EF recv_0.fsm_state = rejected_md | inconclusive | 1310.000 | spec-11-CTL.log |
| 12 | CTL |  | EF recv_0.fsm_state = notified_return | false | 1.000 | spec-12-CTL.log |
| 13 | CTL |  | EF recv_0.fsm_state = account_state_changed | true | 1.000 | spec-13-CTL.log |
| 14 | CTL |  | EF odfi_i.fsm_state = tps_verified | false | 1.000 | spec-14-CTL.log |
| 15 | CTL |  | EF odfi_i.fsm_state = tps_rejected | inconclusive | 2678.000 | spec-15-CTL.log |
| 16 | CTL |  | EF odfi_i.fsm_state = validation_rejected | true | 5.000 | spec-16-CTL.log |
| 17 | CTL |  | EF odfi_i.fsm_state = operator_acked | true | 16.000 | spec-17-CTL.log |
| 18 | CTL |  | EF odfi_i.fsm_state = link_acked | true | 1.000 | spec-18-CTL.log |
| 19 | CTL |  | EF odfi_i.u3_batch_reject | true | 6.000 | spec-19-CTL.log |
| 20 | CTL |  | EF odfi_i.u3_flag_entries | true | 6.000 | spec-20-CTL.log |
| 21 | CTL |  | EF ach_i.fsm_state = data_rejected_batch | true | 19.000 | spec-21-CTL.log |
| 22 | CTL |  | EF ach_i.fsm_state = data_rejected_entry | true | 20.000 | spec-22-CTL.log |
| 23 | CTL |  | EF ach_i.fsm_state = forwarded_ack | true | 8.000 | spec-23-CTL.log |
| 24 | CTL |  | EF rdfi_i.fsm_state = settled_state | true | 24.000 | spec-24-CTL.log |
| 25 | CTL |  | EF rdfi_i.fsm_state = returning | true | 24.000 | spec-25-CTL.log |
| 26 | CTL |  | EF rdfi_i.fsm_state = reversed_state | false | 1.000 | spec-26-CTL.log |
| 27 | CTL |  | EF rdfi_i.selected_return_code = R16 | true | 52.000 | spec-27-CTL.log |
| 28 | CTL |  | EF rdfi_i.selected_return_code = R29 | inconclusive | 559.000 | spec-28-CTL.log |
| 29 | CTL |  | EF env_i.window_count = 3 | true | 39.000 | spec-29-CTL.log |
| 30 | CTL |  | EF env_i.phase = ph_return_closed | true | 4.000 | spec-30-CTL.log |
| 31 | CTL |  | EF g.n_credits_micro > 0 | true | 58.000 | spec-31-CTL.log |
| 32 | CTL |  | EF g.n_credits_small > 0 | true | 71.000 | spec-32-CTL.log |
| 33 | CTL |  | EF g.n_credits_large > 0 | true | 72.000 | spec-33-CTL.log |
| 34 | CTL |  | EF g.n_debits_micro > 0 | true | 70.000 | spec-34-CTL.log |
| 35 | CTL |  | EF g.n_debits_small > 0 | true | 72.000 | spec-35-CTL.log |
| 36 | CTL |  | EF g.n_debits_large > 0 | true | 39.000 | spec-36-CTL.log |
| 37 | Invar | Φ1 Continuous Authorization (A1: creditBLEED Attack) | (((phi1_ok_tx0 & phi1_ok_tx1) & phi1_ok_tx2) & phi1_ok_tx3) | false | 13.000 | spec-0-INV.log |
| 38 | Invar | Φ2 Zero-Sum Invariant (A2: creditMINT Attack) | (((orig_0.verification_cycle_complete -> orig_0.verification_credits = orig_0.verification_debits) & (orig_1.verification_cycle_complete -> orig_1.verification_credits = orig_1.verification_debits)) & (g.cycle_complete -> g.n_credits_regular = g.n_debits_regular)) | false | 33.000 | spec-1-INV.log |
| 39 | Invar | Φ3 Settlement Finality (A3: creditRESET Attack) | ((((resource_released_tx0 -> env_i.return_window_expired) & (resource_released_tx1 -> env_i.return_window_expired)) & (resource_released_tx2 -> env_i.return_window_expired)) & (resource_released_tx3 -> env_i.return_window_expired)) | false | 9.000 | spec-2-INV.log |

## Dynamic (verification run)

| Metric | Value |
| --- | --- |
| Total wall time (all parallel specs) | 7158.000 s |
| Wall time Invar 0 (gidx 37) | 13.000 s |
| Wall time Invar 1 (gidx 38) | 33.000 s |
| Wall time Invar 2 (gidx 39) | 9.000 s |
| Wall time CTL 0 (gidx 0) | 3.000 s |
| Wall time CTL 1 (gidx 1) | 122.000 s |
| Wall time CTL 2 (gidx 2) | 80.000 s |
| Wall time CTL 3 (gidx 3) | 6.000 s |
| Wall time CTL 4 (gidx 4) | 15.000 s |
| Wall time CTL 5 (gidx 5) | 44.000 s |
| Wall time CTL 6 (gidx 6) | 1.000 s |
| Wall time CTL 7 (gidx 7) | 324.000 s |
| Wall time CTL 8 (gidx 8) | 1.000 s |
| Wall time CTL 9 (gidx 9) | 1.000 s |
| Wall time CTL 10 (gidx 10) | 1349.000 s |
| Wall time CTL 11 (gidx 11) | 1310.000 s |
| Wall time CTL 12 (gidx 12) | 1.000 s |
| Wall time CTL 13 (gidx 13) | 1.000 s |
| Wall time CTL 14 (gidx 14) | 1.000 s |
| Wall time CTL 15 (gidx 15) | 2678.000 s |
| Wall time CTL 16 (gidx 16) | 5.000 s |
| Wall time CTL 17 (gidx 17) | 16.000 s |
| Wall time CTL 18 (gidx 18) | 1.000 s |
| Wall time CTL 19 (gidx 19) | 6.000 s |
| Wall time CTL 20 (gidx 20) | 6.000 s |
| Wall time CTL 21 (gidx 21) | 19.000 s |
| Wall time CTL 22 (gidx 22) | 20.000 s |
| Wall time CTL 23 (gidx 23) | 8.000 s |
| Wall time CTL 24 (gidx 24) | 24.000 s |
| Wall time CTL 25 (gidx 25) | 24.000 s |
| Wall time CTL 26 (gidx 26) | 1.000 s |
| Wall time CTL 27 (gidx 27) | 52.000 s |
| Wall time CTL 28 (gidx 28) | 559.000 s |
| Wall time CTL 29 (gidx 29) | 39.000 s |
| Wall time CTL 30 (gidx 30) | 4.000 s |
| Wall time CTL 31 (gidx 31) | 58.000 s |
| Wall time CTL 32 (gidx 32) | 71.000 s |
| Wall time CTL 33 (gidx 33) | 72.000 s |
| Wall time CTL 34 (gidx 34) | 70.000 s |
| Wall time CTL 35 (gidx 35) | 72.000 s |
| Wall time CTL 36 (gidx 36) | 39.000 s |
| Max bound explored (spec 0) | 7 |
| Verdict (spec 0) | invariant (((phi1_ok_tx0 & phi1_ok_tx1) & phi1_ok_tx2) & phi1_ok_tx3)  is false |
| Verification log size (bytes, spec 0) | 31418 |
| Max bound explored (spec 1) | 28 |
| Verdict (spec 1) | invariant (((orig_0.verification_cycle_complete -> orig_0.verification_credits = orig_0.verification_debits) & (orig_1.verification_cycle_complete -> orig_1.verification_credits = orig_1.verification_... |
| Verification log size (bytes, spec 1) | 70694 |
| Max bound explored (spec 2) | 6 |
| Verdict (spec 2) | invariant ((((resource_released_tx0 -> env_i.return_window_expired) & (resource_released_tx1 -> env_i.return_window_expired)) & (resource_released_tx2 -> env_i.return_window_expired)) & (resource_rele... |
| Verification log size (bytes, spec 2) | 31267 |

## Raw JSON (machine-readable)

```json
{
  "static": {
    "nuXmv_exit_code": 0,
    "show_vars_summary": {
      "Number of Input Variables": "11",
      "Number of State Variables": "197",
      "Number of Frozen Variables": "0",
      "Number of bits (summary)": "417 (0 frozen, 15 input, 402 state)"
    },
    "cudd": {
      "Memory in use": "115345816",
      "Peak number of nodes": "2782906",
      "Number of BDD variables": "820",
      "Number of LIVE BDD and ADD nodes": "2735350",
      "Total number of nodes allocated": "2942491"
    },
    "fsm": {
      "BDD nodes representing init set of states": "391",
      "BDD nodes representing state constraints": "380700",
      "BDD nodes representing input constraints": "1",
      "BDD cluster sizes (forward schedule)": "cluster 1 : size 1124; cluster 2 : size 15568; cluster 3 : size 1086; cluster 4 : size 4877; cluster 5 : size 1148; cluster 6 : size 1478; cluster 7 : size 1123; cluster 8 : size 1307; cluster 9 : size 12596; cluster 10 : size 1087; cluster 11 : size 4877; cluster 12 : size 1149; cluster 13 : size 1478; cluster 14 : size 1123; cluster 15 : size 1307; cluster 16 : size 23856; cluster 17 : size 1037; cluster 18 : size 626; cluster 19 : size 1599; cluster 20 : size 1175; cluster 21 : size 4797; cluster 22 : size 2140; cluster 23 : size 1102; cluster 24 : size 135; cluster 25 : size 3725; cluster 26 : size 8244; cluster 27 : size 23285; cluster 28 : size 4046; cluster 29 : size 2267; cluster 30 : size 761"
    },
    "usage": {
      "BDD nodes allocated (usage)": "2782077"
    }
  },
  "dynamic": {
    "log_dir": "/home/ahm/Desktop/project/artifacts-eval/acm-ccs-ach-payments/eval_review/source-ach-model-checking/output/local-run-20261029-201918",
    "timing": {
      "specs": [
        {
          "kind": "Invar",
          "spec_index": 0,
          "invar_index": 37,
          "wall_seconds": 13.0
        },
        {
          "kind": "Invar",
          "spec_index": 1,
          "invar_index": 38,
          "wall_seconds": 33.0
        },
        {
          "kind": "Invar",
          "spec_index": 2,
          "invar_index": 39,
          "wall_seconds": 9.0
        },
        {
          "kind": "CTL",
          "spec_index": 0,
          "invar_index": 0,
          "wall_seconds": 3.0
        },
        {
          "kind": "CTL",
          "spec_index": 1,
          "invar_index": 1,
          "wall_seconds": 122.0
        },
        {
          "kind": "CTL",
          "spec_index": 2,
          "invar_index": 2,
          "wall_seconds": 80.0
        },
        {
          "kind": "CTL",
          "spec_index": 3,
          "invar_index": 3,
          "wall_seconds": 6.0
        },
        {
          "kind": "CTL",
          "spec_index": 4,
          "invar_index": 4,
          "wall_seconds": 15.0
        },
        {
          "kind": "CTL",
          "spec_index": 5,
          "invar_index": 5,
          "wall_seconds": 44.0
        },
        {
          "kind": "CTL",
          "spec_index": 6,
          "invar_index": 6,
          "wall_seconds": 1.0
        },
        {
          "kind": "CTL",
          "spec_index": 7,
          "invar_index": 7,
          "wall_seconds": 324.0
        },
        {
          "kind": "CTL",
          "spec_index": 8,
          "invar_index": 8,
          "wall_seconds": 1.0
        },
        {
          "kind": "CTL",
          "spec_index": 9,
          "invar_index": 9,
          "wall_seconds": 1.0
        },
        {
          "kind": "CTL",
          "spec_index": 10,
          "invar_index": 10,
          "wall_seconds": 1349.0
        },
        {
          "kind": "CTL",
          "spec_index": 11,
          "invar_index": 11,
          "wall_seconds": 1310.0
        },
        {
          "kind": "CTL",
          "spec_index": 12,
          "invar_index": 12,
          "wall_seconds": 1.0
        },
        {
          "kind": "CTL",
          "spec_index": 13,
          "invar_index": 13,
          "wall_seconds": 1.0
        },
        {
          "kind": "CTL",
          "spec_index": 14,
          "invar_index": 14,
          "wall_seconds": 1.0
        },
        {
          "kind": "CTL",
          "spec_index": 15,
          "invar_index": 15,
          "wall_seconds": 2678.0
        },
        {
          "kind": "CTL",
          "spec_index": 16,
          "invar_index": 16,
          "wall_seconds": 5.0
        },
        {
          "kind": "CTL",
          "spec_index": 17,
          "invar_index": 17,
          "wall_seconds": 16.0
        },
        {
          "kind": "CTL",
          "spec_index": 18,
          "invar_index": 18,
          "wall_seconds": 1.0
        },
        {
          "kind": "CTL",
          "spec_index": 19,
          "invar_index": 19,
          "wall_seconds": 6.0
        },
        {
          "kind": "CTL",
          "spec_index": 20,
          "invar_index": 20,
          "wall_seconds": 6.0
        },
        {
          "kind": "CTL",
          "spec_index": 21,
          "invar_index": 21,
          "wall_seconds": 19.0
        },
        {
          "kind": "CTL",
          "spec_index": 22,
          "invar_index": 22,
          "wall_seconds": 20.0
        },
        {
          "kind": "CTL",
          "spec_index": 23,
          "invar_index": 23,
          "wall_seconds": 8.0
        },
        {
          "kind": "CTL",
          "spec_index": 24,
          "invar_index": 24,
          "wall_seconds": 24.0
        },
        {
          "kind": "CTL",
          "spec_index": 25,
          "invar_index": 25,
          "wall_seconds": 24.0
        },
        {
          "kind": "CTL",
          "spec_index": 26,
          "invar_index": 26,
          "wall_seconds": 1.0
        },
        {
          "kind": "CTL",
          "spec_index": 27,
          "invar_index": 27,
          "wall_seconds": 52.0
        },
        {
          "kind": "CTL",
          "spec_index": 28,
          "invar_index": 28,
          "wall_seconds": 559.0
        },
        {
          "kind": "CTL",
          "spec_index": 29,
          "invar_index": 29,
          "wall_seconds": 39.0
        },
        {
          "kind": "CTL",
          "spec_index": 30,
          "invar_index": 30,
          "wall_seconds": 4.0
        },
        {
          "kind": "CTL",
          "spec_index": 31,
          "invar_index": 31,
          "wall_seconds": 58.0
        },
        {
          "kind": "CTL",
          "spec_index": 32,
          "invar_index": 32,
          "wall_seconds": 71.0
        },
        {
          "kind": "CTL",
          "spec_index": 33,
          "invar_index": 33,
          "wall_seconds": 72.0
        },
        {
          "kind": "CTL",
          "spec_index": 34,
          "invar_index": 34,
          "wall_seconds": 70.0
        },
        {
          "kind": "CTL",
          "spec_index": 35,
          "invar_index": 35,
          "wall_seconds": 72.0
        },
        {
          "kind": "CTL",
          "spec_index": 36,
          "invar_index": 36,
          "wall_seconds": 39.0
        }
      ],
      "total_wall_seconds": 7158.0
    },
    "spec_0": {
      "log_file": "spec-0-INV.log",
      "max_bound_explored": "7",
      "verdict_line": "invariant (((phi1_ok_tx0 & phi1_ok_tx1) & phi1_ok_tx2) & phi1_ok_tx3)  is false",
      "log_bytes": 31418
    },
    "spec_1": {
      "log_file": "spec-1-INV.log",
      "max_bound_explored": "28",
      "verdict_line": "invariant (((orig_0.verification_cycle_complete -> orig_0.verification_credits = orig_0.verification_debits) & (orig_1.verification_cycle_complete -> orig_1.verification_credits = orig_1.verification_...",
      "log_bytes": 70694
    },
    "spec_2": {
      "log_file": "spec-2-INV.log",
      "max_bound_explored": "6",
      "verdict_line": "invariant ((((resource_released_tx0 -> env_i.return_window_expired) & (resource_released_tx1 -> env_i.return_window_expired)) & (resource_released_tx2 -> env_i.return_window_expired)) & (resource_rele...",
      "log_bytes": 31267
    },
    "properties": [
      {
        "global_index": 0,
        "local_index": 0,
        "kind": "CTL",
        "formula": "EF orig_0.fsm_state = linked_ok",
        "name": "",
        "result": "true",
        "wall_seconds": 3.0,
        "log_file": "spec-0-CTL.log"
      },
      {
        "global_index": 1,
        "local_index": 1,
        "kind": "CTL",
        "formula": "EF orig_0.fsm_state = link_failed",
        "name": "",
        "result": "true",
        "wall_seconds": 122.0,
        "log_file": "spec-1-CTL.log"
      },
      {
        "global_index": 2,
        "local_index": 2,
        "kind": "CTL",
        "formula": "EF orig_0.md_state = md_confirmed",
        "name": "",
        "result": "true",
        "wall_seconds": 80.0,
        "log_file": "spec-2-CTL.log"
      },
      {
        "global_index": 3,
        "local_index": 3,
        "kind": "CTL",
        "formula": "EF orig_0.md_state = md_failed",
        "name": "",
        "result": "true",
        "wall_seconds": 6.0,
        "log_file": "spec-3-CTL.log"
      },
      {
        "global_index": 4,
        "local_index": 4,
        "kind": "CTL",
        "formula": "EF orig_0.tx_0.payment_state = rejected",
        "name": "",
        "result": "true",
        "wall_seconds": 15.0,
        "log_file": "spec-4-CTL.log"
      },
      {
        "global_index": 5,
        "local_index": 5,
        "kind": "CTL",
        "formula": "EF orig_0.tx_0.payment_state = returned",
        "name": "",
        "result": "true",
        "wall_seconds": 44.0,
        "log_file": "spec-5-CTL.log"
      },
      {
        "global_index": 6,
        "local_index": 6,
        "kind": "CTL",
        "formula": "EF orig_0.tx_0.payment_state = reversed",
        "name": "",
        "result": "false",
        "wall_seconds": 1.0,
        "log_file": "spec-6-CTL.log"
      },
      {
        "global_index": 7,
        "local_index": 7,
        "kind": "CTL",
        "formula": "EF orig_0.fsm_state = reversing",
        "name": "",
        "result": "true",
        "wall_seconds": 324.0,
        "log_file": "spec-7-CTL.log"
      },
      {
        "global_index": 8,
        "local_index": 8,
        "kind": "CTL",
        "formula": "EF recv_0.fsm_state = auth_granted",
        "name": "",
        "result": "true",
        "wall_seconds": 1.0,
        "log_file": "spec-8-CTL.log"
      },
      {
        "global_index": 9,
        "local_index": 9,
        "kind": "CTL",
        "formula": "EF recv_0.fsm_state = auth_revoked_state",
        "name": "",
        "result": "true",
        "wall_seconds": 1.0,
        "log_file": "spec-9-CTL.log"
      },
      {
        "global_index": 10,
        "local_index": 10,
        "kind": "CTL",
        "formula": "EF recv_0.fsm_state = confirmed_md",
        "name": "",
        "result": "inconclusive",
        "wall_seconds": 1349.0,
        "log_file": "spec-10-CTL.log"
      },
      {
        "global_index": 11,
        "local_index": 11,
        "kind": "CTL",
        "formula": "EF recv_0.fsm_state = rejected_md",
        "name": "",
        "result": "inconclusive",
        "wall_seconds": 1310.0,
        "log_file": "spec-11-CTL.log"
      },
      {
        "global_index": 12,
        "local_index": 12,
        "kind": "CTL",
        "formula": "EF recv_0.fsm_state = notified_return",
        "name": "",
        "result": "false",
        "wall_seconds": 1.0,
        "log_file": "spec-12-CTL.log"
      },
      {
        "global_index": 13,
        "local_index": 13,
        "kind": "CTL",
        "formula": "EF recv_0.fsm_state = account_state_changed",
        "name": "",
        "result": "true",
        "wall_seconds": 1.0,
        "log_file": "spec-13-CTL.log"
      },
      {
        "global_index": 14,
        "local_index": 14,
        "kind": "CTL",
        "formula": "EF odfi_i.fsm_state = tps_verified",
        "name": "",
        "result": "false",
        "wall_seconds": 1.0,
        "log_file": "spec-14-CTL.log"
      },
      {
        "global_index": 15,
        "local_index": 15,
        "kind": "CTL",
        "formula": "EF odfi_i.fsm_state = tps_rejected",
        "name": "",
        "result": "inconclusive",
        "wall_seconds": 2678.0,
        "log_file": "spec-15-CTL.log"
      },
      {
        "global_index": 16,
        "local_index": 16,
        "kind": "CTL",
        "formula": "EF odfi_i.fsm_state = validation_rejected",
        "name": "",
        "result": "true",
        "wall_seconds": 5.0,
        "log_file": "spec-16-CTL.log"
      },
      {
        "global_index": 17,
        "local_index": 17,
        "kind": "CTL",
        "formula": "EF odfi_i.fsm_state = operator_acked",
        "name": "",
        "result": "true",
        "wall_seconds": 16.0,
        "log_file": "spec-17-CTL.log"
      },
      {
        "global_index": 18,
        "local_index": 18,
        "kind": "CTL",
        "formula": "EF odfi_i.fsm_state = link_acked",
        "name": "",
        "result": "true",
        "wall_seconds": 1.0,
        "log_file": "spec-18-CTL.log"
      },
      {
        "global_index": 19,
        "local_index": 19,
        "kind": "CTL",
        "formula": "EF odfi_i.u3_batch_reject",
        "name": "",
        "result": "true",
        "wall_seconds": 6.0,
        "log_file": "spec-19-CTL.log"
      },
      {
        "global_index": 20,
        "local_index": 20,
        "kind": "CTL",
        "formula": "EF odfi_i.u3_flag_entries",
        "name": "",
        "result": "true",
        "wall_seconds": 6.0,
        "log_file": "spec-20-CTL.log"
      },
      {
        "global_index": 21,
        "local_index": 21,
        "kind": "CTL",
        "formula": "EF ach_i.fsm_state = data_rejected_batch",
        "name": "",
        "result": "true",
        "wall_seconds": 19.0,
        "log_file": "spec-21-CTL.log"
      },
      {
        "global_index": 22,
        "local_index": 22,
        "kind": "CTL",
        "formula": "EF ach_i.fsm_state = data_rejected_entry",
        "name": "",
        "result": "true",
        "wall_seconds": 20.0,
        "log_file": "spec-22-CTL.log"
      },
      {
        "global_index": 23,
        "local_index": 23,
        "kind": "CTL",
        "formula": "EF ach_i.fsm_state = forwarded_ack",
        "name": "",
        "result": "true",
        "wall_seconds": 8.0,
        "log_file": "spec-23-CTL.log"
      },
      {
        "global_index": 24,
        "local_index": 24,
        "kind": "CTL",
        "formula": "EF rdfi_i.fsm_state = settled_state",
        "name": "",
        "result": "true",
        "wall_seconds": 24.0,
        "log_file": "spec-24-CTL.log"
      },
      {
        "global_index": 25,
        "local_index": 25,
        "kind": "CTL",
        "formula": "EF rdfi_i.fsm_state = returning",
        "name": "",
        "result": "true",
        "wall_seconds": 24.0,
        "log_file": "spec-25-CTL.log"
      },
      {
        "global_index": 26,
        "local_index": 26,
        "kind": "CTL",
        "formula": "EF rdfi_i.fsm_state = reversed_state",
        "name": "",
        "result": "false",
        "wall_seconds": 1.0,
        "log_file": "spec-26-CTL.log"
      },
      {
        "global_index": 27,
        "local_index": 27,
        "kind": "CTL",
        "formula": "EF rdfi_i.selected_return_code = R16",
        "name": "",
        "result": "true",
        "wall_seconds": 52.0,
        "log_file": "spec-27-CTL.log"
      },
      {
        "global_index": 28,
        "local_index": 28,
        "kind": "CTL",
        "formula": "EF rdfi_i.selected_return_code = R29",
        "name": "",
        "result": "inconclusive",
        "wall_seconds": 559.0,
        "log_file": "spec-28-CTL.log"
      },
      {
        "global_index": 29,
        "local_index": 29,
        "kind": "CTL",
        "formula": "EF env_i.window_count = 3",
        "name": "",
        "result": "true",
        "wall_seconds": 39.0,
        "log_file": "spec-29-CTL.log"
      },
      {
        "global_index": 30,
        "local_index": 30,
        "kind": "CTL",
        "formula": "EF env_i.phase = ph_return_closed",
        "name": "",
        "result": "true",
        "wall_seconds": 4.0,
        "log_file": "spec-30-CTL.log"
      },
      {
        "global_index": 31,
        "local_index": 31,
        "kind": "CTL",
        "formula": "EF g.n_credits_micro > 0",
        "name": "",
        "result": "true",
        "wall_seconds": 58.0,
        "log_file": "spec-31-CTL.log"
      },
      {
        "global_index": 32,
        "local_index": 32,
        "kind": "CTL",
        "formula": "EF g.n_credits_small > 0",
        "name": "",
        "result": "true",
        "wall_seconds": 71.0,
        "log_file": "spec-32-CTL.log"
      },
      {
        "global_index": 33,
        "local_index": 33,
        "kind": "CTL",
        "formula": "EF g.n_credits_large > 0",
        "name": "",
        "result": "true",
        "wall_seconds": 72.0,
        "log_file": "spec-33-CTL.log"
      },
      {
        "global_index": 34,
        "local_index": 34,
        "kind": "CTL",
        "formula": "EF g.n_debits_micro > 0",
        "name": "",
        "result": "true",
        "wall_seconds": 70.0,
        "log_file": "spec-34-CTL.log"
      },
      {
        "global_index": 35,
        "local_index": 35,
        "kind": "CTL",
        "formula": "EF g.n_debits_small > 0",
        "name": "",
        "result": "true",
        "wall_seconds": 72.0,
        "log_file": "spec-35-CTL.log"
      },
      {
        "global_index": 36,
        "local_index": 36,
        "kind": "CTL",
        "formula": "EF g.n_debits_large > 0",
        "name": "",
        "result": "true",
        "wall_seconds": 39.0,
        "log_file": "spec-36-CTL.log"
      },
      {
        "global_index": 37,
        "local_index": 0,
        "kind": "Invar",
        "formula": "(((phi1_ok_tx0 & phi1_ok_tx1) & phi1_ok_tx2) & phi1_ok_tx3)",
        "name": "\u03a61 Continuous Authorization (A1: creditBLEED Attack)",
        "result": "false",
        "wall_seconds": 13.0,
        "log_file": "spec-0-INV.log"
      },
      {
        "global_index": 38,
        "local_index": 1,
        "kind": "Invar",
        "formula": "(((orig_0.verification_cycle_complete -> orig_0.verification_credits = orig_0.verification_debits) & (orig_1.verification_cycle_complete -> orig_1.verification_credits = orig_1.verification_debits)) & (g.cycle_complete -> g.n_credits_regular = g.n_debits_regular))",
        "name": "\u03a62 Zero-Sum Invariant (A2: creditMINT Attack)",
        "result": "false",
        "wall_seconds": 33.0,
        "log_file": "spec-1-INV.log"
      },
      {
        "global_index": 39,
        "local_index": 2,
        "kind": "Invar",
        "formula": "((((resource_released_tx0 -> env_i.return_window_expired) & (resource_released_tx1 -> env_i.return_window_expired)) & (resource_released_tx2 -> env_i.return_window_expired)) & (resource_released_tx3 -> env_i.return_window_expired))",
        "name": "\u03a63 Settlement Finality (A3: creditRESET Attack)",
        "result": "false",
        "wall_seconds": 9.0,
        "log_file": "spec-2-INV.log"
      }
    ]
  }
}
```
