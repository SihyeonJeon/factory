# round_memory_detail_r1 spec

Base: 6fdfc63

## Deliverables
1. `workspace/ios/Features/Detail/MemoryDetailView.swift`
   - Input: `SampleMemoryPin` (+ expanded detail); NavigationView surface
   - Sections: photo carousel (horizontal scroll of placeholder photo cards), location + time card, mood chips, note body, member contributions (each = card with avatar placeholder + name + comment)
   - Previous/Next buttons in nav bar for browsing samples
2. `workspace/ios/Shared/SampleModels.swift` — add `SampleMemoryDetail` struct: contributions[], photos[], mood tag ids, note body; `SampleMemoryPin` gains `detail: SampleMemoryDetail?` computed/sample-linked
3. `workspace/ios/Features/Home/MemorySummaryCard.swift` — optional trailing CTA row "상세 보기" Button that triggers navigation (via onTap closure parameter, so parent owns navigation)
4. `workspace/ios/Features/Home/MemoryMapHomeView.swift` — wrap in NavigationStack; `MemorySummaryCard` onDetailTap → pushes `MemoryDetailView(pin:)`
5. `UnfadingLocalized.Detail` new section: navTitle, previousButton, nextButton, contributionsLabel, moodLabel, locationLabel, timeLabel, detailCtaButton
6. Tests: SampleMemoryDetail sample exists; MemoryDetailView builds from sample; navigation pattern test (push detail view state transition)

## Vibe-coding-limits citations
1 (architecture coherence), 7 (Korean UI fidelity), 8 (a11y), 11 (sample data mapping), 12 (state transition tests)

## Acceptance
- Build ✅, tests ≥ 63 (60+3 new)
- Runtime: Map → tap "상세 보기" on sheet → detail renders (screenshot)
- Korean + theme + 44pt throughout
- vibe-limit-checked comments
