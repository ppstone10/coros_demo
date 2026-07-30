import SwiftUI

private enum MainTab: CaseIterable {
    case fitness, records, explore, me
    var label: String {
        switch self {
        case .fitness: return appLocalized("nav_fitness")
        case .records: return appLocalized("nav_records")
        case .explore: return appLocalized("nav_explore")
        case .me: return appLocalized("nav_me")
        }
    }
    var images: (String, String) {
        switch self {
        case .fitness: return AppImages.Navigation.fitness
        case .records: return AppImages.Navigation.records
        case .explore: return AppImages.Navigation.explore
        case .me: return AppImages.Navigation.me
        }
    }
}

struct MainTabsView: View {
    @ObservedObject var viewModel: LoginViewModel
    @ObservedObject var healthViewModel: HealthDashboardViewModel
    @EnvironmentObject private var languageStore: AppLanguageStore
    let router: AuthRouter
    @State private var selected: MainTab = .fitness

    var body: some View {
        let _ = languageStore.current
        VStack(spacing: 0) {
            Group {
                switch selected {
                case .fitness:
                    HealthDashboardView(
                        viewModel: healthViewModel,
                        onOpenDetail: { router.push(.healthDetail(cardID: $0.id)) },
                        onOpenEditor: { router.push(.healthEditor) },
                        onOpenNormalDataEditor: { router.push(.normalDataEditor) },
                        onWatchTap: { selected = .me }
                    )
                case .me:
                    AccountView(
                        viewModel: viewModel,
                        onEditProfile: { router.push(.profileEdit) }
                    )
                case .records: RecordsPlaceholderView()
                case .explore: ExplorePlaceholderView()
                }
            }
            HStack(spacing: 0) {
                ForEach(MainTab.allCases, id: \.self) { tab in
                    Button {
                        selected = tab
                    } label: {
                        VStack(spacing: 2) {
                            Image(selected == tab ? tab.images.1 : tab.images.0).resizable().scaledToFit().frame(width: 27, height: 27)
                            Text(tab.label).font(.system(size: 11, weight: selected == tab ? .medium : .regular))
                                .foregroundStyle(selected == tab ? .white : AppColors.Navigation.unselected)
                        }.frame(maxWidth: .infinity)
                    }.buttonStyle(.plain)
                }
            }
            .padding(.top, 7).padding(.bottom, 5)
            .background(AppColors.Navigation.bar.ignoresSafeArea(edges: .bottom))
        }
        .background(AppColors.Core.black)
    }
}
 
 #Preview {
	     MainTabsView(
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
     .environmentObject(AppLanguageStore.shared)
     .preferredColorScheme(.dark)
 }
