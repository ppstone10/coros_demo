import SwiftUI

struct SignedInView: View {
    @ObservedObject var viewModel: LoginViewModel
    @ObservedObject var healthViewModel: HealthDashboardViewModel
    let router: AuthRouter

    var body: some View {
        MainTabsView(
            viewModel: viewModel,
            healthViewModel: healthViewModel,
            router: router
        )
    }
}
 
 #Preview {
	     SignedInView(
	         viewModel: LoginViewModel(),
             healthViewModel: HealthDashboardViewModel(),
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
