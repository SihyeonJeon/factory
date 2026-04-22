# eval_protocol round_memory_detail_r1
1. SHAs
2. xcodebuild test
3. Runtime screenshot via SIMCTL_CHILD_MEMORYMAP_EVIDENCE_MODE for entry; if detail view isn't directly reachable via evidence mode, add a new `detailOpen` mode during this round's dispatch (in whitelist)
4. Grep forbidden/English/vibe-limit
5. Multi-axis eval per v5.7 §12
