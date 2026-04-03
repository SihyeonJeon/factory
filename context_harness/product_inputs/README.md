# Product Inputs

This directory is the preferred source of truth for user intent.

## Recommended files

- `idea.md`
- `constraints.md`
- `design.md`
- `acceptance.md`

## Intake behavior

- The orchestrator loads these files automatically during intake when they exist.
- Existing top-level context such as `sprint_contract.json`, `00_system_rules.md`, and HIG policies are also attached.
- Keep these files concise but detailed enough that the planner can act without guessing.

## Execution

After editing these files, start the factory with a short command such as:

```bash
python3 run_factory.py "Use the context_harness product inputs as the source of truth."
```
