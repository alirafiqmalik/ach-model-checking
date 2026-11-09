# Credit Without Debit

Formal verification models and reproducible checks for ACH payment flows.

<p align="center">
  <a href="https://zenodo.org/records/22701199"><img alt="Zenodo DOI 10.5281/zenodo.22701199" src="https://img.shields.io/badge/DOI-10.5281%2Fzenodo.22701199-1682D4?logo=zenodo&logoColor=white"></a>
  <img alt="ACM CCS 2026" src="https://img.shields.io/badge/ACM%20CCS-2026-0969da">
  <img alt="Model checker: nuXmv 2.1.0" src="https://img.shields.io/badge/model%20checker-nuXmv%202.1.0-8250df">
  <img alt="Docker: linux/amd64" src="https://img.shields.io/badge/docker-linux%2Famd64-2496ED?logo=docker&logoColor=white">
  <img alt="Properties: 40 checks" src="https://img.shields.io/badge/checks-3%20INVARSPEC%20%2B%2037%20EF-57606a">
  <a href="LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-1a7f37"></a>
</p>

The artifact connects the paper’s payment-system obligations to executable formal models.

<p align="center">
  <img src="docs/assets/hero.svg" alt="Credit Without Debit: ACH participants, message buses, and the three violated properties" width="100%">
</p>

## What is this?

Artifact for the ACM CCS 2026 paper **Credit Without Debit: Formal Verification of Banking Payment Systems**, by Ali Hamza Malik and Muhammad Taqi Raza, University of Massachusetts Amherst. NuSMV/nuXmv models describe Automated Clearing House (ACH) payment flow; scripts merge, verify and summarize results in Markdown. Credit Without Debit (CWD) encompasses A1 creditBLEED (Φ1), A2 creditMINT (Φ2) and A3 creditRESET (Φ3).

