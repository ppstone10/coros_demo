import SwiftUI
import Shared

/// 健康域二级路由的目的地渲染，由 AuthCoordinator 转发。
/// AuthRoute 仍是全局 NavigationStack 的单一路径容器（SwiftUI 约束），
/// 但健康页面的视图组合归属健康模块，auth 域不再内嵌健康详情实现。
@MainActor
@ViewBuilder
func healthDestination(
    _ route: AuthRoute,
    healthViewModel: HealthDashboardViewModel,
    router: AuthRouter
) -> some View {
    switch route {
    case let .healthDetail(cardID):
        if let card = healthViewModel.cards.first(where: { $0.id == cardID }) {
            HealthDetailView(card: card) { router.pop() }
                .navigationBarBackButtonHidden(true)
        } else {
            AppColors.Core.black
                .ignoresSafeArea()
                .onAppear { router.pop() }
                .navigationBarBackButtonHidden(true)
        }
    case .healthEditor:
        HealthCardEditor(
            initial: healthViewModel.cards,
            onClose: { router.pop() },
            onSave: { cards in
                healthViewModel.saveCardConfiguration(cards.map(\.id))
                router.pop()
            }
        )
        .navigationBarBackButtonHidden(true)
    case .normalDataEditor:
        NormalDataEditorOverview(
            viewModel: healthViewModel,
            router: router
        )
        .navigationBarBackButtonHidden(true)
    case let .normalDataSection(section):
        NormalDataSectionEditor(
            section: section,
            viewModel: healthViewModel,
            router: router
        )
        .navigationBarBackButtonHidden(true)
    default:
        EmptyView()
    }
}
