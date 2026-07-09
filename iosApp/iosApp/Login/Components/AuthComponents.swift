import SwiftUI
#if canImport(UIKit)
import AVFoundation
import UIKit
#endif

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

struct AuthBlackPage<Content: View>: View {
    let onBack: () -> Void
    let showFeedback: Bool
    var showBack: Bool = true
    var onUnavailableClick: () -> Void = {}
    @ViewBuilder let content: () -> Content

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        if showBack {
                            Button(action: onBack) {
                                Text("‹")
                                    .foregroundStyle(.white)
                                    .font(.system(size: 44, weight: .light))
                            }
                            .buttonStyle(.plain)
                        }
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
                .frame(maxWidth: .infinity, minHeight: max(812, proxy.size.height), alignment: .topLeading)
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)
            .background(Color.black.ignoresSafeArea())
        }
    }
}

struct AuthTitle: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .foregroundStyle(.white)
            .font(.system(size: 32, weight: .light))
            .padding(.top, authTitleTopPadding)
    }
}

struct CorosLogo: View {
    var body: some View {
        Image("coros_logo")
            .resizable()
            .scaledToFit()
            .frame(width: 260, height: 48)
            .frame(maxWidth: .infinity)
    }
}

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
                        Text("输入手机号").foregroundStyle(corosMuted).font(.system(size: 17))
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
                    .foregroundStyle(value.isEmpty ? corosMuted : Color.white.opacity(0.55))
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

struct AgreementCheck: View {
    let accepted: Bool
    var body: some View {
        ZStack {
            Circle().fill(accepted ? corosRed : .clear).frame(width: agreementCheckVisualSize, height: agreementCheckVisualSize)
            Circle().stroke(accepted ? corosRed : Color.white.opacity(0.82), lineWidth: 1).frame(width: agreementCheckVisualSize, height: agreementCheckVisualSize)
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
                else { Text(text).foregroundStyle(Color.white.opacity(enabled ? 1 : 0.42)).font(.system(size: textSize)) }
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
                    .stroke(hasError ? corosRed : Color(red: 58 / 255, green: 58 / 255, blue: 61 / 255), lineWidth: 2))
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

struct ThirdPartyArea: View {
    let onUnavailableClick: () -> Void
    var body: some View {
        VStack(spacing: 24) {
            HStack(spacing: 12) {
                Rectangle().fill(corosLine).frame(height: 1)
                Text("第三方账号").foregroundStyle(corosMuted).font(.system(size: 14)).fixedSize()
                Rectangle().fill(corosLine).frame(height: 1)
            }
            HStack(spacing: 54) {
                ThirdPartyCircle(text: "☘", onClick: onUnavailableClick)
                ThirdPartyCircle(text: "···", onClick: onUnavailableClick)
            }
        }.frame(maxWidth: .infinity)
    }
}

struct ThirdPartyCircle: View {
    let text: String
    let onClick: () -> Void
    var body: some View {
        Button(action: onClick) {
            Text(text).foregroundStyle(.white).font(.system(size: 20))
                .frame(width: 34, height: 34)
                .overlay(Circle().stroke(Color(red: 48 / 255, green: 48 / 255, blue: 54 / 255), lineWidth: 1))
        }.buttonStyle(.plain)
    }
}

struct ErrorText: View {
    let message: String?
    init(_ message: String?) { self.message = message }
    var body: some View {
        if let message, !message.isEmpty {
            Text(message).foregroundStyle(corosRed).font(.system(size: 15)).padding(.top, 10)
        }
    }
}

struct TermsConsentSheet: View {
    let onDismiss: () -> Void
    let onPrivacyClick: () -> Void
    let onServiceTermsClick: () -> Void
    let onAgree: () -> Void
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.78).ignoresSafeArea()
            VStack(spacing: 0) {
                Button(action: onDismiss) {
                    Text("×").foregroundStyle(.white).font(.system(size: 34, weight: .light))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }.buttonStyle(.plain)
                Spacer().frame(height: 12)
                Text("阅读并同意以下条款，").foregroundStyle(.white).font(.system(size: 18)).multilineTextAlignment(.center)
                HStack(spacing: 0) {
                    Button(action: onPrivacyClick) { Text("《隐私政策》").foregroundStyle(corosRed) }.buttonStyle(.plain)
                    Text(" 和 ").foregroundStyle(.white)
                    Button(action: onServiceTermsClick) { Text("《服务条款》").foregroundStyle(corosRed) }.buttonStyle(.plain)
                }.font(.system(size: 18)).padding(.top, 8)
                Spacer().frame(height: 42)
                CorosFilledButton(text: "同意并继续", color: corosRed, action: onAgree)
            }
            .padding(.horizontal, 22).padding(.top, 18).padding(.bottom, 18)
            .background(Color(red: 26 / 255, green: 26 / 255, blue: 27 / 255))
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 12, topTrailingRadius: 12))
        }
    }
}

