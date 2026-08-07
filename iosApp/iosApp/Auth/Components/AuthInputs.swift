import SwiftUI

struct UnderlineInput: View {
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

                ClearInputButton(visible: !text.isEmpty, onClick: { text = "" })
                if isPassword && !text.isEmpty {
                    Spacer().frame(width: 6)
                    PasswordVisibilityButton(passwordVisible: passwordVisible, onClick: { passwordVisible.toggle() })
                }
            }
            .frame(height: 48)
            Rectangle().fill(corosLine).frame(height: 1)
        }
        .onAppear {
            if autoFocus {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { isFocused = true }
            }
        }
    }
}

struct PhoneInput: View {
    @Binding var text: String
    var autoFocus: Bool = false
    @FocusState private var isFocused: Bool
    @State private var displayText: String = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 24) {
                Text("+86").foregroundStyle(.white).font(.system(size: 17))
                ZStack(alignment: .leading) {
                    if displayText.isEmpty {
                        Text(appLocalized("auth_phone_placeholder")).foregroundStyle(corosMuted).font(.system(size: 17))
                    }
                    TextField("", text: $displayText)
                        .keyboardType(.phonePad)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isFocused)
                        .foregroundStyle(.white)
                        .font(.system(size: 17))
                        .tint(corosRed)
                        .onChange(of: displayText) { _, newValue in
                            let filtered = String(newValue.filter { $0.isNumber }.prefix(11))
                            if filtered != newValue {
                                displayText = filtered
                            }
                            text = filtered
                        }
                }
                ClearInputButton(visible: !displayText.isEmpty, onClick: { displayText = ""; text = "" })
            }
            .frame(height: 48)
            Rectangle().fill(corosLine).frame(height: 1)
        }
        .onAppear {
            displayText = text
            if autoFocus {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { isFocused = true }
            }
        }
    }
}

struct DisabledUnderlineValue: View {
    let value: String
    let placeholder: String

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text(value.isEmpty ? placeholder : value)
                    .foregroundStyle(value.isEmpty ? corosMuted : AppColors.Auth.placeholderText)
                    .font(.system(size: 17))
                Spacer(minLength: 0)
            }
            .frame(height: 48)
            Rectangle().fill(corosLine).frame(height: 1)
        }
        .contentShape(Rectangle())
    }
}

struct AgreementRow: View {
    let accepted: Bool
    let onToggle: () -> Void
    let onPrivacyClick: () -> Void
    let onServiceTermsClick: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Button(action: onToggle) {
                AgreementCheck(accepted: accepted).frame(width: 14, height: 14)
            }
            .buttonStyle(.plain)
            .frame(width: 24, height: 24, alignment: .top)
            .padding(.top, 2)
            Text(agreementText)
                .font(.system(size: 14)).lineSpacing(6).multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .environment(\.openURL, OpenURLAction { url in
                    switch url.host {
                    case "privacy": onPrivacyClick(); return .handled
                    case "terms": onServiceTermsClick(); return .handled
                    default: return .discarded
                    }
                })
            Spacer(minLength: 0)
        }
    }

    private var agreementText: AttributedString {
        let privacy = appLocalized("auth_privacy_policy_link")
        let terms = appLocalized("auth_service_terms_link")
        let content = appLocalized("auth_terms_inline_prefix") + privacy + appLocalized("auth_terms_joiner") + terms
        var text = AttributedString(content)
        text.foregroundColor = .white
        if let privacyRange = text.range(of: privacy) {
            text[privacyRange].foregroundColor = corosRed
            text[privacyRange].link = URL(string: "coros-auth://privacy")
        }
        if let termsRange = text.range(of: terms) {
            text[termsRange].foregroundColor = corosRed
            text[termsRange].link = URL(string: "coros-auth://terms")
        }
        return text
    }
}

struct AgreementCheck: View {
    let accepted: Bool
    var body: some View {
        ZStack {
            Circle().fill(accepted ? corosRed : .clear).frame(width: agreementCheckVisualSize, height: agreementCheckVisualSize)
            Circle().stroke(accepted ? corosRed : AppColors.Auth.checkboxBorder, lineWidth: 1).frame(width: agreementCheckVisualSize, height: agreementCheckVisualSize)
            if accepted { Image(systemName: "checkmark").font(.system(size: 7, weight: .bold)).foregroundStyle(.white) }
        }
    }
}

struct CorosFilledButton: View {
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
                if isLoading { ProgressView().tint(.white) }
                else { Text(text).foregroundStyle(enabled ? AppColors.Core.white : AppColors.Auth.disabledText).font(.system(size: textSize)) }
            }
            .frame(maxWidth: .infinity).frame(height: buttonHeight)
            .background(color.opacity(enabled ? 1 : 0.45))
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
        .buttonStyle(.plain).disabled(!enabled)
    }
}

struct CodeBoxes: View {
    @Binding var code: String
    let hasError: Bool
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            HStack(spacing: 36) {
                ForEach(0..<4, id: \.self) { index in
                    CodeBoxCell(digit: codeDigit(index), isActive: index == code.count && code.count < 4, hasError: hasError)
                        .frame(maxWidth: .infinity).aspectRatio(1, contentMode: .fit)
                }
            }
            TextField("", text: $code)
                .keyboardType(.numberPad).focused($isFocused)
                .foregroundStyle(.clear).tint(.clear).opacity(0.02)
        }
        .contentShape(Rectangle())
        .onTapGesture { isFocused = true }
        .onChange(of: code) { _, newValue in
            let filtered = String(newValue.filter(\.isNumber).prefix(4))
            if filtered != newValue { code = filtered }
        }
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { isFocused = true } }
    }

    private func codeDigit(_ index: Int) -> String? {
        guard index < code.count else { return nil }
        let stringIndex = code.index(code.startIndex, offsetBy: index)
        return String(code[stringIndex])
    }
}

struct CodeBoxCell: View {
    let digit: String?
    let isActive: Bool
    let hasError: Bool
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isActive ? corosCodeActiveField : .black)
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(hasError ? corosRed : AppColors.Auth.inputBorder, lineWidth: 2))
            if let digit { Text(digit).foregroundStyle(.white).font(.system(size: 30)) }
            else if isActive { BlinkingCursor() }
        }
    }
}

struct BlinkingCursor: View {
    @State private var visible = true
    private let timer = Timer.publish(every: 0.53, on: .main, in: .common).autoconnect()
    var body: some View {
        Rectangle()
            .fill(corosRed).frame(width: 2, height: 28)
            .opacity(visible ? 1 : 0)
            .onReceive(timer) { _ in visible.toggle() }
    }
}

struct ClearInputButton: View {
    let visible: Bool
    let onClick: () -> Void
    var body: some View {
        Button(action: onClick) {
            if visible {
                Image("icon_delete").resizable().scaledToFit()
                    .frame(width: 28, height: 28).padding(4)
            }
        }
        .buttonStyle(.plain).frame(width: 34, height: 34)
        .opacity(visible ? 1 : 0).disabled(!visible)
    }
}

struct PasswordVisibilityButton: View {
    let passwordVisible: Bool
    let onClick: () -> Void
    var body: some View {
        Button(action: onClick) {
            Image("icon_uneye").resizable().scaledToFit()
                .frame(width: 34, height: 34).padding(3)
                .opacity(passwordVisible ? 0.45 : 1)
        }
        .buttonStyle(.plain)
    }
}

#Preview("Agreement check") {
    AgreementCheck(accepted: true)
}

#Preview("Blinking cursor") {
    BlinkingCursor()
}
