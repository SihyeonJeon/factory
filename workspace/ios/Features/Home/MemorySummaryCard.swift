import SwiftUI

struct MemorySummaryCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ScrollView(.vertical, showsIndicators: dynamicTypeSize.isAccessibilitySize) {
            VStack(alignment: .leading, spacing: 14) {
                header

                Text("Three years ago today, your group dropped a pin here after the concert. Two new reactions arrived this morning.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                tagSection
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(maxHeight: dynamicTypeSize.isAccessibilitySize ? 320 : nil, alignment: .top)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    @ViewBuilder
    private var header: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 12) {
                titleBlock
                peopleBadge
            }
        } else {
            HStack(alignment: .top, spacing: 12) {
                titleBlock
                Spacer(minLength: 12)
                peopleBadge
            }
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Tonight's rewind")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("Sangsu rooftop dinner")
                .font(.title3.weight(.bold))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var peopleBadge: some View {
        Label("4 friends", systemImage: "person.3.fill")
            .font(.footnote.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(minHeight: 44)
            .background(Color.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .fixedSize(horizontal: false, vertical: true)
    }

    private var tagSection: some View {
        ViewThatFits(in: .vertical) {
            HStack(spacing: 12) {
                MemoryTag(title: "Joy", systemImage: "sparkles")
                MemoryTag(title: "Night out", systemImage: "moon.stars.fill")
                MemoryTag(title: "Photo set", systemImage: "photo.on.rectangle")
            }

            VStack(alignment: .leading, spacing: 10) {
                MemoryTag(title: "Joy", systemImage: "sparkles")
                MemoryTag(title: "Night out", systemImage: "moon.stars.fill")
                MemoryTag(title: "Photo set", systemImage: "photo.on.rectangle")
            }
        }
    }
}

private struct MemoryTag: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.footnote.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(minHeight: 44)
            .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .fixedSize(horizontal: false, vertical: true)
    }
}
