import { AppColors } from '../../../core/resources/AppResources';
import { HealthRangeSegmentData, HealthVisualData, localizedHealthText } from '../../HealthDashboardTypes';
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

  private rangeSegments(): HealthRangeSegmentData[] {
    return this.visual.range?.segments || [];
  }

  private segmentWidth(segment: HealthRangeSegmentData): number {
    const range = this.visual.range;
    if (!range) return 0;
    const total = Math.max(1, range.maximum - range.minimum);
    return 130 * Math.max(0, segment.maximum - segment.minimum) / total;
  }

  private segmentColor(level: string): ResourceColor {
    if (level === 'VeryLow') return AppColors.HEALTH_WARNING;
    if (level === 'Low') return AppColors.VISUAL_YELLOW;
    if (level === 'Normal') return AppColors.VISUAL_GREEN;
    return AppColors.VISUAL_ORANGE;
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
      Column({ space: 2 }) {
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
            ForEach(this.rangeSegments(), (segment: HealthRangeSegmentData) => {
              Row()
                .width(this.segmentWidth(segment))
                .height(4)
                .backgroundColor(this.segmentColor(segment.level))
            }, (segment: HealthRangeSegmentData) => `${segment.minimum}-${segment.maximum}-${segment.level}`)
          }
          .width(130).height(4).borderRadius(2).clip(true).margin({ top: 10 })
          this.RangeMarker()
        }
        .width(130).height(18)
        Row({ space: 4 }) {
          Circle().width(5).height(5).fill(AppColors.VISUAL_GREEN)
          Text(this.normalRangeText())
            .fontSize(9).fontColor(AppColors.MUTED).maxLines(2)
        }
        .width(130).height(24).alignItems(VerticalAlign.Top).justifyContent(FlexAlign.Center)
      }
      .width(130).height(60).alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
    }
    .width('100%').height(60).alignItems(VerticalAlign.Center)
  }
}
