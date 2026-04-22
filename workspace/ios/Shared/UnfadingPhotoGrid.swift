import PhotosUI
import SwiftUI

// vibe-limit-checked: 2 reusable asset, 4 weak async capture, 6 do-catch no try?, 8 accessibility/Dynamic Type
struct UnfadingPhotoGrid: View {
    @Binding private var selection: [PhotosPickerItem]
    private let maxSelection: Int
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(selection: Binding<[PhotosPickerItem]>, maxSelection: Int = 12) {
        _selection = selection
        self.maxSelection = maxSelection
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: UnfadingTheme.Spacing.sm) {
            ForEach(Array(selection.enumerated()), id: \.offset) { index, item in
                PhotoCell(item: item) {
                    removePhoto(at: index)
                }
            }

            if selection.count < maxSelection {
                PhotosPicker(
                    selection: $selection,
                    maxSelectionCount: maxSelection,
                    matching: .images
                ) {
                    addCell
                }
                .accessibilityLabel(UnfadingLocalized.PhotoGrid.addPhoto)
            }
        }
    }

    private var columns: [GridItem] {
        if dynamicTypeSize.isAccessibilitySize {
            return [GridItem(.adaptive(minimum: 112), spacing: UnfadingTheme.Spacing.sm)]
        }
        return Array(
            repeating: GridItem(.flexible(), spacing: UnfadingTheme.Spacing.sm),
            count: 4
        )
    }

    private var addCell: some View {
        RoundedRectangle(cornerRadius: UnfadingTheme.Radius.card, style: .continuous)
            .stroke(UnfadingTheme.Color.primary, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
            .background(UnfadingTheme.Color.primarySoft, in: RoundedRectangle(cornerRadius: UnfadingTheme.Radius.card, style: .continuous))
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                VStack(spacing: UnfadingTheme.Spacing.xs) {
                    Image(systemName: "plus")
                        .font(.title3.weight(.bold))
                    Text(UnfadingLocalized.PhotoGrid.addPhoto)
                        .font(UnfadingTheme.Font.captionSemibold())
                }
                .foregroundStyle(UnfadingTheme.Color.primary)
            }
            .frame(minHeight: 44)
    }

    private func removePhoto(at index: Int) {
        guard selection.indices.contains(index) else { return }
        selection.remove(at: index)
    }
}

private struct PhotoCell: View {
    let item: PhotosPickerItem
    let onRemove: () -> Void

    @StateObject private var loader = PhotoThumbnailLoader()

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: UnfadingTheme.Radius.card, style: .continuous)
                .fill(UnfadingTheme.Color.card)
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    content
                }
                .clipShape(RoundedRectangle(cornerRadius: UnfadingTheme.Radius.card, style: .continuous))

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(UnfadingTheme.Color.textOnPrimary, UnfadingTheme.Color.primary)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(UnfadingLocalized.PhotoGrid.removePhoto)
        }
        .task {
            loader.load(from: item)
        }
    }

    @ViewBuilder
    private var content: some View {
        if let image = loader.image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .accessibilityHidden(true)
        } else if let errorMessage = loader.errorMessage {
            VStack(spacing: UnfadingTheme.Spacing.xs) {
                Image(systemName: "exclamationmark.triangle")
                Text(errorMessage)
                    .font(UnfadingTheme.Font.caption2Semibold())
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(UnfadingTheme.Color.textSecondary)
            .padding(UnfadingTheme.Spacing.sm)
        } else {
            VStack(spacing: UnfadingTheme.Spacing.xs) {
                Image(systemName: "photo")
                Text(UnfadingLocalized.PhotoGrid.loading)
                    .font(UnfadingTheme.Font.caption2Semibold())
            }
            .foregroundStyle(UnfadingTheme.Color.textSecondary)
        }
    }
}

@MainActor
private final class PhotoThumbnailLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var errorMessage: String?
    private var didStartLoading = false

    // vibe-limit-checked: 4 weak self in async Task, 5 MainActor state, 6 do-catch user-facing error
    func load(from item: PhotosPickerItem) {
        guard didStartLoading == false else { return }
        didStartLoading = true

        Task { [weak self] in
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    self?.errorMessage = UnfadingLocalized.PhotoGrid.loadFailed
                    return
                }
                guard let image = UIImage(data: data) else {
                    self?.errorMessage = UnfadingLocalized.PhotoGrid.loadFailed
                    return
                }
                self?.image = image
            } catch {
                self?.errorMessage = UnfadingLocalized.PhotoGrid.loadFailed
            }
        }
    }
}
