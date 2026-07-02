import SwiftUI
#if canImport(UIKit)
import AVFoundation
import UIKit
#endif

#if !os(iOS)
private enum UIKeyboardType {
    case `default`
    case emailAddress
    case phonePad
    case numberPad
}

private enum TextInputAutocapitalization {
    case never
}

private extension View {
    func keyboardType(_ type: UIKeyboardType) -> some View {
        self
    }

    func textInputAutocapitalization(_ value: TextInputAutocapitalization) -> some View {
        self
    }
}
#endif

private let corosRed = Color(red: 233 / 255, green: 0, blue: 61 / 255)
private let corosButtonRed = Color(red: 184 / 255, green: 0, blue: 53 / 255)
private let corosMuted = Color(red: 143 / 255, green: 143 / 255, blue: 150 / 255)
private let corosLine = Color(red: 31 / 255, green: 31 / 255, blue: 34 / 255)
private let corosField = Color(red: 14 / 255, green: 14 / 255, blue: 16 / 255)
private let corosCodeActiveField = Color(red: 21 / 255, green: 21 / 255, blue: 23 / 255)
private let corosLegalText = Color(red: 201 / 255, green: 201 / 255, blue: 204 / 255)
private let authTitleTopPadding: CGFloat = 18
private let agreementCheckTouchSize: CGFloat = 18
private let agreementCheckVisualSize: CGFloat = 10

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch viewModel.page {
            case .entrance:
                entrancePage
            case .login:
                loginPage
            case .phoneRegister:
                phoneRegisterPage
            case .emailRegister:
                emailRegisterPage
            case .verifyCode:
                VerifyCodeContent(viewModel: viewModel)
            case .passwordSetup:
                passwordSetupPage
            case .privacyPolicy:
                LegalDocumentPage(
                    title: "隐私政策",
                    paragraphs: privacyPolicyParagraphs,
                    onBack: viewModel.closeLegalDocument
                )
            case .serviceTerms:
                LegalDocumentPage(
                    title: "服务条款",
                    paragraphs: serviceTermsParagraphs,
                    onBack: viewModel.closeLegalDocument
                )
            case .signedIn:
                signedInPage
            }

            if viewModel.termsPromptAction != nil {
                TermsConsentSheet(
                    onDismiss: viewModel.dismissTermsPrompt,
                    onPrivacyClick: viewModel.openPrivacyPolicy,
                    onServiceTermsClick: viewModel.openServiceTerms,
                    onAgree: viewModel.acceptTermsPromptAndContinue
                )
            }

            if viewModel.unavailableDialogVisible {
                UnavailableFeatureDialog(onDismiss: viewModel.dismissUnavailableFeature)
            }
        }
        .alert(
            "提示",
            isPresented: Binding(
                get: { viewModel.toastMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        viewModel.toastMessage = nil
                    }
                }
            ),
            actions: {
                Button("OK", role: .cancel) {}
            },
            message: {
                Text(viewModel.toastMessage ?? "")
            }
        )
    }

    private var entrancePage: some View {
        ZStack {
            Color(red: 17 / 255, green: 17 / 255, blue: 17 / 255).ignoresSafeArea()
            LoopingVideoBackground(videoName: "home")
                .ignoresSafeArea()

            CorosLogo()
                .padding(.top, 62)
                .frame(maxHeight: .infinity, alignment: .top)

            VStack(spacing: 20) {
                CorosFilledButton(
                    text: "注册",
                    color: corosRed,
                    action: viewModel.showPhoneRegister
                )
                CorosFilledButton(
                    text: "登录",
                    color: Color.white.opacity(0.26),
                    action: viewModel.showLogin
                )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 60)
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
    }

    private var loginPage: some View {
        AuthBlackPage(
            onBack: viewModel.backToEntrance,
            showFeedback: true,
            onUnavailableClick: viewModel.showUnavailableFeature
        ) {
            AuthTitle("账号登录")

            Spacer().frame(height: 45)

            UnderlineInput(
                text: Binding(get: { viewModel.state.account }, set: viewModel.updateAccount),
                placeholder: "输入手机号或邮箱",
                keyboardType: .emailAddress,
                autoFocus: true
            )

            Spacer().frame(height: 16)

            UnderlineInput(
                text: Binding(get: { viewModel.state.password }, set: viewModel.updatePassword),
                placeholder: "密码",
                isPassword: true
            )

            Spacer().frame(height: 59)

            AgreementRow(
                accepted: viewModel.acceptedTerms,
                onToggle: viewModel.toggleTerms,
                onPrivacyClick: viewModel.openPrivacyPolicy,
                onServiceTermsClick: viewModel.openServiceTerms
            )

            Spacer().frame(height: 12)

            CorosFilledButton(
                text: "登录",
                color: corosButtonRed,
                enabled: viewModel.canSubmitLogin,
                isLoading: viewModel.state.isLoading,
                action: { viewModel.submitLogin() }
            )

            ErrorText(viewModel.visibleError)

            Button(action: viewModel.showUnavailableFeature) {
                Text("忘记密码?")
                    .foregroundStyle(corosMuted)
                    .font(.system(size: 14))
                    .padding(.top, 16)
            }
            .buttonStyle(.plain)

            Spacer(minLength: 40)

            ThirdPartyArea(onUnavailableClick: viewModel.showUnavailableFeature)

            Text("V4.8.1.14")
                .foregroundStyle(corosMuted)
                .font(.system(size: 16))
                .frame(maxWidth: .infinity)
                .padding(.top, 22)
                .padding(.bottom, 12)
        }
    }

    private var phoneRegisterPage: some View {
        AuthBlackPage(
            onBack: viewModel.backToEntrance,
            showFeedback: true,
            onUnavailableClick: viewModel.showUnavailableFeature
        ) {
            AuthTitle("手机号注册")

            Spacer().frame(height: 60)

            PhoneInput(
                text: Binding(get: { viewModel.state.account }, set: viewModel.updatePhone),
                autoFocus: true
            )

            Spacer().frame(height: 44)

            AgreementRow(
                accepted: viewModel.acceptedTerms,
                onToggle: viewModel.toggleTerms,
                onPrivacyClick: viewModel.openPrivacyPolicy,
                onServiceTermsClick: viewModel.openServiceTerms
            )

            Spacer().frame(height: 28)

            CorosFilledButton(
                text: "发送验证码",
                color: corosButtonRed,
                enabled: viewModel.canRequestPhoneCode,
                isLoading: viewModel.state.isLoading,
                action: { viewModel.requestPhoneVerifyCode() }
            )

            ErrorText(viewModel.visibleError)

            Button(action: viewModel.showEmailRegister) {
                Text("邮箱注册")
                    .foregroundStyle(corosRed)
                    .font(.system(size: 18))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 26)
            }
            .buttonStyle(.plain)

            Spacer(minLength: 80)
        }
    }

    private var emailRegisterPage: some View {
        AuthBlackPage(
            onBack: viewModel.backToEntrance,
            showFeedback: true,
            onUnavailableClick: viewModel.showUnavailableFeature
        ) {
            AuthTitle("邮箱注册")

            Spacer().frame(height: 60)

            UnderlineInput(
                text: Binding(get: { viewModel.emailInput }, set: viewModel.updateEmail),
                placeholder: "请输入邮箱",
                keyboardType: .emailAddress,
                autoFocus: true
            )

            Spacer().frame(height: 44)

            AgreementRow(
                accepted: viewModel.acceptedTerms,
                onToggle: viewModel.toggleTerms,
                onPrivacyClick: viewModel.openPrivacyPolicy,
                onServiceTermsClick: viewModel.openServiceTerms
            )

            Spacer().frame(height: 28)

            CorosFilledButton(
                text: "发送验证码",
                color: corosButtonRed,
                enabled: viewModel.canRequestEmailCode,
                isLoading: viewModel.state.isLoading,
                action: { viewModel.requestEmailVerifyCode() }
            )

            ErrorText(viewModel.visibleError)

            Button(action: viewModel.showPhoneRegisterFromEmail) {
                Text("手机号注册")
                    .foregroundStyle(corosRed)
                    .font(.system(size: 18))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 26)
            }
            .buttonStyle(.plain)

            Spacer(minLength: 80)
        }
    }

    private var passwordSetupPage: some View {
        AuthBlackPage(onBack: viewModel.backToVerifyCode, showFeedback: false) {
            AuthTitle("设置登录密码")

            Spacer().frame(height: 60)

            UnderlineInput(
                text: Binding(get: { viewModel.setupPassword }, set: viewModel.updateSetupPassword),
                placeholder: "输入新的密码",
                isPassword: true,
                autoFocus: true
            )

            Spacer().frame(height: 48)

            UnderlineInput(
                text: Binding(get: { viewModel.confirmPassword }, set: viewModel.updateConfirmPassword),
                placeholder: "再次输入密码",
                isPassword: true
            )

            Spacer().frame(height: 8)

            Text("6-20位必须包含字母和数字")
                .foregroundStyle(Color(red: 216 / 255, green: 216 / 255, blue: 221 / 255))
                .font(.system(size: 14))

            Spacer().frame(height: 80)

            CorosFilledButton(
                text: "注册",
                color: corosButtonRed,
                enabled: viewModel.canRegisterWithPassword,
                isLoading: viewModel.state.isLoading,
                action: viewModel.register
            )

            ErrorText(viewModel.visibleError)

            Spacer(minLength: 80)
        }
    }

    private var signedInPage: some View {
        AuthBlackPage(onBack: {}, showFeedback: false) {
            CorosLogo()
                .frame(maxWidth: .infinity)
                .padding(.top, 80)

            Spacer().frame(height: 96)

            Text("欢迎使用 COROS\n\(viewModel.state.currentSession?.account ?? "")")
                .foregroundStyle(.white)
                .font(.system(size: 26))
                .lineSpacing(10)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            Spacer().frame(height: 48)

            CorosFilledButton(text: "退出登录", color: corosButtonRed, action: viewModel.logout)
        }
    }
}

