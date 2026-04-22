# round_group_hub_r1 spec base c11eb2b
## Deliverables
1. GroupHubView rewrite: cover VStack (gradient) + mode toggle (Picker segmented with couple/general) + member avatar row + member list + "초대" button
2. Features/Groups/GroupStore.swift @MainActor: @Published selectedGroup: SampleGroup, mode: GroupMode, members: [SampleGroupMember]
3. Shared/UnfadingAvatarStack.swift: reusable 3-6 avatar stack with overflow count
4. SampleModels extended: SampleGroup, SampleGroupMember, GroupMode (couple/general)
5. UnfadingLocalized.Groups extended: modeCouple="커플", modeGroup="그룹", membersLabel="멤버", inviteCta="초대", etc.
6. Tests ≥ 3
