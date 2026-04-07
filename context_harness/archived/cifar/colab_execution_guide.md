# Colab Execution Guide

Date: 2026-04-03

This guide covers the Colab-native execution path for the CIFAR-10 smoke benchmark.

## What Runs Where

- Local machine
  - runs the MCP client
  - hosts your agent (`Claude Code`, `Codex`, or `Gemini CLI`)
  - stores the source repository

- Browser Colab session
  - provides the notebook UI
  - owns the A100 runtime
  - executes training and evaluation code

## Important Constraint

`colab-mcp` does not make the local repository appear automatically inside the Colab runtime.

That means you need one of these two patterns:

1. Git-backed pattern
   - push the repo to a remote Git host
   - clone it in Colab
   - run the scripts from the cloned repo

2. Inline payload pattern
   - send a standalone script into a Colab cell
   - execute it entirely inside the Colab runtime

For now, this repository supports the inline payload pattern directly through:

- `context_harness/colab_payloads/cifar10_smoke_001_job.py`

## Recommended CIFAR-10 Smoke Flow

1. Open a Colab notebook in the browser.
2. Switch runtime to A100 GPU.
3. Ensure `colab-mcp` is enabled in `.mcp.json`.
4. Use MCP to create a new Python cell.
5. Paste the contents of `context_harness/colab_payloads/cifar10_smoke_001_job.py` into that cell, or write it to `/content/cifar10_smoke_001_job.py`.
6. Execute the cell.
7. Inspect outputs under `/content/factory_outputs/experiment_log` and `/content/factory_outputs/checkpoints`.

## If You Want File-Based Execution

Use two Colab cells:

Cell 1:

```python
from pathlib import Path

payload = Path("/content/cifar10_smoke_001_job.py")
payload.write_text(open("/content/cell_payload.txt").read(), encoding="utf-8")
print(payload)
```

Cell 2:

```python
!python /content/cifar10_smoke_001_job.py
```

In practice, MCP usually makes it simpler to create one large code cell and execute it directly.

## Artifacts Produced In Colab

- `/content/factory_outputs/experiment_log/training_run_cifar10-smoke-001.json`
- `/content/factory_outputs/experiment_log/eval_report_cifar10-smoke-001.json`
- `/content/factory_outputs/checkpoints/cifar10-smoke-001/best.pt`

## After Execution

Copy the JSON logs back into the repo-local `experiment_log/` directory or have the agent transcribe the contents into the local files. The Colab runtime filesystem is ephemeral unless you persist to Drive or another remote store.
