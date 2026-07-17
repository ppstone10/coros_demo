import SwiftUI

struct PrivacyPolicyView: View {
    let router: AuthRouter
    var body: some View {
        LegalDocumentPage(
            title: appLocalized("auth_privacy_policy"),
            paragraphs: parseLegalDocument(appLocalized("legal_privacy_body")),
            onBack: { router.pop() }
        )
    }
}

struct ServiceTermsView: View {
    let router: AuthRouter
    var body: some View {
        LegalDocumentPage(
            title: appLocalized("auth_service_terms"),
            paragraphs: parseLegalDocument(appLocalized("legal_service_terms_body")),
            onBack: { router.pop() }
        )
    }
}
