import SwiftUI

@MainActor
final class EventFieldSheetModel: ObservableObject {
    @Published private(set) var existingEvent: DBEvent?
    @Published var binding: MemoryComposerState.EventBinding
    @Published var createTitle: String
    @Published var isTrip: Bool
    @Published var endDate: Date

    private let groupId: UUID?
    private let selectedTime: Date
    private let repository: EventRepository

    init(
        binding: MemoryComposerState.EventBinding,
        groupId: UUID?,
        selectedTime: Date,
        repository: EventRepository = SupabaseEventRepository()
    ) {
        self.binding = binding
        self.groupId = groupId
        self.selectedTime = selectedTime
        self.repository = repository
        self.createTitle = ""
        self.isTrip = false
        self.endDate = selectedTime
    }

    func loadExistingEvent() async {
        guard let groupId else { return }
        existingEvent = try? await repository.findEventAt(groupId: groupId, timestamp: selectedTime)
        if let existingEvent, binding == .none {
            binding = .bindExisting(existingEvent)
        }
    }

    func chooseExisting() {
        if let existingEvent {
            binding = .bindExisting(existingEvent)
        }
    }

    func chooseCreateNew() {
        binding = .createNew(title: createTitle, isTrip: isTrip, endDate: isTrip ? endDate : nil)
    }
}

struct EventFieldSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var model: EventFieldSheetModel
    @Binding private var binding: MemoryComposerState.EventBinding

    init(
        binding: Binding<MemoryComposerState.EventBinding>,
        groupId: UUID?,
        selectedTime: Date,
        repository: EventRepository = SupabaseEventRepository()
    ) {
        _binding = binding
        _model = StateObject(
            wrappedValue: EventFieldSheetModel(
                binding: binding.wrappedValue,
                groupId: groupId,
                selectedTime: selectedTime,
                repository: repository
            )
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                if let existing = model.existingEvent {
                    Section(UnfadingLocalized.Composer.eventBindToSameDay) {
                        Button {
                            model.chooseExisting()
                            binding = model.binding
                            dismiss()
                        } label: {
                            Label(existing.title, systemImage: "calendar.badge.checkmark")
                                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        }
                    }
                }

                Section(UnfadingLocalized.Composer.eventCreateNew) {
                    TextField(UnfadingLocalized.Composer.eventCreateNew, text: $model.createTitle)
                    Toggle(UnfadingLocalized.Composer.eventTripToggle, isOn: $model.isTrip)
                    if model.isTrip {
                        DatePicker(UnfadingLocalized.Composer.eventStartDate, selection: .constant(Date()), displayedComponents: .date)
                        DatePicker(UnfadingLocalized.Composer.eventEndDate, selection: $model.endDate, displayedComponents: .date)
                    }
                    Button(UnfadingLocalized.Composer.eventCreateNew) {
                        model.chooseCreateNew()
                        binding = model.binding
                        dismiss()
                    }
                    .frame(minHeight: 44)
                }
            }
            .font(UnfadingTheme.Font.body())
            .navigationTitle(UnfadingLocalized.Composer.eventFieldTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(UnfadingLocalized.Common.cancel) { dismiss() }
                }
            }
            .task {
                await model.loadExistingEvent()
                binding = model.binding
            }
        }
    }
}
