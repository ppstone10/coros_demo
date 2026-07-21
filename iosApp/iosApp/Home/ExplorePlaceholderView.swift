import SwiftUI

struct ExplorePlaceholderView: View {
    var body: some View {
        Text(String(format: appLocalized("nav_unavailable"), appLocalized("nav_explore")))
            .foregroundStyle(AppColors.Navigation.unselected)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.Core.black)
    }
}
