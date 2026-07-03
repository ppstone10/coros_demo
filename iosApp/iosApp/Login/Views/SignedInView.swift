import SwiftUI
import Shared

struct SignedInView: View {
    @ObservedObject var viewModel: LoginViewModel
    @Binding var path: NavigationPath
    @State private var showDeleteDialog = false
    @State private var localError: String?

    var body: some View {
        AuthBlackPage(onBack: {}, showFeedback: false, showBack: false) {
            CorosLogo().frame(maxWidth: .infinity).padding(.top, 80)
            Spacer().frame(height: 96)
            Text("欢迎使用 COROS\n\(viewModel.state.currentSession?.resolvedDisplayName ?? viewModel.state.currentSession?.account ?? "")")
                .foregroundStyle(.white).font(.system(size: 26))
                .lineSpacing(10).multilineTextAlignment(.center).frame(maxWidth: .infinity)
            Spacer().frame(height: 48)
            CorosFilledButton(text: "退出登录", color: corosButtonRed, action: { viewModel.logout() })
            Spacer().frame(height: 14)
            CorosFilledButton(
                text: "注销账户",
                color: Color(red: 44 / 255, green: 44 / 255, blue: 48 / 255),
                action: { showDeleteDialog = true }
            )
            ErrorText(localError)
        }
        .confirmationDialog(
            "是否确认注销账号",
            isPresented: $showDeleteDialog,
            titleVisibility: .visible
        ) {
            Button("确认", role: .destructive) { deleteAccount() }
            Button("取消", role: .cancel) {}
        }
    }

    private func deleteAccount() {
        if let message = viewModel.deleteCurrentAccountMessage() {
            localError = message
            return
        }
        path = NavigationPath()
        path.append(AuthRoute.entrance)
        viewModel.toastMessage = "账号已注销"
    }
}
