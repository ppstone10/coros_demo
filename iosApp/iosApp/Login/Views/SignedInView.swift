import SwiftUI

struct SignedInView: View {
    @ObservedObject var viewModel: LoginViewModel
    let router: AuthRouter

    var body: some View {
        MainTabsView(viewModel: viewModel, router: router)
    }
}
 
 #Preview {
     SignedInView(
         viewModel: LoginViewModel(),
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
