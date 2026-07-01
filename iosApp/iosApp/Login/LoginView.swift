import SwiftUI
#if canImport(UIKit)
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
            case .verifyCode:
                verifyCodePage
            case .passwordSetup:
                passwordSetupPage
            case .signedIn:
                signedInPage
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
        VStack {
            CorosLogo()
                .padding(.top, 84)

            Spacer()

            VStack(spacing: 28) {
                CorosFilledButton(text: "注册", color: corosRed, action: viewModel.showPhoneRegister)
                CorosFilledButton(
                    text: "登录",
                    color: Color.white.opacity(0.18),
                    action: viewModel.showLogin
                )
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 82)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 17 / 255, green: 17 / 255, blue: 17 / 255))
    }

    private var loginPage: some View {
        AuthBlackPage(onBack: viewModel.backToEntrance, showFeedback: true) {
            Text("账号登录")
                .foregroundStyle(.white)
                .font(.system(size: 38, weight: .light))
                .padding(.top, 56)

            Spacer().frame(height: 76)

            UnderlineInput(
                text: Binding(get: { viewModel.state.account }, set: viewModel.updateAccount),
                placeholder: "输入手机号或邮箱",
                keyboardType: .emailAddress
            )

            Spacer().frame(height: 28)

            UnderlineInput(
                text: Binding(get: { viewModel.state.password }, set: viewModel.updatePassword),
                placeholder: "密码",
                isSecure: true
            )

            Spacer().frame(height: 82)

            AgreementRow(accepted: viewModel.acceptedTerms, action: viewModel.toggleTerms)

            Spacer().frame(height: 22)

            CorosFilledButton(
                text: viewModel.state.isLoading ? "登录中" : "登录",
                color: corosButtonRed,
                enabled: viewModel.state.account.isEmpty == false
                    && viewModel.state.password.count >= 6
                    && viewModel.acceptedTerms
                    && !viewModel.state.isLoading,
                action: viewModel.login
            )

            ErrorText(viewModel.visibleError)

            Spacer().frame(height: 24)

            Text("忘记密码?")
                .foregroundStyle(corosMuted)
                .font(.system(size: 20))

            Spacer(minLength: 44)
            ThirdPartyArea()

            Text("V4.8.1.14")
                .foregroundStyle(corosMuted)
                .font(.system(size: 20))
                .frame(maxWidth: .infinity)
                .padding(.top, 22)
                .padding(.bottom, 12)
        }
    }

    private var phoneRegisterPage: some View {
        AuthBlackPage(onBack: viewModel.backToEntrance, showFeedback: true) {
            Text("手机号注册")
                .foregroundStyle(.white)
                .font(.system(size: 38, weight: .light))
                .padding(.top, 56)

            Spacer().frame(height: 78)

            PhoneInput(
                text: Binding(get: { viewModel.state.account }, set: viewModel.updatePhone)
            )

            Spacer().frame(height: 66)

            AgreementRow(accepted: viewModel.acceptedTerms, action: viewModel.toggleTerms)

            Spacer().frame(height: 42)

            CorosFilledButton(
                text: "发送验证码",
                color: corosButtonRed,
                enabled: viewModel.state.account.count == 11 && viewModel.acceptedTerms && !viewModel.state.isLoading,
                action: viewModel.sendCode
            )

            ErrorText(viewModel.visibleError)

            Button(action: viewModel.showEmailRegisterUnavailable) {
                Text("邮箱注册")
                    .foregroundStyle(corosRed)
                    .font(.system(size: 22))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 26)
            }
            .buttonStyle(.plain)

            Spacer(minLength: 80)
            HomeIndicator()
        }
    }

    private var verifyCodePage: some View {
        AuthBlackPage(onBack: viewModel.backToPhoneRegister, showFeedback: false) {
            Text("输入验证码")
                .foregroundStyle(.white)
                .font(.system(size: 38, weight: .light))
                .padding(.top, 56)

            Spacer().frame(height: 20)

            Text("验证码已发送至你的手机+86-\(viewModel.state.account)，有效期10分钟")
                .foregroundStyle(Color(red: 216 / 255, green: 216 / 255, blue: 221 / 255))
                .font(.system(size: 20))
                .lineSpacing(4)

            Spacer().frame(height: 56)

            CodeBoxes(
                code: Binding(get: { viewModel.codeInput }, set: viewModel.updateCode)
            )

            Spacer().frame(height: 58)

            HStack(spacing: 0) {
                Text("重新发送").foregroundStyle(corosMuted)
                Text("（55s）").foregroundStyle(corosRed)
            }
            .font(.system(size: 20))

            ErrorText(viewModel.visibleError)

            Spacer().frame(height: 36)

            CorosFilledButton(
                text: viewModel.state.isLoading ? "处理中" : "完成",
                color: corosButtonRed,
                enabled: !viewModel.state.isLoading,
                action: viewModel.submitCode
            )

            Spacer(minLength: 80)
            HomeIndicator()
        }
    }

    private var passwordSetupPage: some View {
        let hasLetter = viewModel.setupPassword.contains(where: \.isLetter)
        let hasDigit = viewModel.setupPassword.contains(where: \.isNumber)
        let canRegister = viewModel.setupPassword.count >= 6
            && viewModel.setupPassword.count <= 20
            && hasLetter
            && hasDigit
            && viewModel.confirmPassword == viewModel.setupPassword
            && !viewModel.state.isLoading

        return AuthBlackPage(onBack: viewModel.backToVerifyCode, showFeedback: false) {
            Text("设置登录密码")
                .foregroundStyle(.white)
                .font(.system(size: 38, weight: .light))
                .padding(.top, 56)

            Spacer().frame(height: 82)

            UnderlineInput(
                text: Binding(get: { viewModel.setupPassword }, set: viewModel.updateSetupPassword),
                placeholder: "输入新的密码",
                isSecure: true
            )

            Spacer().frame(height: 52)

            UnderlineInput(
                text: Binding(get: { viewModel.confirmPassword }, set: viewModel.updateConfirmPassword),
                placeholder: "再次输入密码",
                isSecure: true
            )

            Spacer().frame(height: 8)

            Text("6-20位必须包含字母和数字")
                .foregroundStyle(Color(red: 216 / 255, green: 216 / 255, blue: 221 / 255))
                .font(.system(size: 16))

            Spacer().frame(height: 80)

            CorosFilledButton(
                text: viewModel.state.isLoading ? "注册中" : "注册",
                color: corosButtonRed,
                enabled: canRegister,
                action: viewModel.register
            )

            ErrorText(viewModel.visibleError)

            Spacer(minLength: 80)
            HomeIndicator()
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

private struct AuthBlackPage<Content: View>: View {
    let onBack: () -> Void
    let showFeedback: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
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
                        Text("◔ 建议&反馈")
                            .foregroundStyle(corosMuted)
                            .font(.system(size: 18))
                    }
                }
                .frame(height: 52)

                content()
            }
            .frame(maxWidth: .infinity, minHeight: 812, alignment: .topLeading)
            .padding(.horizontal, 30)
        }
        .background(Color.black)
    }
}