private struct VerifyCodeContent: View {
    @ObservedObject var viewModel: LoginViewModel
    @State private var countdown = 60
    @State private var resendLoading = false
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            AuthBlackPage(
                onBack: viewModel.backToRegistrationSource,
                showFeedback: false,
                onUnavailableClick: viewModel.showUnavailableFeature
            ) {
                AuthTitle("输入验证码")

                Spacer().frame(height: 14)

                Text(viewModel.verifyCodeMessage)
                    .foregroundStyle(Color(red: 216 / 255, green: 216 / 255, blue: 221 / 255))
                    .font(.system(size: 16))
                    .lineSpacing(4)

                Spacer().frame(height: 56)

                CodeBoxes(
                    code: Binding(get: { viewModel.codeInput }, set: viewModel.updateCode),
                    hasError: !(viewModel.visibleError ?? "").isEmpty
                )
                .onChange(of: viewModel.codeInput) { _, newValue in
                    guard newValue.count == 4 else {
                        return
                    }
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 120_000_000)
                        if viewModel.codeInput == newValue {
                            viewModel.submitCodeIfComplete()
                        }
                    }
                }

                ErrorText(viewModel.visibleError)

                Spacer().frame(height: 58)

                HStack(alignment: .center, spacing: 0) {
                    if countdown > 0 {
                        Text("重新发送")
                            .foregroundStyle(corosMuted)
                        Text("（\(countdown)s）")
                            .foregroundStyle(corosRed)
                    } else {
                        Button(action: resendCode) {
                            Text("获取验证码")
                                .foregroundStyle(corosRed)
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()

                    Button(action: viewModel.showUnavailableFeature) {
                        Text("收不到验证码?")
                            .foregroundStyle(corosMuted)
                    }
                    .buttonStyle(.plain)
                }
                .font(.system(size: 16))

                Spacer(minLength: 80)
            }

            if resendLoading {
                BlockingLoadingOverlay()
            }
        }
        .onReceive(timer) { _ in
            if countdown > 0 {
                countdown -= 1
            }
        }
        .onAppear {
            countdown = 60
        }
    }

    private func resendCode() {
        Task { @MainActor in
            resendLoading = true
            try? await Task.sleep(nanoseconds: 650_000_000)
            if viewModel.resendVerifyCode() {
                countdown = 60
            }
            resendLoading = false
        }
    }
}

