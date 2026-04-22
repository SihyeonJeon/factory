import SwiftUI

struct RewindFeedView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(RewindMoment.samples) { moment in
                        RewindMomentCard(moment: moment)
                    }
                }
                .padding(20)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Rewind")
        }
    }
}

#Preview {
    RewindFeedView()
}
