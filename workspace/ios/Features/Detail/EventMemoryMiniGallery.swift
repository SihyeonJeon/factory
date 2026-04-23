import SwiftUI

struct EventMemoryMiniGallery: View {
    let memories: [DBMemory]
    let selectedMemoryId: UUID
    let onSelect: (DBMemory) -> Void

    var body: some View {
        HStack(spacing: UnfadingTheme.Spacing.sm) {
            ForEach(Array(memories.prefix(3).enumerated()), id: \.element.id) { index, memory in
                Button {
                    onSelect(memory)
                } label: {
                    thumbnail(memory: memory, index: index)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(memory.title)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityIdentifier("memory-detail-mini-gallery")
    }

    private func thumbnail(memory: DBMemory, index: Int) -> some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xs) {
            ZStack {
                if let path = (memory.photoURLs + [memory.photoURL].compactMap { $0 }).first {
                    RemoteImageView(storagePath: path)
                        .accessibilityHidden(true)
                } else {
                    UnfadingTheme.Color.accentSoft
                    Image(systemName: fallbackSymbols[index % fallbackSymbols.count])
                        .imageScale(.large)
                        .foregroundStyle(UnfadingTheme.Color.primary)
                        .accessibilityHidden(true)
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: UnfadingTheme.Radius.compact, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: UnfadingTheme.Radius.compact, style: .continuous)
                    .stroke(memory.id == selectedMemoryId ? UnfadingTheme.Color.primary : UnfadingTheme.Color.divider, lineWidth: memory.id == selectedMemoryId ? 2 : 0.5)
            }

            Text(memory.placeTitle)
                .font(UnfadingTheme.Font.tag(11))
                .foregroundStyle(UnfadingTheme.Color.textSecondary)
                .lineLimit(1)
        }
        .frame(width: 96)
        .frame(minHeight: 132, alignment: .top)
    }

    private var fallbackSymbols: [String] {
        ["photo", "sparkles", "mappin"]
    }
}

#Preview {
    EventMemoryMiniGallery(
        memories: [],
        selectedMemoryId: UUID()
    ) { _ in }
    .padding()
    .background(UnfadingTheme.Color.sheet)
}
