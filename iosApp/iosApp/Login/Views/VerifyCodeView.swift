import SwiftUI

struct VerifyCodeView: View {
    let account: String
    let targetKind: VerifyTargetKind
    @ObservedObject var viewModel: LoginViewModel
    @Binding var path: NavigationPath

    @State private var code = ""
    @State private var countdown = 60
    @State private var resendLoading = false
    @State private var localError: String?
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            AuthBlackPage(onBack: { path.removeLast() }, showFeedback: false) {
                AuthTitle("输入验证码")
                Spacer().frame(height: 14)
                Text(verifyCodeMessage)
                    .foregroundStyle(Color(red: 216 / 255, green: 216 / 255, blue: 221 / 255))
                    .font(.system(size: 16)).lineSpacing(4)
                Spacer().frame(height: 56)
                CodeBoxes(code: $code, hasError: !(localError ?? "").isEmpty)
                    .onChange(of: code) { _, newValue in
                        guard newValue.count == 4 else { return }
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 120_000_000)
                            if code == newValue { submitCode() }
                        }
                    }
                ErrorText(localError)
                Spacer().frame(height: 58)
                HStack(alignment: .center, spacing: 0) {
                    if countdown > 0 {
                        Text("重新发送").foregroundStyle(corosMuted)
                        Text("（\(countdown)s）").foregroundStyle(corosRed)
                    } else {
                        Button(action: resendCode) { Text("获取验证码").foregroundStyle(corosRed) }.buttonStyle(.plain)
                    }
                    Spacer()
                    Button(action: { /* show unavailable */ }) {
                        Text("收不到验证码?").foregroundStyle(corosMuted)
                    }.buttonStyle(.plain)
                }.font(.system(size: 16))
                Spacer(minLength: 80)
            }
            if resendLoading { BlockingLoadingOverlay() }
        }
        .onReceive(timer) { _ in if countdown > 0 { countdown -= 1 } }
        .onAppear { countdown = 60 }
    }

    private var verifyCodeMessage: String {
        switch targetKind {
        case .email: return "验证码已发送至你的邮箱 \(account)，有效期10分钟"
        case .phone: return "验证码已发送至你的手机+86-\(account)，有效期10分钟"
        }
    }

    private func submitCode() {
        if code.count != 4 { localError = "请输入验证码"; return }
        let message = viewModel.verifyCodeMessage(account: account, code: code)
        if message == nil || message?.isEmpty == true {
            viewModel.updateVerifyCode(code)
            path.append(AuthRoute.passwordSetup(targetKind: targetKind))
        } else {
            localError = message
        }
    }

    private func resendCode() {
        Task { @MainActor in
            resendLoading = true
            try? await Task.sleep(nanoseconds: 650_000_000)
            let message = viewModel.resendVerifyCode()
            if message == nil || message?.isEmpty == true {
                code = ""
                localError = nil
                countdown = 60
            } else {
                localError = message
            }
            resendLoading = false
        }
    }
}
