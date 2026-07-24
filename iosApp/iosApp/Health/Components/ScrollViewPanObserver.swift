import SwiftUI
import UIKit

struct ScrollViewPanObserver: UIViewRepresentable {
    let isRefreshing: Bool
    let onPullChanged: (CGFloat) -> Void
    let onPullEnded: (CGFloat, Bool) -> Void

    func makeUIView(context: Context) -> ObserverView {
        let view = ObserverView()
        configure(view)
        return view
    }

    func updateUIView(_ uiView: ObserverView, context: Context) {
        configure(uiView)
        uiView.attachToEnclosingScrollViewIfNeeded()
    }

    private func configure(_ view: ObserverView) {
        view.isRefreshing = isRefreshing
        view.onPullChanged = onPullChanged
        view.onPullEnded = onPullEnded
    }

    final class ObserverView: UIView {
        weak var observedScrollView: UIScrollView?
        var isRefreshing = false
        var onPullChanged: ((CGFloat) -> Void)?
        var onPullEnded: ((CGFloat, Bool) -> Void)?
        private var gestureBeganAtTop = false

        override func didMoveToWindow() {
            super.didMoveToWindow()
            DispatchQueue.main.async { [weak self] in
                self?.attachToEnclosingScrollViewIfNeeded()
            }
        }

        func attachToEnclosingScrollViewIfNeeded() {
            guard observedScrollView == nil else { return }
            var ancestor = superview
            while let view = ancestor {
                if let scrollView = view as? UIScrollView {
                    observedScrollView = scrollView
                    scrollView.panGestureRecognizer.addTarget(self, action: #selector(handlePan(_:)))
                    return
                }
                ancestor = view.superview
            }
        }

        @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
            guard let scrollView = observedScrollView else { return }
            switch recognizer.state {
            case .began:
                gestureBeganAtTop = !isRefreshing &&
                    scrollView.contentOffset.y <= -scrollView.adjustedContentInset.top + 1
            case .changed:
                guard gestureBeganAtTop else { return }
                onPullChanged?(max(0, recognizer.translation(in: scrollView).y))
            case .ended:
                let distance = max(0, recognizer.translation(in: scrollView).y)
                onPullEnded?(distance, gestureBeganAtTop)
                gestureBeganAtTop = false
            case .cancelled, .failed:
                onPullEnded?(0, false)
                gestureBeganAtTop = false
            default:
                break
            }
        }

        deinit {
            observedScrollView?.panGestureRecognizer.removeTarget(self, action: #selector(handlePan(_:)))
        }
    }
}
