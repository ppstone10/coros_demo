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
    @EnvironmentObject private var languageStore: AppLanguageStore
    let router: AuthRouter
    @State private var selected: MainTab = .fitness
    @State private var contentFullscreen = false

    var body: some View {
        let _ = languageStore.current
        VStack(spacing: 0) {
            Group {
                switch selected {
                case .fitness: HealthDashboardView(isFullscreen: $contentFullscreen)
                case .me: AccountView(viewModel: viewModel, router: router, isFullscreen: $contentFullscreen)
                case .records: RecordsPlaceholderView()
                case .explore: ExplorePlaceholderView()
                }
            }
            if !contentFullscreen {
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
        }
        .background(AppColors.Core.black)
    }
}
