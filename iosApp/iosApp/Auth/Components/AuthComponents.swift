import SwiftUI
#if canImport(UIKit)
import AVFoundation
import UIKit
#endif

private struct AuthComponentsPreviewHost: View {
    @State private var account = "preview@example.com"
    @State private var phone = "13800138000"
    @State private var code = "20"
    @State private var accepted = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                CorosLogo()
                AuthTitle(appLocalized("auth_login_title"))
                UnderlineInput(text: $account, placeholder: appLocalized("auth_email_placeholder"))
                PhoneInput(text: $phone)
                CodeBoxes(code: $code, hasError: false)
                AgreementRow(
                    accepted: accepted,
                    onToggle: { accepted.toggle() },
                    onPrivacyClick: {},
                    onServiceTermsClick: {}
                )
                CorosFilledButton(text: appLocalized("auth_login_button"), color: corosRed, action: {})
                ErrorText(appLocalized("auth_invalid_credentials"))
                ThirdPartyArea(onUnavailableClick: {})
            }
            .padding(20)
        }
        .background(AppColors.Core.black)
        .preferredColorScheme(.dark)
    }
}

#Preview("Authentication component catalog") {
    AuthComponentsPreviewHost()
        .environmentObject(AppLanguageStore.shared)
}

#if !os(iOS)
enum UIKeyboardType {
    case `default`
    case emailAddress
    case phonePad
    case numberPad
}

enum TextInputAutocapitalization {
    case never
}

extension View {
    func keyboardType(_ type: UIKeyboardType) -> some View { self }
    func textInputAutocapitalization(_ value: TextInputAutocapitalization) -> some View { self }
}
#endif

enum VerifyTargetKind: Hashable { case phone, email }
enum TermsPromptAction: Hashable { case login, phoneCode, emailCode }
