# Epic 1 Brief: Group Creation and Invitations

This brief details the user flows and requirements for the first epic, focusing on building the foundational social layer of the application.

**Epic:** 모임 그룹 생성과 멤버 초대 (Group creation and member invitation)
**Priority:** P0

## Acceptance Criteria

- Group creation requires a name; image and introduction are optional.
- Invitation links are valid for 24 hours and can be reissued.
- A user can be a member of a maximum of 20 groups.
- The group creator has permissions to remove members and delete the group.

---

## Detailed User Flows

### 1. Group Creation

**Entry Point:**
- A user initiates group creation from a primary UI element, e.g., a "+" button on the main group list screen.

**Creation Form:**
1.  **Group Name:** (Required) Text input.
2.  **Group Image:** (Optional) User can tap to select an image from their photo library or use the camera.
3.  **Group Introduction:** (Optional) A short description of the group.
4.  **Create Button:** Becomes active once the group name is entered.

**Post-Creation:**
- Upon tapping "Create", the user is navigated to the newly created group's main screen (the memory map, scoped to this group).
- A prominent "Invite Members" call-to-action should be visible.

### 2. Member Invitation

**Initiation:**
- The group creator (or any member, TBD policy) taps the "Invite Members" button within a group.

**Link Generation & Sharing:**
1.  A unique invitation link (or code) is generated.
2.  The native iOS Share Sheet is presented, allowing the user to share the link through Messages, Mail, or other apps.
3.  The UI should clearly state that the link is valid for 24 hours.
4.  There should be an option to invalidate the current link and generate a new one (e.g., in the Group Settings).

### 3. Joining a Group (Invitee Flow)

**Entry Point:**
- An invitee taps the shared invitation link.

**App Interaction:**
1.  **App Not Installed:** The link directs the user to the app's page on the App Store.
2.  **App Installed:** The app opens and displays an "Invitation" screen.
    - This screen should show the Group Name, Group Image, and number of members.
    - Buttons: "Accept" and "Decline".
3.  **On Accept:**
    - The app checks if the user has reached the 20-group limit. If so, an error message is displayed.
    - If not at the limit, the user is added to the group, and they are navigated to the group's memory map.
4.  **On Decline:** The user is returned to their main screen.

### 4. Group Management (for Group Creator)

**Entry Point:**
- A "Settings" or "Manage" button within the group's screen.

**Management Screen Options:**
1.  **Edit Group Info:** Allows changing the group name, image, and intro.
2.  **Member List:** Shows a list of all group members.
    - Next to each member's name, the creator has an option to "Remove from Group". A confirmation dialog should be presented before removal.
3.  **Invitation Link:** Option to view and regenerate the invitation link.
4.  **Delete Group:**
    - A clearly marked, potentially destructive-action-styled button.
    - Tapping it presents a confirmation alert that requires a second, explicit confirmation (e.g., typing the group's name or a two-step dialog). This action is irreversible and deletes all associated data for all members.

---

## HIG & Native iOS Considerations

- **Touch Targets:** All buttons, text fields, and interactive elements must have a minimum touch target of 44x44 pt.
- **Permissions:** The app must request permission to access the Photo Library when the user wants to add a group image. The purpose of the request must be clearly stated in the `NSPhotoLibraryUsageDescription` string.
- **Native Components:** Use the native iOS Share Sheet for invitations. Navigation should use standard SwiftUI patterns. Modals and alerts should be native.
- **Safe Areas:** All views must respect safe area insets, especially the creation form and settings screens.
- **Accessibility:** All form fields, buttons, and images should have VoiceOver labels. Dynamic Type should be supported.
