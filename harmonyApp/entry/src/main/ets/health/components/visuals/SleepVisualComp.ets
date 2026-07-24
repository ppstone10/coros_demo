import { AppColors } from '../../../resources/AppResources';
import { HealthVisualData, SleepStageData, localizedHealthText } from '../../HealthDashboardTypes';

@Component
export struct SleepVisualComp {
  @Prop visual: HealthVisualData;

  private text(key: string | undefined, args: string[] | undefined = []): string {
    if (!key) return '';
    return localizedHealthText(this, key, args || []);
  }

  private sleepTotalMinutes(): number {
    let total: number = 1;
    this.visual.sleepStages.forEach((stage: SleepStageData) => {
      total = Math.max(total, stage.startMinute + stage.durationMinutes);
    });
    return total;
  }

  private sleepStageTop(stage: SleepStageData): number {
    if (stage.stage === 'Awake') return 0;
    if (stage.stage === 'Rem') return 16;
    if (stage.stage === 'Deep') return 48;
    return 32;
  }

  private sleepStageColor(stage: SleepStageData): ResourceColor {
    if (stage.stage === 'Awake') return AppColors.VISUAL_YELLOW;
    if (stage.stage === 'Rem') return AppColors.VISUAL_CYAN;
    if (stage.stage === 'Deep') return AppColors.VISUAL_DEEP_BLUE;
    return AppColors.VISUAL_BLUE;
  }

  @Builder SleepOverview() {
    Stack({ alignContent: Alignment.TopStart }) {
      ForEach(this.visual.sleepStages, (stage: SleepStageData) => {
        Row()
          .width(Math.max(2, 130 * stage.durationMinutes / this.sleepTotalMinutes() - 2))
          .height(7)
          .backgroundColor(this.sleepStageColor(stage))
          .borderRadius(2)
          .margin({
            left: 130 * stage.startMinute / this.sleepTotalMinutes(),
            top: this.sleepStageTop(stage)
          })
      })
    }.width(130).height(56).clip(true)
  }

  build() {
    Row() {
      Column({ space: 0 }) {
        Row() {
          Text(this.visual.primaryValue || '--').fontSize(32).fontFamily('COROSAPPBold').fontWeight(FontWeight.Bold).fontColor(AppColors.WHITE)
          Text(this.text(this.visual.primaryUnitKey)).fontSize(20).fontFamily('COROSAPPBold').fontWeight(FontWeight.Bold).fontColor(AppColors.HEALTH_METRIC_UNIT)
          Text(this.visual.secondaryValue || '--').fontSize(32).fontFamily('COROSAPPBold').fontWeight(FontWeight.Bold).fontColor(AppColors.WHITE).margin({ left: 5 })
          Text(this.text(this.visual.secondaryUnitKey)).fontSize(20).fontFamily('COROSAPPBold').fontWeight(FontWeight.Bold).fontColor(AppColors.HEALTH_METRIC_UNIT)
        }
        Text((this.visual.startTime || '--') + ' – ' + (this.visual.endTime || '--')).fontSize(12).fontColor(AppColors.MUTED)
      }.width(141).alignItems(HorizontalAlign.Start).margin({ top: 8 })
      Blank()
      this.SleepOverview()
    }.width('100%').alignItems(VerticalAlign.Center)
  }
}
