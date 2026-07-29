import { AppColors } from '../../../resources/AppResources';
import { HealthVisualData, localizedHealthText } from '../../HealthDashboardTypes';
import { gaugeProgress, abilitySegmentPath, abilityNeedlePath } from './HealthVisualHelpers';

@Component
export struct AbilityVisualComp {
  @Prop cardType: string;
  @Prop visual: HealthVisualData;

  private text(key: string | undefined, args: string[] | undefined = []): string {
    if (!key) return '';
    return localizedHealthText(this, key, args || []);
  }

  private gaugeAccent(): ResourceColor {
    return this.cardType === 'RunningAbility' ? AppColors.VISUAL_ORANGE : AppColors.VISUAL_GREEN;
  }

  @Builder AbilityOverview() {
    Column({ space: 0 }) {
      Stack({ alignContent: Alignment.TopStart }) {
        ForEach([
          0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
          10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
          20, 21, 22, 23, 24, 25, 26, 27, 28, 29
        ], (index: number) => {
          Path()
            .commands(abilitySegmentPath(index))
            .width(121).height(60).fill(AppColors.TRANSPARENT)
            .stroke((index + 0.5) / 30 <= gaugeProgress(this.visual.progress)
              ? this.gaugeAccent()
              : AppColors.RANGE_TRACK)
            .strokeWidth(3)
        })
        Path()
          .commands(abilityNeedlePath(this.visual.progress || 0))
          .width(121).height(60).fill(AppColors.TRANSPARENT)
          .stroke(AppColors.HEALTH_CARD_TITLE).strokeWidth(2)
        Circle()
          .width(5).height(5).fill(AppColors.HEALTH_CARD_TITLE)
          .margin({ left: 58, top: 52.5 })
      }
      .width(121).height(60)
      Row() {
        Text('0').fontSize(10).fontColor(AppColors.MUTED)
        Blank()
        Text('100').fontSize(10).fontColor(AppColors.MUTED)
      }
      .width(121)
    }
    .width(121).height(71)
  }

  build() {
    Row() {
      Column({ space: 0 }) {
        Row() {
          Text(this.visual.primaryValue || '--')
            .fontSize(32).fontFamily('COROSAPPBold')
            .fontColor(AppColors.WHITE).fontWeight(FontWeight.Bold)
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
      .width(141).height(71).alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)
      Blank()
      this.AbilityOverview()
    }
    .width('100%').height(71).alignItems(VerticalAlign.Center)
  }
}
