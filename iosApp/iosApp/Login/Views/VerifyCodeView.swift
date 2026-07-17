import SwiftUI

struct VerifyCodeView: View {
    let account: String
    let targetKind: VerifyTargetKind
    @ObservedObject var viewModel: LoginViewModel
    let router: AuthRouter

    @State private var code = ""
    @State private var countdown = 0
    @State private var resendLoading = false
    @State private var localError: String?
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            AuthBlackPage(onBack: { router.pop() }, showFeedback: false) {
                AuthTitle(appLocalized("auth_verification_code"))
                Spacer().frame(height: 14)
                Text(verifyCodeMessage)
                    .foregroundStyle(AppColors.Auth.inputText)
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
                        Text(appLocalized("auth_resend")).foregroundStyle(corosMuted)
                        Text(String(format: appLocalized("auth_resend_countdown"), countdown)).foregroundStyle(corosRed)
                    } else {
                        Button(action: resendCode) { Text(appLocalized("auth_get_code")).foregroundStyle(corosRed) }.buttonStyle(.plain)
                    }
                    Spacer()
                    Button(action: { /* show unavailable */ }) {
                        Text(appLocalized("auth_code_help")).foregroundStyle(corosMuted)
                    }.buttonStyle(.plain)
                }.font(.system(size: 16))
                Spacer(minLength: 80)
            }
            if resendLoading { BlockingLoadingOverlay() }
        }
        .onReceive(timer) { _ in refreshCountdown() }
        .onAppear { refreshCountdown() }
    }

    private var verifyCodeMessage: String {
        switch targetKind {
        case .email: return String(format: appLocalized("auth_verification_sent_email"), account)
        case .phone: return String(format: appLocalized("auth_verification_sent_phone"), account)
        }
    }

    private func submitCode() {
        if code.count != 4 { localError = appLocalized("auth_validation_verify_code_required"); return }
        let message = viewModel.verifyCodeMessage(account: account, code: code)
        if message == nil || message?.isEmpty == true {
            viewModel.updateVerifyCode(code)
            router.push(.passwordSetup(targetKind: targetKind))
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
                refreshCountdown()
            } else {
                localError = message
            }
            resendLoading = false
        }
    }

    private func refreshCountdown() {
        countdown = viewModel.verifyCodeRemainingSeconds(account: account)
    }
}
