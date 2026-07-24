import { AppColors } from '../../../resources/AppResources';
import { HealthVisualData, localizedHealthText } from '../../HealthDashboardTypes';
import { rangeMarkerPath, rangeFraction } from './HealthVisualHelpers';

@Component
export struct RangeIndicatorVisualComp {
  @Prop cardType: string;
  @Prop visual: HealthVisualData;

  private text(key: string | undefined, args: string[] | undefined = []): string {
    if (!key) return '';
    return localizedHealthText(this, key, args || []);
  }

  private rangeHeaderText(): string {
    if (this.cardType === 'RestingHeartRate') {
      return this.text(this.visual.detailKey, this.visual.detailArgs);
    }
    const r = this.visual.range;
    if (!r) return '';
    return this.text('health_visual_normal_range_short', [
      r.normalMin === undefined ? '--' : Math.round(r.normalMin).toString(),
      r.normalMax === undefined ? '--' : Math.round(r.normalMax).toString(),
      this.text(this.visual.primaryUnitKey)
    ]);
  }

  @Builder RangeMarker() {
    Path()
      .commands(rangeMarkerPath())
      .width(8).height(7)
      .fill(AppColors.WHITE)
      .stroke(AppColors.WHITE).strokeWidth(1)
      .margin({ left: Math.max(0, Math.min(122, 130 * rangeFraction(this.visual.range) - 4)), top: 7 })
  }

  build() {
    Row() {
      Column({ space: 0 }) {
        Row() {
          Text(this.visual.primaryValue || '--').fontSize(32).fontFamily('COROSAPPBold').fontWeight(FontWeight.Bold).fontColor(AppColors.WHITE)
          if (this.visual.primaryUnitKey) { Text(this.text(this.visual.primaryUnitKey)).fontSize(20).fontFamily('COROSAPPBold').fontWeight(FontWeight.Bold).fontColor(AppColors.HEALTH_METRIC_UNIT).margin({ left: 3 }) }
        }
        Text(this.text(
          this.cardType === 'RestingHeartRate' ? this.visual.captionKey : this.visual.detailKey,
          this.cardType === 'RestingHeartRate' ? this.visual.captionArgs : this.visual.detailArgs
        )).fontSize(12).fontColor(AppColors.MUTED).maxLines(1)
      }.width(141).alignItems(HorizontalAlign.Start).margin({ top: 8 })
      Blank()
      Column({ space: 4 }) {
        Text(this.rangeHeaderText())
          .fontSize(12).fontColor(AppColors.MUTED).maxLines(1)
        Stack({ alignContent: Alignment.TopStart }) {
          if (this.cardType === 'HrvAssessment') {
            Row({ space: 0 }) {
              Row().width(23).height(4).backgroundColor(AppColors.HEALTH_WARNING)
              Row().width(26).height(4).backgroundColor(AppColors.VISUAL_YELLOW)
              Row().width(49).height(4).backgroundColor(AppColors.VISUAL_GREEN)
              Row().layoutWeight(1).height(4).backgroundColor(AppColors.VISUAL_ORANGE)
            }
            .width(130).height(4).borderRadius(2).clip(true)
          } else {
            Row().width(130).height(4).backgroundColor(AppColors.VISUAL_PINK).borderRadius(2)
          }
          this.RangeMarker()
        }
        .width(130).height(20)
        if (this.cardType === 'HrvAssessment') {
          Row({ space: 4 }) {
            Circle().width(5).height(5).fill(AppColors.VISUAL_GREEN)
            Text(this.text(this.visual.captionKey, this.visual.captionArgs))
              .fontSize(10).fontColor(AppColors.MUTED).maxLines(1)
          }
        }
      }
      .width(130)
    }.width('100%').alignItems(VerticalAlign.Center)
  }
}
