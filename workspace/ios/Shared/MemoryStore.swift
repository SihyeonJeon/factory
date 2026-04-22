import Foundation
import os

// vibe-limit-checked: 5 @MainActor store state, 6 do-catch/no try?, 11 sample drafts to future persistence
@MainActor
final class MemoryStore: ObservableObject {
    @Published private(set) var drafts: [SampleMemoryDraft]

    private let fileURL: URL
    private let logger = Logger(subsystem: "com.jeonsihyeon.memorymap", category: "MemoryStore")

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? Self.defaultFileURL()
        do {
            let data = try Data(contentsOf: self.fileURL)
            self.drafts = try JSONDecoder().decode([SampleMemoryDraft].self, from: data)
        } catch {
            logger.info("메모리 초안 저장소를 기본 샘플로 시작합니다: \(error.localizedDescription, privacy: .public)")
            self.drafts = SampleMemoryDraft.defaultSamples
        }
    }

    func save(_ draft: SampleMemoryDraft) throws {
        if let index = drafts.firstIndex(where: { $0.id == draft.id }) {
            drafts[index] = draft
        } else {
            drafts.append(draft)
        }
        try persist()
    }

    func delete(id: UUID) throws {
        drafts.removeAll { $0.id == id }
        try persist()
    }

    private func persist() throws {
        do {
            let data = try JSONEncoder().encode(drafts)
            let directory = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            logger.error("메모리 초안 저장 실패: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    private static func defaultFileURL() -> URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return documents.appendingPathComponent("memories").appendingPathExtension("json")
    }
}
