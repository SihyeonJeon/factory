import SwiftUI

struct WheelPicker: View {
    static let hourRange = Array(0...23)
    static let minuteRange = Array(0...59)

    @Binding var hour: Int
    @Binding var minute: Int

    var body: some View {
        HStack(spacing: UnfadingTheme.Spacing.sm) {
            wheel(values: Self.hourRange, selection: $hour)
            Text(":")
                .font(UnfadingTheme.Font.metaNum(24, weight: .bold))
                .foregroundStyle(UnfadingTheme.Color.textPrimary)
            wheel(values: Self.minuteRange, selection: $minute)
        }
        .frame(maxWidth: .infinity)
    }

    private func wheel(values: [Int], selection: Binding<Int>) -> some View {
        Picker("", selection: selection) {
            ForEach(values, id: \.self) { value in
                Text(String(format: "%02d", value))
                    .font(UnfadingTheme.Font.metaNum(20, weight: .bold))
                    .foregroundStyle(UnfadingTheme.Color.textPrimary)
                    .tag(value)
            }
        }
        .pickerStyle(.wheel)
        .frame(width: 88, height: 132)
        .clipped()
    }
}
