"""Xcode runtime and test probes.

Extracted from orchestrator.py. Both probes run against a repo with a
``workspace/ios`` directory and emit a JSON report plus (for the runtime
probe) a markdown summary and captured screenshot. Dependencies on
orchestrator-level state are bundled in ``ProbeDeps`` and injected at
call time.
"""

from __future__ import annotations

import os
import plistlib
import re
import subprocess
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable


@dataclass
class ProbeDeps:
    reports_dir: Path
    host_runtime_baseline_file: Path
    run_shell: Callable
    load_json: Callable
    save_json: Callable
    save_text: Callable
    append_ledger: Callable
    append_operator_journal: Callable


def run_xcode_runtime_probe(deps: ProbeDeps, repo: Path) -> Path:
    report_path = deps.reports_dir / "xcode_runtime_probe.json"
    summary_path = deps.reports_dir / "xcode_runtime_probe.md"
    host_baseline = deps.load_json(deps.host_runtime_baseline_file, {})
    workspace = repo / "workspace"
    ios_dir = workspace / "ios"
    xcworkspace = next(iter(sorted(ios_dir.glob("*.xcworkspace"))), None) if ios_dir.exists() else None
    xcodeproj = next(iter(sorted(ios_dir.glob("*.xcodeproj"))), None) if ios_dir.exists() else None

    payload: dict[str, Any] = {
        "workspace_root": str(workspace),
        "ios_dir_exists": ios_dir.exists(),
        "xcworkspace": str(xcworkspace) if xcworkspace else None,
        "xcodeproj": str(xcodeproj) if xcodeproj else None,
    }

    xcode_version = deps.run_shell(["xcodebuild", "-version"], timeout=20)
    simctl = deps.run_shell(["xcrun", "simctl", "list", "devices"], timeout=20)
    simctl_host_ok = bool(host_baseline.get("simctl", {}).get("ok"))
    payload["xcodebuild_version"] = (xcode_version.stdout or xcode_version.stderr).strip()[:300]
    payload["simctl"] = {
        "ok": simctl.returncode == 0 or simctl_host_ok,
        "detail": (
            (simctl.stdout or simctl.stderr).strip()[:500]
            if simctl.returncode == 0 or not simctl_host_ok
            else f"sandbox false negative; host ok: {host_baseline['simctl'].get('detail', '')[:420]}"
        ),
    }

    scheme = None
    if xcworkspace:
        build_list = deps.run_shell(["xcodebuild", "-list", "-workspace", str(xcworkspace)], cwd=ios_dir, timeout=30)
        payload["project_discovery"] = {"ok": build_list.returncode == 0, "detail": (build_list.stdout or build_list.stderr).strip()[:1000]}
        if build_list.returncode == 0:
            for line in build_list.stdout.splitlines():
                candidate = line.strip()
                if candidate and candidate not in {"Information about workspace", "Schemes:"} and not candidate.endswith(":"):
                    scheme = candidate
                    break
    elif xcodeproj:
        build_list = deps.run_shell(["xcodebuild", "-list", "-project", str(xcodeproj)], cwd=ios_dir, timeout=30)
        payload["project_discovery"] = {"ok": build_list.returncode == 0, "detail": (build_list.stdout or build_list.stderr).strip()[:1000]}
        if build_list.returncode == 0:
            in_schemes = False
            for line in build_list.stdout.splitlines():
                stripped = line.strip()
                if stripped == "Schemes:":
                    in_schemes = True
                    continue
                if in_schemes and stripped:
                    scheme = stripped
                    break
    else:
        payload["project_discovery"] = {
            "ok": False,
            "detail": "No native iOS project detected under workspace/ios. Current evaluation remains Expo web plus visual QA.",
        }

    if not scheme:
        scheme = "MemoryMap" if xcodeproj and xcodeproj.stem == "MemoryMap" else (xcodeproj.stem if xcodeproj else None)
    payload["scheme"] = scheme

    build_log = deps.reports_dir / "xcode_build.log"
    screenshot_path = deps.reports_dir / "xcode_runtime_screenshot.png"
    derived_data = repo / ".deriveddata" / "evaluation"
    destination_name = None
    device_id = None
    simulator_status = "unavailable"

    if simctl.returncode == 0:
        for line in simctl.stdout.splitlines():
            if "(Booted)" in line and "iPhone" in line:
                match = re.search(r"^\s*(.+?) \(([0-9A-F-]+)\) \((Booted|Shutdown)\)\s*$", line)
                if match:
                    destination_name = match.group(1).strip()
                    device_id = match.group(2).strip()
                    simulator_status = "booted"
                    break
        if not device_id:
            for line in simctl.stdout.splitlines():
                if "iPhone" not in line:
                    continue
                match = re.search(r"^\s*(.+?) \(([0-9A-F-]+)\) \((Booted|Shutdown)\)\s*$", line)
                if match:
                    destination_name = match.group(1).strip()
                    device_id = match.group(2).strip()
                    simulator_status = match.group(3).lower()
                    break

    build_target: list[str] = []
    if xcworkspace:
        build_target = ["-workspace", str(xcworkspace)]
    elif xcodeproj:
        build_target = ["-project", str(xcodeproj)]

    build_command: list[str] = []
    if build_target and scheme:
        build_command = [
            "xcodebuild",
            *build_target,
            "-scheme",
            scheme,
            "-derivedDataPath",
            str(derived_data),
        ]
        if destination_name:
            build_command.extend(["-destination", f"platform=iOS Simulator,name={destination_name}"])
        else:
            build_command.extend(["-destination", "generic/platform=iOS Simulator"])
        build_command.append("build")

    if build_command:
        build_proc = subprocess.run(
            build_command,
            cwd=str(ios_dir),
            capture_output=True,
            text=True,
            env=os.environ.copy(),
        )
        build_text = "\n".join(part for part in [build_proc.stdout, build_proc.stderr] if part).strip()
        deps.save_text(build_log, build_text or "[no build output]")
        payload["build"] = {
            "ok": build_proc.returncode == 0,
            "returncode": build_proc.returncode,
            "command": " ".join(build_command),
            "log_path": str(build_log),
            "detail": build_text[-1500:] if build_text else "",
        }
        payload["build_output"] = "BUILD SUCCEEDED" if build_proc.returncode == 0 else "BUILD FAILED"
    else:
        payload["build"] = {
            "ok": False,
            "returncode": None,
            "command": "",
            "log_path": None,
            "detail": "No project/scheme available for native build.",
        }
        payload["build_output"] = "NONE"

    app_binary = None
    if derived_data.exists():
        candidates = sorted(derived_data.glob("Build/Products/Debug-iphonesimulator/*.app"))
        if candidates:
            app_binary = candidates[0]

    payload["app_binary"] = str(app_binary) if app_binary else None
    payload["simulator_status"] = simulator_status
    payload["runtime_verification"] = {
        "booted_device": destination_name,
        "device_id": device_id,
        "install_ok": False,
        "launch_ok": False,
        "screenshot": None,
        "bundle_id": None,
    }

    if app_binary and device_id:
        try:
            info = plistlib.loads((app_binary / "Info.plist").read_bytes())
            bundle_id = info.get("CFBundleIdentifier")
        except Exception:
            bundle_id = None
        payload["runtime_verification"]["bundle_id"] = bundle_id

        boot_proc = deps.run_shell(["xcrun", "simctl", "boot", device_id], timeout=30)
        bootstatus_proc = deps.run_shell(["xcrun", "simctl", "bootstatus", device_id, "-b"], timeout=60)
        if boot_proc.returncode == 0 or "Unable to boot device in current state: Booted" in (boot_proc.stderr or ""):
            install_proc = deps.run_shell(["xcrun", "simctl", "install", device_id, str(app_binary)], timeout=60)
            payload["runtime_verification"]["install_ok"] = install_proc.returncode == 0
            if bundle_id and install_proc.returncode == 0 and bootstatus_proc.returncode == 0:
                launch_proc = deps.run_shell(
                    ["xcrun", "simctl", "launch", "--terminate-running-process", device_id, bundle_id],
                    timeout=45,
                )
                payload["runtime_verification"]["launch_ok"] = launch_proc.returncode == 0
                if launch_proc.returncode == 0:
                    time.sleep(2)
                    screenshot_proc = deps.run_shell(["xcrun", "simctl", "io", device_id, "screenshot", str(screenshot_path)], timeout=30)
                    if screenshot_proc.returncode == 0 and screenshot_path.exists():
                        payload["runtime_verification"]["screenshot"] = str(screenshot_path)
        payload["runtime_verification"]["bootstatus_detail"] = (bootstatus_proc.stdout or bootstatus_proc.stderr).strip()[:500]

    payload["screenshot"] = payload["runtime_verification"]["screenshot"]

    summary_lines = [
        "# Xcode Runtime Probe",
        "",
        f"- xcodeproj: {payload.get('xcodeproj') or 'NONE'}",
        f"- scheme: {payload.get('scheme') or 'NONE'}",
        f"- build_output: {payload.get('build_output')}",
        f"- build_log: {payload.get('build', {}).get('log_path') or 'NONE'}",
        f"- simulator_status: {payload.get('simulator_status')}",
        f"- booted_device: {payload.get('runtime_verification', {}).get('booted_device') or 'NONE'}",
        f"- app_binary: {payload.get('app_binary') or 'NOT FOUND'}",
        f"- bundle_id: {payload.get('runtime_verification', {}).get('bundle_id') or 'NONE'}",
        f"- install_ok: {payload.get('runtime_verification', {}).get('install_ok')}",
        f"- launch_ok: {payload.get('runtime_verification', {}).get('launch_ok')}",
        f"- screenshot: {payload.get('screenshot') or 'NONE'}",
        "",
        "## Evidence",
        "",
        payload.get("build", {}).get("detail") or "No build detail captured.",
    ]
    deps.save_text(summary_path, "\n".join(summary_lines))

    deps.save_json(report_path, payload)
    deps.append_ledger({"type": "xcode_runtime_probe", "report": str(report_path)})
    deps.append_operator_journal(f"Xcode runtime probe wrote {report_path.name}")
    return report_path