private struct AuthTitle: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .foregroundStyle(.white)
            .font(.system(size: 32, weight: .light))
            .padding(.top, authTitleTopPadding)
    }
}

private struct AuthBlackPage<Content: View>: View {
    let onBack: () -> Void
    let showFeedback: Bool
    var onUnavailableClick: () -> Void = {}
    @ViewBuilder let content: () -> Content

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Button(action: onBack) {
                            Text("‹")
                                .foregroundStyle(.white)
                                .font(.system(size: 44, weight: .light))
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        if showFeedback {
                            Button(action: onUnavailableClick) {
                                Text("◔ 建议&反馈")
                                    .foregroundStyle(corosMuted)
                                    .font(.system(size: 14))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(height: 52)

                    content()
                }
                .frame(
                    maxWidth: .infinity,
                    minHeight: max(812, proxy.size.height),
                    alignment: .topLeading
                )
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)
            .background(Color.black.ignoresSafeArea())
        }
    }
}

private struct CorosLogo: View {
    var body: some View {
        Image("coros_logo")
            .resizable()
            .scaledToFit()
            .frame(width: 260, height: 48)
            .frame(maxWidth: .infinity)
    }
}

private struct UnderlineInput: View {
    @Binding var text: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    var isPassword: Bool = false
    var autoFocus: Bool = false
    @State private var passwordVisible = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ZStack(alignment: .leading) {
                    if text.isEmpty {
                        Text(placeholder)
                            .foregroundStyle(corosMuted)
                            .font(.system(size: 17))
                    }

                    if isPassword && !passwordVisible {
                        SecureField("", text: $text)
                            .textContentType(.password)
                            .focused($isFocused)
                    } else {
                        TextField("", text: $text)
                            .keyboardType(keyboardType)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($isFocused)
                    }
                }
                .foregroundStyle(.white)
                .font(.system(size: 17))
                .tint(corosRed)
                .frame(height: 47)

