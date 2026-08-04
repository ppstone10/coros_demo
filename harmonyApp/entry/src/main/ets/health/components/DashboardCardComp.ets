import { AppColors, AppImages } from '../../core/resources/AppResources';
import { HealthCardModel, HealthMetricData, localizedHealthText } from '../HealthDashboardTypes';
import { ActivityVisualComp } from './visuals/ActivityVisualComp';
import { WeeklyPlanVisualComp } from './visuals/WeeklyPlanVisualComp';
import { TrainingLoadVisualComp } from './visuals/TrainingLoadVisualComp';
import { TrainingAssessmentVisualComp } from './visuals/TrainingAssessmentVisualComp';
import { RecoveryVisualComp } from './visuals/RecoveryVisualComp';
import { AbilityVisualComp } from './visuals/AbilityVisualComp';
import { TrendVisualComp } from './visuals/TrendVisualComp';
import { RestingHeartRateVisualComp } from './visuals/RestingHeartRateVisualComp';
import { HrvAssessmentVisualComp } from './visuals/HrvAssessmentVisualComp';
import { SleepVisualComp } from './visuals/SleepVisualComp';
import { HealthGridVisualComp } from './visuals/HealthGridVisualComp';
import { BodyManagementVisualComp } from './visuals/BodyManagementVisualComp';

@Component
export struct DashboardCardComp {
  @Prop card: HealthCardModel;
  onTap?: () => void;
  onBodyWeightTap?: () => void;

  private text(key: string | undefined, args: string[] | undefined = []): string {
    if (!key) return '';
    return localizedHealthText(this, key, args || []);
  }

  private contentMinimumHeight(): number {
    if (this.card.id === 'TodayActivity') return 58;
    if (this.card.id === 'WeeklyPlan') return 110;
    if (this.card.id === 'TrainingLoad') return 60;
    if (this.card.id === 'TrainingAssessment') return 130;
    if (this.card.id === 'Recovery') return 78;
    if (this.card.id === 'RunningAbility' || this.card.id === 'CyclingAbility') return 71;
    if (this.card.id === 'HeartRate' || this.card.id === 'Stress' ||
      this.card.id === 'RestingHeartRate' || this.card.id === 'HrvAssessment' ||
      this.card.id === 'Sleep') return 60;
    if (this.card.id === 'HealthCheck') return 114;
    if (this.card.id === 'BodyManagement') return 121;
    return 0;
  }

  @Builder Header() {
    Row() {
      Image(this.card.id === 'TodayActivity' ? AppImages.todayHeader() : AppImages.healthCardIcon(this.card.id)).width(20).height(20).objectFit(ImageFit.Contain)
      Blank().width(5)
      Text(this.card.title).fontSize(16).fontColor(AppColors.HEALTH_CARD_TITLE).fontWeight(FontWeight.Medium).maxLines(1)
      Blank()
      if (this.card.id === 'HealthCheck' && this.card.visual.captionKey) {
        Text(this.text(this.card.visual.captionKey, this.card.visual.captionArgs))
          .fontSize(10).fontColor(AppColors.MUTED).maxLines(1)
      }
    }.width('100%').height(24)
  }

  @Builder Metric(metric: HealthMetricData, accent: ResourceColor = AppColors.WHITE) {
    Column({ space: 1 }) {
      Row() {
        Text(metric.value).fontSize(30).fontFamily('COROSAPPBold').fontWeight(FontWeight.Bold).fontColor(accent)
        if (metric.unitKey) { Text(this.text(metric.unitKey)).fontSize(16).fontFamily('COROSAPPBold').fontWeight(FontWeight.Bold).fontColor(AppColors.HEALTH_METRIC_UNIT).margin({ left: 3 }) }
      }
      Text(this.text(metric.labelKey)).fontSize(12).fontColor(AppColors.MUTED).maxLines(1)
    }.alignItems(HorizontalAlign.Start)
  }

  @Builder VisualContent() {
    if (this.card.id === 'TodayActivity') {
      ActivityVisualComp({ visual: this.card.visual })
    } else if (this.card.id === 'WeeklyPlan') {
      WeeklyPlanVisualComp({ visual: this.card.visual })
    } else if (this.card.id === 'TrainingLoad') {
      TrainingLoadVisualComp({ visual: this.card.visual })
    } else if (this.card.id === 'HeartRate' || this.card.id === 'Stress') {
      TrendVisualComp({ cardType: this.card.id, visual: this.card.visual })
    } else if (this.card.id === 'TrainingAssessment') {
      TrainingAssessmentVisualComp({ visual: this.card.visual })
    } else if (this.card.id === 'Recovery') {
      RecoveryVisualComp({ visual: this.card.visual })
    } else if (this.card.id === 'RunningAbility' || this.card.id === 'CyclingAbility') {
      AbilityVisualComp({ cardType: this.card.id, visual: this.card.visual })
    } else if (this.card.id === 'RestingHeartRate') {
      RestingHeartRateVisualComp({ visual: this.card.visual })
    } else if (this.card.id === 'HrvAssessment') {
      HrvAssessmentVisualComp({ visual: this.card.visual })
    } else if (this.card.id === 'Sleep') {
      SleepVisualComp({ visual: this.card.visual })
    } else if (this.card.id === 'HealthCheck') {
      HealthGridVisualComp({ visual: this.card.visual })
    } else if (this.card.id === 'BodyManagement') {
      BodyManagementVisualComp({
        visual: this.card.visual,
        onWeightTap: () => {
          if (this.onBodyWeightTap) this.onBodyWeightTap();
        }
      })
    }
  }

  build() {
    Row() {
      Column({ space: 0 }) {
        this.Header()
        if (this.card.status === 'Empty') {
          Text(this.card.summary).fontSize(14).lineHeight(18).fontColor(AppColors.MUTED).margin({ top: 12 })
        } else {
          Column() {
            this.VisualContent()
          }
          .width('100%')
          .constraintSize({ minHeight: this.contentMinimumHeight() })
          .alignItems(HorizontalAlign.Start)
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .padding({ left: 16, right: 16, top: 14, bottom: 14 })
      .backgroundColor(AppColors.HEALTH_CARD).borderRadius(8).clip(true)
      .gesture(
        TapGesture().onAction(() => { if (this.onTap) { this.onTap(); } })
      )
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 6, bottom: 6 })
  }
}
