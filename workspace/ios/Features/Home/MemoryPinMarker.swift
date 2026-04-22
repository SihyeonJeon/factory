import SwiftUI

struct MemoryPinMarker: View {
    let pin: SampleMemoryPin

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: pin.symbol)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(pin.color.gradient, in: Circle())
                .shadow(color: .black.opacity(0.18), radius: 8, y: 4)

            Text(pin.shortLabel)
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial, in: Capsule())
        }
    }
}
