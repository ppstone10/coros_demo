import { AppColors, AppImages } from '../../../resources/AppResources';
import { HealthMetricData, HealthVisualData, localizedHealthText } from '../../HealthDashboardTypes';

@Component
export struct BodyManagementVisualComp {
  @Prop visual: HealthVisualData;

  private text(key: string | undefined, args: string[] | undefined = []): string {
    if (!key) return '';
    return localizedHealthText(this, key, args || []);
  }

  build() {
    Row() {
      Column({ space: 4 }) {
        Text(this.text(this.visual.captionKey, this.visual.captionArgs)).fontSize(14).fontColor(AppColors.HEALTH_CARD_TITLE)
        Row() {
          Text(this.visual.primaryValue || '--').fontSize(32).fontFamily('COROSAPPBold').fontWeight(FontWeight.Bold).fontColor(AppColors.WHITE)
          Text(this.text(this.visual.primaryUnitKey)).fontSize(20).fontFamily('COROSAPPBold').fontWeight(FontWeight.Bold).fontColor(AppColors.HEALTH_METRIC_UNIT).margin({ left: 3 })
        }
        Text(this.text(this.visual.detailKey, this.visual.detailArgs)).fontSize(12).fontColor(AppColors.MUTED)
      }.width(141).alignItems(HorizontalAlign.Start).margin({ top: 8 })
      Blank()
      Column({ space: 0 }) {
        Row({ space: 4 }) {
          Image(AppImages.bodyFront()).width(52).height(108).objectFit(ImageFit.Contain)
          Image(AppImages.bodyBack()).width(52).height(108).objectFit(ImageFit.Contain)
        }
        Row({ space: 3 }) {
          ForEach(this.visual.metrics.slice(0, 2), (metric: HealthMetricData, index: number) => {
            if (index > 0) { Text('·').fontSize(11).fontColor(AppColors.MUTED) }
            Text(this.text(metric.labelKey)).fontSize(11).fontColor(AppColors.MUTED).maxLines(1)
          })
        }
      }.width(142).alignItems(HorizontalAlign.Center).clip(true)
    }.width('100%').alignItems(VerticalAlign.Center)
  }
}
