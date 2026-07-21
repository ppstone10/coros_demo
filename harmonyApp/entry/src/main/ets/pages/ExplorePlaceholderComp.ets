import { AppColors, AppTypography } from '../resources/AppResources';

@Component
export struct ExplorePlaceholderComp {
  build() {
    Column() {
      Text($r('app.string.nav_unavailable', $r('app.string.nav_explore')))
        .fontSize(16).fontColor(AppColors.NAV_PLACEHOLDER).textAlign(TextAlign.Center)
    }
    .layoutWeight(1).width('100%').justifyContent(FlexAlign.Center)
  }
}
