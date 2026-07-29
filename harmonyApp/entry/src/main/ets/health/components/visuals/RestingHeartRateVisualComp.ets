import { AppColors } from '../../../resources/AppResources';
import { HealthVisualData, localizedHealthText } from '../../HealthDashboardTypes';
import { rangeMarkerPath, rangeFraction } from './HealthVisualHelpers';

@Component
export struct RestingHeartRateVisualComp {
  @Prop visual: HealthVisualData;

  private text(key: string | undefined, args: string[] | undefined = []): string {
    if (!key) return '';
    return localizedHealthText(this, key, args || []);
  }

  @Builder RangeMarker() {
    Path()
      .commands(rangeMarkerPath())
      .width(8).height(7)
      .fill(AppColors.WHITE)
      .stroke(AppColors.WHITE).strokeWidth(1)
      .margin({ left: Math.max(0, Math.min(122, 130 * rangeFraction(this.visual.range) - 4)), top: 7 })
  }

  private averageLeft(): number {
    const range = this.visual.range;
    if (!range || range.average === undefined) return 0;
    const width = Math.max(1, range.maximum - range.minimum);
    return Math.max(0, Math.min(129, 130 * (range.average - range.minimum) / width));
  }

  build() {
    Row() {
      Column({ space: 0 }) {
        Row() {
          Text(this.visual.primaryValue || '--')
            .fontSize(32).fontFamily('COROSAPPBold')
            .fontWeight(FontWeight.Bold).fontColor(AppColors.WHITE)
          if (this.visual.primaryUnitKey) {
            Text(this.text(this.visual.primaryUnitKey))
              .fontSize(20).fontFamily('COROSAPPBold').fontWeight(FontWeight.Bold)
              .fontColor(AppColors.HEALTH_METRIC_UNIT).margin({ left: 3 })
          }
        }
        if (this.visual.captionKey) {
          Text(this.text(this.visual.captionKey, this.visual.captionArgs))
            .fontSize(12).fontColor(AppColors.MUTED).maxLines(1)
        }
      }
      .width(141).height(60).alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)
      Blank()
      Column({ space: 4 }) {
        if (this.visual.detailKey) {
          Row({ space: 3 }) {
            Path().commands(`M${vp2px(1)} 0 L${vp2px(1)} ${vp2px(12)}`)
              .width(2).height(12).stroke(AppColors.MUTED).strokeWidth(1).strokeDashArray([2, 2])
            Text(this.text(this.visual.detailKey, this.visual.detailArgs))
              .fontSize(11).fontColor(AppColors.MUTED).maxLines(1)
          }
        }
        Stack({ alignContent: Alignment.TopStart }) {
          Row().width(130).height(4).backgroundColor(AppColors.VISUAL_PINK).borderRadius(2).margin({ top: 10 })
          this.RangeMarker()
          if (this.visual.range && this.visual.range.average !== undefined) {
            Path().commands(`M0 0 L0 ${vp2px(18)}`)
              .width(1).height(18).stroke(AppColors.WHITE).strokeWidth(1).strokeDashArray([2, 2])
              .margin({ left: this.averageLeft() })
          }
        }
        .width(130).height(18)
        Row() {
          Text(this.visual.range ? Math.round(this.visual.range.minimum).toString() : '--')
            .fontSize(10).fontColor(AppColors.MUTED)
          Blank()
          Text(this.visual.range ? Math.round(this.visual.range.maximum).toString() : '--')
            .fontSize(10).fontColor(AppColors.MUTED)
        }
        .width(130)
      }
      .width(130).alignItems(HorizontalAlign.Center)
    }
    .width('100%').height(60).alignItems(VerticalAlign.Center)
  }
}
