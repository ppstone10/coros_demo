import SwiftUI

struct ThirdPartyArea: View {
    let onUnavailableClick: () -> Void
    var body: some View {
        VStack(spacing: 24) {
            HStack(spacing: 12) {
                Rectangle().fill(corosLine).frame(height: 1)
                Text(appLocalized("auth_third_party_account")).foregroundStyle(corosMuted).font(.system(size: 14)).fixedSize()
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
                .overlay(Circle().stroke(AppColors.Auth.avatarBorder, lineWidth: 1))
        }.buttonStyle(.plain)
    }
}

struct ErrorText: View {
    let message: String?
    init(_ message: String?) { self.message = message }
    var body: some View {
        if let message, !message.isEmpty {
            Text(localizedAuthMessage(message) ?? message)
                .foregroundStyle(corosRed).font(.system(size: 15)).padding(.top, 10)
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
            AppColors.Core.overlayStrong.ignoresSafeArea()
            VStack(spacing: 0) {
                Button(action: onDismiss) {
                    Text("×").foregroundStyle(.white).font(.system(size: 34, weight: .light))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }.buttonStyle(.plain)
                Spacer().frame(height: 12)
                Text(appLocalized("auth_read_terms")).foregroundStyle(.white).font(.system(size: 18)).multilineTextAlignment(.center)
                HStack(spacing: 0) {
                    Button(action: onPrivacyClick) { Text(appLocalized("auth_privacy_policy_link")).foregroundStyle(corosRed) }.buttonStyle(.plain)
                    Text(appLocalized("auth_terms_joiner")).foregroundStyle(.white)
                    Button(action: onServiceTermsClick) { Text(appLocalized("auth_service_terms_link")).foregroundStyle(corosRed) }.buttonStyle(.plain)
                }.font(.system(size: 18)).padding(.top, 8)
                Spacer().frame(height: 42)
                CorosFilledButton(text: appLocalized("auth_agree_and_continue"), color: corosRed, action: onAgree)
            }
            .padding(.horizontal, 22).padding(.top, 18).padding(.bottom, 18)
            .background(AppColors.Auth.termsSheet)
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 12, topTrailingRadius: 12))
        }
    }
}

struct UnavailableFeatureDialog: View {
    let onDismiss: () -> Void
    var body: some View {
        ZStack {
            AppColors.Core.overlayMedium.ignoresSafeArea().onTapGesture(perform: onDismiss)
            VStack(spacing: 20) {
                Text(appLocalized("auth_unavailable")).foregroundStyle(.white).font(.system(size: 16)).multilineTextAlignment(.center)
                Button(action: onDismiss) { Text(appLocalized("auth_got_it")).foregroundStyle(corosRed).font(.system(size: 16)) }.buttonStyle(.plain)
            }
            .padding(.horizontal, 28).padding(.vertical, 24)
            .background(AppColors.Auth.dialog)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, 42)
        }
    }
}

struct BlockingLoadingOverlay: View {
    var body: some View {
        ZStack {
            AppColors.Core.overlayLoading.ignoresSafeArea()
            ProgressView()
                .tint(AppColors.Auth.inputText)
                .frame(width: 96, height: 96)
                .background(AppColors.Auth.loading)
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
        .background(AppColors.Core.black.ignoresSafeArea())
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

#Preview("Error text") {
    ErrorText("Demo error")
}