                ClearInputButton(
                    visible: !text.isEmpty,
                    onClick: {
                        text = ""
                    }
                )

                if isPassword && !text.isEmpty {
                    Spacer().frame(width: 6)
                    PasswordVisibilityButton(
                        passwordVisible: passwordVisible,
                        onClick: {
                            passwordVisible.toggle()
                        }
                    )
                }
            }
            .frame(height: 48)

            Rectangle()
                .fill(corosLine)
                .frame(height: 1)
        }
        .onAppear {
            if autoFocus {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    isFocused = true
                }
            }
        }
    }
}

private struct PhoneInput: View {
    @Binding var text: String
    var autoFocus: Bool = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 24) {
                Text("+86")
                    .foregroundStyle(.white)
                    .font(.system(size: 17))

                ZStack(alignment: .leading) {
                    if text.isEmpty {
                        Text("输入手机号")
                            .foregroundStyle(corosMuted)
                            .font(.system(size: 17))
                    }

                    TextField("", text: $text)
                        .keyboardType(.phonePad)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isFocused)
                        .foregroundStyle(.white)
                        .font(.system(size: 17))
                        .tint(corosRed)
                }

                ClearInputButton(
                    visible: !text.isEmpty,
                    onClick: {
                        text = ""
                    }
                )
            }
            .frame(height: 48)

            Rectangle()
                .fill(corosLine)
                .frame(height: 1)
        }
        .onAppear {
            if autoFocus {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    isFocused = true
                }
            }
        }
    }
}

private struct AgreementRow: View {
    let accepted: Bool
    let onToggle: () -> Void
    let onPrivacyClick: () -> Void
    let onServiceTermsClick: () -> Void

    private let checkSize: CGFloat = 14
    private let checkTouchSize: CGFloat = 24
    private let textFontSize: CGFloat = 14

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Button(action: onToggle) {
                AgreementCheck(accepted: accepted)
                    .frame(width: 14, height: 14)
            }
            .buttonStyle(.plain)
            .frame(width: 24, height: 24, alignment: .top)
            .padding(.top, 2)

            Text(agreementText)
                .font(.system(size: 14))
                .lineSpacing(6)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .environment(\.openURL, OpenURLAction { url in
                    switch url.host {
                    case "privacy":
                        onPrivacyClick()
                        return .handled
                    case "terms":
                        onServiceTermsClick()
                        return .handled
                    default:
                        return .discarded
                    }
                })

            Spacer(minLength: 0)
        }
    }

    private var agreementText: AttributedString {
        var text = AttributedString("我已阅读并同意COROS的 《隐私政策》 和 《服务条款》")
        text.foregroundColor = .white

        if let privacyRange = text.range(of: "《隐私政策》") {
            text[privacyRange].foregroundColor = corosRed
            text[privacyRange].link = URL(string: "coros-auth://privacy")
        }

        if let termsRange = text.range(of: "《服务条款》") {
            text[termsRange].foregroundColor = corosRed
            text[termsRange].link = URL(string: "coros-auth://terms")
        }

        return text
    }
}



private struct AgreementCheck: View {
    let accepted: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(accepted ? corosRed : .clear)
                .frame(width: agreementCheckVisualSize, height: agreementCheckVisualSize)
            Circle()
                .stroke(accepted ? corosRed : Color.white.opacity(0.82), lineWidth: 1)
                .frame(width: agreementCheckVisualSize, height: agreementCheckVisualSize)
            if accepted {
                Image(systemName: "checkmark")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
    }
}

private struct CorosFilledButton: View {
    let text: String
    let color: Color
    var enabled: Bool = true
    var isLoading: Bool = false
    var buttonHeight: CGFloat = 48
    var textSize: CGFloat = 18
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(text)
                        .foregroundStyle(Color.white.opacity(enabled ? 1 : 0.42))
                        .font(.system(size: textSize))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: buttonHeight)
            .background(color.opacity(enabled ? 1 : 0.45))
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

