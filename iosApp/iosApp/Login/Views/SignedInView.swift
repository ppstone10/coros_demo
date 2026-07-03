import SwiftUI
import Shared

struct SignedInView: View {
    @ObservedObject var viewModel: LoginViewModel
    @Binding var path: NavigationPath

    var body: some View {
        AuthBlackPage(onBack: {}, showFeedback: false) {
            CorosLogo().frame(maxWidth: .infinity).padding(.top, 80)
            Spacer().frame(height: 96)
            Text("欢迎使用 COROS\n\(viewModel.state.currentSession?.account ?? "")")
                .foregroundStyle(.white).font(.system(size: 26))
                .lineSpacing(10).multilineTextAlignment(.center).frame(maxWidth: .infinity)
            Spacer().frame(height: 48)
            CorosFilledButton(text: "退出登录", color: corosButtonRed, action: { viewModel.logout() })
        }
    }
}
