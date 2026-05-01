#!/usr/bin/env python3
"""
Emit a Markdown report of nuXmv static (BDD/FSM/vars) and dynamic (verification) stats.

Static: batch nuXmv with `go`, print_bdd_stats, print_fsm_stats, show_vars, print_usage.
Dynamic: parse IC3 log(s) and optional timing.tsv produced by run_all_artifact.sh.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path
from typing import Any


def _run_nuxmv(nuxmv: Path, model: Path, commands: str) -> tuple[int, str]:
    cmdfile = Path(os.environ.get("TMPDIR", "/tmp")) / f"nuxmv-stats-{os.getpid()}.cmd"
    try:
        cmdfile.write_text(commands, encoding="utf-8")
        p = subprocess.run(
            [str(nuxmv), "-source", str(cmdfile), str(model)],
            capture_output=True,
            text=True,
            timeout=None,
        )
        out = (p.stdout or "") + (p.stderr or "")
        return p.returncode, out
    finally:
        try:
            cmdfile.unlink(missing_ok=True)
        except OSError:
            pass


def _static_commands() -> str:
    return "\n".join(
        [
            "set on_failure_script_quits",
            "read_model -i {model}",
            "flatten_hierarchy",
            "encode_variables",
            "build_boolean_model",
            "go",
            "print_bdd_stats",
            "print_fsm_stats",
            "show_vars",
            "print_usage",
            "quit",
            "",
        ]
    )


def _parse_show_vars_summary(text: str) -> dict[str, str]:
    out: dict[str, str] = {}
    for line in text.splitlines():
        s = line.strip()
        if re.match(r"^Number of (Input|State|Frozen) Variables:", s):
            k, _, rest = s.partition(":")
            out[k.strip()] = rest.strip()
        elif s.startswith("Number of bits:"):
            out["Number of bits (summary)"] = s.replace("Number of bits:", "").strip()
    return out


def _parse_cudd_block(text: str) -> dict[str, str]:
    """Extract a few headline CUDD lines from print_bdd_stats output."""
    keys = (
        "Memory in use",
        "Peak number of nodes",
        "Number of BDD variables",
        "Total number of nodes allocated",
        "Number of LIVE BDD and ADD nodes",
    )
    found: dict[str, str] = {}
    for line in text.splitlines():
        line = line.strip()
        for k in keys:
            if line.startswith(k + ":"):
                found[k] = line.split(":", 1)[1].strip()
    return found


def _parse_fsm_headlines(text: str) -> dict[str, str]:
    """Take FSM summary lines; cluster sizes only from the forward schedule (nuXmv repeats backward)."""
    found: dict[str, str] = {}
    clusters: list[str] = []
    forward = False
    for line in text.splitlines():
        s = line.strip()
        if "Forward Partitioning Schedule" in line:
            forward = True
            continue
        if "Backward Partitioning Schedule" in line:
            break
        if forward and s.startswith("cluster ") and ":	size" in s:
            clusters.append(s.replace("\t", " "))
    for line in text.splitlines():
        s = line.strip()
        if s.startswith("BDD nodes representing"):
            key = s.split(":")[0].strip()
            found[key] = s.split(":", 1)[1].strip()
    if clusters:
        found["BDD cluster sizes (forward schedule)"] = "; ".join(clusters)
    return found


def _parse_print_usage(text: str) -> dict[str, str]:
    """Lines between 'BDD statistics' / usage blocks."""
    out: dict[str, str] = {}
    for line in text.splitlines():
        s = line.strip()
        if re.match(r"^BDD nodes allocated:", s):
            out["BDD nodes allocated (usage)"] = s.split(":", 1)[1].strip()
    return out


def _collect_static(nuxmv: Path, model: Path) -> tuple[dict[str, Any], str]:
    cmds = _static_commands().format(model=str(model.resolve()))
    code, raw = _run_nuxmv(nuxmv, model, cmds)
    block: dict[str, Any] = {
        "nuXmv_exit_code": code,
        "show_vars_summary": _parse_show_vars_summary(raw),
        "cudd": _parse_cudd_block(raw),
        "fsm": _parse_fsm_headlines(raw),
        "usage": _parse_print_usage(raw),
    }
    return block, raw


def _ic3_max_bound(log_text: str) -> str | None:
    """Largest integer k in 'no proof or counterexample found with bound k'."""
    bounds = [int(m.group(1)) for m in re.finditer(r"no proof or counterexample found with bound (\d+)", log_text)]
    if not bounds:
        return None
    return str(max(bounds))


def _ic3_verdict(log_text: str) -> str | None:
    for pat in (
        r"invariant .* is true",
        r"invariant .* is false",
        r"-- specification .* is true",
        r"-- specification .* is false",
        r"is true\s*$",
        r"is false\s*$",
    ):
        m = re.search(pat, log_text, re.MULTILINE | re.IGNORECASE)
        if m:
            line = m.group(0).strip()
            if len(line) > 200:
                return line[:200] + "…"
            return line
    return None


def _load_timing(log_dir: Path) -> dict[str, Any]:
    tsv = log_dir / "timing.tsv"
    if not tsv.is_file():
        return {}
    rows = []
    for line in tsv.read_text(encoding="utf-8", errors="replace").splitlines():
        parts = line.strip().split("\t")
        if len(parts) >= 3:
            rows.append(
                {"spec_index": int(parts[0]), "invar_index": int(parts[1]), "wall_seconds": float(parts[2])}
            )
    total = sum(r["wall_seconds"] for r in rows) if rows else None
    return {"specs": rows, "total_wall_seconds": total}


def _dynamic_from_logs(log_dir: Path) -> dict[str, Any]:
    out: dict[str, Any] = {"log_dir": str(log_dir)}
    timing = _load_timing(log_dir)
    if timing:
        out["timing"] = timing
    spec0 = log_dir / "spec-0-INV.log"
    if spec0.is_file():
        text = spec0.read_text(encoding="utf-8", errors="replace")
        out["spec_0"] = {
            "log_file": spec0.name,
            "ic3_max_bound_explored": _ic3_max_bound(text),
            "verdict_line": _ic3_verdict(text),
            "log_bytes": spec0.stat().st_size,
        }
    return out


def _md_table(rows: list[tuple[str, str]]) -> str:
    lines = ["| Metric | Value |", "| --- | --- |"]
    for k, v in rows:
        vv = v.replace("|", "\\|") if v else ""
        lines.append(f"| {k} | {vv} |")
    return "\n".join(lines)


def _flatten(prefix: str, d: dict[str, Any]) -> list[tuple[str, str]]:
    rows: list[tuple[str, str]] = []
    for k in sorted(d.keys()):
        v = d[k]
        if isinstance(v, dict):
            for sk, sv in sorted(v.items()):
                rows.append((f"{prefix}{k} / {sk}", str(sv)))
        else:
            rows.append((f"{prefix}{k}", str(v)))
    return rows


def build_markdown(
    static: dict[str, Any],
    dynamic: dict[str, Any],
    nuxmv: Path,
    model: Path,
) -> str:
    parts: list[str] = []
    parts.append("# nuXmv model statistics\n")
    parts.append(f"- **nuXmv:** `{nuxmv}`")
    parts.append(f"- **Model:** `{model}`")
    parts.append("")

    parts.append("## Static (after `go`)\n")
    st = dict(static)
    code = st.pop("nuXmv_exit_code", None)
    rows: list[tuple[str, str]] = []
    if code is not None:
        rows.append(("nuXmv exit code (static batch)", str(code)))
    for section in ("show_vars_summary", "cudd", "fsm", "usage"):
        sub = st.get(section)
        if isinstance(sub, dict) and sub:
            rows.extend(_flatten("", sub))
    parts.append(_md_table(rows))

    parts.append("\n## Dynamic (verification run)\n")
    if not dynamic or (len(dynamic) == 1 and "log_dir" in dynamic):
        parts.append("_No verification logs or timing in this run (e.g. merge-only)._")
    else:
        drows: list[tuple[str, str]] = []
        if "timing" in dynamic:
            t = dynamic["timing"]
            if t.get("total_wall_seconds") is not None:
                drows.append(("Total wall time (all parallel specs)", f"{t['total_wall_seconds']:.3f} s"))
            for spec in t.get("specs", []):
                drows.append(
                    (
                        f"Wall time spec {spec['spec_index']} (INVAR gidx {spec['invar_index']})",
                        f"{spec['wall_seconds']:.3f} s",
                    )
                )
        if "spec_0" in dynamic:
            s0 = dynamic["spec_0"]
            labels = {
                "ic3_max_bound_explored": "IC3 max bound explored (spec 0)",
                "verdict_line": "Verdict (first matching line, spec 0)",
                "log_bytes": "Verification log size (bytes, spec 0)",
            }
            for key, label in labels.items():
                if s0.get(key) is not None:
                    drows.append((label, str(s0[key])))
        parts.append(_md_table(drows))

    parts.append("\n## Raw JSON (machine-readable)\n")
    blob = {"static": static, "dynamic": dynamic}
    parts.append("```json")
    parts.append(json.dumps(blob, indent=2))
    parts.append("```\n")
    return "\n".join(parts)


def main() -> int:
    ap = argparse.ArgumentParser(description="Generate nuXmv static/dynamic Markdown stats.")
    ap.add_argument("model", type=Path, nargs="?", default=Path("_main_model.smv"))
    ap.add_argument("--nuxmv", type=Path, help="Path to nuXmv binary")
    ap.add_argument("--output", "-o", type=Path, default=Path("model_stats.md"))
    ap.add_argument("--log-dir", type=Path, help="Directory with spec-*-INV.log and timing.tsv")
    args = ap.parse_args()

    root = Path.cwd()
    model = args.model if args.model.is_absolute() else root / args.model
    if not model.is_file():
        print(f"model not found: {model}", file=sys.stderr)
        return 1

    nuxmv = args.nuxmv
    if nuxmv is None:
        env = os.environ.get("NUXMV")
        if env:
            nuxmv = Path(env)
        else:
            sysname = os.uname().sysname.lower()
            cand = Path(root / "tools" / ("nuxmv-linux" if sysname == "linux" else "nuxmv-mac"))
            nuxmv = cand
    assert nuxmv is not None
    if not os.access(nuxmv, os.X_OK):
        print(f"nuXmv not executable: {nuxmv}", file=sys.stderr)
        return 1

    static, raw = _collect_static(nuxmv, model)
    dynamic: dict[str, Any] = {}
    if args.log_dir:
        ld = args.log_dir if args.log_dir.is_absolute() else root / args.log_dir
        if ld.is_dir():
            dynamic = _dynamic_from_logs(ld)

    md = build_markdown(static, dynamic, nuxmv, model)
    out = args.output if args.output.is_absolute() else root / args.output
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(md, encoding="utf-8")
    print(f"Wrote {out}", file=sys.stderr)
    return 0 if static.get("nuXmv_exit_code") == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
