import SwiftUI
#if canImport(UIKit)
import AVFoundation
import UIKit
#endif

struct AuthBlackPage<Content: View>: View {
    let onBack: () -> Void
    let showFeedback: Bool
    var showBack: Bool = true
    var onUnavailableClick: () -> Void = {}
    @ViewBuilder let content: () -> Content

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        if showBack {
                            Button(action: onBack) {
                                Text("‹")
                                    .foregroundStyle(.white)
                                    .font(.system(size: 44, weight: .light))
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer()
                        if showFeedback {
                            Button(action: onUnavailableClick) {
                                Text(appLocalized("auth_feedback"))
                                    .foregroundStyle(corosMuted)
                                    .font(.system(size: 14))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(height: 52)
                    content()
                }
                .frame(maxWidth: .infinity, minHeight: max(812, proxy.size.height), alignment: .topLeading)
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)
            .background(AppColors.Core.black.ignoresSafeArea())
        }
    }
}

struct AuthTitle: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .foregroundStyle(.white)
            .font(.system(size: 32, weight: .light))
            .padding(.top, authTitleTopPadding)
    }
}

struct CorosLogo: View {
    var body: some View {
        Image("coros_logo")
            .resizable()
            .scaledToFit()
            .frame(width: 260, height: 48)
            .frame(maxWidth: .infinity)
    }
}

#if canImport(UIKit)
struct LoopingVideoBackground: UIViewRepresentable {
    let videoName: String
    func makeUIView(context: Context) -> LoopingVideoView {
        let view = LoopingVideoView()
        view.configure(videoName: videoName)
        return view
    }
    func updateUIView(_ uiView: LoopingVideoView, context: Context) { uiView.play() }
}

final class LoopingVideoView: UIView {
    private let playerLayer = AVPlayerLayer()
    private var queuePlayer: AVQueuePlayer?
    private var playerLooper: AVPlayerLooper?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)
    }
    required init?(coder: NSCoder) { return nil }
    override func layoutSubviews() { super.layoutSubviews(); playerLayer.frame = bounds }

    func configure(videoName: String) {
        guard queuePlayer == nil, let url = Bundle.main.url(forResource: videoName, withExtension: "mp4") else { return }
        let item = AVPlayerItem(url: url)
        let player = AVQueuePlayer()
        player.isMuted = true; player.actionAtItemEnd = .none
        playerLayer.player = player
        playerLooper = AVPlayerLooper(player: player, templateItem: item)
        queuePlayer = player
        player.play()
    }
    func play() { queuePlayer?.play() }
}
#else
struct LoopingVideoBackground: View {
    let videoName: String
    var body: some View { AppColors.Auth.entranceBackground }
}
#endif

#Preview("Auth title") {
    AuthTitle("Demo").preferredColorScheme(.dark)
}

#Preview("Logo") {
    CorosLogo().preferredColorScheme(.dark)
}
