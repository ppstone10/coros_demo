import { AppColors, AppImages } from '../../../core/resources/AppResources';
import { HealthVisualData, localizedHealthText } from '../../HealthDashboardTypes';
import { gaugeProgress, gaugeArcPath } from './HealthVisualHelpers';

@Component
export struct RecoveryVisualComp {
  @Prop visual: HealthVisualData;

  private text(key: string | undefined, args: string[] | undefined = []): string {
    if (!key) return '';
    return localizedHealthText(this, key, args || []);
  }

  @Builder RecoveryOverview() {
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
        Image(AppImages.recoveryStatus())
          .width(21).height(30).objectFit(ImageFit.Contain).margin({ top: 20 })
      }
      .width(114).height(58)
      Text(this.text(gaugeProgress(this.visual.progress) >= 0.7
        ? 'health_visual_recovery_ready'
        : 'health_visual_recovery_low'))
        .fontSize(11).fontColor(AppColors.HEALTH_CARD_TITLE)
    }
    .width(114).height(78).alignItems(HorizontalAlign.Center)
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
      .width(141).height(78).alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)
      Blank()
      this.RecoveryOverview()
    }
    .width('100%').height(78).alignItems(VerticalAlign.Center)
  }
}
