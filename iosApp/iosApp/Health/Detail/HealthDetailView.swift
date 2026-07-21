import SwiftUI

struct HealthDetailView: View {
    let card: HealthCard; let onBack: () -> Void
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onBack) { Text("‹").font(.system(size: 38, weight: .light)) }.frame(width: 38)
                Text(card.title).font(.system(size: AppTypography.sectionTitle)).frame(maxWidth: .infinity, alignment: .center)
                Spacer().frame(width: 38)
            }.foregroundStyle(.white).padding(.horizontal, 18).frame(height: 64)
            Spacer()
            Image(card.icon).resizable().scaledToFit().frame(width: 56, height: 56)
            Spacer().frame(height: 20)
            Text(String(format: appLocalized("health_pending_feature"), card.title)).foregroundStyle(AppColors.Health.placeholder).font(.system(size: AppTypography.cardTitle))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity).background(AppColors.Core.black)
    }
}
