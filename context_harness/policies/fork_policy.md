# Fork Policy

Subagents and forks exist to increase throughput without increasing hallucination or merge conflict risk.

## Spawn criteria

- The task has a clear owner, concrete output, and bounded file scope.
- The parent can continue working on non-overlapping tasks.
- The fork can be evaluated mechanically with a test, screenshot, lint, report, or targeted review.
- The planner can explain the handoff in seven acceptance bullets or fewer.

## Do not fork

- The parent needs the answer immediately for its next decision.
- The write scope overlaps another active agent.
- The task is still ambiguous and should be clarified by planning first.

## Default topology

- One planner controls task decomposition.
- Up to three active implementation forks may run in parallel.
- One evaluation fork may run in parallel with implementation.
- A second evaluation fork is allowed only when visual QA and code QA are independent.

## Required handoff

- Goal
- Owned files or directories
- Acceptance criteria
- Explicit non-goals
- Verification artifact expected back

