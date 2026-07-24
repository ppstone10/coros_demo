import { AppColors, AppImages } from '../../../resources/AppResources';
import { HealthVisualData, localizedHealthText } from '../../HealthDashboardTypes';
import { gaugeProgress, gaugeArcPath, abilitySegmentPath, abilityNeedlePath } from './HealthVisualHelpers';

@Component
export struct GaugeVisualComp {
  @Prop cardType: string;
  @Prop visual: HealthVisualData;

  private text(key: string | undefined, args: string[] | undefined = []): string {
    if (!key) return '';
    return localizedHealthText(this, key, args || []);
  }

  private gaugeAccent(): ResourceColor {
    if (this.cardType === 'RunningAbility') return AppColors.VISUAL_ORANGE;
    if (this.cardType === 'CyclingAbility') return AppColors.VISUAL_GREEN;
    return AppColors.VISUAL_CYAN;
  }

  @Builder GaugeOverview() {
    if (this.cardType === 'Recovery') {
      Column({ space: 2 }) {
        Stack({ alignContent: Alignment.Top }) {
          Path()
            .commands(gaugeArcPath(1, 57, 55, 52))
            .width(114).height(58).fill(AppColors.TRANSPARENT)
            .stroke(AppColors.RANGE_TRACK).strokeWidth(4)
          if (gaugeProgress(this.visual.progress) > 0) {
            Path()
              .commands(gaugeArcPath(gaugeProgress(this.visual.progress), 57, 55, 52))
              .width(114).height(58).fill(AppColors.TRANSPARENT)
              .stroke(AppColors.VISUAL_CYAN).strokeWidth(4)
          }
          Image(AppImages.recoveryStatus()).width(21).height(30).objectFit(ImageFit.Contain).margin({ top: 20 })
        }
        .width(114).height(58)
        Text(this.text(gaugeProgress(this.visual.progress) >= 0.7 ? 'health_visual_recovery_ready' : 'health_visual_recovery_low'))
          .fontSize(11).fontColor(AppColors.HEALTH_CARD_TITLE)
      }
      .width(114).height(78).alignItems(HorizontalAlign.Center)
    } else {
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
              .stroke((index + 0.5) / 30 <= gaugeProgress(this.visual.progress) ? this.gaugeAccent() : AppColors.RANGE_TRACK)
              .strokeWidth(3)
          })
          Path()
            .commands(abilityNeedlePath(this.visual.progress || 0))
            .width(121).height(60).fill(AppColors.TRANSPARENT)
            .stroke(AppColors.HEALTH_CARD_TITLE).strokeWidth(2)
          Circle().width(5).height(5).fill(AppColors.HEALTH_CARD_TITLE).margin({ left: 58, top: 52.5 })
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
  }

  build() {
    Row() {
      Column({ space: 0 }) {
        Row() {
          Text(this.visual.primaryValue || '--').fontSize(32).fontFamily('COROSAPPBold').fontColor(AppColors.WHITE).fontWeight(FontWeight.Bold)
          if (this.visual.primaryUnitKey) { Text(this.text(this.visual.primaryUnitKey)).fontSize(20).fontFamily('COROSAPPBold').fontWeight(FontWeight.Bold).fontColor(AppColors.HEALTH_METRIC_UNIT).margin({ left: 3 }) }
        }
        Text(this.text(this.visual.captionKey, this.visual.captionArgs)).fontSize(12).fontColor(AppColors.MUTED).maxLines(1)
        Text(this.text(this.visual.detailKey, this.visual.detailArgs)).fontSize(12).fontColor(AppColors.MUTED).maxLines(1)
      }.width(141).alignItems(HorizontalAlign.Start).margin({ top: 8 })
      Blank()
      this.GaugeOverview()
    }.width('100%').alignItems(VerticalAlign.Center)
  }
}
