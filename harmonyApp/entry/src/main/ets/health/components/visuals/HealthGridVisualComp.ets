import { AppColors } from '../../../resources/AppResources';
import { HealthMetricData, HealthVisualData, localizedHealthText } from '../../HealthDashboardTypes';

@Component
export struct HealthGridVisualComp {
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
    Column() {
      Column({ space: 7 }) {
        Row({ space: 18 }) {
          ForEach(this.visual.metrics.slice(0, 3), (metric: HealthMetricData) => {
            Column() { this.Metric(metric) }.width(92).alignItems(HorizontalAlign.Start)
          })
        }.width('100%')
        Row({ space: 18 }) {
          ForEach(this.visual.metrics.slice(3, 5), (metric: HealthMetricData) => {
            Column() { this.Metric(metric) }.width(92).alignItems(HorizontalAlign.Start)
          })
        }.width('100%')
      }.width('100%').alignItems(HorizontalAlign.Start)
    }.width('100%').alignItems(HorizontalAlign.Start).margin({ top: 8 })
  }
}
