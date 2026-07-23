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
 
 #Preview {
     PrivacyPolicyView(
         router: AuthRouter(
             push: { _ in },
             pop: {},
             replaceTop: { _ in },
             resetTo: { _ in },
             resetKeepingEntranceAndPush: { _ in }
         )
     )
     .preferredColorScheme(.dark)
 }
 
 #Preview {
     ServiceTermsView(
         router: AuthRouter(
             push: { _ in },
             pop: {},
             replaceTop: { _ in },
             resetTo: { _ in },
             resetKeepingEntranceAndPush: { _ in }
         )
     )
     .preferredColorScheme(.dark)
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
