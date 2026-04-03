# iOS Architecture Contract for Epic 1: Group Creation & Invitations

## File Ownership Matrix

### Core Models (`/Models`)
```swift
// GroupModel.swift
struct Group: Codable, Identifiable {
    let id: UUID
    var name: String // Required, 1-50 chars
    var imageData: Data? // Optional, max 5MB
    var description: String? // Optional, max 200 chars
    let creatorId: UUID
    let createdAt: Date
    var memberIds: Set<UUID> // Max 100 members
}

// InvitationModel.swift  
struct Invitation: Codable, Identifiable {
    let id: UUID
    let groupId: UUID
    let code: String // 8 char alphanumeric
    let link: URL
    let expiresAt: Date // 24 hours from creation
    let createdBy: UUID
}

// UserGroupMembership.swift
struct UserGroupMembership: Codable {
    let userId: UUID
    let groupIds: Set<UUID> // Max 20 groups per user
}
```

### Data Layer (`/Services`)
```swift
// GroupDataService.swift - Owner: Core Data persistence
protocol GroupDataService {
    func createGroup(_ group: Group) async throws -> Group
    func fetchUserGroups(userId: UUID) async throws -> [Group]
    func deleteGroup(id: UUID) async throws
    func validateGroupLimit(userId: UUID) async throws -> Bool
}

// InvitationService.swift - Owner: Link generation & validation
protocol InvitationService {
    func generateInvitation(for groupId: UUID) async throws -> Invitation
    func validateInvitation(code: String) async throws -> Invitation
    func invalidateExpiredInvitations() async
}
```

### View Models (`/ViewModels`)
```swift
// GroupCreationViewModel.swift - Owner: Creation flow state
@MainActor
final class GroupCreationViewModel: ObservableObject {
    @Published var groupName: String = ""
    @Published var groupDescription: String = ""
    @Published var selectedImage: UIImage?
    @Published var validationError: ValidationError?
    @Published var isCreating: Bool = false
    
    func createGroup() async
    func validateInputs() -> Bool
}

// InvitationViewModel.swift - Owner: Invitation state
@MainActor
final class InvitationViewModel: ObservableObject {
    @Published var activeInvitation: Invitation?
    @Published var shareSheetItem: ShareSheetItem?
    @Published var copiedToClipboard: Bool = false
    
    func generateInvitation(for groupId: UUID) async
    func shareInvitation()
}
```

### Views (`/Views`)
```swift
// GroupCreationView.swift - Owner: Form UI & HIG compliance
struct GroupCreationView: View {
    @StateObject private var viewModel: GroupCreationViewModel
    @Environment(\.safeAreaInsets) var safeAreaInsets
    
    // HIG Requirements:
    // - TextField height >= 44pt
    // - Image picker button >= 44x44pt
    // - Proper keyboard avoidance
    // - Dynamic Type support
}

// InvitationView.swift - Owner: Link display & sharing
struct InvitationView: View {
    @StateObject private var viewModel: InvitationViewModel
    
    // HIG Requirements:
    // - Share button >= 44x44pt
    // - Code display with high contrast
    // - Copy feedback with haptics
}

// GroupJoinView.swift - Owner: Join flow UI
struct GroupJoinView: View {
    @State private var invitationCode: String = ""
    
    // HIG Requirements:
    // - Text input >= 44pt height
    // - Clear error states
    // - Loading states with ProgressView
}
```

## Data Flow Architecture

### State Boundaries
```swift
// App-level state
@StateObject var appState = AppState() // Owns current user & group list

// Screen-level state  
@StateObject var creationVM = GroupCreationViewModel() // Owns creation flow

// Component-level state
@State private var showingImagePicker = false // Owns local UI state
```

### Data Flow Rules
1. **Unidirectional**: Views → ViewModels → Services → Core Data
2. **Async boundaries**: All service calls use async/await
3. **Error propagation**: Services throw → ViewModels handle → Views display
4. **State ownership**: Each ViewModel owns its complete UI state

## HIG Compliance Contract

### Touch Target Enforcement
```swift
struct HIG {
    static let minTouchTarget: CGFloat = 44
    static let standardPadding: CGFloat = 16
    static let keyboardAvoidance: CGFloat = 8
}

// Enforced in every interactive element:
Button(action: {}) {
    Text("Create Group")
        .frame(minHeight: HIG.minTouchTarget)
}
```

### Safe Area Handling
```swift
extension View {
    func respectsSafeArea() -> some View {
        self
            .padding(.top, safeAreaInsets.top)
            .padding(.bottom, max(safeAreaInsets.bottom, HIG.standardPadding))
    }
}
```

### Accessibility Requirements
- All images: `.accessibilityLabel()`
- All buttons: `.accessibilityHint()`
- All text inputs: `.accessibilityIdentifier()`
- Dynamic Type: `.dynamicTypeSize(...)`

## SPM Dependencies

### Package.swift
```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "UnfadingCore",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "UnfadingCore", targets: ["UnfadingCore"])
    ],
    dependencies: [
        // No external dependencies for Epic 1
        // Core Data, SwiftUI, and Combine are built-in
    ],
    targets: [
        .target(name: "UnfadingCore"),
        .testTarget(name: "UnfadingCoreTests")
    ]
)
```

## Navigation Architecture

### Coordinator Pattern
```swift
@MainActor
final class GroupCoordinator: ObservableObject {
    @Published var path = NavigationPath()
    
    enum Destination: Hashable {
        case createGroup
        case invitation(groupId: UUID)
        case joinGroup(code: String?)
    }
    
    func navigate(to destination: Destination) {
        path.append(destination)
    }
}
```

## Testing Contract

### Unit Test Coverage
- Models: 100% coverage for validation logic
- ViewModels: 90% coverage for business logic
- Services: Mocked for all async operations

### UI Test Requirements
```swift
// Required UI test scenarios:
// 1. Create group with all fields
// 2. Generate and copy invitation
// 3. Join group with valid code
// 4. Hit all validation errors
// 5. Verify HIG compliance (programmatically check frame sizes)
```

## Release Gate Checklist

Before Epic 1 ships:
- [ ] All touch targets >= 44x44pt verified
- [ ] Safe areas respected on all devices
- [ ] Dark mode fully supported
- [ ] Dynamic Type scales properly
- [ ] VoiceOver labels complete
- [ ] No hardcoded colors or dimensions
- [ ] Core Data migration tested
- [ ] Memory leaks profiled
- [ ] Screenshot evidence collected

This contract establishes the foundation for a premium iOS experience that respects both user expectations and Apple's guidelines.
