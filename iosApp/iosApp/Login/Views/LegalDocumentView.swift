import SwiftUI

struct PrivacyPolicyView: View {
    @Binding var path: NavigationPath
    var body: some View {
        LegalDocumentPage(title: "隐私政策", paragraphs: privacyPolicyParagraphs, onBack: { path.removeLast() })
    }
}

struct ServiceTermsView: View {
    @Binding var path: NavigationPath
    var body: some View {
        LegalDocumentPage(title: "服务条款", paragraphs: serviceTermsParagraphs, onBack: { path.removeLast() })
    }
}