def run_xcode_test_probe(deps: ProbeDeps, repo: Path) -> Path:
    report_path = deps.reports_dir / "xcode_test_probe.json"
    workspace = repo / "workspace"
    ios_dir = workspace / "ios"
    xcodeproj = next(iter(sorted(ios_dir.glob("*.xcodeproj"))), None) if ios_dir.exists() else None

    payload: dict[str, Any] = {
        "workspace_root": str(workspace),
        "xcodeproj": str(xcodeproj) if xcodeproj else None,
        "scheme": "MemoryMap" if xcodeproj else None,
        "ok": False,
        "returncode": None,
        "command": None,
        "log_path": None,
        "detail": "",
    }

    if not xcodeproj:
        payload["detail"] = "No xcodeproj available for test execution."
        deps.save_json(report_path, payload)
        return report_path

    log_path = deps.reports_dir / "xcode_test.log"
    command = [
        "xcodebuild",
        "-project",
        str(xcodeproj),
        "-scheme",
        "MemoryMap",
        "-destination",
        "platform=iOS Simulator,name=iPhone 17 Pro",
        "test",
    ]
    proc = subprocess.run(
        command,
        cwd=str(ios_dir),
        capture_output=True,
        text=True,
        env=os.environ.copy(),
    )
    output = "\n".join(part for part in [proc.stdout, proc.stderr] if part).strip()
    deps.save_text(log_path, output or "[no test output]")
    payload.update(
        {
            "ok": proc.returncode == 0,
            "returncode": proc.returncode,
            "command": " ".join(command),
            "log_path": str(log_path),
            "detail": output[-1500:] if output else "",
        }
    )
    deps.save_json(report_path, payload)
    deps.append_ledger({"type": "xcode_test_probe", "report": str(report_path), "ok": payload["ok"]})
    deps.append_operator_journal(f"Xcode test probe wrote {report_path.name} with ok={payload['ok']}")
    return report_path
