import CoreLocation
import MapKit
import SwiftUI

/// F7: 세 탭(지도에서/검색/현재 위치) 단일 sheet. 사용자가 "이 위치가 아닌가요?" 를 탭했을 때 엔트리.
/// 선택 결과는 `onSelect(PickedPlace)` 콜백으로 composer 로 돌려줌.
struct PlacePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var locationPermission: LocationPermissionStore

    let initialCoordinate: CLLocationCoordinate2D?
    let onSelect: (PickedPlace) -> Void

    @State private var selectedTab: Tab = .map
    @State private var mapPosition: MapCameraPosition
    @State private var currentCenter: CLLocationCoordinate2D
    @State private var searchText: String = ""
    @State private var searchResults: [DiscoveredPlace] = []
    @State private var currentLocation: DiscoveredPlace?
    @State private var isLocating = false
    @State private var errorMessage: String?

    private let resolver: PlaceResolving

    init(
        initialCoordinate: CLLocationCoordinate2D?,
        resolver: PlaceResolving = NearbyPlaceService(),
        onSelect: @escaping (PickedPlace) -> Void
    ) {
        self.initialCoordinate = initialCoordinate
        self.resolver = resolver
        self.onSelect = onSelect
        let center = initialCoordinate ?? CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)
        _currentCenter = State(initialValue: center)
        _mapPosition = State(
            initialValue: .region(
                MKCoordinateRegion(
                    center: center,
                    latitudinalMeters: 600,
                    longitudinalMeters: 600
                )
            )
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: UnfadingTheme.Spacing.md) {
                Picker(UnfadingLocalized.Composer.placePickerTitle, selection: $selectedTab) {
                    Text(UnfadingLocalized.Composer.pickerMapTab).tag(Tab.map)
                    Text(UnfadingLocalized.Composer.pickerSearchTab).tag(Tab.search)
                    Text(UnfadingLocalized.Composer.pickerCurrentTab).tag(Tab.current)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, UnfadingTheme.Spacing.lg)
                .accessibilityIdentifier("place-picker-tabs")

                if let errorMessage {
                    Text(errorMessage)
                        .font(UnfadingTheme.Font.footnote())
                        .foregroundStyle(UnfadingTheme.Color.textSecondary)
                        .padding(.horizontal, UnfadingTheme.Spacing.lg)
                }

                content
            }
            .padding(.vertical, UnfadingTheme.Spacing.md)
            .navigationTitle(UnfadingLocalized.Composer.placePickerTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(UnfadingLocalized.Common.cancel) { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch selectedTab {
        case .map:   mapTab
        case .search: searchTab
        case .current: currentTab
        }
    }

    // MARK: 지도에서 선택

    private var mapTab: some View {
        VStack(spacing: UnfadingTheme.Spacing.md) {
            ZStack(alignment: .center) {
                Map(position: $mapPosition)
                    .mapStyle(.standard(elevation: .flat))
                    .onMapCameraChange(frequency: .continuous) { ctx in
                        currentCenter = ctx.region.center
                    }
                    .accessibilityIdentifier("place-picker-map")
                Image(systemName: "mappin")
                    .font(UnfadingTheme.Font.sectionTitle(36))
                    .foregroundStyle(UnfadingTheme.Color.primary)
                    .accessibilityHidden(true)
                    .offset(y: -14)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Text(UnfadingLocalized.Composer.pickerMapHint)
                .font(UnfadingTheme.Font.footnote())
                .foregroundStyle(UnfadingTheme.Color.textSecondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, UnfadingTheme.Spacing.lg)

            Button {
                Task { await confirmMapCenter() }
            } label: {
                Text(UnfadingLocalized.Composer.pickerMapConfirm)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.unfadingPrimaryFullWidth)
            .padding(.horizontal, UnfadingTheme.Spacing.lg)
            .accessibilityIdentifier("place-picker-map-confirm")
        }
    }

    private func confirmMapCenter() async {
        let center = currentCenterCoordinate()
        errorMessage = nil
        let place: PickedPlace
        if let match = try? await resolver.closestMatch(to: center) {
            place = match.pickedPlace(at: center)
        } else {
            place = PickedPlace(
                name: UnfadingLocalized.Composer.placeholderCurrent,
                coordinate: center,
                address: nil
            )
        }
        onSelect(place)
        dismiss()
    }

    private func currentCenterCoordinate() -> CLLocationCoordinate2D {
        currentCenter
    }

    // MARK: 검색

    private var searchTab: some View {
        VStack(spacing: UnfadingTheme.Spacing.md) {
            TextField(UnfadingLocalized.Composer.searchPlaces, text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, UnfadingTheme.Spacing.lg)
                .accessibilityIdentifier("place-picker-search-field")
                .submitLabel(.search)
                .onSubmit { Task { await runSearch() } }
                .onChange(of: searchText) { _, _ in
                    Task { await runSearch() }
                }

            if searchResults.isEmpty {
                Text(UnfadingLocalized.Composer.pickerNoResults)
                    .font(UnfadingTheme.Font.footnote())
                    .foregroundStyle(UnfadingTheme.Color.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                List(searchResults) { place in
                    Button {
                        onSelect(place.pickedPlace)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(place.name)
                                .font(UnfadingTheme.Font.subheadlineSemibold())
                                .foregroundStyle(UnfadingTheme.Color.textPrimary)
                            if let address = place.address {
                                Text(address)
                                    .font(UnfadingTheme.Font.footnote())
                                    .foregroundStyle(UnfadingTheme.Color.textSecondary)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    }
                    .accessibilityIdentifier("place-picker-search-row")
                }
                .listStyle(.plain)
            }
        }
    }

    private func runSearch() async {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else {
            searchResults = []
            return
        }
        do {
            let results = try await resolver.searchByName(q, near: initialCoordinate)
            searchResults = results
            errorMessage = nil
        } catch {
            searchResults = []
            errorMessage = error.localizedDescription
        }
    }

    // MARK: 현재 위치

    private var currentTab: some View {
        VStack(spacing: UnfadingTheme.Spacing.md) {
            if locationPermission.permissionState == .denied
                || locationPermission.permissionState == .restricted {
                Text(UnfadingLocalized.Composer.locationDeniedShortTab)
                    .font(UnfadingTheme.Font.subheadline())
                    .foregroundStyle(UnfadingTheme.Color.textSecondary)
                    .padding(.horizontal, UnfadingTheme.Spacing.lg)
            } else if isLocating {
                ProgressView(UnfadingLocalized.Composer.pickerLocating)
            } else if let place = currentLocation {
                VStack(spacing: UnfadingTheme.Spacing.sm) {
                    Image(systemName: "location.fill")
                        .font(UnfadingTheme.Font.sectionTitle(28))
                        .foregroundStyle(UnfadingTheme.Color.primary)
                    Text(place.name)
                        .font(UnfadingTheme.Font.subheadlineSemibold())
                    if let address = place.address {
                        Text(address)
                            .font(UnfadingTheme.Font.footnote())
                            .foregroundStyle(UnfadingTheme.Color.textSecondary)
                    }
                    Button {
                        onSelect(place.pickedPlace)
                        dismiss()
                    } label: {
                        Text(UnfadingLocalized.Composer.pickerUseThis)
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.unfadingPrimaryFullWidth)
                    .padding(.horizontal, UnfadingTheme.Spacing.lg)
                    .accessibilityIdentifier("place-picker-current-use")
                }
            } else {
                Button {
                    Task { await locateNow() }
                } label: {
                    Label(UnfadingLocalized.Composer.pickerCurrentTab, systemImage: "location.fill")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.unfadingPrimaryFullWidth)
                .padding(.horizontal, UnfadingTheme.Spacing.lg)
                .accessibilityIdentifier("place-picker-current-locate")
            }
        }
        .task(id: selectedTab == .current) {
            if selectedTab == .current, currentLocation == nil, !isLocating {
                await locateNow()
            }
        }
    }

    private func locateNow() async {
        switch locationPermission.handleCurrentLocationTap() {
        case .centerOnUser:
            break
        case .requestSystemPermission:
            // 권한 다이얼로그가 뜨고 사용자 선택 대기. 다음 tap 에서 재시도.
            return
        case .showRecoveryPrompt:
            errorMessage = UnfadingLocalized.Composer.locationDeniedShortTab
            return
        }
        isLocating = true
        defer { isLocating = false }
        let manager = CLLocationManager()
        if let coord = manager.location?.coordinate {
            currentLocation = try? await resolver.closestMatch(to: coord)
        } else if let init_ = initialCoordinate {
            currentLocation = try? await resolver.closestMatch(to: init_)
        } else {
            errorMessage = UnfadingLocalized.Composer.pickerLocating
        }
    }

    private enum Tab: Hashable { case map, search, current }
}

#Preview {
    PlacePickerSheet(
        initialCoordinate: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
        onSelect: { _ in }
    )
    .environmentObject(LocationPermissionStore())
}
