# MCP Stack — Deep Learning Harness

## Active Target Stack

### `claude-code-cli` (Primary Orchestrator)
- **Vendor:** Anthropic
- **Purpose:** 가설 설정, 실험 우선순위화, 비평, 최종 선택
- **Why it sits at the top of the harness:** 애매한 문제를 계획 가능한 작업 단위로 쪼개고, 서브에이전트/훅 기반으로 통제하기 좋다.

### `codex-cli` (Primary Implementation Worker)
- **Vendor:** OpenAI
- **Purpose:** 로컬 코드 수정, 하네스 리팩터링, 스크립트 생성, bounded parameter-tuning scaffolds
- **Why it is paired with Claude Code:** 전략 수립보다는 구현과 병렬 실행 단위에 투입할 때 효율이 높다.

### `gemini-cli` (Primary Research Worker)
- **Vendor:** Google
- **Purpose:** paper search, benchmark verification, community scan, large-context evidence gathering
- **Why it is paired with the harness:** 외부 최신 근거가 필요한 작업을 검색 기반으로 보강한다.

### `colab-mcp` (Primary — Google Official)
- **Repository:** [googlecolab/colab-mcp](https://github.com/googlecolab/colab-mcp)
- **Released:** 2026-03-17 by Google
- **Purpose:** A100 GPU execution for PyTorch training, inference, profiling, and Kaggle-style audio experimentation via Google Colab
- **Transport:** stdio via `uvx`
- **Install target:** Project-scoped `.mcp.json`

### Available Tools (from Colab MCP)
- `create_cell` — 새 코드/마크다운 셀 생성
- `edit_cell` — 기존 셀 수정
- `execute_cell` — 셀 실행 (GPU 코드 포함)
- `get_cell_output` — 실행 결과 수신
- `get_notebook_state` — 노트북 전체 상태 조회
- `delete_cell` / `move_cell` — 셀 관리

### Setup Prerequisites
```bash
# 1. uv 설치 (uvx 포함)
pip install uv

# 2. Google Colab 노트북을 브라우저에서 열어둔 상태로 유지
#    - A100 런타임 선택: Runtime > Change runtime type > A100 GPU

# 3. .mcp.json 설정 (이미 완료)
# {
#   "mcpServers": {
#     "colab-mcp": {
#       "command": "uvx",
#       "args": ["git+https://github.com/googlecolab/colab-mcp"],
#       "timeout": 30000
#     }
#   }
# }

# 4. Claude Code 재시작 후 Colab MCP 자동 연결
```

### Current Blockers
- `uv` / `uvx` 미설치 → `pip install uv` 필요
- Google Colab A100 런타임이 브라우저에서 활성화되어 있어야 함
- Colab Pro/Pro+ 구독 필요 (A100 접근)

## Integration Pattern

```
Claude Code CLI
    ↓ hypothesis, routing, critique
Gemini CLI
    ↓ citations, benchmarks, community signal
Codex CLI
    ↓ code diffs, harness utilities, sweep scripts
Trainer/Evaluator Agent
    ↓ create_cell + execute_cell via Colab MCP
Google Colab A100 Runtime
    ↓ get_cell_output → metrics, logs
experiment_log/
```

## Recommended Work Split

- `claude-code-cli`: hypothesis formation, experiment design, ambiguity resolution, critique, final selection
- `codex-cli`: implement approved changes, parameter sweep scaffolds, reproducibility scripts, repo-local automation
- `gemini-cli`: retrieve external evidence, track latest docs/papers/community practices, inspect long logs or plots with grounding
- `colab-mcp`: run training/evaluation/profiling only after the above three agree on the artifact to execute
- For BirdCLEF 2026, mount Google Drive first and keep dataset paths explicit inside the run manifest

## Handoff Shape

All CLI-to-CLI requests should use the same structured payload:

```json
{
  "task_id": "birdclef-2026-exp-001",
  "objective": "Implement critic-approved EfficientNet-B0 baseline training config",
  "success_criteria": [
    "config committed in experiment_log input artifact",
    "train script logs per-epoch LR, loss, auroc, memory",
    "OOM retry path covered"
  ],
  "input_artifacts": [
    "context_harness/manifests/methods/birdclef2026_effnet_b0_gem.json",
    "experiment_log/critique_birdclef_queue_001.json"
  ],
  "output_artifacts": [
    "experiment_log/training_run_birdclef2026-effnet-b0-001.json",
    "experiment_log/eval_report_birdclef2026-effnet-b0-001.json"
  ],
  "evidence_requirements": [
    "diff summary",
    "reproduction command",
    "metric summary"
  ],
  "stop_conditions": [
    "missing architecture approval",
    "ambiguous metric definition",
    "missing Drive mount"
  ]
}
```

BirdCLEF-specific usage notes are captured in:

- `context_harness/birdclef_cli_handoff_spec.md`

## Resource Constraints

- A100 80GB HBF2 memory
- 312 TFLOPS FP16 / 156 TFLOPS FP32
- Colab session timeout: ~12h (Pro+), checkpoint to Google Drive not /tmp
- Early stopping guardrail: 3 consecutive val_loss increases → kill training
- BirdCLEF audio I/O can bottleneck training; cache spectrograms or chunk metadata when repeated feature extraction becomes dominant

## Next MCP Targets

- Weights & Biases MCP — if experiment tracking outgrows local JSON logs
- Hugging Face MCP — if model sharing/Hub upload becomes needed
- Keep stack minimal until a concrete need emerges
