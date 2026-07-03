import SwiftUI

struct EmailRegisterView: View {
    @ObservedObject var viewModel: LoginViewModel
    @Binding var path: NavigationPath

    @State private var acceptedTerms = false
    @State private var emailInput = ""
    @State private var localError: String?
    @State private var termsPromptAction: TermsPromptAction?
    @State private var showUnavailable = false

    var body: some View {
        AuthBlackPage(onBack: { path.removeLast() }, showFeedback: true, onUnavailableClick: { showUnavailable = true }) {
            AuthTitle("邮箱注册")
            Spacer().frame(height: 60)
            UnderlineInput(
                text: $emailInput,
                placeholder: "请输入邮箱",
                keyboardType: .emailAddress,
                autoFocus: true
            )
            Spacer().frame(height: 44)
            AgreementRow(
                accepted: acceptedTerms,
                onToggle: { acceptedTerms.toggle(); localError = nil },
                onPrivacyClick: { path.append(AuthRoute.privacyPolicy) },
                onServiceTermsClick: { path.append(AuthRoute.serviceTerms) }
            )
            Spacer().frame(height: 28)
            CorosFilledButton(
                text: "发送验证码",
                color: corosButtonRed,
                enabled: canSendEmailCode,
                isLoading: viewModel.state.isLoading,
                action: { requestEmailVerifyCode() }
            )
            ErrorText(localError ?? viewModel.state.errorMessage)
            Button(action: {
                viewModel.updateAccount("")
                path.removeLast()
            }) {
                Text("手机号注册").foregroundStyle(corosRed).font(.system(size: 18))
                    .frame(maxWidth: .infinity).padding(.top, 26)
            }.buttonStyle(.plain)
            Spacer(minLength: 80)
        }
        .overlay {
            if termsPromptAction != nil {
                TermsConsentSheet(
                    onDismiss: { termsPromptAction = nil },
                    onPrivacyClick: { path.append(AuthRoute.privacyPolicy) },
                    onServiceTermsClick: { path.append(AuthRoute.serviceTerms) },
                    onAgree: {
                        acceptedTerms = true
                        termsPromptAction = nil
                        requestEmailVerifyCode(skipTerms: true)
                    }
                )
            }
            if showUnavailable { UnavailableFeatureDialog(onDismiss: { showUnavailable = false }) }
        }
    }

    private var canSendEmailCode: Bool {
        let email = viewModel.normalizeEmailInput(emailInput)
        return email.contains("@") && email.contains(".") && !viewModel.state.isLoading
    }

    private func requestEmailVerifyCode(skipTerms: Bool = false) {
        guard skipTerms || acceptedTerms else {
            termsPromptAction = .emailCode
            return
        }
        let message = viewModel.requestEmailVerifyCode(email: viewModel.normalizeEmailInput(emailInput))
        if message == nil || message?.isEmpty == true {
            let email = viewModel.normalizeEmailInput(emailInput)
            viewModel.updateAccount(email)
            viewModel.updateDisplayName(email)
            path.append(AuthRoute.verifyCode(account: email, targetKind: .email))
        } else {
            localError = message
        }
    }
}
