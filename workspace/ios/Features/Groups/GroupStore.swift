import Foundation

// vibe-limit-checked: 5 @MainActor group state, 11 sample-group mapping, 12 mode transition tests
@MainActor
final class GroupStore: ObservableObject {
    @Published var currentGroup: SampleGroup = .sampleCouple
    @Published var mode: GroupMode = .couple

    func setMode(_ mode: GroupMode) {
        self.mode = mode
        switch mode {
        case .couple:
            currentGroup = .sampleCouple
        case .general:
            currentGroup = .sampleGeneral
        }
    }
}
