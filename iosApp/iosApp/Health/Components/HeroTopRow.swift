import SwiftUI
import Lottie

struct HeroTopRow: View {
    let dateLabel: String
    let isSyncing: Bool
    let syncCycle: Int
    let onLongPressWatch: () -> Void
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(dateLabel).font(.system(size: AppTypography.caption)).foregroundStyle(AppColors.Health.date)
                Text(appLocalized("health_today")).font(.system(size: AppTypography.heroTitle, weight: .semibold)).foregroundStyle(.white)
            }
            Spacer()
            Image(AppImages.Health.calendar).resizable().scaledToFit().frame(width: 23, height: 23)
            Spacer().frame(width: 18)
            WatchSyncLottieView(isSyncing: isSyncing, syncCycle: syncCycle)
                .frame(width: 30, height: 30)
                .clipped()
                .onLongPressGesture(perform: onLongPressWatch)
        }
        .padding(.horizontal, 20).padding(.top, 54)
    }
}

private struct WatchSyncLottieView: UIViewRepresentable {
    let isSyncing: Bool
    let syncCycle: Int

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.clipsToBounds = true
        container.backgroundColor = .clear

        let animationView = LottieAnimationView(name: "watch_status")
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .playOnce
        animationView.currentProgress = 0
        animationView.clipsToBounds = true
        animationView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(animationView)
        NSLayoutConstraint.activate([
            animationView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            animationView.topAnchor.constraint(equalTo: container.topAnchor),
            animationView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        context.coordinator.animationView = animationView
        return container
    }

    func updateUIView(_ container: UIView, context: Context) {
        guard let animationView = context.coordinator.animationView else { return }
        let shouldStart = isSyncing && (context.coordinator.lastCycle != syncCycle || !context.coordinator.wasSyncing)
        if shouldStart {
            animationView.stop()
            animationView.currentProgress = 0
            animationView.play()
        } else if !isSyncing && context.coordinator.wasSyncing {
            animationView.stop()
            animationView.currentProgress = 0
        }
        context.coordinator.lastCycle = syncCycle
        context.coordinator.wasSyncing = isSyncing
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.animationView?.stop()
        coordinator.animationView = nil
    }

    final class Coordinator {
        var animationView: LottieAnimationView?
        var lastCycle = -1
        var wasSyncing = false
    }
}
