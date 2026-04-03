#!/usr/bin/env python3
"""
run_factory.py - Thin wrapper around the company harness orchestrator.
"""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

FACTORY_DIR = Path(__file__).parent.resolve()
ORCHESTRATOR = FACTORY_DIR / "orchestrator.py"
VENV_PYTHON = FACTORY_DIR / "venv" / "bin" / "python"


def run_command(args: list[str]) -> int:
    python_bin = str(VENV_PYTHON) if VENV_PYTHON.exists() else sys.executable
    proc = subprocess.run([python_bin, str(ORCHESTRATOR), *args], cwd=str(FACTORY_DIR))
    return proc.returncode


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Run the company harness pipeline")
    parser.add_argument("brief", nargs="?", help="High-level app brief")
    parser.add_argument("--image-path", help="Screenshot path for evaluation")
    parser.add_argument("--quick", action="store_true", help="Use quick diagnostics when supported")
    parser.add_argument(
        "--phase",
        choices=["doctor", "intake", "delivery", "evaluation", "autopilot", "all", "record-changes", "evaluator-mode"],
        default="autopilot",
    )
    parser.add_argument("--max-rounds", type=int, default=2)
    return parser


def main() -> int:
    args = build_parser().parse_args()

    if args.phase == "record-changes":
        return run_command(["record-changes"])
    if args.phase == "doctor":
        cmd = ["doctor"]
        if args.quick:
            cmd.append("--quick")
        return run_command(cmd)
    if args.phase == "evaluator-mode":
        return run_command(["evaluator-mode"])

    if not args.brief:
        print("brief is required unless --phase record-changes")
        return 2

    phases = ["intake", "delivery", "evaluation"] if args.phase == "all" else [args.phase]
    for phase in phases:
        cmd = [phase, args.brief]
        if phase == "autopilot":
            cmd += ["--max-rounds", str(args.max_rounds)]
        if phase == "evaluation" and args.image_path:
            cmd += ["--image-path", args.image_path]
        if phase == "autopilot" and args.image_path:
            cmd += ["--image-path", args.image_path]
        code = run_command(cmd)
        if code != 0:
            return code
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
