import SwiftUI
import UIKit

struct SheetScrollCoordinator<Content: View>: UIViewRepresentable {
    @Binding var offset: CGPoint
    @Binding var isAtTop: Bool
    @Binding var downwardDrag: CGFloat

    let onReleaseToSheet: (_ velocityY: CGFloat) -> Void
    @ViewBuilder let content: () -> Content

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = true
        scrollView.backgroundColor = .clear
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.accessibilityIdentifier = "unfading-bottom-sheet-scroll"

        let hostingController = UIHostingController(rootView: content())
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(hostingController.view)

        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            hostingController.view.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])

        context.coordinator.hostingController = hostingController
        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.hostingController?.rootView = content()
        context.coordinator.publish(scrollView)
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: SheetScrollCoordinator
        var hostingController: UIHostingController<Content>?

        init(parent: SheetScrollCoordinator) {
            self.parent = parent
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            publish(scrollView)
        }

        func scrollViewWillEndDragging(
            _ scrollView: UIScrollView,
            withVelocity velocity: CGPoint,
            targetContentOffset: UnsafeMutablePointer<CGPoint>
        ) {
            let translation = scrollView.panGestureRecognizer.translation(in: scrollView)
            let isDownwardRelease = velocity.y > 0 || translation.y > 20

            guard scrollView.contentOffset.y <= 0, isDownwardRelease else { return }
            targetContentOffset.pointee = .zero
            parent.downwardDrag = max(translation.y, 0)
            parent.onReleaseToSheet(velocity.y)
        }

        func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
            true
        }

        func publish(_ scrollView: UIScrollView) {
            let contentOffset = scrollView.contentOffset
            let translation = scrollView.panGestureRecognizer.translation(in: scrollView)
            let velocity = scrollView.panGestureRecognizer.velocity(in: scrollView)
            let atTop = contentOffset.y <= 0.5
            let downward = atTop && (translation.y > 0 || velocity.y > 0)

            DispatchQueue.main.async {
                self.parent.offset = contentOffset
                self.parent.isAtTop = atTop
                self.parent.downwardDrag = downward ? max(translation.y, 0) : 0
            }
        }
    }
}
