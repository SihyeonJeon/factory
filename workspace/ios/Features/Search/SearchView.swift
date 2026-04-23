import SwiftUI

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var model: SearchViewModel
    private let onSelectMemory: (DBMemory) -> Void

    init(
        groupId: UUID?,
        repository: MemoryRepository = SupabaseMemoryRepository(),
        recentStore: SearchRecentStore = .shared,
        onSelectMemory: @escaping (DBMemory) -> Void = { _ in }
    ) {
        _model = StateObject(
            wrappedValue: SearchViewModel(
                groupId: groupId,
                repository: repository,
                recentStore: recentStore
            )
        )
        self.onSelectMemory = onSelectMemory
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: UnfadingTheme.Spacing.md) {
                searchField

                if model.trimmedQuery.isEmpty {
                    recentSearches
                } else if model.isLoading {
                    Spacer()
                    ProgressView()
                        .tint(UnfadingTheme.Color.primary)
                    Spacer()
                } else if let errorMessage = model.errorMessage {
                    Spacer()
                    Text(errorMessage)
                        .font(UnfadingTheme.Font.body(14))
                        .foregroundStyle(UnfadingTheme.Color.textSecondary)
                        .padding(.horizontal, UnfadingTheme.Spacing.lg)
                    Spacer()
                } else if model.results.isEmpty {
                    Spacer()
                    Text(UnfadingLocalized.Search.emptyResults)
                        .font(UnfadingTheme.Font.body(14))
                        .foregroundStyle(UnfadingTheme.Color.textSecondary)
                        .padding(.horizontal, UnfadingTheme.Spacing.lg)
                    Spacer()
                } else {
                    resultsList
                }
            }
            .padding(.top, UnfadingTheme.Spacing.md)
            .padding(.bottom, UnfadingTheme.Spacing.md)
            .background(UnfadingTheme.Color.bg.ignoresSafeArea())
            .navigationTitle(UnfadingLocalized.Search.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(UnfadingLocalized.Common.cancel) {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            model.loadRecentSearches()
        }
    }

    private var searchField: some View {
        HStack(spacing: UnfadingTheme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(UnfadingTheme.Color.textSecondary)
                .accessibilityHidden(true)

            TextField(UnfadingLocalized.Search.placeholder, text: $model.query)
                .font(UnfadingTheme.Font.body(15))
                .foregroundStyle(UnfadingTheme.Color.textPrimary)
                .submitLabel(.search)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .accessibilityIdentifier("search-query-field")
                .onSubmit {
                    model.runSearchNow()
                }
                .onChange(of: model.query) { _, _ in
                    model.scheduleSearch()
                }

            if model.query.isEmpty == false {
                Button {
                    model.clearQuery()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(UnfadingTheme.Color.textSecondary)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityLabel(UnfadingLocalized.Search.clearQuery)
                .accessibilityIdentifier("search-clear-query")
            }
        }
        .padding(.horizontal, UnfadingTheme.Spacing.md)
        .frame(minHeight: 52)
        .background(
            RoundedRectangle(cornerRadius: UnfadingTheme.Radius.button, style: .continuous)
                .fill(UnfadingTheme.Color.sheet)
        )
        .overlay {
            RoundedRectangle(cornerRadius: UnfadingTheme.Radius.button, style: .continuous)
                .stroke(UnfadingTheme.Color.divider, lineWidth: 0.5)
        }
        .padding(.horizontal, UnfadingTheme.Spacing.lg)
    }

    private var recentSearches: some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.md) {
            HStack(spacing: UnfadingTheme.Spacing.sm) {
                Text(UnfadingLocalized.Search.recentTitle)
                    .font(UnfadingTheme.Font.sectionTitle(16))
                    .foregroundStyle(UnfadingTheme.Color.textPrimary)

                Spacer()

                if model.recentSearches.isEmpty == false {
                    Button(UnfadingLocalized.Search.clearRecent) {
                        model.clearRecentSearches()
                    }
                    .font(UnfadingTheme.Font.body(13))
                    .foregroundStyle(UnfadingTheme.Color.textSecondary)
                    .frame(minHeight: 44)
                    .accessibilityIdentifier("search-clear-recent")
                }
            }

            if model.visibleRecentSearches.isEmpty {
                Text(UnfadingLocalized.Search.emptyRecent)
                    .font(UnfadingTheme.Font.body(14))
                    .foregroundStyle(UnfadingTheme.Color.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, UnfadingTheme.Spacing.xs)
            } else {
                VStack(spacing: UnfadingTheme.Spacing.sm) {
                    ForEach(model.visibleRecentSearches, id: \.self) { recent in
                        Button {
                            model.query = recent
                            model.runSearchNow()
                        } label: {
                            HStack(spacing: UnfadingTheme.Spacing.sm) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .foregroundStyle(UnfadingTheme.Color.primary)
                                    .accessibilityHidden(true)
                                Text(recent)
                                    .font(UnfadingTheme.Font.body(15))
                                    .foregroundStyle(UnfadingTheme.Color.textPrimary)
                                    .lineLimit(1)
                                Spacer()
                            }
                            .padding(.horizontal, UnfadingTheme.Spacing.md)
                            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: UnfadingTheme.Radius.card, style: .continuous)
                                    .fill(UnfadingTheme.Color.card)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("search-recent-\(recent)")
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, UnfadingTheme.Spacing.lg)
    }

    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: UnfadingTheme.Spacing.sm) {
                ForEach(MemoryRowCardModel.realItems(for: model.results)) { item in
                    Button {
                        if let memory = model.results.first(where: { $0.id == item.id }) {
                            model.recordSelection()
                            onSelectMemory(memory)
                            dismiss()
                        }
                    } label: {
                        MemoryRowCard(item: item)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("search-result-\(item.id.uuidString)")
                }
            }
            .padding(.horizontal, UnfadingTheme.Spacing.lg)
            .padding(.bottom, UnfadingTheme.Spacing.sheetBottom)
        }
        .scrollIndicators(.hidden)
    }
}

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published private(set) var results: [DBMemory] = []
    @Published private(set) var recentSearches: [String] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    let groupId: UUID?

    private let repository: MemoryRepository
    private let recentStore: SearchRecentStore
    private var debounceTask: Task<Void, Never>?

    init(
        groupId: UUID?,
        repository: MemoryRepository,
        recentStore: SearchRecentStore
    ) {
        self.groupId = groupId
        self.repository = repository
        self.recentStore = recentStore
    }

    var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var visibleRecentSearches: [String] {
        trimmedQuery.isEmpty ? recentSearches : []
    }

    func loadRecentSearches() {
        recentSearches = recentStore.load()
    }

    func clearQuery() {
        debounceTask?.cancel()
        query = ""
        results = []
        errorMessage = nil
        isLoading = false
    }

    func clearRecentSearches() {
        recentStore.clear()
        recentSearches = []
    }

    func scheduleSearch() {
        debounceTask?.cancel()

        guard trimmedQuery.isEmpty == false else {
            results = []
            errorMessage = nil
            isLoading = false
            return
        }

        debounceTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard Task.isCancelled == false else { return }
            await self?.performSearch()
        }
    }

    func runSearchNow() {
        debounceTask?.cancel()

        guard trimmedQuery.isEmpty == false else {
            results = []
            errorMessage = nil
            return
        }

        debounceTask = Task { [weak self] in
            await self?.performSearch()
        }
    }

    func recordSelection() {
        persistRecentQuery()
    }

    private func performSearch() async {
        guard let groupId else {
            results = []
            errorMessage = UnfadingLocalized.Search.noGroup
            isLoading = false
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let fetched = try await repository.searchMemories(groupId: groupId, query: trimmedQuery)
            guard Task.isCancelled == false else { return }
            results = fetched
            persistRecentQuery()
        } catch {
            guard Task.isCancelled == false else { return }
            results = []
            errorMessage = UnfadingLocalized.Search.searchFailed
        }

        isLoading = false
    }

    private func persistRecentQuery() {
        let trimmed = trimmedQuery
        guard trimmed.isEmpty == false else { return }
        recentSearches = recentStore.record(trimmed)
    }
}

struct SearchRecentStore {
    static let shared = SearchRecentStore()

    private let defaults: UserDefaults
    private let key: String
    private let limit: Int

    init(
        defaults: UserDefaults = .standard,
        key: String = "search.recentQueries",
        limit: Int = 8
    ) {
        self.defaults = defaults
        self.key = key
        self.limit = limit
    }

    func load() -> [String] {
        defaults.stringArray(forKey: key) ?? []
    }

    @discardableResult
    func record(_ query: String) -> [String] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return load() }

        var updated = load().filter { $0.caseInsensitiveCompare(trimmed) != .orderedSame }
        updated.insert(trimmed, at: 0)
        updated = Array(updated.prefix(limit))
        defaults.set(updated, forKey: key)
        return updated
    }

    func clear() {
        defaults.removeObject(forKey: key)
    }
}
