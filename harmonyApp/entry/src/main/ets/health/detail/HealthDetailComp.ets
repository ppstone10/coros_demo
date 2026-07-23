import { AppColors, AppTypography, AppImages } from '../../resources/AppResources';
import { HealthCardModel, localizedHealthText, resourceText } from '../HealthDashboardTypes';

 @Preview
@Component
export struct HealthDetailComp {
  @Prop cardId: string = '';
  @Prop healthCards: HealthCardModel[] = [];
  backAction?: () => void;

  build() {
    Column() {
      Row() {
        Text('‹').fontSize(38).fontColor(AppColors.WHITE).width(48)
          .onClick(() => { if (this.backAction) this.backAction(); })
        Text(this.card().title).fontSize(AppTypography.SECTION_TITLE).fontColor(AppColors.WHITE)
          .layoutWeight(1).textAlign(TextAlign.Center)
        Blank().width(48)
      }
      .height(64).width('100%').padding({ left: 18, right: 18 }).margin({ top: 32 })
      .alignItems(VerticalAlign.Center)
      Column({ space: 20 }) {
        Image(AppImages.healthCardIcon(this.card().id)).width(56).height(56).objectFit(ImageFit.Contain)
        Text(localizedHealthText(this, 'health_pending_feature', [resourceText(this, this.card().title)]))
          .fontSize(AppTypography.CARD_TITLE).fontColor(AppColors.HEALTH_PLACEHOLDER)
      }
      .layoutWeight(1).justifyContent(FlexAlign.Center)
    }
    .width('100%').height('100%').backgroundColor(AppColors.BLACK)
  }

  private card(): HealthCardModel {
    let found: HealthCardModel | undefined = this.healthCards.find((c: HealthCardModel) => c.id === this.cardId);
    return found === undefined ? this.healthCards[0] : found;
  }
}
