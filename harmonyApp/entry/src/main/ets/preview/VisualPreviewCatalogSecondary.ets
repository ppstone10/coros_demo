import { TrendVisualComp } from '../health/components/visuals/TrendVisualComp';
import { WeeklyPlanVisualComp } from '../health/components/visuals/WeeklyPlanVisualComp';
import { AppColors } from '../core/resources/AppResources';
import {
  heartRatePreviewVisual,
  stressPreviewVisual,
  weeklyPlanPreviewVisual
} from './VisualPreviewData';

/** Additional pure hosts keep every ArkTS file within DevEco's 10-Preview limit. */
@Preview
@Component
struct TrendVisualPreviewHost {
  build() {
    Column({ space: 20 }) {
      TrendVisualComp({ cardType: 'HeartRate', visual: heartRatePreviewVisual() })
      Divider().color(AppColors.DIVIDER)
      TrendVisualComp({ cardType: 'Stress', visual: stressPreviewVisual() })
    }.width('100%').padding(16).backgroundColor(AppColors.HEALTH_CARD)
  }
}

@Preview
@Component
struct WeeklyPlanVisualPreviewHost {
  build() {
    Column() {
      WeeklyPlanVisualComp({ visual: weeklyPlanPreviewVisual() })
    }.width('100%').padding(16).backgroundColor(AppColors.HEALTH_CARD)
  }
}
