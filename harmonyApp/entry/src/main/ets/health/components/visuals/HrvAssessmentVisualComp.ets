import { AppColors } from '../../../resources/AppResources';
import { HealthVisualData, localizedHealthText } from '../../HealthDashboardTypes';
import { rangeMarkerPath, rangeFraction } from './HealthVisualHelpers';

@Component
export struct HrvAssessmentVisualComp {
  @Prop visual: HealthVisualData;

  private text(key: string | undefined, args: string[] | undefined = []): string {
    if (!key) return '';
    return localizedHealthText(this, key, args || []);
  }

  private normalRangeText(): string {
    const range = this.visual.range;
    if (!range) return '';
    return this.text('health_visual_normal_range_short', [
      range.normalMin === undefined ? '--' : Math.round(range.normalMin).toString(),
      range.normalMax === undefined ? '--' : Math.round(range.normalMax).toString(),
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
      Column({ space: 4 }) {
        if (this.visual.captionKey) {
          Text(this.text(this.visual.captionKey, this.visual.captionArgs))
            .fontSize(32).fontWeight(FontWeight.Bold).fontColor(AppColors.WHITE).maxLines(1)
        }
        if (this.visual.detailKey) {
          Text(this.text(this.visual.detailKey, this.visual.detailArgs))
            .fontSize(12).fontColor(AppColors.MUTED).maxLines(1)
        }
      }
      .width(141).height(60).alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)
      Blank()
      Column({ space: 4 }) {
        Stack({ alignContent: Alignment.TopStart }) {
          Row({ space: 0 }) {
            Row().width(23).height(4).backgroundColor(AppColors.HEALTH_WARNING)
            Row().width(26).height(4).backgroundColor(AppColors.VISUAL_YELLOW)
            Row().width(49).height(4).backgroundColor(AppColors.VISUAL_GREEN)
            Row().layoutWeight(1).height(4).backgroundColor(AppColors.VISUAL_ORANGE)
          }
          .width(130).height(4).borderRadius(2).clip(true).margin({ top: 10 })
          this.RangeMarker()
        }
        .width(130).height(18)
        Row({ space: 4 }) {
          Circle().width(5).height(5).fill(AppColors.VISUAL_GREEN)
          Text(this.normalRangeText())
            .fontSize(10).fontColor(AppColors.MUTED).maxLines(1)
        }
      }
      .width(130).alignItems(HorizontalAlign.Center)
    }
    .width('100%').height(60).alignItems(VerticalAlign.Center)
  }
}
