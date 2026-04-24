import SwiftUI
import UIKit

struct UnfadingRotorMarkerEntry: Identifiable {
    let id: String
    let label: String
}

extension View {
    func unfadingSemanticGroup() -> some View {
        accessibilityElement(children: .contain)
            .background(
                UnfadingAccessibilityContainerTypeConfigurator(containerType: .semanticGroup)
                    .frame(width: 0, height: 0)
            )
    }

    func unfadingListContainer() -> some View {
        accessibilityElement(children: .contain)
            .background(
                UnfadingAccessibilityContainerTypeConfigurator(containerType: .list)
                    .frame(width: 0, height: 0)
            )
    }

    func unfadingUITestRotorMarkers(_ entries: [UnfadingRotorMarkerEntry], prefix: String) -> some View {
        overlay(alignment: .topLeading) {
            if ProcessInfo.processInfo.environment["UNFADING_UI_TEST"] == "1" {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(entries) { entry in
                        Text(entry.label)
                            .font(.caption2)
                            .foregroundStyle(.clear)
                            .frame(width: 1, height: 1)
                            .clipped()
                            .accessibilityIdentifier("\(prefix)-\(entry.id)")
                    }
                }
                .allowsHitTesting(false)
            }
        }
    }
}

private struct UnfadingAccessibilityContainerTypeConfigurator: UIViewRepresentable {
    let containerType: UIAccessibilityContainerType

    func makeUIView(context: Context) -> ProbeView {
        ProbeView(containerType: containerType)
    }

    func updateUIView(_ uiView: ProbeView, context: Context) {
        uiView.containerType = containerType
        uiView.applyContainerType()
    }

    final class ProbeView: UIView {
        var containerType: UIAccessibilityContainerType

        init(containerType: UIAccessibilityContainerType) {
            self.containerType = containerType
            super.init(frame: .zero)
            isUserInteractionEnabled = false
            isAccessibilityElement = false
            backgroundColor = .clear
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func didMoveToSuperview() {
            super.didMoveToSuperview()
            applyContainerType()
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            applyContainerType()
        }

        func applyContainerType() {
            DispatchQueue.main.async { [weak self] in
                self?.nearestContainerView()?.accessibilityContainerType = self?.containerType ?? .none
            }
        }

        private func nearestContainerView() -> UIView? {
            var candidate = superview
            while let view = candidate {
                let className = NSStringFromClass(type(of: view))
                if className.contains("Hosting") || className.contains("Accessibility") {
                    return view
                }
                candidate = view.superview
            }
            return superview
        }
    }
}
