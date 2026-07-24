import { AppColors, AppImages } from '../../resources/AppResources';
import { HealthCardModel, HealthMetricData, localizedHealthText } from '../HealthDashboardTypes';
import { ActivityVisualComp } from './visuals/ActivityVisualComp';
import { WeeklyPlanVisualComp } from './visuals/WeeklyPlanVisualComp';
import { TrainingLoadVisualComp } from './visuals/TrainingLoadVisualComp';
import { TrainingAssessmentVisualComp } from './visuals/TrainingAssessmentVisualComp';
import { GaugeVisualComp } from './visuals/GaugeVisualComp';
import { TrendVisualComp } from './visuals/TrendVisualComp';
import { RangeIndicatorVisualComp } from './visuals/RangeIndicatorVisualComp';
import { SleepVisualComp } from './visuals/SleepVisualComp';
import { HealthGridVisualComp } from './visuals/HealthGridVisualComp';
import { BodyManagementVisualComp } from './visuals/BodyManagementVisualComp';

@Component
export struct DashboardCardComp {
  @Prop card: HealthCardModel;
  onTap?: () => void;

  private text(key: string | undefined, args: string[] | undefined = []): string {
    if (!key) return '';
    return localizedHealthText(this, key, args || []);
  }

  private contentMinimumHeight(): number {
    if (this.card.visual.kind === 'TodayActivity') return 58;
    if (this.card.visual.kind === 'WeeklyPlan') return 110;
    if (this.card.visual.kind === 'TrainingLoad') return 60;
    if (this.card.visual.kind === 'TrainingAssessment') return 130;
    if (this.card.visual.kind === 'RecoveryGauge' || this.card.visual.kind === 'AbilityGauge') return 78;
    if (this.card.visual.kind === 'TrendBars' ||
      this.card.visual.kind === 'RangeIndicator' ||
      this.card.visual.kind === 'SleepStages') return 60;
    if (this.card.visual.kind === 'HealthCheckGrid') return 114;
    if (this.card.visual.kind === 'BodyMap') return 121;
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
    if (this.card.visual.kind === 'TodayActivity') {
      ActivityVisualComp({ visual: this.card.visual })
    } else if (this.card.visual.kind === 'WeeklyPlan') {
      WeeklyPlanVisualComp({ visual: this.card.visual })
    } else if (this.card.visual.kind === 'TrainingLoad') {
      TrainingLoadVisualComp({ visual: this.card.visual })
    } else if (this.card.visual.kind === 'TrendBars') {
      TrendVisualComp({ cardType: this.card.id, visual: this.card.visual })
    } else if (this.card.visual.kind === 'TrainingAssessment') {
      TrainingAssessmentVisualComp({ visual: this.card.visual })
    } else if (this.card.visual.kind === 'RecoveryGauge' || this.card.visual.kind === 'AbilityGauge') {
      GaugeVisualComp({ cardType: this.card.id, visual: this.card.visual })
    } else if (this.card.visual.kind === 'RangeIndicator') {
      RangeIndicatorVisualComp({ cardType: this.card.id, visual: this.card.visual })
    } else if (this.card.visual.kind === 'SleepStages') {
      SleepVisualComp({ visual: this.card.visual })
    } else if (this.card.visual.kind === 'HealthCheckGrid') {
      HealthGridVisualComp({ visual: this.card.visual })
    } else if (this.card.visual.kind === 'BodyMap') {
      BodyManagementVisualComp({ visual: this.card.visual })
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
      .onClick(() => { if (this.onTap) { this.onTap(); } })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 6, bottom: 6 })
  }
}