struct UnavailableFeatureDialog: View {
    let onDismiss: () -> Void
    var body: some View {
        ZStack {
            Color.black.opacity(0.62).ignoresSafeArea().onTapGesture(perform: onDismiss)
            VStack(spacing: 20) {
                Text("抱歉，该功能还在实现中").foregroundStyle(.white).font(.system(size: 16)).multilineTextAlignment(.center)
                Button(action: onDismiss) { Text("知道了").foregroundStyle(corosRed).font(.system(size: 16)) }.buttonStyle(.plain)
            }
            .padding(.horizontal, 28).padding(.vertical, 24)
            .background(Color(red: 34 / 255, green: 34 / 255, blue: 36 / 255))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, 42)
        }
    }
}

struct BlockingLoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.72).ignoresSafeArea()
            ProgressView()
                .tint(Color(red: 216 / 255, green: 216 / 255, blue: 221 / 255))
                .frame(width: 96, height: 96)
                .background(Color(red: 58 / 255, green: 58 / 255, blue: 60 / 255))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }
}

struct LegalDocumentPage: View {
    let title: String
    let paragraphs: [LegalParagraph]
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Button(action: onBack) {
                    Text("‹").foregroundStyle(.white).font(.system(size: 44, weight: .light))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }.buttonStyle(.plain)
                Text(title).foregroundStyle(.white).font(.system(size: 18, weight: .bold))
            }
            .frame(height: 52).padding(.horizontal, 20)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(paragraphs.indices, id: \.self) { index in
                        LegalParagraphText(paragraph: paragraphs[index])
                        if index != paragraphs.indices.last {
                            Spacer().frame(height: paragraphs[index].isHeading ? 8 : 12)
                        }
                    }
                }
                .padding(.top, 58).padding(.bottom, 32).padding(.horizontal, 20).padding(.trailing, 12)
            }
            .scrollIndicators(.visible)
        }
        .background(Color.black.ignoresSafeArea())
    }
}

struct LegalParagraphText: View {
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
                if searchStart == text.endIndex { break }
            }
        }
        return text
    }
}

#if canImport(UIKit)
struct LoopingVideoBackground: UIViewRepresentable {
    let videoName: String
    func makeUIView(context: Context) -> LoopingVideoView {
        let view = LoopingVideoView()
        view.configure(videoName: videoName)
        return view
    }
    func updateUIView(_ uiView: LoopingVideoView, context: Context) { uiView.play() }
}

final class LoopingVideoView: UIView {
    private let playerLayer = AVPlayerLayer()
    private var queuePlayer: AVQueuePlayer?
    private var playerLooper: AVPlayerLooper?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)
    }
    required init?(coder: NSCoder) { return nil }
    override func layoutSubviews() { super.layoutSubviews(); playerLayer.frame = bounds }

    func configure(videoName: String) {
        guard queuePlayer == nil, let url = Bundle.main.url(forResource: videoName, withExtension: "mp4") else { return }
        let item = AVPlayerItem(url: url)
        let player = AVQueuePlayer()
        player.isMuted = true; player.actionAtItemEnd = .none
        playerLayer.player = player
        playerLooper = AVPlayerLooper(player: player, templateItem: item)
        queuePlayer = player
        player.play()
    }
    func play() { queuePlayer?.play() }
}
#else
struct LoopingVideoBackground: View {
    let videoName: String
    var body: some View { Color(red: 17 / 255, green: 17 / 255, blue: 17 / 255) }
}
#endif
