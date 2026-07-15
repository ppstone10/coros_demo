import SwiftUI

struct SignedInView: View {
    @ObservedObject var viewModel: LoginViewModel
    let router: AuthRouter

    var body: some View {
        MainTabsView(viewModel: viewModel, router: router)
    }
}
