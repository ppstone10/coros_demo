import { AppColors, AppTypography, AppImages } from '../../resources/AppResources';
import { HealthCardModel } from '../HealthDashboardTypes';

@Component
export struct DashboardCardComp {
  @Prop card: HealthCardModel;
  onTap?: () => void;

  build() {
    Row() {
      Image(AppImages.healthIcon(this.card.iconIndex)).width(22).height(22).objectFit(ImageFit.Contain)
      Blank().width(10)
      Column({ space: 5 }) {
        Text(this.card.title).fontSize(AppTypography.CARD_TITLE).fontColor(AppColors.HEALTH_CARD_TITLE).fontWeight(FontWeight.Medium)
        Text(this.card.summary).fontSize(AppTypography.SUPPORTING).fontColor(this.card.isRisk ? AppColors.RISK : AppColors.MUTED)
          .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start).layoutWeight(1)
      Text('›').fontSize(25).fontColor(AppColors.HEALTH_CHEVRON)
    }
    .width('calc(100% - 32vp)')
    .constraintSize({ minHeight: 76 })
    .padding({ left: 15, right: 15, top: 12, bottom: 12 })
    .margin({ left: 16, right: 16, top: 5, bottom: 5 })
    .backgroundColor(AppColors.HEALTH_CARD)
    .borderRadius(8)
    .onClick(() => {
      if (this.onTap) { this.onTap(); }
    })
  }
}
