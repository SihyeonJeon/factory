import SwiftUI

struct GroupHubView: View {
    var body: some View {
        NavigationStack {
            List(GroupPreview.samples) { group in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(group.name)
                            .font(.headline)
                        Spacer()
                        Text(group.members)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    Text(group.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }
            .navigationTitle("Groups")
        }
    }
}

#Preview {
    GroupHubView()
}
