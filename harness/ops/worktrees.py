"""Git worktree + lane branch helpers for parallel role execution.

Extracted from orchestrator.py. Any harness that needs to run several
agents in parallel on isolated working copies can reuse this module: it
owns the integration worktree lifecycle, per-lane worktree creation,
workspace overlay copy, and branch merging with conflict rollback.
"""

from __future__ import annotations

import shutil
from dataclasses import dataclass
from pathlib import Path
from typing import Callable


@dataclass
class WorktreeDeps:
    factory_dir: Path
    integration_worktree: Path
    integration_branch: str
    worktrees_dir: Path
    reports_dir: Path
    git: Callable
    git_output: Callable
    save_json: Callable
    append_ledger: Callable
    append_operator_journal: Callable


def ensure_integration_worktree(deps: WorktreeDeps) -> Path:
    if deps.integration_worktree.exists():
        factory_head = deps.git_output("rev-parse", "HEAD", cwd=deps.factory_dir)
        integration_head = deps.git_output("rev-parse", "HEAD", cwd=deps.integration_worktree)
        integration_clean = not deps.git("status", "--short", cwd=deps.integration_worktree).stdout.strip()
        if integration_head != factory_head and integration_clean:
            deps.git("worktree", "remove", str(deps.integration_worktree), cwd=deps.factory_dir)
            deps.git("worktree", "add", "-B", deps.integration_branch, str(deps.integration_worktree), "HEAD", cwd=deps.factory_dir)
        return deps.integration_worktree
    deps.git("worktree", "add", "-B", deps.integration_branch, str(deps.integration_worktree), "HEAD")
    return deps.integration_worktree


def sync_workspace_overlay(source_repo: Path, target_repo: Path) -> None:
    source_workspace = source_repo / "workspace"
    target_workspace = target_repo / "workspace"
    if not source_workspace.exists():
        return

    target_workspace.mkdir(parents=True, exist_ok=True)
    for item in source_workspace.iterdir():
        if item.name == "node_modules":
            continue
        destination = target_workspace / item.name
        if item.is_dir():
            shutil.copytree(item, destination, dirs_exist_ok=True)
        else:
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(item, destination)


def ensure_lane_worktree(
    deps: WorktreeDeps,
    role_name: str,
    lane_tag: str,
    start_point: str,
) -> tuple[Path, str]:
    worktree_dir = deps.worktrees_dir / f"{role_name}-{lane_tag}"
    branch_name = f"harness/{role_name}-{lane_tag}"
    if worktree_dir.exists():
        # Remove stale worktree so it re-branches from latest start_point.
        # Any prior uncommitted work is already auto-committed before merge.
        deps.git("worktree", "remove", "--force", str(worktree_dir), cwd=deps.factory_dir, check=False)
    deps.git("worktree", "add", "-B", branch_name, str(worktree_dir), start_point)
    sync_workspace_overlay(deps.factory_dir, worktree_dir)
    return worktree_dir, branch_name


def find_worktree_for_branch(deps: WorktreeDeps, branch_name: str) -> Path | None:
    listing = deps.git("worktree", "list", "--porcelain", cwd=deps.factory_dir).stdout.splitlines()
    current_worktree: Path | None = None
    for line in listing:
        if line.startswith("worktree "):
            current_worktree = Path(line.split(" ", 1)[1])
            continue
        if line.startswith("branch "):
            current_branch = line.split(" ", 1)[1].removeprefix("refs/heads/")
            if current_worktree and current_branch == branch_name:
                return current_worktree
    return None


def current_target_repo(deps: WorktreeDeps) -> Path:
    return deps.integration_worktree if deps.integration_worktree.exists() else deps.factory_dir


def current_target_workspace(deps: WorktreeDeps) -> Path:
    return current_target_repo(deps) / "workspace"


def branch_ahead_count(deps: WorktreeDeps, base_ref: str, branch_ref: str, cwd: Path) -> int:
    proc = deps.git("rev-list", "--count", f"{base_ref}..{branch_ref}", cwd=cwd)
    return int(proc.stdout.strip() or "0")


def auto_commit_worktree(deps: WorktreeDeps, branch_name: str) -> bool:
    """Auto-commit any uncommitted changes in the worktree for the given branch.

    Returns True if a commit was created, False if there was nothing to commit.
    """
    worktree = find_worktree_for_branch(deps, branch_name)
    if not worktree:
        return False
    status = deps.git("status", "--short", cwd=worktree).stdout.strip()
    if not status:
        return False
    deps.git("add", "-A", cwd=worktree)
    deps.git(
        "commit", "-m", f"fix: auto-commit {branch_name} changes from harness agent",
        cwd=worktree, check=False,
    )
    deps.append_operator_journal(f"Auto-committed worktree changes for {branch_name}")
    return True


def merge_branch_into_integration(deps: WorktreeDeps, branch_name: str) -> tuple[bool, str]:
    auto_commit_worktree(deps, branch_name)
    integration = ensure_integration_worktree(deps)
    if branch_ahead_count(deps, deps.integration_branch, branch_name, integration) == 0:
        return True, f"{branch_name} already merged or has no unique commits"

    proc = deps.git("merge", "--no-ff", "--no-edit", branch_name, cwd=integration, check=False)
    if proc.returncode == 0:
        return True, proc.stdout.strip() or f"merged {branch_name}"

    deps.git("merge", "--abort", cwd=integration, check=False)
    return False, proc.stderr.strip() or proc.stdout.strip() or f"merge failed for {branch_name}"


def merge_delivery_branches(deps: WorktreeDeps, branches: list[str], phase_label: str) -> Path:
    results = []
    integration = ensure_integration_worktree(deps)
    for branch_name in branches:
        success, detail = merge_branch_into_integration(deps, branch_name)
        results.append({"branch": branch_name, "success": success, "detail": detail})
        if success:
            source_worktree = find_worktree_for_branch(deps, branch_name)
            if source_worktree:
                sync_workspace_overlay(source_worktree, integration)
        if not success:
            break

    merge_report = deps.reports_dir / f"platform_operator_merge_{phase_label}.json"
    deps.save_json(merge_report, {"integration_branch": deps.integration_branch, "results": results})
    deps.append_ledger({"type": "merge", "phase": phase_label, "report": str(merge_report), "branches": branches})
    deps.append_operator_journal(f"Merged delivery branches for {phase_label} -> {merge_report.name}")
    return merge_report
