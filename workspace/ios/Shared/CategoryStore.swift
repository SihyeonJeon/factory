import Foundation

struct Category: Codable, Hashable, Identifiable {
    let id: String
    let name: String
    let icon: String

    init(name: String, icon: String) {
        let normalized = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.id = normalized
        self.name = normalized
        self.icon = icon
    }
}

@MainActor
final class CategoryStore: ObservableObject {
    enum CategoryError: LocalizedError, Equatable {
        case duplicateName
        case emptyName

        var errorDescription: String? {
            switch self {
            case .duplicateName: return UnfadingLocalized.Categories.duplicateError
            case .emptyName: return UnfadingLocalized.Categories.emptyNameError
            }
        }
    }

    static let shared = CategoryStore()
    static let allCategoryId = "__all__"
    private static let storageKey = "unf.categories"

    @Published private(set) var categories: [Category] = []

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func load() {
        guard
            let data = defaults.data(forKey: Self.storageKey),
            let decoded = try? JSONDecoder().decode([Category].self, from: data),
            !decoded.isEmpty
        else {
            categories = Self.defaultCategories
            return
        }
        categories = decoded
    }

    func save() {
        guard let data = try? JSONEncoder().encode(categories) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }

    func add(name: String, icon: String) throws {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw CategoryError.emptyName }
        guard !categories.contains(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) else {
            throw CategoryError.duplicateName
        }
        categories.append(Category(name: trimmed, icon: icon))
        save()
    }

    func remove(id: String) {
        categories.removeAll { $0.id == id }
        save()
    }

    func reset() {
        categories = Self.defaultCategories
        save()
    }

    static var defaultCategories: [Category] {
        [
            Category(name: UnfadingLocalized.Categories.defaultMemory, icon: "heart.fill"),
            Category(name: UnfadingLocalized.Categories.defaultMeal, icon: "fork.knife"),
            Category(name: UnfadingLocalized.Categories.defaultCafe, icon: "cup.and.saucer.fill"),
            Category(name: UnfadingLocalized.Categories.defaultExperience, icon: "safari.fill")
        ]
    }
}
