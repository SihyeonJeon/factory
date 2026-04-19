"""Runtime QA pipeline — build, install, run XCUITest, capture screenshots, visual analysis.

Usage:
    from harness.runtime_qa import RuntimeQAPipeline
    pipeline = RuntimeQAPipeline(workspace=Path("..."), simulator="iPhone 17 Pro")
    result = pipeline.run()
"""

from __future__ import annotations

import json
import subprocess
import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional


SCREENSHOT_DIR_NAME = "qa_screenshots"


@dataclass
class QAResult:
    """Result of a runtime QA pipeline execution."""
    success: bool
    unit_tests_passed: int = 0
    unit_tests_failed: int = 0
    ui_tests_passed: int = 0
    ui_tests_failed: int = 0
    screenshots: list[Path] = field(default_factory=list)
    ui_test_output: str = ""
    errors: list[str] = field(default_factory=list)
    blocker_findings: list[str] = field(default_factory=list)
    advisory_findings: list[str] = field(default_factory=list)

    @property
    def total_tests(self) -> int:
        return self.unit_tests_passed + self.unit_tests_failed + self.ui_tests_passed + self.ui_tests_failed

    @property
    def all_passed(self) -> bool:
        return self.unit_tests_failed == 0 and self.ui_tests_failed == 0

    def summary(self) -> str:
        status = "PASS" if self.all_passed else "FAIL"
        lines = [
            f"## Runtime QA: {status}",
            f"- Unit tests: {self.unit_tests_passed}/{self.unit_tests_passed + self.unit_tests_failed}",
            f"- UI tests: {self.ui_tests_passed}/{self.ui_tests_passed + self.ui_tests_failed}",
            f"- Screenshots captured: {len(self.screenshots)}",
        ]
        if self.blocker_findings:
            lines.append(f"- BLOCKERS: {len(self.blocker_findings)}")
            for b in self.blocker_findings:
                lines.append(f"  - {b}")
        if self.advisory_findings:
            lines.append(f"- ADVISORY: {len(self.advisory_findings)}")
            for a in self.advisory_findings:
                lines.append(f"  - {a}")
        if self.errors:
            lines.append(f"- Errors: {len(self.errors)}")
            for e in self.errors:
                lines.append(f"  - {e}")
        return "\n".join(lines)


