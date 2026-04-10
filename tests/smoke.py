#!/usr/bin/env python3
"""Dependency-free smoke tests for orchestrator's public surface.

Run before and after any structural refactor of ``orchestrator.py`` to
confirm that the import graph, argparse wiring, health-check contract,
contract loader, and ledger auto-injection all still work.

Usage:
    python3 tests/smoke.py
"""

from __future__ import annotations

import json
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))


def assert_eq(actual, expected, label: str) -> None:
    if actual != expected:
        raise AssertionError(f"{label}: expected {expected!r}, got {actual!r}")


def assert_true(cond: bool, label: str) -> None:
    if not cond:
        raise AssertionError(f"{label}: expected truthy")


def test_import() -> None:
    import orchestrator  # noqa: F401 — import side effect is the test

    import harness.ops.session  # noqa: F401
    import harness.ops.json_parse  # noqa: F401
    import harness.ops.artifacts  # noqa: F401
    print("  ok  import orchestrator + harness.ops.*")


def test_argparse_help() -> None:
    proc = subprocess.run(
        [sys.executable, str(ROOT / "orchestrator.py"), "--help"],
        capture_output=True,
        text=True,
        cwd=str(ROOT),
        timeout=30,
    )
    assert_eq(proc.returncode, 0, "argparse --help returncode")
    assert_true("autopilot" in proc.stdout, "argparse --help mentions autopilot")
    assert_true("doctor" in proc.stdout, "argparse --help mentions doctor")
    print("  ok  argparse --help")


def test_validate_role_output() -> None:
    import orchestrator
    from master_router import TaskType

    cases = [
        ("You're out of extra usage · resets 9pm (Asia/Seoul)", None, "out_of_usage"),
        ("Credit balance is too low", None, "credit"),
        ("", None, "empty"),
        ("x" * 50, None, "short_text"),
        ("Rate limit exceeded, try again later", None, "rate_limit"),
    ]
    for text, schema, tag in cases:
        try:
            orchestrator.validate_role_output(
                "ios_architect", TaskType.ARCHITECTURE, text, schema
            )
        except RuntimeError:
            continue
        raise AssertionError(f"validate_role_output should have raised for {tag}")

    # happy paths
    orchestrator.validate_role_output(
        "ios_architect", TaskType.ARCHITECTURE, "x" * 500, None
    )
    orchestrator.validate_role_output(
        "product_lead",
        TaskType.PRODUCT_RESEARCH,
        '{"summary":"real content here okay enough","pains":["a","b","c","d"]}',
        {"type": "object"},
    )
    print("  ok  validate_role_output (5 failure + 2 happy paths)")


def test_load_role_contract() -> None:
    import orchestrator

    orchestrator._ROLE_CONTRACT_CACHE.clear()  # ensure fresh read
    contract = orchestrator.load_role_contract("product_lead")
    assert_eq(contract.get("role_id"), "product_lead", "product_lead role_id")
    assert_true(
        isinstance(contract.get("output", {}).get("json_schema"), dict),
        "product_lead has json_schema",
    )

    contract = orchestrator.load_role_contract("ios_architect")
    assert_eq(
        contract.get("output", {}).get("kind"), "markdown", "ios_architect kind"
    )

    assert_eq(
        orchestrator.load_role_contract("nonexistent_role"),
        {},
        "unknown role returns empty",
    )

    schema = orchestrator.product_schema()
    assert_true(
        "summary" in schema.get("required", []),
        "product_schema required includes summary",
    )
    schema = orchestrator.plan_schema()
    assert_true(
        "execution_summary" in schema.get("required", []),
        "plan_schema required includes execution_summary",
    )
    print("  ok  load_role_contract + product_schema/plan_schema")


def test_append_ledger_auto_injection() -> None:
    import orchestrator

    with tempfile.NamedTemporaryFile(
        "w", delete=False, suffix=".jsonl"
    ) as handle:
        tmp_path = Path(handle.name)

    original = orchestrator.HANDOFF_LEDGER_FILE
    orchestrator.HANDOFF_LEDGER_FILE = tmp_path
    try:
        orchestrator.append_ledger({"type": "smoke_default"})
        orchestrator.append_ledger(
            {
                "type": "smoke_override",
                "ts": "manual-ts",
                "schema_version": 99,
            }
        )
    finally:
        orchestrator.HANDOFF_LEDGER_FILE = original

    lines = [
        json.loads(line)
        for line in tmp_path.read_text(encoding="utf-8").strip().splitlines()
    ]
    tmp_path.unlink()

    assert_true("ts" in lines[0], "default entry has ts")
    assert_eq(
        lines[0]["schema_version"],
        orchestrator.LEDGER_SCHEMA_VERSION,
        "default entry schema_version",
    )
    assert_eq(lines[1]["ts"], "manual-ts", "override ts respected")
    assert_eq(lines[1]["schema_version"], 99, "override schema_version respected")
    print("  ok  append_ledger auto-injection and override")


def test_pure_helpers() -> None:
    from harness.ops.json_parse import parse_json_output
    from harness.ops.session import describe_session, parse_iso_timestamp
    from harness.ops.artifacts import read_artifact_excerpt

    assert_eq(parse_json_output('{"a": 1}'), {"a": 1}, "parse_json_output simple")
    assert_eq(
        parse_json_output('garbage {"k": 2} trailing')["k"],
        2,
        "parse_json_output embedded",
    )

    dt = parse_iso_timestamp("2026-04-10T12:00:00+00:00")
    assert_true(dt is not None, "parse_iso_timestamp valid")
    assert_eq(parse_iso_timestamp(None), None, "parse_iso_timestamp none")

    status, _ = describe_session(None)
    assert_eq(status, "blocked", "describe_session none")

    tmp = Path(tempfile.mkstemp(suffix=".md")[1])
    tmp.write_text("hello world", encoding="utf-8")
    assert_eq(
        read_artifact_excerpt(tmp), "hello world", "read_artifact_excerpt text"
    )
    tmp.unlink()
    print("  ok  pure helpers (json_parse, session, artifacts)")


def main() -> int:
    tests = [
        test_import,
        test_argparse_help,
        test_validate_role_output,
        test_load_role_contract,
        test_append_ledger_auto_injection,
        test_pure_helpers,
    ]
    print(f"running {len(tests)} smoke tests against {ROOT}")
    failed = 0
    for test in tests:
        try:
            test()
        except Exception as exc:
            failed += 1
            print(f"  FAIL {test.__name__}: {exc}")
    if failed:
        print(f"\n{failed}/{len(tests)} failed")
        return 1
    print(f"\n{len(tests)}/{len(tests)} passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
