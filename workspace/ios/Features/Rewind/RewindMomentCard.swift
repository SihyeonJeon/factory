import SwiftUI

struct RewindMomentCard: View {
    let moment: RewindMoment

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(moment.gradient)
                .frame(height: 180)
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(moment.dateLabel)
                            .font(.caption.weight(.semibold))
                        Text(moment.title)
                            .font(.title3.weight(.bold))
                    }
                    .foregroundStyle(.white)
                    .padding(18)
                }

            VStack(alignment: .leading, spacing: 8) {
                Text(moment.location)
                    .font(.headline)
                Text(moment.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Label(moment.people, systemImage: "person.2.fill")
                Spacer()
                Label(moment.mood, systemImage: "heart.fill")
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}