class RuntimeQAPipeline:
    """Orchestrates the full build → test → screenshot → analysis pipeline."""

    def __init__(
        self,
        workspace: Path,
        simulator: str = "iPhone 17 Pro",
        os_version: str = "26.4",
        derived_data: Optional[Path] = None,
    ):
        self.workspace = workspace.resolve()
        self.simulator = simulator
        self.os_version = os_version
        self.derived_data = derived_data or (self.workspace / ".deriveddata" / "qa")
        self.screenshot_dir = self.workspace / SCREENSHOT_DIR_NAME
        self.project_path = self.workspace / "Unfading.xcodeproj"

    def run(self, skip_unit_tests: bool = False) -> QAResult:
        """Execute full pipeline."""
        result = QAResult(success=False)

        # Step 1: xcodegen
        if not self._xcodegen(result):
            return result

        # Step 2: Unit tests (gate 1)
        if not skip_unit_tests:
            self._run_unit_tests(result)
            if result.unit_tests_failed > 0:
                result.errors.append("Unit tests failed — aborting UI tests")
                return result

        # Step 3: UI tests with screenshots
        self._run_ui_tests(result)

        # Step 4: Collect screenshots
        self._collect_screenshots(result)

        # Step 5: Basic launch screenshot via simctl
        self._capture_simctl_screenshot(result)

        result.success = result.all_passed
        return result

    def _xcodegen(self, result: QAResult) -> bool:
        try:
            proc = subprocess.run(
                ["xcodegen", "generate"],
                cwd=self.workspace,
                capture_output=True,
                text=True,
                timeout=60,
            )
            if proc.returncode != 0:
                result.errors.append(f"xcodegen failed: {proc.stderr[:500]}")
                return False
            return True
        except Exception as e:
            result.errors.append(f"xcodegen exception: {e}")
            return False

    def _run_unit_tests(self, result: QAResult):
        destination = f"platform=iOS Simulator,name={self.simulator},OS={self.os_version}"
        cmd = [
            "xcodebuild", "test",
            "-project", str(self.project_path),
            "-scheme", "Unfading",
            "-destination", destination,
            "-derivedDataPath", str(self.derived_data),
            "-only-testing:UnfadingTests",
            "-quiet",
        ]
        try:
            proc = subprocess.run(
                cmd,
                cwd=self.workspace,
                capture_output=True,
                text=True,
                timeout=300,
            )
            output = proc.stdout + proc.stderr
            passed, failed = self._parse_test_counts(output)
            result.unit_tests_passed = passed
            result.unit_tests_failed = failed
        except subprocess.TimeoutExpired:
            result.errors.append("Unit test timeout (300s)")
        except Exception as e:
            result.errors.append(f"Unit test exception: {e}")

    def _run_ui_tests(self, result: QAResult):
        destination = f"platform=iOS Simulator,name={self.simulator},OS={self.os_version}"
        # Create result bundle path for screenshot extraction
        result_bundle = self.derived_data / "ui_test_results.xcresult"
        if result_bundle.exists():
            subprocess.run(["rm", "-rf", str(result_bundle)], check=False)

        cmd = [
            "xcodebuild", "test",
            "-project", str(self.project_path),
            "-scheme", "Unfading",
            "-destination", destination,
            "-derivedDataPath", str(self.derived_data),
            "-only-testing:UnfadingUITests",
            "-resultBundlePath", str(result_bundle),
        ]
        try:
            proc = subprocess.run(
                cmd,
                cwd=self.workspace,
                capture_output=True,
                text=True,
                timeout=600,
            )
            output = proc.stdout + proc.stderr
            result.ui_test_output = output[-3000:]  # keep last 3k chars
            passed, failed = self._parse_test_counts(output)
            result.ui_tests_passed = passed
            result.ui_tests_failed = failed
        except subprocess.TimeoutExpired:
            result.errors.append("UI test timeout (600s)")
        except Exception as e:
            result.errors.append(f"UI test exception: {e}")

    def _collect_screenshots(self, result: QAResult):
        """Extract screenshots from xcresult bundle via xcresulttool activities API."""
        result_bundle = self.derived_data / "ui_test_results.xcresult"
        if not result_bundle.exists():
            return

        self.screenshot_dir.mkdir(parents=True, exist_ok=True)

        # Get test list
        try:
            proc = subprocess.run(
                ["xcrun", "xcresulttool", "get", "test-results", "tests",
                 "--path", str(result_bundle)],
                capture_output=True, text=True, timeout=60,
            )
            if proc.returncode != 0:
                return
            tests_data = json.loads(proc.stdout)
        except Exception:
            return

        test_ids = self._find_test_ids(tests_data)
        exported_payloads: set[str] = set()

        for test_id in test_ids:
            try:
                proc = subprocess.run(
                    ["xcrun", "xcresulttool", "get", "test-results", "activities",
                     "--test-id", test_id, "--path", str(result_bundle)],
                    capture_output=True, text=True, timeout=60,
                )
                if proc.returncode != 0:
                    continue
                activities = json.loads(proc.stdout)
                attachments = self._find_attachments(activities)
                for att in attachments:
                    payload_id = att.get("payloadId", "")
                    if not payload_id or payload_id in exported_payloads:
                        continue
                    exported_payloads.add(payload_id)
                    raw_name = att.get("name", "unknown")
                    # Strip UUID suffix from attachment name
                    name = raw_name.rsplit("_0_", 1)[0] if "_0_" in raw_name else raw_name.rsplit(".", 1)[0]
                    filename = f"{name.replace(' ', '_')}.png"
                    dest = self.screenshot_dir / filename
                    export_proc = subprocess.run(
                        ["xcrun", "xcresulttool", "export", "object", "--legacy",
                         "--path", str(result_bundle), "--output-path", str(dest),
                         "--id", payload_id, "--type", "file"],
                        capture_output=True, text=True, timeout=30,
                    )
                    if export_proc.returncode == 0 and dest.exists():
                        result.screenshots.append(dest)
            except Exception:
                continue

    @staticmethod
    def _find_test_ids(node) -> list[str]:
        """Recursively find Test Case nodeIdentifiers."""
        results = []
        if isinstance(node, dict):
            if node.get("nodeType") == "Test Case":
                results.append(node["nodeIdentifier"])
            for v in node.values():
                results.extend(RuntimeQAPipeline._find_test_ids(v))
        elif isinstance(node, list):
            for item in node:
                results.extend(RuntimeQAPipeline._find_test_ids(item))
        return results

    @staticmethod
    def _find_attachments(node) -> list[dict]:
        """Recursively find attachment dicts."""
        results = []
        if isinstance(node, dict):
            if "attachments" in node:
                results.extend(node["attachments"])
            for v in node.values():
                results.extend(RuntimeQAPipeline._find_attachments(v))
        elif isinstance(node, list):
            for item in node:
                results.extend(RuntimeQAPipeline._find_attachments(item))
        return results

    def _capture_simctl_screenshot(self, result: QAResult):
        """Capture a screenshot of the currently running simulator."""
        self.screenshot_dir.mkdir(parents=True, exist_ok=True)
        screenshot_path = self.screenshot_dir / "simctl_current_state.png"
        try:
            proc = subprocess.run(
                ["xcrun", "simctl", "io", "booted", "screenshot", str(screenshot_path)],
                capture_output=True, text=True, timeout=30,
            )
            if proc.returncode == 0 and screenshot_path.exists():
                result.screenshots.append(screenshot_path)
        except Exception:
            pass

    @staticmethod
    def _parse_test_counts(output: str) -> tuple[int, int]:
        """Parse 'Executed N tests, with M failures' from xcodebuild output."""
        import re
        # Match the last occurrence (summary line)
        matches = re.findall(r"Executed (\d+) tests?, with (\d+) failures?", output)
        if matches:
            last = matches[-1]
            total = int(last[0])
            failed = int(last[1])
            return total - failed, failed
        return 0, 0