private struct CodeBoxes: View {
    @Binding var code: String
    let hasError: Bool
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            HStack(spacing: 36) {
                ForEach(0..<4, id: \.self) { index in
                    CodeBoxCell(
                        digit: codeDigit(index),
                        isActive: index == code.count && code.count < 4,
                        hasError: hasError
                    )
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fit)
                }
            }

            TextField("", text: $code)
                .keyboardType(.numberPad)
                .focused($isFocused)
                .foregroundStyle(.clear)
                .tint(.clear)
                .opacity(0.02)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isFocused = true
        }
        .onChange(of: code) { _, newValue in
            let filtered = String(newValue.filter(\.isNumber).prefix(4))
            if filtered != newValue {
                code = filtered
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                isFocused = true
            }
        }
    }

    private func codeDigit(_ index: Int) -> String? {
        guard index < code.count else {
            return nil
        }
        let stringIndex = code.index(code.startIndex, offsetBy: index)
        return String(code[stringIndex])
    }
}

private struct CodeBoxCell: View {
    let digit: String?
    let isActive: Bool
    let hasError: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isActive ? corosCodeActiveField : .black)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(hasError ? corosRed : Color(red: 58 / 255, green: 58 / 255, blue: 61 / 255), lineWidth: 2)
                )

            if let digit {
                Text(digit)
                    .foregroundStyle(.white)
                    .font(.system(size: 30))
            } else if isActive {
                BlinkingCursor()
            }
        }
    }
}

private struct BlinkingCursor: View {
    @State private var visible = true
    private let timer = Timer.publish(every: 0.53, on: .main, in: .common).autoconnect()

    var body: some View {
        Rectangle()
            .fill(corosRed)
            .frame(width: 2, height: 28)
            .opacity(visible ? 1 : 0)
            .onReceive(timer) { _ in
                visible.toggle()
            }
    }
}

private struct ClearInputButton: View {
    let visible: Bool
    let onClick: () -> Void

    var body: some View {
        Button(action: onClick) {
            ZStack {
                if visible {
                    Image("icon_delete")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .padding(4)
                }
            }
            .frame(width: 34, height: 34)
        }
        .buttonStyle(.plain)
        .opacity(visible ? 1 : 0)
        .disabled(!visible)
    }
}

private struct PasswordVisibilityButton: View {
    let passwordVisible: Bool
    let onClick: () -> Void

    var body: some View {
        Button(action: onClick) {
            Image("icon_uneye")
                .resizable()
                .scaledToFit()
                .frame(width: 34, height: 34)
                .padding(3)
                .opacity(passwordVisible ? 0.45 : 1)
        }
        .buttonStyle(.plain)
    }
}

private struct ThirdPartyArea: View {
    let onUnavailableClick: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            HStack(spacing: 12) {
                Rectangle()
                    .fill(corosLine)
                    .frame(height: 1)
                Text("第三方账号")
                    .foregroundStyle(corosMuted)
                    .font(.system(size: 14))
                    .fixedSize()
                Rectangle()
                    .fill(corosLine)
                    .frame(height: 1)
            }