private struct CorosLogo: View {
    var body: some View {
        Image("coros_logo")
            .resizable()
            .scaledToFit()
            .frame(width: 260, height: 64)
            .frame(maxWidth: .infinity)
    }
}

private struct UnderlineInput: View {
    @Binding var text: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundStyle(corosMuted)
                        .font(.system(size: 21))
                }

                if isSecure {
                    SecureField("", text: $text)
                        .textContentType(.password)
                } else {
                    TextField("", text: $text)
                        .keyboardType(keyboardType)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            .foregroundStyle(.white)
            .font(.system(size: 21))
            .tint(corosRed)
            .frame(height: 53)

            Rectangle()
                .fill(corosLine)
                .frame(height: 1)
        }
    }
}

private struct PhoneInput: View {
    @Binding var text: String

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 24) {
                Text("+86")
                    .foregroundStyle(.white)
                    .font(.system(size: 22))

                ZStack(alignment: .leading) {
                    if text.isEmpty {
                        Text("输入手机号")
                            .foregroundStyle(corosMuted)
                    }
                    TextField("", text: $text)
                        .keyboardType(.phonePad)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .foregroundStyle(.white)
                        .tint(corosRed)
                }
                .font(.system(size: 22))
            }
            .frame(height: 53)

            Rectangle()
                .fill(corosLine)
                .frame(height: 1)
        }
    }
}

private struct AgreementRow: View {
    let accepted: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 6) {
                ZStack {
                    Circle()
                        .fill(accepted ? corosRed : .clear)
                    Circle()
                        .stroke(.white, lineWidth: 1)
                    if accepted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 18, height: 18)
                .padding(.top, 6)

                Text(agreementText)
                .font(.system(size: 20))
                .lineSpacing(6)
                .multilineTextAlignment(.leading)

                Spacer(minLength: 0)
            }
        }
        .buttonStyle(.plain)
    }

    private var agreementText: AttributedString {
        var text = AttributedString("我已阅读并同意COROS的 《隐私政策》 和 《服务条款》")
        text.foregroundColor = .white
        if let privacyRange = text.range(of: "《隐私政策》") {
            text[privacyRange].foregroundColor = corosRed
        }
        if let termsRange = text.range(of: "《服务条款》") {
            text[termsRange].foregroundColor = corosRed
        }
        return text
    }
}

private struct CorosFilledButton: View {
    let text: String
    let color: Color
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .foregroundStyle(.white)
                .font(.system(size: 24))
                .frame(maxWidth: .infinity)
                .frame(height: 66)
                .background(color.opacity(enabled ? 1 : 0.45))
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

private struct CodeBoxes: View {
    @Binding var code: String
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            HStack(spacing: 28) {
                ForEach(0..<4, id: \.self) { index in
                    CodeBoxCell(
                        digit: codeDigit(index),
                        showsCursor: index == code.count && isFocused,
                        cursorColor: corosRed
                    )
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
            code = String(newValue.filter(\.isNumber).prefix(4))
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
    let showsCursor: Bool
    let cursorColor: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(corosField)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color(red: 58 / 255, green: 58 / 255, blue: 61 / 255), lineWidth: 2)
                )

            if let digit {
                Text(digit)
                    .foregroundStyle(.white)
                    .font(.system(size: 30))
            } else if showsCursor {
                Rectangle()
                    .fill(cursorColor)
                    .frame(width: 2, height: 28)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

private struct ThirdPartyArea: View {
    var body: some View {
        VStack(spacing: 28) {
            HStack(spacing: 12) {
                Rectangle().fill(corosLine).frame(width: 140, height: 1)
                Text("第三方账号")
                    .foregroundStyle(corosMuted)
                    .font(.system(size: 20))
                Rectangle().fill(corosLine).frame(width: 140, height: 1)
            }

            HStack(spacing: 54) {
                ThirdPartyCircle(text: "☘")
                ThirdPartyCircle(text: "···")
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ThirdPartyCircle: View {
    let text: String

    var body: some View {
        Text(text)
            .foregroundStyle(.white)
            .font(.system(size: 24))
            .frame(width: 48, height: 48)
            .overlay(Circle().stroke(Color(red: 48 / 255, green: 48 / 255, blue: 54 / 255), lineWidth: 1))
    }
}

private struct HomeIndicator: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(.white)
            .frame(width: 150, height: 5)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 14)
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

struct LoginViewPreview: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
