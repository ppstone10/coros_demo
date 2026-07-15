import SwiftUI

private enum MainTab: CaseIterable {
    case fitness, records, explore, me

    var label: String {
        switch self {
        case .fitness: return AppText.Navigation.fitness
        case .records: return AppText.Navigation.records
        case .explore: return AppText.Navigation.explore
        case .me: return AppText.Navigation.me
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
    let router: AuthRouter
    @State private var selected: MainTab = .fitness
    @State private var contentFullscreen = false

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch selected {
                case .fitness:
                    HealthDashboardView(isFullscreen: $contentFullscreen)
                case .me:
                    AccountView(viewModel: viewModel, router: router, isFullscreen: $contentFullscreen)
                case .records, .explore:
                    Text(AppText.Navigation.unavailable(selected.label))
                        .foregroundStyle(AppColors.Navigation.unselected)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black)
                }
            }

            if !contentFullscreen {
                HStack(spacing: 0) {
                    ForEach(MainTab.allCases, id: \.self) { tab in
                        Button {
                            selected = tab
                        } label: {
                            VStack(spacing: 2) {
                                Image(selected == tab ? tab.images.1 : tab.images.0)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 27, height: 27)
                                Text(tab.label)
                                    .font(.system(size: 11, weight: selected == tab ? .medium : .regular))
                                    .foregroundStyle(selected == tab ? .white : AppColors.Navigation.unselected)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 7)
                .padding(.bottom, 5)
                .background(AppColors.Navigation.bar.ignoresSafeArea(edges: .bottom))
            }
        }
        .background(Color.black)
    }
}
