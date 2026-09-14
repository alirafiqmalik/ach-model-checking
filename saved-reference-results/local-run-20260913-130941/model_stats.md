# nuXmv model statistics

- nuXmv: `/home/ahm/Desktop/project/artifacts-eval/ach-model-checking/tools/nuxmv-linux`
- Model: `/home/ahm/Desktop/project/artifacts-eval/ach-model-checking/output/_main_model.smv`

## Static (after `go`)

| Metric | Value |
| --- | --- |
| nuXmv exit code (static batch) | 0 |
| Number of Frozen Variables | 0 |
| Number of Input Variables | 11 |
| Number of State Variables | 191 |
| Number of bits (summary) | 411 (0 frozen, 15 input, 396 state) |
| Memory in use | 87764792 |
| Number of BDD variables | 808 |
| Number of LIVE BDD and ADD nodes | 1937209 |
| Peak number of nodes | 1991878 |
| Total number of nodes allocated | 2146598 |
| BDD cluster sizes (forward schedule) | cluster 1 : size 1124; cluster 2 : size 15383; cluster 3 : size 1410; cluster 4 : size 1035; cluster 5 : size 1099; cluster 6 : size 2631; cluster 7 : size 2319; cluster 8 : size 6382; cluster 9 : size 1411; cluster 10 : size 1035; cluster 11 : size 1100; cluster 12 : size 2631; cluster 13 : size 2319; cluster 14 : size 11394; cluster 15 : size 1037; cluster 16 : size 626; cluster 17 : size 1599; cluster 18 : size 1175; cluster 19 : size 4482; cluster 20 : size 3505; cluster 21 : size 3660; cluster 22 : size 127; cluster 23 : size 3725; cluster 24 : size 8244; cluster 25 : size 23285; cluster 26 : size 4046; cluster 27 : size 2267; cluster 28 : size 619 |
| BDD nodes representing init set of states | 385 |
| BDD nodes representing input constraints | 1 |
| BDD nodes representing state constraints | 193180 |
| BDD nodes allocated (usage) | 1990954 |

## Dynamic (verification run)

| Metric | Value |
| --- | --- |
| Total wall time (all parallel specs) | 3116.000 s |
| Wall time spec 0 (INVAR gidx 35) | 222.000 s |
| Wall time spec 1 (INVAR gidx 36) | 2888.000 s |
| Wall time spec 2 (INVAR gidx 37) | 6.000 s |
| IC3 max bound explored (spec 0) | 19 |
| Verdict (spec 0) | invariant (((phi1_ok_tx0 & phi1_ok_tx1) & phi1_ok_tx2) & phi1_ok_tx3)  is false |
| Verification log size (bytes, spec 0) | 44452 |
| IC3 max bound explored (spec 1) | 26 |
| Verdict (spec 1) | invariant (g.cycle_complete -> (g.n_credits_micro = g.n_debits_micro & g.n_credits_regular = g.n_debits_regular))  is false |
| Verification log size (bytes, spec 1) | 64439 |
| IC3 max bound explored (spec 2) | 7 |
| Verdict (spec 2) | invariant ((((resource_released_tx0 -> env_i.return_window_expired) & (resource_released_tx1 -> env_i.return_window_expired)) & (resource_released_tx2 -> env_i.return_window_expired)) & (resource_rele... |
| Verification log size (bytes, spec 2) | 29233 |

## Raw JSON (machine-readable)

```json
{
  "static": {
    "nuXmv_exit_code": 0,
    "show_vars_summary": {
      "Number of Input Variables": "11",
      "Number of State Variables": "191",
      "Number of Frozen Variables": "0",
      "Number of bits (summary)": "411 (0 frozen, 15 input, 396 state)"
    },
    "cudd": {
      "Memory in use": "87764792",
      "Peak number of nodes": "1991878",
      "Number of BDD variables": "808",
      "Number of LIVE BDD and ADD nodes": "1937209",
      "Total number of nodes allocated": "2146598"
    },
    "fsm": {
      "BDD nodes representing init set of states": "385",
      "BDD nodes representing state constraints": "193180",
      "BDD nodes representing input constraints": "1",
      "BDD cluster sizes (forward schedule)": "cluster 1 : size 1124; cluster 2 : size 15383; cluster 3 : size 1410; cluster 4 : size 1035; cluster 5 : size 1099; cluster 6 : size 2631; cluster 7 : size 2319; cluster 8 : size 6382; cluster 9 : size 1411; cluster 10 : size 1035; cluster 11 : size 1100; cluster 12 : size 2631; cluster 13 : size 2319; cluster 14 : size 11394; cluster 15 : size 1037; cluster 16 : size 626; cluster 17 : size 1599; cluster 18 : size 1175; cluster 19 : size 4482; cluster 20 : size 3505; cluster 21 : size 3660; cluster 22 : size 127; cluster 23 : size 3725; cluster 24 : size 8244; cluster 25 : size 23285; cluster 26 : size 4046; cluster 27 : size 2267; cluster 28 : size 619"
    },
    "usage": {
      "BDD nodes allocated (usage)": "1990954"
    }
  },
  "dynamic": {
    "log_dir": "/home/ahm/Desktop/project/artifacts-eval/ach-model-checking/output/local-run-20260913-130941",
    "timing": {
      "specs": [
        {
          "spec_index": 0,
          "invar_index": 35,
          "wall_seconds": 222.0
        },
        {
          "spec_index": 1,
          "invar_index": 36,
          "wall_seconds": 2888.0
        },
        {
          "spec_index": 2,
          "invar_index": 37,
          "wall_seconds": 6.0
        }
      ],
      "total_wall_seconds": 3116.0
    },
    "spec_0": {
      "log_file": "spec-0-INV.log",
      "ic3_max_bound_explored": "19",
      "verdict_line": "invariant (((phi1_ok_tx0 & phi1_ok_tx1) & phi1_ok_tx2) & phi1_ok_tx3)  is false",
      "log_bytes": 44452
    },
    "spec_1": {
      "log_file": "spec-1-INV.log",
      "ic3_max_bound_explored": "26",
      "verdict_line": "invariant (g.cycle_complete -> (g.n_credits_micro = g.n_debits_micro & g.n_credits_regular = g.n_debits_regular))  is false",
      "log_bytes": 64439
    },
    "spec_2": {
      "log_file": "spec-2-INV.log",
      "ic3_max_bound_explored": "7",
      "verdict_line": "invariant ((((resource_released_tx0 -> env_i.return_window_expired) & (resource_released_tx1 -> env_i.return_window_expired)) & (resource_released_tx2 -> env_i.return_window_expired)) & (resource_rele...",
      "log_bytes": 29233
    }
  }
}
```
