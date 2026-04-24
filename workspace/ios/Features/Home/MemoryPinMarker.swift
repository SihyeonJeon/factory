import SwiftUI

struct MemoryPinMarker: View {
    let memory: DBMemory
    var isSelected: Bool = false
    var isDimmed: Bool = false

    var body: some View {
        VStack(spacing: UnfadingTheme.Spacing.xs) {
            Image(systemName: MemoryMapPinStyle.symbol(for: memory))
                .font(UnfadingTheme.Font.title3Bold())
                .foregroundStyle(UnfadingTheme.Color.textOnPrimary)
                .frame(width: 44, height: 44)
                .background(MemoryMapPinStyle.color(for: memory).gradient, in: Circle())
                .overlay {
                    if isSelected {
                        Circle()
                            .stroke(UnfadingTheme.Color.primary.opacity(0.35), lineWidth: 8)
                            .frame(width: 58, height: 58)
                    }
                }
                .shadow(color: UnfadingTheme.Color.pinShadow, radius: 8, y: 4)

            Text(MemoryMapPinStyle.shortLabel(for: memory))
                .font(UnfadingTheme.Font.caption2Semibold())
                .foregroundStyle(UnfadingTheme.Color.textPrimary)
                .padding(.horizontal, UnfadingTheme.Spacing.sm)
                .padding(.vertical, UnfadingTheme.Spacing.xs)
                .background(.ultraThinMaterial, in: Capsule())
        }
        .scaleEffect(isSelected ? 1.15 : 1)
        .opacity(isDimmed ? 0.4 : 1)
        .animation(.easeInOut(duration: 0.22), value: isSelected)
        .animation(.easeInOut(duration: 0.22), value: isDimmed)
    }
}

enum MemoryMapPinStyle {
    static func symbol(for memory: DBMemory) -> String {
        let category = memory.categories.first?.lowercased()
        switch category {
        case "food", "meal", "restaurant": return "fork.knife"
        case "cafe", "coffee": return "cup.and.saucer.fill"
        case "walk": return "figure.walk"
        case "trip", "travel": return "map.fill"
        case "photo": return "camera.fill"
        default: return "heart.fill"
        }
    }

    static func color(for memory: DBMemory) -> Color {
        let values = UnfadingTheme.Color.memberPalette
        let hash = abs(memory.id.uuidString.reduce(0) { partial, character in
            partial &+ Int(character.unicodeScalars.first?.value ?? 0)
        })
        return values[hash % values.count]
    }

    static func shortLabel(for memory: DBMemory) -> String {
        let trimmed = memory.placeTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return "추억" }
        if trimmed.count <= 5 { return trimmed }
        return String(trimmed.prefix(5))
    }

    static func matches(memory: DBMemory, categoryID: String, categoryName: String?, icon: String?) -> Bool {
        let tokens = Set(memory.categories.map(normalize))
        let normalizedID = normalize(categoryID)

        if tokens.contains(normalizedID) {
            return true
        }

        if let categoryName, tokens.contains(normalize(categoryName)) {
            return true
        }

        guard let icon else { return false }

        switch icon {
        case "fork.knife":
            return tokens.intersection(["food", "meal", "restaurant", "밥"]).isEmpty == false
        case "cup.and.saucer.fill":
            return tokens.intersection(["cafe", "coffee", "카페"]).isEmpty == false
        case "safari.fill":
            return tokens.intersection(["walk", "trip", "travel", "experience", "경험"]).isEmpty == false
        case "heart.fill":
            return tokens.isEmpty || tokens.intersection(["memory", "photo", "추억"]).isEmpty == false
        default:
            return false
        }
    }

    static let emptyMemory = DBMemory(
        id: UUID(uuidString: "00000000-0000-4000-8000-000000000038")!,
        userId: UUID(uuidString: "00000000-0000-4000-8000-000000000039")!,
        groupId: UUID(uuidString: "00000000-0000-4000-8000-000000000040")!,
        title: "추억",
        note: "",
        placeTitle: "추억",
        address: nil,
        locationLat: 37.5665,
        locationLng: 126.9780,
        date: Date(timeIntervalSince1970: 0),
        capturedAt: nil,
        photoURL: nil,
        photoURLs: [],
        categories: [],
        emotions: [],
        reactionCount: 0,
        createdAt: nil
    )

    private static func normalize(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }
}
