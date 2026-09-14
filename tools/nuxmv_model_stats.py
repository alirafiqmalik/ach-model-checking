#!/usr/bin/env python3
"""
Write model_stats.md: static BDD/FSM/var counts from nuXmv, plus a property sheet.

Static batch: go, print_bdd_stats, print_fsm_stats, show_vars, print_usage.
Dynamic: show_property.txt, spec-*-INV.log, spec-*-CTL.log, timing.tsv.
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
    """Selected CUDD fields from print_bdd_stats."""
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
    """FSM summary. Cluster sizes come from the forward schedule; nuXmv reprints them for backward."""
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
    """BDD node allocation line from print_usage."""
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
                return line[:200] + "..."
            return line
    return None


_INVAR_NAMES = {
    0: "Φ1 Continuous Authorization (A1: creditBLEED Attack)",
    1: "Φ2 Zero-Sum Invariant (A2: creditMINT Attack)",
    2: "Φ3 Settlement Finality (A3: creditRESET Attack)",
}
_TRUE_FALSE = re.compile(r"is (true|false)\s*$", re.I)
_EF_TRAILER = re.compile(r"EF_RESULT\s+(true|false|inconclusive)", re.I)


def parse_show_property(text: str) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    pending: tuple[int, str] | None = None
    local: dict[str, int] = {}
    for line in text.splitlines():
        s = line.strip()
        m = re.match(r"^(\d+)\s*:(.*)$", s)
        if m:
            pending = (int(m.group(1)), m.group(2).strip())
            continue
        mm = re.match(r"^\[(\S+)", s)
        if not mm or pending is None:
            continue
        kind = mm.group(1)
        loc = local.get(kind, 0)
        local[kind] = loc + 1
        rows.append({"global_index": pending[0], "local_index": loc, "kind": kind, "formula": pending[1]})
        pending = None
    return rows


def _last_tf(text: str) -> str | None:
    hits = [m.group(1).lower() for m in _TRUE_FALSE.finditer(text)]
    return hits[-1] if hits else None


def _result(kind: str, text: str) -> str:
    m = _EF_TRAILER.search(text)
    if m:
        return m.group(1).lower()
    tf = _last_tf(text)
    if not tf:
        return "inconclusive" if "no proof or counterexample" in text else "not run"
    # CTL jobs check !(p); a false invariant is a witness for EF p.
    if kind == "CTL":
        return "true" if tf == "false" else "false"
    return tf


def _load_timing(log_dir: Path) -> dict[str, Any]:
    rows: list[dict[str, Any]] = []
    for path in (log_dir / "timing.tsv", log_dir / "timing.ctl.tsv"):
        if not path.is_file():
            continue
        for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
            p = line.strip().split("\t")
            if len(p) >= 4 and p[0] in {"INV", "CTL", "Invar"}:
                kind = "CTL" if p[0] == "CTL" else "Invar"
                rows.append(
                    {"kind": kind, "spec_index": int(p[1]), "invar_index": int(p[2]), "wall_seconds": float(p[3])}
                )
            elif len(p) >= 3:
                kind = "CTL" if path.name.endswith("ctl.tsv") else "Invar"
                rows.append(
                    {"kind": kind, "spec_index": int(p[0]), "invar_index": int(p[1]), "wall_seconds": float(p[2])}
                )
    total = sum(r["wall_seconds"] for r in rows) if rows else None
    return {"specs": rows, "total_wall_seconds": total}


def _property_sheet(log_dir: Path) -> list[dict[str, Any]]:
    show = log_dir / "show_property.txt"
    if not show.is_file():
        return []
    timing = {(t["kind"], t["spec_index"]): t["wall_seconds"] for t in _load_timing(log_dir).get("specs", [])}
    sheet = []
    for row in parse_show_property(show.read_text(encoding="utf-8", errors="replace")):
        kind, loc = row["kind"], int(row["local_index"])
        suffix = "CTL" if kind == "CTL" else "INV"
        log = log_dir / f"spec-{loc}-{suffix}.log"
        text = log.read_text(encoding="utf-8", errors="replace") if log.is_file() else ""
        sheet.append(
            {
                **row,
                "name": _INVAR_NAMES.get(loc, "") if kind == "Invar" else "",
                "result": _result(kind, text) if text else "not run",
                "wall_seconds": timing.get((kind if kind == "CTL" else "Invar", loc)),
                "log_file": log.name if log.is_file() else "",
            }
        )
    return sheet


def _dynamic_from_logs(log_dir: Path) -> dict[str, Any]:
    out: dict[str, Any] = {"log_dir": str(log_dir)}
    timing = _load_timing(log_dir)
    if timing:
        out["timing"] = timing
    for spec_log in sorted(log_dir.glob("spec-*-INV.log")):
        m = re.match(r"spec-(\d+)-INV\.log$", spec_log.name)
        if not m:
            continue
        text = spec_log.read_text(encoding="utf-8", errors="replace")
        out[f"spec_{m.group(1)}"] = {
            "log_file": spec_log.name,
            "ic3_max_bound_explored": _ic3_max_bound(text),
            "verdict_line": _ic3_verdict(text),
            "log_bytes": spec_log.stat().st_size,
        }
    sheet = _property_sheet(log_dir)
    if sheet:
        out["properties"] = sheet
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


def _properties_md(sheet: list[dict[str, Any]]) -> str:
    lines = [
        "| # | Kind | Name | Formula | Result | Time (s) | Log |",
        "| --- | --- | --- | --- | --- | --- | --- |",
    ]
    for r in sheet:
        wall = "" if r["wall_seconds"] is None else f"{r['wall_seconds']:.3f}"
        formula = r["formula"].replace("|", "\\|")
        lines.append(
            f"| {r['global_index']} | {r['kind']} | {r['name']} | {formula} | {r['result']} | {wall} | {r['log_file']} |"
        )
    return "\n".join(lines)


def build_markdown(
    static: dict[str, Any],
    dynamic: dict[str, Any],
    nuxmv: Path,
    model: Path,
) -> str:
    parts: list[str] = []
    parts.append("# nuXmv model statistics\n")
    parts.append(f"- nuXmv: `{nuxmv}`")
    parts.append(f"- Model: `{model}`")
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

    sheet = dynamic.get("properties") if dynamic else None
    if sheet:
        parts.append("\n## Properties\n")
        parts.append(
            "CTL `EF p` is BMC of `!(p)`: a counterexample means the executability property is true.\n"
        )
        parts.append(_properties_md(sheet))

    parts.append("\n## Dynamic (verification run)\n")
    if not dynamic or (len(dynamic) == 1 and "log_dir" in dynamic):
        parts.append("No verification logs or timing in this run (merge-only, or no log dir).")
    else:
        drows: list[tuple[str, str]] = []
        if "timing" in dynamic:
            t = dynamic["timing"]
            if t.get("total_wall_seconds") is not None:
                drows.append(("Total wall time (all parallel specs)", f"{t['total_wall_seconds']:.3f} s"))
            for spec in t.get("specs", []):
                kind = spec.get("kind", "Invar")
                drows.append(
                    (
                        f"Wall time {kind} {spec['spec_index']} (gidx {spec['invar_index']})",
                        f"{spec['wall_seconds']:.3f} s",
                    )
                )
        spec_keys = sorted(
            (k for k in dynamic if re.fullmatch(r"spec_\d+", k)),
            key=lambda k: int(k.split("_", 1)[1]),
        )
        for skey in spec_keys:
            spec = dynamic[skey]
            idx = skey.split("_", 1)[1]
            labels = {
                "ic3_max_bound_explored": f"IC3 max bound explored (spec {idx})",
                "verdict_line": f"Verdict (spec {idx})",
                "log_bytes": f"Verification log size (bytes, spec {idx})",
            }
            for key, label in labels.items():
                if spec.get(key) is not None:
                    drows.append((label, str(spec[key])))
        parts.append(_md_table(drows) if drows else "No verification logs or timing in this run (merge-only, or no log dir).")

    parts.append("\n## Raw JSON (machine-readable)\n")
    blob = {"static": static, "dynamic": dynamic}
    parts.append("```json")
    parts.append(json.dumps(blob, indent=2))
    parts.append("```\n")
    return "\n".join(parts)


def main() -> int:
    ap = argparse.ArgumentParser(description="Generate nuXmv static/dynamic Markdown stats.")
    ap.add_argument("model", type=Path, nargs="?", default=Path("output/_main_model.smv"))
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
