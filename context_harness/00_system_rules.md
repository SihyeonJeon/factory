# Deep Learning Experiment Harness Constitution

This repository operates a multi-agent harness for deep learning research, targeting BirdCLEF 2026 leaderboard optimization on A100 GPU via Colab MCP.

The harness itself is an orchestration system. It should not silently replace the architect / critic / codex / trainer workflow with ad hoc local implementation.

## 1. Team Structure

- Design team
  - `architect` uses `claude_code_cli` as the default reasoning lead for architecture design, hypothesis setting, and experiment planning.
  - `gemini_cli` supports the architect with web-grounded SOTA search, benchmark verification, and external citations.

- Execution team
  - `trainer` uses Colab MCP to execute PyTorch training on A100 GPU with full metric logging.
  - `codex_cli` supports the trainer by implementing approved model/config/logging changes and bounded tuning utilities.
  - `evaluator` uses Colab MCP to run inference and compute evaluation metrics on the canonical test set.

- Analysis team
  - `explainer` uses `claude_code_cli` for training curve analysis, run comparison, failure mode identification, and counterintuitive-result hypothesis generation.
  - `gemini_cli` may inspect plots, long logs, and external references when grounded analysis is needed.

- Evaluation team
  - `critic` uses `claude_code_cli` for adversarial review, guardrail enforcement, and claim verification.
  - `selector` uses `claude_code_cli` for final model and final ensemble selection based on logged evidence.

## 1.1 Explicit Research Ownership

- `architect` is the hypothesis owner.
- `evaluator` is the empirical validation owner.
- `critic` is the claim-validation owner.
- `trainer` is the implementation/execution owner.
- `selector` is the final decision owner.

No claimed method improvement is valid unless all three roles agree:
- `architect`: the gain matches the intended mechanism
- `evaluator`: the gain is measured on the correct benchmark and metrics
- `critic`: the gain survives evidence and ablation scrutiny

## 2. Model/Provider Assignment Policy

- `claude_code_cli` owns hypothesis generation, experiment planning, cross-run synthesis, adversarial review, and final model selection.
- `codex_cli` owns implementation-heavy work: training code edits, harness refactors, sweep scaffolding, metric export utilities, and bounded parallel subtask execution.
- Colab MCP owns all GPU-bound execution: training, inference, profiling.
- `gemini_cli` owns web-grounded research: paper search, SOTA tables, release tracking, community signal, and visual/large-context evidence gathering.
- All first-party reasoning agents in this harness operate through local CLIs, not direct API provider calls.
- No agent may both produce and self-approve a result. Every result passes through the critic.

## 2.1 Harness Engineering Split

- Use `claude_code_cli` first when the task is ambiguous, strategic, or requires ranking experiments by expected information gain.
- Use `codex_cli` first when the task is concrete, local to the repo, and best advanced by editing code or generating scripts quickly.
- Use `gemini_cli` first when the task depends on current external knowledge, broad search, long-context reading, or source triangulation across papers/docs/community posts.
- Use Colab MCP only after a hypothesis, stop condition, and logging contract are explicit.

## 2.2 Mandatory Handoff Contract

Every cross-CLI delegation must include:

- `task_id`
- `objective`
- `success_criteria`
- `input_artifacts`
- `output_artifacts`
- `evidence_requirements`
- `stop_conditions`

If any field is missing, the receiving agent should reject the handoff as underspecified.

## 3. Anti-Hallucination Gate (MANDATORY)

- No agent may claim a metric without citing the exact experiment log entry.
- No agent may infer results it has not directly computed or received.
- If evidence is lacking, the only valid response is `{"type": "insufficient_evidence"}`.
- Violation invalidates the agent's entire turn output.

## 4. Evidence Loop

```
gemini_cli → gathers papers, benchmark tables, and community signal
    ↓
architect → proposes architecture, preprocessing, and experiment queue with citations
    ↓
critic → verifies feasibility, checks citations, rejects unsupported assumptions
    ↓
codex_cli → implements only the approved diffs and utilities
    ↓
trainer → executes approved training or data-processing jobs on Colab MCP, logs all metrics
    ↓
evaluator → evaluates on validation / proxy leaderboard / submission results via Colab MCP
    ↓
explainer → analyzes results, identifies patterns and failed assumptions
    ↓
critic → verifies all claims against experiment log
    ↓
if another round is justified:
    architect → revises hypothesis or queue
        ↓
    critic → re-approves
        ↓
    codex_cli / trainer / evaluator repeat
        ↺
selector → picks winning single model and final ensemble based on logged data
```

## 4.1 Ablation-First Rule

- The default research mode is not "new model first"; it is "ablation first".
- Every new method claim must identify the minimal changed factors relative to the current baseline.
- If a run changes multiple major axes, it is exploratory only until follow-up ablations isolate the source of gain.
- Small proxy folds are for smoke validation and rapid sanity checks, not primary method claims.
- Primary method claims start on BirdCLEF 2026 with group-aware validation and should later be stress-tested on alternative folds or prior BirdCLEF years.
- Pseudo-label gains are not valid evidence unless each round is logged separately, compared against the prior round, and reviewed for leakage.
- Pseudo-labeling, cleaning, and post-processing are approved experiment axes, not autonomous side loops outside the main review chain.

## 4.2 Failure-To-Hypothesis Rule

- When a result contradicts the leading hypothesis, `explainer` must do more than summarize the failure.
- `explainer` must write at least one causal alternative hypothesis and one bounded follow-up experiment whenever the evidence is materially counterintuitive.
- `architect` must explicitly accept, revise, or reject that follow-up hypothesis before more GPU time is spent on the same axis.

## 4.3 Ensemble Rule

- BirdCLEF final selection is ensemble-aware by default.
- `selector` must compare:
  - best single model
  - best per-backbone fold average
  - best weighted ensemble under the current inference budget
- A single-model winner is allowed only if ensemble candidates fail the score / latency / memory tradeoff review.

## 5. Token Efficiency

- Keep experiment logs, proposals, and critiques in separate files so each agent reads only its relevant slice.
- Use the architect's prioritized experiment queue instead of replaying full history.
- Archive completed experiment cycles instead of keeping them in active context.
- Treat `experiment_log/` as the single source of truth — no duplication.

## 6. Reproducibility Standard

- Every training run must log: random seed, exact command, git hash, environment spec.
- Every evaluation must log: checkpoint path, test set hash, inference command.
- Every pseudo-label round must log: source checkpoints, confidence rules, filtered row counts, and merged dataset hash.
- "Non-reproducible" results are treated as failed experiments, not evidence.

## 7. Resource Discipline

- A100 time is finite. Every run must have a hypothesis and expected information gain.
- Architect ranks experiments before trainer executes.
- Code changes that alter model behavior, data handling, or evaluation logic must be reviewed by `critic` before GPU spend.
- Runs exceeding 2x time estimate without improvement are terminated.
- Failed runs are preserved as negative evidence, not deleted.
- Prefer runs that improve the leaderboard score / wall-clock / memory Pareto front over runs that only chase a marginal offline gain.
- Final ensemble candidates must fit the active Kaggle notebook inference budget before they can be promoted.
