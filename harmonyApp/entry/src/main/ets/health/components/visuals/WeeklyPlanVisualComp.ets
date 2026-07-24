import { AppColors, AppImages } from '../../../resources/AppResources';
import { HealthChartPointData, HealthVisualData, WeeklyDayPlanData, localizedHealthText } from '../../HealthDashboardTypes';
import { barColor, barHeight } from './HealthVisualHelpers';

@Component
export struct WeeklyPlanVisualComp {
  @Prop visual: HealthVisualData;
  @State selectedDay: number = -1;

  private text(key: string | undefined, args: string[] | undefined = []): string {
    if (!key) return '';
    return localizedHealthText(this, key, args || []);
  }

  private weeklySelectedIndex(): number {
    if (this.selectedDay >= 0) return Math.max(0, Math.min(6, this.selectedDay));
    return Math.max(0, Math.min(6, this.visual.highlightedIndex || 0));
  }

  private weeklyPlan(): WeeklyDayPlanData | undefined {
    const selected: number = this.weeklySelectedIndex();
    return (this.visual.weeklyDayPlans || []).find((plan: WeeklyDayPlanData) => plan.dayIndex === selected);
  }

  build() {
    Column({ space: 8 }) {
      Row() {
        ForEach(this.visual.chartPoints.slice(0, 7), (point: HealthChartPointData, index: number) => {
          Text(this.text(point.label)).fontSize(14).fontColor(index === this.weeklySelectedIndex() ? AppColors.WHITE : AppColors.MUTED)
            .width(28).height(28).textAlign(TextAlign.Center)
            .backgroundColor(index === this.weeklySelectedIndex() ? AppColors.ACTION : AppColors.TRANSPARENT).borderRadius(14)
            .onClick(() => {
              this.selectedDay = index;
            })
          if (index < 6) { Blank() }
        })
      }.width('100%')
      Row({ space: 8 }) {
        Image(AppImages.todayRunner()).width(20).height(20).objectFit(ImageFit.Contain)
        Column({ space: 2 }) {
          Text(this.weeklyPlan()?.workoutNameKey ?
            this.text(this.weeklyPlan()?.workoutNameKey) : this.text('health_visual_weekly_rest_day'))
            .fontSize(14).fontColor(AppColors.WHITE).maxLines(1)
          Row() {
            Text(this.weeklyPlan()?.workoutDurationMinutes?.toString() || '--')
              .fontSize(12).fontFamily('COROSAPPBold').fontColor(AppColors.WHITE)
            if (this.weeklyPlan()?.workoutDurationMinutes !== undefined) {
              Text(this.text('health_unit_minutes_long'))
                .fontSize(12).fontFamily('COROSAPPBold').fontColor(AppColors.MUTED).margin({ left: 2 })
            }
            if (this.weeklyPlan()?.workoutTrainingLoad !== undefined) {
              Text(`  ${this.weeklyPlan()?.workoutTrainingLoad} ${this.text('health_visual_training_load_short')}`)
                .fontSize(11).fontColor(AppColors.MUTED)
            }
          }
        }.alignItems(HorizontalAlign.Start).layoutWeight(1)
        Blank()
        Row({ space: 5 }) {
          ForEach(this.visual.chartPoints, (point: HealthChartPointData, index: number) => {
            Stack({ alignContent: Alignment.Bottom }) {
              Row().width('100%').height(barHeight(point, 36, this.visual.chartPoints))
                .backgroundColor(barColor(this.visual.kind, point, index, this.weeklySelectedIndex())).borderRadius(2)
            }
            .height(36).layoutWeight(1)
          })
        }.height(36).width(80).alignItems(VerticalAlign.Bottom).clip(true)
      }.width('100%').height(64).padding({ left: 16, right: 16 }).backgroundColor(AppColors.ACTIVITY_TILE).borderRadius(6)
    }.margin({ top: 8 })
  }
}