            HStack(spacing: 54) {
                ThirdPartyCircle(text: "☘", onClick: onUnavailableClick)
                ThirdPartyCircle(text: "···", onClick: onUnavailableClick)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ThirdPartyCircle: View {
    let text: String
    let onClick: () -> Void

    var body: some View {
        Button(action: onClick) {
            Text(text)
                .foregroundStyle(.white)
                .font(.system(size: 20))
                .frame(width: 34, height: 34)
                .overlay(
                    Circle()
                        .stroke(Color(red: 48 / 255, green: 48 / 255, blue: 54 / 255), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct ErrorText: View {
    let message: String?

    init(_ message: String?) {
        self.message = message
    }

    var body: some View {
        if let message, !message.isEmpty {
            Text(message)
                .foregroundStyle(corosRed)
                .font(.system(size: 15))
                .padding(.top, 10)
        }
    }
}

private struct TermsConsentSheet: View {
    let onDismiss: () -> Void
    let onPrivacyClick: () -> Void
    let onServiceTermsClick: () -> Void
    let onAgree: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.78)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Button(action: onDismiss) {
                    Text("×")
                        .foregroundStyle(.white)
                        .font(.system(size: 34, weight: .light))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .buttonStyle(.plain)

                Spacer().frame(height: 12)

                Text("阅读并同意以下条款，")
                    .foregroundStyle(.white)
                    .font(.system(size: 18))
                    .multilineTextAlignment(.center)

                HStack(spacing: 0) {
                    Button(action: onPrivacyClick) {
                        Text("《隐私政策》")
                            .foregroundStyle(corosRed)
                    }
                    .buttonStyle(.plain)

                    Text(" 和 ")
                        .foregroundStyle(.white)

                    Button(action: onServiceTermsClick) {
                        Text("《服务条款》")
                            .foregroundStyle(corosRed)
                    }
                    .buttonStyle(.plain)
                }
                .font(.system(size: 18))
                .padding(.top, 8)

                Spacer().frame(height: 42)

                CorosFilledButton(
                    text: "同意并继续",
                    color: corosRed,
                    action: onAgree
                )
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)
            .padding(.bottom, 18)
            .background(Color(red: 26 / 255, green: 26 / 255, blue: 27 / 255))
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 12, topTrailingRadius: 12))
        }
    }
}

private struct UnavailableFeatureDialog: View {
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.62)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            VStack(spacing: 20) {
                Text("抱歉，该功能还在实现中")
                    .foregroundStyle(.white)
                    .font(.system(size: 16))
                    .multilineTextAlignment(.center)

                Button(action: onDismiss) {
                    Text("知道了")
                        .foregroundStyle(corosRed)
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            .background(Color(red: 34 / 255, green: 34 / 255, blue: 36 / 255))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, 42)
        }
    }
}

private struct BlockingLoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.72)
                .ignoresSafeArea()

            ProgressView()
                .tint(Color(red: 216 / 255, green: 216 / 255, blue: 221 / 255))
                .frame(width: 96, height: 96)
                .background(Color(red: 58 / 255, green: 58 / 255, blue: 60 / 255))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }
}

private struct LegalDocumentPage: View {
    let title: String
    let paragraphs: [LegalParagraph]
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Button(action: onBack) {
                    Text("‹")
                        .foregroundStyle(.white)
                        .font(.system(size: 44, weight: .light))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)

                Text(title)
                    .foregroundStyle(.white)
                    .font(.system(size: 18, weight: .bold))
            }
            .frame(height: 52)
            .padding(.horizontal, 20)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(paragraphs.indices, id: \.self) { index in
                        LegalParagraphText(paragraph: paragraphs[index])
                        if index != paragraphs.indices.last {
                            Spacer().frame(height: paragraphs[index].isHeading ? 8 : 12)
                        }
                    }
                }
                .padding(.top, 58)
                .padding(.bottom, 32)
                .padding(.horizontal, 20)
                .padding(.trailing, 12)
            }
            .scrollIndicators(.visible)
        }
        .background(Color.black.ignoresSafeArea())
    }
}

private struct LegalParagraphText: View {
    let paragraph: LegalParagraph

    var body: some View {
        Text(attributedText)
            .font(.system(size: paragraph.isHeading ? 19 : 18, weight: paragraph.isHeading ? .bold : .regular))
            .lineSpacing(paragraph.isHeading ? 4 : 6)
    }

    private var attributedText: AttributedString {
        var text = AttributedString(paragraph.text)
        text.foregroundColor = paragraph.isHeading ? .white : corosLegalText
        for highlight in paragraph.highlights where !highlight.isEmpty {
            var searchStart = text.startIndex
            while let range = text[searchStart...].range(of: highlight) {
                text[range].foregroundColor = .white
                text[range].font = .system(size: paragraph.isHeading ? 19 : 18, weight: .bold)
                searchStart = range.upperBound
                if searchStart == text.endIndex {
                    break
                }
            }
        }
        return text
    }
}

private struct LegalParagraph {
    let text: String
    var highlights: [String] = []
    var isHeading: Bool = false
}

#if canImport(UIKit)
private struct LoopingVideoBackground: UIViewRepresentable {
    let videoName: String

    func makeUIView(context: Context) -> LoopingVideoView {
        let view = LoopingVideoView()
        view.configure(videoName: videoName)
        return view
    }

    func updateUIView(_ uiView: LoopingVideoView, context: Context) {
        uiView.play()
    }
}

