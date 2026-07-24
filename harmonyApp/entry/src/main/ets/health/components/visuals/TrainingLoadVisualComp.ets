import { AppColors } from '../../../resources/AppResources';
import { HealthChartPointData, HealthVisualData, localizedHealthText } from '../../HealthDashboardTypes';
import { barColor, barHeight } from './HealthVisualHelpers';

@Component
export struct TrainingLoadVisualComp {
  @Prop visual: HealthVisualData;

  private text(key: string | undefined, args: string[] | undefined = []): string {
    if (!key) return '';
    return localizedHealthText(this, key, args || []);
  }

  @Builder Bars(widthValue: number = 130, heightValue: number = 36, highlightedIndex: number = -1, showTrack: boolean = false) {
    Row({ space: 5 }) {
      ForEach(this.visual.chartPoints, (point: HealthChartPointData, index: number) => {
        Stack({ alignContent: Alignment.Bottom }) {
          if (showTrack) {
            Row().width('100%').height(heightValue).backgroundColor(AppColors.RANGE_TRACK).borderRadius(2)
          }
          Row().width('100%').height(barHeight(point, heightValue, this.visual.chartPoints))
            .backgroundColor(barColor(this.visual.kind, point, index, highlightedIndex)).borderRadius(2)
        }
        .height(heightValue).layoutWeight(1)
      })
    }.height(heightValue).width(widthValue).alignItems(VerticalAlign.Bottom).clip(true)
  }

  @Builder LoadOverview() {
    Column({ space: 4 }) {
      this.Bars(130, 36, this.visual.highlightedIndex, true)
      Row() {
        ForEach(this.visual.chartPoints.slice(0, 7), (point: HealthChartPointData, index: number) => {
          Text(this.text(point.label)).fontSize(9)
            .fontColor(index === this.visual.highlightedIndex ? AppColors.WHITE : AppColors.MUTED)
          if (index < 6) { Blank() }
        })
      }.width(130)
    }.width(130)
  }

  build() {
    Row() {
      Column() {
        Text(this.visual.primaryValue || '--').fontSize(32).fontFamily('COROSAPPBold')
          .fontColor(AppColors.WHITE).fontWeight(FontWeight.Bold)
        Text(this.text(this.visual.captionKey, this.visual.captionArgs))
          .fontSize(12).fontColor(AppColors.MUTED).maxLines(1)
      }.width(141).alignItems(HorizontalAlign.Start).margin({ top: 8 })
      Blank()
      this.LoadOverview()
    }.width('100%').alignItems(VerticalAlign.Center)
  }
}
