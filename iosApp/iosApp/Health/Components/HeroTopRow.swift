import SwiftUI
import Lottie

struct HeroTopRow: View {
    let dateLabel: String
    let isSyncing: Bool
    let onLongPressWatch: () -> Void
    @State private var lottieId = UUID()
    private var playback: LottiePlaybackMode {
        isSyncing ? .playing(.fromProgress(0, toProgress: 1, loopMode: .playOnce)) : .paused
    }
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(dateLabel).font(.system(size: AppTypography.caption)).foregroundStyle(AppColors.Health.date)
                Text(appLocalized("health_today")).font(.system(size: AppTypography.heroTitle, weight: .semibold)).foregroundStyle(.white)
            }
            Spacer()
            Image(AppImages.Health.calendar).resizable().scaledToFit().frame(width: 23, height: 23)
            Spacer().frame(width: 18)
            LottieView(animation: .named("watch_status"))
                .playbackMode(playback).animationDidFinish { _ in lottieId = UUID() }
                .frame(width: 30, height: 30).id(lottieId)
                .onLongPressGesture(perform: onLongPressWatch)
        }
        .padding(.horizontal, 20).padding(.top, 54)
    }
}