private final class LoopingVideoView: UIView {
    private let playerLayer = AVPlayerLayer()
    private var queuePlayer: AVQueuePlayer?
    private var playerLooper: AVPlayerLooper?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }

    func configure(videoName: String) {
        guard queuePlayer == nil,
              let url = Bundle.main.url(forResource: videoName, withExtension: "mp4") else {
            return
        }

        let item = AVPlayerItem(url: url)
        let player = AVQueuePlayer()
        player.isMuted = true
        player.actionAtItemEnd = .none
        playerLayer.player = player
        playerLooper = AVPlayerLooper(player: player, templateItem: item)
        queuePlayer = player
        player.play()
    }

    func play() {
        queuePlayer?.play()
    }
}
#else
private struct LoopingVideoBackground: View {
    let videoName: String

    var body: some View {
        Color(red: 17 / 255, green: 17 / 255, blue: 17 / 255)
    }
}
#endif

private let privacyPolicyParagraphs = [
    LegalParagraph(text: "最后更新时间：2025年12月24日"),
    LegalParagraph(text: "导言"),
    LegalParagraph(
        text: "广东高驰运动科技有限公司（以下简称\"COROS\"或\"我们\"）非常重视用户（或\"您\"）的隐私和个人信息保护，我们将按照法律法规的要求，尽力保护您的个人信息安全。",
        highlights: ["COROS", "我们", "您", "隐私和个人信息保护", "个人信息安全"]
    ),
    LegalParagraph(
        text: "本个人信息保护政策（以下简称\"本政策\"）适用于您通过 COROS 网站、COROS 移动应用程序（\"COROS App\"）及其他 COROS 产品和服务使用我们的产品与服务。",
        highlights: ["本政策", "COROS App", "COROS 产品和服务"]
    ),
    LegalParagraph(
        text: "本政策解释了我们如何收集、存储、使用、提供、删除您的信息，以及您享有的权利。请您认真阅读并充分理解本政策，特别是涉及个人敏感信息、系统权限、第三方共享和账号注销的条款。",
        highlights: ["收集、存储、使用、提供、删除", "您享有的权利", "认真阅读并充分理解本政策", "个人敏感信息、系统权限、第三方共享和账号注销"]
    ),
    LegalParagraph(text: "一、我们如何收集和使用您的个人信息", isHeading: true),
    LegalParagraph(
        text: "1. 我们将逐一说明所收集的个人信息类型及其对应用途，以便您了解每一项功能所处理的具体个人信息类别、处理目的及处理方式。",
        highlights: ["个人信息类型", "处理目的及处理方式"]
    ),
    LegalParagraph(
        text: "2. 为了向您提供运动记录、设备连接、账号登录、安全保障和客户支持等服务，我们可能会在获得授权后处理账号信息、设备信息、运动数据、网络状态以及必要的日志信息。",
        highlights: ["获得授权后", "账号信息、设备信息、运动数据、网络状态", "必要的日志信息"]
    ),
    LegalParagraph(text: "二、我们如何提供和共享您的个人信息", isHeading: true),
    LegalParagraph(
        text: "除非经过您的同意，我们不会主动将您的个人信息提供至 COROS 以外的第三方。如确需对外提供，或您需要我们向任何第三方提供信息时，我们会直接征得您的同意，但法律法规另有规定的除外。",
        highlights: ["除非经过您的同意", "不会主动将您的个人信息提供至 COROS 以外的第三方", "直接征得您的同意"]
    ),
    LegalParagraph(text: "三、您如何管理自己的个人信息", isHeading: true),
    LegalParagraph(
        text: "您可以通过本政策所列途径查询、更新、复制、删除您的个人信息，也可以撤回同意、注销账号、投诉举报。我们会在符合法律法规要求的期限内处理您的请求。",
        highlights: ["查询、更新、复制、删除", "撤回同意、注销账号、投诉举报"]
    ),
    LegalParagraph(text: "四、系统权限和敏感信息", isHeading: true),
    LegalParagraph(
        text: "为了依据本政策收集您的信息、向您提供服务、优化我们的服务并保障您的账号安全，我们可能需要向您索取相关系统权限；其中位置等敏感权限不会默认开启，只有在您明确同意后，我们才会在您同意的范围内调用或使用。",
        highlights: ["保障您的账号安全", "系统权限", "敏感权限不会默认开启", "您明确同意后"]
    ),
    LegalParagraph(text: "五、本政策如何更新", isHeading: true),
    LegalParagraph(
        text: "我们会持续保护您的个人信息，并根据产品功能、法律法规或监管要求更新本政策。若本政策发生重大变化，我们会以合理方式向您提示。",
        highlights: ["持续保护您的个人信息", "本政策发生重大变化", "合理方式向您提示"]
    )
]

