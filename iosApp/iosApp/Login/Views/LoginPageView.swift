import SwiftUI
import Shared

struct LoginPageView: View {
    @ObservedObject var viewModel: LoginViewModel
    let router: AuthRouter

    @State private var acceptedTerms = false
    @State private var localError: String?
    @State private var termsPromptAction: TermsPromptAction?
    @State private var showUnavailable = false

    var body: some View {
        AuthBlackPage(onBack: { router.pop() }, showFeedback: true, onUnavailableClick: { showUnavailable = true }) {
            AuthTitle("账号登录")
            Spacer().frame(height: 45)
            UnderlineInput(
                text: Binding(get: { viewModel.state.account }, set: { viewModel.updateAccount($0) }),
                placeholder: "输入手机号或邮箱",
                keyboardType: .emailAddress,
                autoFocus: true
            )
            Spacer().frame(height: 16)
            UnderlineInput(
                text: Binding(get: { viewModel.state.password }, set: { viewModel.updatePassword($0) }),
                placeholder: "密码",
                isPassword: true
            )
            Spacer().frame(height: 59)
            AgreementRow(
                accepted: acceptedTerms,
                onToggle: { acceptedTerms.toggle(); localError = nil },
                onPrivacyClick: { router.push(.privacyPolicy) },
                onServiceTermsClick: { router.push(.serviceTerms) }
            )
            Spacer().frame(height: 12)
            CorosFilledButton(
                text: "登录",
                color: corosButtonRed,
                enabled: canLogin,
                isLoading: viewModel.state.isLoading,
                action: { submitLogin() }
            )
            ErrorText(localError ?? viewModel.state.errorMessage)
            Button(action: { router.push(.forgotPassword) }) {
                Text("忘记密码?").foregroundStyle(corosMuted).font(.system(size: 14)).padding(.top, 16)
            }.buttonStyle(.plain)
            Spacer(minLength: 40)
            ThirdPartyArea(onUnavailableClick: { showUnavailable = true })
            Text("V4.8.1.14").foregroundStyle(corosMuted).font(.system(size: 16))
                .frame(maxWidth: .infinity).padding(.top, 22).padding(.bottom, 12)
        }
        .overlay {
            if termsPromptAction != nil {
                TermsConsentSheet(
                    onDismiss: { termsPromptAction = nil },
                    onPrivacyClick: { router.push(.privacyPolicy) },
                    onServiceTermsClick: { router.push(.serviceTerms) },
                    onAgree: {
                        acceptedTerms = true
                        termsPromptAction = nil
                        submitLogin(skipTerms: true)
                    }
                )
            }
            if showUnavailable { UnavailableFeatureDialog(onDismiss: { showUnavailable = false }) }
        }
    }

    private var canLogin: Bool {
        viewModel.canSubmitLogin()
    }

    private func submitLogin(skipTerms: Bool = false) {
        guard skipTerms || acceptedTerms else {
            termsPromptAction = .login
            return
        }
        viewModel.requestLoginMode()
        viewModel.submit()
    }
}
