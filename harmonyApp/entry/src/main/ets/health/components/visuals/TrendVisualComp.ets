import { AppColors } from '../../../resources/AppResources';
import { HealthChartPointData, HealthVisualData, localizedHealthText } from '../../HealthDashboardTypes';

@Component
export struct TrendVisualComp {
  @Prop cardType: string;
  @Prop visual: HealthVisualData;

  private text(key: string | undefined, args: string[] | undefined = []): string {
    if (!key) return '';
    return localizedHealthText(this, key, args || []);
  }

  private heartChartMinimum(): number {
    let result: number = Number.MAX_VALUE;
    this.visual.chartPoints.forEach((point: HealthChartPointData) => {
      result = Math.min(result, point.minimum === undefined ? point.value : point.minimum);
    });
    return result === Number.MAX_VALUE ? 0 : result;
  }

  private heartChartMaximum(): number {
    let result: number = -Number.MAX_VALUE;
    this.visual.chartPoints.forEach((point: HealthChartPointData) => {
      result = Math.max(result, point.maximum === undefined ? point.value : point.maximum);
    });
    return result === -Number.MAX_VALUE ? 1 : result;
  }

  private stressBarIndexes(): number[] {
    const result: number[] = [];
    for (let index: number = 0; index < 83; index++) result.push(index);
    return result;
  }

  private stressValue(index: number): number {
    const values: HealthChartPointData[] = this.visual.chartPoints;
    if (values.length === 0) return 0;
    const position: number = index / 82 * Math.max(0, values.length - 1);
    const left: number = Math.max(0, Math.min(values.length - 1, Math.floor(position)));
    const right: number = Math.min(values.length - 1, left + 1);
    const fraction: number = position - left;
    return values[left].value + (values[right].value - values[left].value) * fraction;
  }

  private stressHeight(index: number): number {
    return Math.max(2, 56 * this.stressValue(index) / 100);
  }

  private stressColor(index: number): ResourceColor {
    const value: number = this.stressValue(index);
    if (value >= 80) return AppColors.VISUAL_ORANGE;
    if (value >= 60) return AppColors.VISUAL_YELLOW;
    if (value >= 35) return AppColors.STRESS_GOOD;
    return AppColors.STRESS_LOW;
  }

  @Builder HeartRateIntervalOverview() {
    Stack({ alignContent: Alignment.TopStart }) {
      ForEach(this.visual.chartPoints, (point: HealthChartPointData, index: number) => {
        Row()
          .width(1)
          .height(Math.max(1, 38 *
            ((point.maximum === undefined ? point.value : point.maximum) -
              (point.minimum === undefined ? point.value : point.minimum)) /
            Math.max(1, this.heartChartMaximum() - this.heartChartMinimum())))
          .backgroundColor(AppColors.VISUAL_PINK)
          .margin({
            left: this.visual.chartPoints.length <= 1 ? 0 :
              index * 165 / (this.visual.chartPoints.length - 1),
            top: 3 + 38 * (1 -
              ((point.maximum === undefined ? point.value : point.maximum) - this.heartChartMinimum()) /
              Math.max(1, this.heartChartMaximum() - this.heartChartMinimum()))
          })
      })
    }
    .width(166).height(44).clip(true)
  }

  @Builder StressOverview() {
    Row({ space: 1 }) {
      ForEach(this.stressBarIndexes(), (index: number) => {
        Row().width(1).height(this.stressHeight(index)).backgroundColor(this.stressColor(index))
      })
    }.width(166).height(56).alignItems(VerticalAlign.Bottom).clip(true)
  }

  build() {
    Row() {
      Column() {
        Row() {
          Text(this.visual.primaryValue || '--').fontSize(32).fontFamily('COROSAPPBold').fontColor(AppColors.WHITE).fontWeight(FontWeight.Bold)
          if (this.visual.primaryUnitKey) { Text(this.text(this.visual.primaryUnitKey)).fontSize(20).fontFamily('COROSAPPBold').fontWeight(FontWeight.Bold).fontColor(AppColors.HEALTH_METRIC_UNIT).margin({ left: 3 }) }
        }
        Text(this.text(this.visual.captionKey, this.visual.captionArgs)).fontSize(12).fontColor(AppColors.MUTED).maxLines(1)
      }.width(141).alignItems(HorizontalAlign.Start).margin({ top: 8 })
      Blank()
      if (this.cardType === 'HeartRate') {
        this.HeartRateIntervalOverview()
      } else {
        this.StressOverview()
      }
    }.width('100%').alignItems(VerticalAlign.Center)
  }
}