private let serviceTermsParagraphs = [
    LegalParagraph(text: "最后更新日期：2023年9月4日"),
    LegalParagraph(text: "特别提示："),
    LegalParagraph(
        text: "本《COROS 用户协议》（以下简称\"本协议\"）是您（或\"用户\"）与广东高驰运动科技股份有限公司（以下简称\"COROS\"或\"我们\"）签订的，就使用 COROS 网站、COROS 移动应用程序（\"COROS App\"）及其他 COROS 产品和服务（统称为\"COROS产品和服务\"）等事宜订立的协议。",
        highlights: ["本协议", "用户", "COROS", "我们", "COROS App", "COROS产品和服务"]
    ),
    LegalParagraph(
        text: "请您认真阅读并充分理解本协议，特别是以加粗形式提示您注意的免除或减轻 COROS 责任的条款。您有权选择同意或不同意本协议，除非您接受本协议的全部条款，否则您无权注册、登录或使用 COROS 产品和服务。",
        highlights: ["认真阅读并充分理解本协议", "加粗形式提示您注意的免除或减轻 COROS 责任的条款", "除非您接受本协议的全部条款，否则您无权注册、登录或使用 COROS 产品和服务"]
    ),
    LegalParagraph(
        text: "一旦您点击\"本人已阅读并同意接受本协议的全部内容\"并完成注册流程，即视为您已充分阅读、理解并在您点击接受当时接受本协议的所有内容，本协议即在您与 COROS 之间成立并发生法律效力，您同意接受本协议各项条款的约束。",
        highlights: ["一旦您点击\"本人已阅读并同意接受本协议的全部内容\"并完成注册流程", "本协议即在您与 COROS 之间成立并发生法律效力", "您同意接受本协议各项条款的约束"]
    ),
    LegalParagraph(
        text: "请注意，本协议内容包括所有我们已经发布或未来可能变更或发布的各类协议、规则、公告或通知。除非法律规定或本协议有相反规定，前述内容一经公布即自动生效并成为本协议不可分割的组成部分，无需另行通知。",
        highlights: ["已经发布或未来可能变更或发布", "协议、规则、公告或通知", "一经公布即自动生效"]
    ),
    LegalParagraph(
        text: "如您不同意本协议的内容或在您同意本协议之后我们发布生效的任何协议、规则、公告或通知，您应立即取消登录、注销账号、停止使用 COROS 产品和服务；如您继续使用，则视为您始终同意本协议的所有内容并同意遵守。",
        highlights: ["如您不同意本协议的内容或在您同意本协议之后我们发布生效的任何协议、规则、公告或通知", "您应立即取消登录、注销账号、停止使用 COROS 产品和服务", "如您继续使用，则视为您始终同意本协议的所有内容并同意遵守"]
    ),
    LegalParagraph(text: "一、服务范围", isHeading: true),
    LegalParagraph(
        text: "1. 我们就使用 COROS 产品和服务给予您一项个人的、不可转让的、不可转授权的、非独占性的、可撤销的许可。",
        highlights: ["个人的、不可转让的、不可转授权的、非独占性的、可撤销的"]
    ),
    LegalParagraph(
        text: "2. 您应按照法律法规、本协议以及 COROS 发布的规则使用产品和服务，不得利用服务从事违法违规或侵犯他人合法权益的行为。",
        highlights: ["法律法规、本协议以及 COROS 发布的规则", "不得利用服务从事违法违规或侵犯他人合法权益的行为"]
    ),
    LegalParagraph(
        text: "3. 我们可能根据产品运营情况对服务内容进行调整、更新或优化，并会在合理范围内向您提供必要提示。",
        highlights: ["调整、更新或优化", "必要提示"]
    ),
    LegalParagraph(text: "二、账号与安全", isHeading: true),
    LegalParagraph(
        text: "1. 您应对您账号下的所有行为负责，并妥善保管账号、密码和验证码等信息。",
        highlights: ["您账号下的所有行为负责", "妥善保管账号、密码和验证码"]
    ),
    LegalParagraph(
        text: "2. 如发现账号存在异常使用、被盗用或其他安全风险，请及时联系我们处理。",
        highlights: ["异常使用、被盗用或其他安全风险", "及时联系我们处理"]
    ),
    LegalParagraph(text: "三、协议变更", isHeading: true),
    LegalParagraph(
        text: "我们可能根据法律法规变化、业务调整或服务优化需要修改本协议。更新后的协议公布后即生效；如您继续使用 COROS 产品和服务，视为您同意接受更新后的协议。",
        highlights: ["修改本协议", "公布后即生效", "继续使用 COROS 产品和服务，视为您同意接受更新后的协议"]
    )
]

struct LoginViewPreview: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