- **Maintained version:** this repository, <https://github.com/alirafiqmalik/ach-model-checking>
- **Archived version:** Zenodo record [22701199](https://zenodo.org/records/22701199) (DOI [10.5281/zenodo.22701199](https://doi.org/10.5281/zenodo.22701199))

## At a glance

| Item | Value |
| --- | --- |
| Model fragments | 8 |
| Participants | 2 Originators, 2 Receivers, ODFI, ACH Operator, RDFI |
| Checks | 40: 3 INVARSPEC + 37 EF |
| Reference safety results | Φ1–Φ3 all violated |
| Reference EF results | 29 true, 4 false, 4 bounded-inconclusive |

The composition joins participant state machines through control and monetary channels.

```mermaid
flowchart TB
    subgraph ADV_O["Adversarial Originators"]
        direction LR
        O0["orig_0<br/><i>originator(0, …)</i>"]
        O1["orig_1<br/><i>originator(1, …)</i>"]
    end
    subgraph BANKS["Trusted, Nacha-compliant banks"]
        direction LR
        ODFI["odfi_i<br/><b>ODFI</b>"]
        ACH["ach_i<br/><b>ACH Operator</b>"]
        RDFI["rdfi_i<br/><b>RDFI</b>"]
    end
    subgraph ADV_R["Adversarial Receivers"]
        direction LR
        R0["recv_0<br/><i>receiver(0, …)</i>"]
        R1["recv_1<br/><i>receiver(1, …)</i>"]
    end

    ADV_O -- "LINK_REQ · VERIFY_REQ<br/>PAYMENT_INIT · REVERSAL_NOTICE" --> ODFI
    ODFI -- "LINK_ACK · VERIFY_ACK<br/>BATCH_ACK · RETURN_NOTICE" --> ADV_O
    ODFI -- "BATCH_FORWARD" --> ACH
    ACH -- "BATCH_ACK · RETURN_NOTICE" --> ODFI
    ACH -- "SETTLEMENT_REQ" --> RDFI
    RDFI -- "SETTLEMENT_ACK · RETURN_NOTICE<br/>REVERSAL_NOTICE" --> ACH
    RDFI == "c_dollar: FUND_CREDIT · FUND_DEBIT · FUND_REVERSE" ==> ADV_R
    ADV_O == "c_dollar: FUND_CREDIT (MICRO deposit)" ==> ADV_R
    ADV_R -. "GRANT_AUTH · REVOKE_AUTH · VERIFY_ACK" .-> ADV_O

    ENV(["env_i · Nacha phase clock<br/>window_count ≤ 3"])
    G(["g · global_invariants<br/>Φ2 settlement counters"])
    ENV -.-> BANKS
    BANKS -.-> G

    classDef adv fill:#ddf4ff,stroke:#0969da,color:#0a3069
    classDef bank fill:#eaeef2,stroke:#57606a,color:#1f2328
    classDef aux fill:#fbefff,stroke:#8250df,color:#3e1f79
    class O0,O1,R0,R1 adv
    class ODFI,ACH,RDFI bank
    class ENV,G aux
```
<sub>Instances and parameters from <code>MODULE main</code> in <code>models/99_main.smv</code>; message routes from the <code>c_info_req_*</code> / <code>c_dollar_req_*</code> assignments in each participant module. All <code>c_info</code> traffic shares one single-slot bus; all money movement shares the <code>c_dollar</code> bus.</sub>

The runner merges fragments, checks properties and compiles results.

```mermaid
flowchart LR
    A["models/*.smv<br/>8 ordered fragments"] -- "tools/merge_smv.sh<br/>make merge check-merge" --> B["_main_model.smv"]
    B -- "show_property" --> C{"index<br/>discovery"}
    C -- "3 × INVARSPEC" --> D["Φ1, Φ3: IC3<br/>Φ2: incremental BMC, k = 60"]
    C -- "37 × SPEC EF p" --> E["BMC of !(p)<br/>een-sorensson, k = 50"]
    D --> F["spec-{0,1,2}-INV.log"]
    E --> G["spec-{0..36}-CTL.log"]
    F --> H["tools/nuxmv_model_stats.py"]
    G --> H
    H --> I[("model_stats.md")]
    classDef io fill:#ddf4ff,stroke:#0969da,color:#0a3069
    classDef run fill:#fbefff,stroke:#8250df,color:#3e1f79
    class A,B,F,G,I io
    class D,E,H run
```

## Quick start

Run from the repository root with Docker, or use the bundled binary on Linux/macOS with Bash, make, Python 3 and diff:

```bash
./run_all_artifact.sh
# Native alternative:
./run_all_artifact.sh --no-docker
# Compose alternative:
ARTIFACT_CPUS=4 ARTIFACT_MEMORY=8g JOBS=3 docker compose run --build --rm artifact
```

A complete run can take hours. See [pipeline setup, modes, resources and troubleshooting](docs/verification-pipeline.md).

## Results summary

The nuXmv 2.1.0 reference run contains all 40 results. Bounded-inconclusive EF results do not establish unreachability.

<p align="center">
  <img src="docs/assets/results-overview.svg" alt="Verdicts and wall times of all 40 property checks in the reference run" width="100%">
</p>

| Property | Attack | Unified index | Engine | Result | Counterexample | Log |
| --- | --- | --- | --- | --- | --- | --- |
| Φ1 Continuous Authorization | A1 creditBLEED | 37 | IC3 | false | 10 states | [`spec-0-INV.log`](saved-reference-results/local-run-20261029-artifact-reviews/spec-0-INV.log) |
| Φ2 Zero-Sum Invariant | A2 creditMINT | 38 | incremental BMC, k = 60 | false | 30 states | [`spec-1-INV.log`](saved-reference-results/local-run-20261029-artifact-reviews/spec-1-INV.log) |
| Φ3 Settlement Finality | A3 creditRESET | 39 | IC3 | false | 9 states | [`spec-2-INV.log`](saved-reference-results/local-run-20261029-artifact-reviews/spec-2-INV.log) |

The Φ2 counterexample replays the creditMINT sequence: the micro-deposit credit settles and the account is linked, then the recovery debit is returned `R16`, which leaves one settled credit and no settled debit in the verification cycle. See the [step-by-step walkthrough](saved-reference-results/README.md#creditmint-witness) and the [property semantics](docs/properties.md).

<p align="center">
  <img src="docs/assets/phi2-creditmint-trace.svg" alt="Swimlane timeline of the 30-state Phi2 creditMINT counterexample" width="100%">
</p>

## Documentation

| Document | Purpose |
| --- | --- |
| [Model architecture](models/README.md) | Participants, channels, assumptions and extensions |
| [Verification pipeline](docs/verification-pipeline.md) | Commands, environment, outputs and troubleshooting |
| [Properties](docs/properties.md) | Safety obligations, reachability and verdict semantics |
| [Reference results](saved-reference-results/README.md) | Provenance, all 40 results and integrity checks |
| [Tools](tools/README.md) | Utility interfaces and binary licensing |

## Repository layout

Source fragments, tools and retained results occupy separate repository directories.

```text
ach-model-checking/
├── README.md                     ← you are here
├── run_all_artifact.sh           # one-command pipeline: merge → nuXmv checks → stats
├── Makefile                      # merge · check-merge · verify · smoke · test · clean
├── Dockerfile                    # debian:bookworm-slim, linux/amd64, nuXmv + python3
├── compose.yaml                  # resource-limited Compose service "artifact"
├── docker/entrypoint.sh          # container entry → run_all_artifact.sh --inside-docker
├── models/                       # the formal model, merged in filename order  → models/README.md
│   ├── 00_types_channels.smv     #   c_info / c_dollar buses, env phase clock
│   ├── 10_originator.smv         #   Originator FSM + transaction_slot
│   ├── 20_odfi.smv               #   ODFI
│   ├── 30_ach_operator.smv       #   ACH Operator
│   ├── 40_rdfi.smv               #   RDFI
│   ├── 50_receiver.smv           #   Receiver
│   ├── 60_global_constraints.smv #   global observer for Φ2
│   └── 99_main.smv               #   composition, Φ1–Φ3, 37 EF witnesses, JUSTICE
├── tools/                        # merge, statistics, smoke test, nuXmv binaries  → tools/README.md
├── tests/fixtures/minimal/       # two-fragment model used by `make test`
├── docs/                         # layered documentation + figures (docs/assets/)
└── saved-reference-results/      # complete reference run with logs and provenance → saved-reference-results/README.md
```

## Data and privacy

Our empirical evaluation uses real consumer bank accounts owned by members of the research team. Raw account screenshots and transaction logs cannot be shared publicly because they contain personally identifiable financial information. The paper provides the redacted screenshots documenting the user-visible state changes for each CWD instance (A1: creditBLEED Attack, A2: creditMINT Attack, and A3: creditRESET Attack).

## Citation

```bibtex
@inproceedings{malik2026credit,
  title = {Credit Without Debit: Formal Verification of Banking Payment Systems},
  author = {Malik, Ali Hamza and Raza, Muhammad Taqi},
  booktitle = {Proceedings of the ACM Conference on Computer and Communications Security},
  year = {2026}
}
```

To cite the artifact itself, use the Zenodo record: <https://doi.org/10.5281/zenodo.22701199>.

## License

[MIT](LICENSE) covers model sources and scripts. Bundled nuXmv binaries are FBK’s and are shipped as provided under their own licensing terms.
