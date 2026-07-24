import { AppColors } from '../../../resources/AppResources';
import { HealthMetricData, HealthVisualData, localizedHealthText } from '../../HealthDashboardTypes';

@Component
export struct TrainingAssessmentVisualComp {
  @Prop visual: HealthVisualData;

  private text(key: string | undefined, args: string[] | undefined = []): string {
    if (!key) return '';
    return localizedHealthText(this, key, args || []);
  }

  @Builder Metric(metric: HealthMetricData, accent: ResourceColor = AppColors.WHITE) {
    Column({ space: 1 }) {
      Row() {
        Text(metric.value).fontSize(30).fontFamily('COROSAPPBold').fontWeight(FontWeight.Bold).fontColor(accent)
        if (metric.unitKey) { Text(this.text(metric.unitKey)).fontSize(16).fontFamily('COROSAPPBold').fontWeight(FontWeight.Bold).fontColor(AppColors.HEALTH_METRIC_UNIT).margin({ left: 3 }) }
      }
      Text(this.text(metric.labelKey)).fontSize(12).fontColor(AppColors.MUTED).maxLines(1)
    }.alignItems(HorizontalAlign.Start)
  }

  build() {
    Column({ space: 4 }) {
      Text(this.text(this.visual.captionKey, this.visual.captionArgs)).fontSize(20).fontColor(AppColors.VISUAL_ORANGE).fontWeight(FontWeight.Medium)
      Text(this.text(this.visual.detailKey, this.visual.detailArgs)).fontSize(14).fontColor(AppColors.HEALTH_CARD_TITLE).maxLines(2)
      Row() {
        ForEach(this.visual.metrics.slice(0, 3), (metric: HealthMetricData, index: number) => {
          Column() { this.Metric(metric) }.width(82).alignItems(HorizontalAlign.Start)
          if (index < 2) { Blank(); Divider().vertical(true).height(42).color(AppColors.DIVIDER); Blank() }
        })
      }.width('100%').margin({ top: 12 })
    }.alignItems(HorizontalAlign.Start).margin({ top: 8 })
  }
}
