import { AppColors, AppImages } from '../../../resources/AppResources';
import { HealthVisualData, localizedHealthText } from '../../HealthDashboardTypes';

@Component
export struct ActivityVisualComp {
  @Prop visual: HealthVisualData;

  private text(key: string | undefined, args: string[] | undefined = []): string {
    if (!key) return '';
    return localizedHealthText(this, key, args || []);
  }

  build() {
    Row({ space: 12 }) {
      Image(AppImages.activityMap()).width(48).height(48).objectFit(ImageFit.Cover).borderRadius(6)
      Column({ space: 0 }) {
        Row() {
          Text(this.visual.primaryValue || '--').fontSize(24).fontFamily('COROSAPPBold').fontWeight(FontWeight.Bold).fontColor(AppColors.WHITE)
          Text(this.text(this.visual.primaryUnitKey)).fontSize(16).fontFamily('COROSAPPBold').fontWeight(FontWeight.Bold).fontColor(AppColors.HEALTH_METRIC_UNIT).margin({ left: 3 })
        }
        Row({ space: 3 }) {
          Text(this.text(this.visual.detailKey, this.visual.detailArgs)).fontSize(12).fontColor(AppColors.MUTED).maxLines(1)
          Text(this.text(this.visual.captionKey, this.visual.captionArgs)).fontSize(12).fontColor(AppColors.MUTED).maxLines(1)
        }
      }.alignItems(HorizontalAlign.Start).layoutWeight(1)
      Image(AppImages.todayRunner()).width(24).height(24).objectFit(ImageFit.Contain)
    }.width('100%').height(48).alignItems(VerticalAlign.Center).margin({ top: 10 })
  }
}
