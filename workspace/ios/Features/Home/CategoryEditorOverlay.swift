import SwiftUI

struct CategoryEditorOverlay: View {
    @EnvironmentObject private var categoryStore: CategoryStore
    @Binding var isPresented: Bool

    @State private var newName = ""
    @State private var selectedIcon = "heart.fill"
    @State private var errorMessage: String?

    private let icons = [
        "heart.fill",
        "fork.knife",
        "cup.and.saucer.fill",
        "safari.fill",
        "mountain.2.fill",
        "sparkles",
        "sun.max.fill",
        "camera.fill",
        "mappin",
        "yensign.circle.fill"
    ]

    var body: some View {
        if isPresented {
            GeometryReader { proxy in
                ZStack {
                    Rectangle()
                        .fill(UnfadingTheme.Color.overlayBackdrop)
                        .background(.ultraThinMaterial)
                        .blur(radius: 4)
                        .ignoresSafeArea()
                        .onTapGesture { close() }

                    card(maxHeight: proxy.size.height * 0.80)
                        .frame(width: min(360, proxy.size.width - (UnfadingTheme.Spacing.lg * 2)))
                        .frame(maxHeight: proxy.size.height * 0.80)
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
                .zIndex(201)
                .accessibilityIdentifier("category-editor-overlay")
            }
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
        }
    }

    private func card(maxHeight: CGFloat) -> some View {
        VStack(spacing: UnfadingTheme.Spacing.lg) {
            header

            ScrollView {
                VStack(spacing: UnfadingTheme.Spacing.md) {
                    categoryList
                    addBlock
                }
                .padding(.vertical, UnfadingTheme.Spacing.xs)
            }
            .frame(maxHeight: maxHeight - 150)

            footer
        }
        .padding(UnfadingTheme.Spacing.xl)
        .background(UnfadingTheme.Color.sheet, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(style: UnfadingTheme.Shadow.overlay)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: UnfadingTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.xs) {
                Text(UnfadingLocalized.Categories.editorTitle)
                    .font(UnfadingTheme.Font.sectionTitle(18))
                    .foregroundStyle(UnfadingTheme.Color.textPrimary)
                Text(UnfadingLocalized.Categories.editorSubtitle)
                    .font(UnfadingTheme.Font.body(12))
                    .foregroundStyle(UnfadingTheme.Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Button(action: close) {
                Image(systemName: "xmark")
                    .imageScale(.small)
                    .foregroundStyle(UnfadingTheme.Color.textPrimary)
                    .frame(width: 34, height: 34)
                    .background(UnfadingTheme.Color.surface, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(UnfadingLocalized.Categories.close)
            .accessibilityIdentifier("category-editor-close")
        }
    }

    private var categoryList: some View {
        VStack(spacing: UnfadingTheme.Spacing.xs) {
            ForEach(categoryStore.categories) { category in
                HStack(spacing: UnfadingTheme.Spacing.md) {
                    Image(systemName: category.icon)
                        .imageScale(.small)
                        .foregroundStyle(UnfadingTheme.Color.primary)
                        .frame(width: 32, height: 32)
                        .background(UnfadingTheme.Color.accentSoft, in: Circle())

                    Text(category.name)
                        .font(UnfadingTheme.Font.body(14))
                        .foregroundStyle(UnfadingTheme.Color.textPrimary)

                    Spacer()

                    Button {
                        categoryStore.remove(id: category.id)
                    } label: {
                        Image(systemName: "xmark")
                            .imageScale(.small)
                            .foregroundStyle(UnfadingTheme.Color.textSecondary)
                            .frame(width: 34, height: 34)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(category.name) 삭제")
                }
                .frame(minHeight: 44)
                .padding(.horizontal, UnfadingTheme.Spacing.sm)
                .background(UnfadingTheme.Color.card, in: RoundedRectangle(cornerRadius: UnfadingTheme.Radius.segment, style: .continuous))
            }
        }
    }

    private var addBlock: some View {
        VStack(alignment: .leading, spacing: UnfadingTheme.Spacing.sm) {
            Text(UnfadingLocalized.Categories.newCategoryLabel)
                .font(UnfadingTheme.Font.body(12))
                .foregroundStyle(UnfadingTheme.Color.textSecondary)

            HStack(spacing: UnfadingTheme.Spacing.sm) {
                TextField(UnfadingLocalized.Categories.newCategoryPlaceholder, text: $newName)
                    .font(UnfadingTheme.Font.body(14))
                    .textInputAutocapitalization(.words)
                    .padding(.horizontal, UnfadingTheme.Spacing.md)
                    .frame(minHeight: 44)
                    .background(UnfadingTheme.Color.card, in: RoundedRectangle(cornerRadius: UnfadingTheme.Radius.segment, style: .continuous))
                    .accessibilityLabel(UnfadingLocalized.Categories.newCategoryLabel)

                Button(action: addCategory) {
                    Text(UnfadingLocalized.Categories.addButton)
                        .font(UnfadingTheme.Font.body(13))
                        .foregroundStyle(UnfadingTheme.Color.textOnPrimary)
                        .frame(minWidth: 58, minHeight: 44)
                        .background(UnfadingTheme.Color.primary, in: RoundedRectangle(cornerRadius: UnfadingTheme.Radius.segment, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("category-editor-add-button")
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: UnfadingTheme.Spacing.xs), count: 5), spacing: UnfadingTheme.Spacing.xs) {
                ForEach(icons, id: \.self) { icon in
                    Button {
                        selectedIcon = icon
                    } label: {
                        Image(systemName: icon)
                            .imageScale(.small)
                            .foregroundStyle(selectedIcon == icon ? UnfadingTheme.Color.textOnPrimary : UnfadingTheme.Color.primary)
                            .frame(width: 44, height: 44)
                            .background(selectedIcon == icon ? UnfadingTheme.Color.primary : UnfadingTheme.Color.card, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(icon)
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(UnfadingTheme.Font.body(12))
                    .foregroundStyle(UnfadingTheme.Color.primary)
            }
        }
        .padding(UnfadingTheme.Spacing.md)
        .background(UnfadingTheme.Color.accentSoft, in: RoundedRectangle(cornerRadius: UnfadingTheme.Radius.card, style: .continuous))
    }

    private var footer: some View {
        HStack(spacing: UnfadingTheme.Spacing.sm) {
            Button {
                categoryStore.reset()
                errorMessage = nil
            } label: {
                Text(UnfadingLocalized.Categories.resetDefault)
                    .font(UnfadingTheme.Font.body(14))
                    .foregroundStyle(UnfadingTheme.Color.textPrimary)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(UnfadingTheme.Color.surface, in: RoundedRectangle(cornerRadius: UnfadingTheme.Radius.button, style: .continuous))
            }
            .buttonStyle(.plain)
            .layoutPriority(1)
            .accessibilityIdentifier("category-editor-reset")

            Button {
                categoryStore.save()
                close()
            } label: {
                Text(UnfadingLocalized.Categories.save)
                    .font(UnfadingTheme.Font.body(14))
                    .foregroundStyle(UnfadingTheme.Color.textOnPrimary)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(UnfadingTheme.Color.primary, in: RoundedRectangle(cornerRadius: UnfadingTheme.Radius.button, style: .continuous))
            }
            .buttonStyle(.plain)
            .layoutPriority(2)
            .accessibilityIdentifier("category-editor-save")
        }
    }

    private func addCategory() {
        do {
            try categoryStore.add(name: newName, icon: selectedIcon)
            newName = ""
            errorMessage = nil
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? UnfadingLocalized.Categories.duplicateError
        }
    }

    private func close() {
        isPresented = false
    }
}
