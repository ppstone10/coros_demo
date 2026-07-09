import SwiftUI

struct PrivacyPolicyView: View {
    let router: AuthRouter
    var body: some View {
        LegalDocumentPage(title: "隐私政策", paragraphs: privacyPolicyParagraphs, onBack: { router.pop() })
    }
}

struct ServiceTermsView: View {
    let router: AuthRouter
    var body: some View {
        LegalDocumentPage(title: "服务条款", paragraphs: serviceTermsParagraphs, onBack: { router.pop() })
    }
}
