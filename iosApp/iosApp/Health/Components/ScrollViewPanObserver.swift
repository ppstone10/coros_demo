import SwiftUI
import UIKit

enum HealthPullRefreshPhase {
    case idle
    case dragging
    case armed
    case refreshing
    case resetting
}

enum HealthPullRefreshConfiguration {
    static let refreshThreshold: CGFloat = 80
    static let refreshHoldOffset: CGFloat = 44
    static let maxPullOffset: CGFloat = 180
    static let indicatorBodyGap: CGFloat = 80
    static let pullResistance: CGFloat = 0.4
    static let settleDuration: Double = 0.3
    static let settleDurationNanoseconds: UInt64 = 300_000_000
    static let syncingDurationNanoseconds: UInt64 = 4_460_000_000
}

func healthPullRefreshPhase(
    offset: CGFloat,
    threshold: CGFloat = HealthPullRefreshConfiguration.refreshThreshold
) -> HealthPullRefreshPhase {
    if offset <= 0 {
        return .idle
    }
    return offset >= threshold ? .armed : .dragging
}

func healthRefreshIndicatorTop(
    bodyTop: CGFloat,
    indicatorHeight: CGFloat,
    fixedGap: CGFloat = HealthPullRefreshConfiguration.indicatorBodyGap
) -> CGFloat {
    bodyTop - indicatorHeight - fixedGap
}

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
        private var originalBounces: Bool?
        private var originalAlwaysBounceVertical: Bool?

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
                    originalBounces = scrollView.bounces
                    originalAlwaysBounceVertical = scrollView.alwaysBounceVertical
                    scrollView.alwaysBounceVertical = true
                    scrollView.bounces = true
                    scrollView.panGestureRecognizer.addTarget(self, action: #selector(handlePan(_:)))
                    return
                }
                ancestor = view.superview
            }
        }

        @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
            guard let scrollView = observedScrollView else { return }
            let rawTranslation = recognizer.translation(in: scrollView).y
            let nativeOffset = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
            let netPull = max(0, rawTranslation - max(0, -nativeOffset))
            switch recognizer.state {
            case .began:
                gestureBeganAtTop = !isRefreshing &&
                    scrollView.contentOffset.y <= -scrollView.adjustedContentInset.top + 1
            case .changed:
                guard gestureBeganAtTop else { return }
                onPullChanged?(netPull)
            case .ended:
                onPullEnded?(netPull, gestureBeganAtTop)
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
            if let originalBounces {
                observedScrollView?.bounces = originalBounces
            }
            if let originalAlwaysBounceVertical {
                observedScrollView?.alwaysBounceVertical = originalAlwaysBounceVertical
            }
        }
    }
}
