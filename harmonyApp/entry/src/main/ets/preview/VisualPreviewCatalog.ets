import { AbilityVisualComp } from '../health/components/visuals/AbilityVisualComp';
import { ActivityVisualComp } from '../health/components/visuals/ActivityVisualComp';
import { BodyManagementVisualComp } from '../health/components/visuals/BodyManagementVisualComp';
import { HealthGridVisualComp } from '../health/components/visuals/HealthGridVisualComp';
import { HrvAssessmentVisualComp } from '../health/components/visuals/HrvAssessmentVisualComp';
import { RecoveryVisualComp } from '../health/components/visuals/RecoveryVisualComp';
import { RestingHeartRateVisualComp } from '../health/components/visuals/RestingHeartRateVisualComp';
import { SleepVisualComp } from '../health/components/visuals/SleepVisualComp';
import { TrainingAssessmentVisualComp } from '../health/components/visuals/TrainingAssessmentVisualComp';
import { TrainingLoadVisualComp } from '../health/components/visuals/TrainingLoadVisualComp';
import { AppColors } from '../core/resources/AppResources';
import {
  abilityPreviewVisual,
  activityPreviewVisual,
  bodyPreviewVisual,
  healthGridPreviewVisual,
  hrvPreviewVisual,
  recoveryPreviewVisual,
  restingHeartRatePreviewVisual,
  sleepPreviewVisual,
  trainingAssessmentPreviewVisual,
  trainingLoadPreviewVisual
} from './VisualPreviewData';

/**
 * Visual components own required @Prop values, so DevEco previews these pure
 * parent hosts instead of previewing the production child components directly.
 * Neither this file nor VisualPreviewData imports KNOI/native runtime code.
 */
@Preview
@Component
struct AbilityVisualPreviewHost {
  build() {
    Column() {
      AbilityVisualComp({ cardType: 'RunningAbility', visual: abilityPreviewVisual() })
    }.width('100%').padding(16).backgroundColor(AppColors.HEALTH_CARD)
  }
}

@Preview
@Component
struct ActivityVisualPreviewHost {
  build() {
    Column() {
      ActivityVisualComp({ visual: activityPreviewVisual() })
    }.width('100%').padding(16).backgroundColor(AppColors.HEALTH_CARD)
  }
}

@Preview
@Component
struct BodyManagementVisualPreviewHost {
  build() {
    Column() {
      BodyManagementVisualComp({ visual: bodyPreviewVisual() })
    }.width('100%').padding(16).backgroundColor(AppColors.HEALTH_CARD)
  }
}

@Preview
@Component
struct HealthGridVisualPreviewHost {
  build() {
    Column() {
      HealthGridVisualComp({ visual: healthGridPreviewVisual() })
    }.width('100%').padding(16).backgroundColor(AppColors.HEALTH_CARD)
  }
}

@Preview
@Component
struct HrvAssessmentVisualPreviewHost {
  build() {
    Column() {
      HrvAssessmentVisualComp({ visual: hrvPreviewVisual() })
    }.width('100%').padding(16).backgroundColor(AppColors.HEALTH_CARD)
  }
}

@Preview
@Component
struct RecoveryVisualPreviewHost {
  build() {
    Column() {
      RecoveryVisualComp({ visual: recoveryPreviewVisual() })
    }.width('100%').padding(16).backgroundColor(AppColors.HEALTH_CARD)
  }
}

@Preview
@Component
struct RestingHeartRateVisualPreviewHost {
  build() {
    Column() {
      RestingHeartRateVisualComp({ visual: restingHeartRatePreviewVisual() })
    }.width('100%').padding(16).backgroundColor(AppColors.HEALTH_CARD)
  }
}

@Preview
@Component
struct SleepVisualPreviewHost {
  build() {
    Column() {
      SleepVisualComp({ visual: sleepPreviewVisual() })
    }.width('100%').padding(16).backgroundColor(AppColors.HEALTH_CARD)
  }
}

@Preview
@Component
struct TrainingAssessmentVisualPreviewHost {
  build() {
    Column() {
      TrainingAssessmentVisualComp({ visual: trainingAssessmentPreviewVisual() })
    }.width('100%').padding(16).backgroundColor(AppColors.HEALTH_CARD)
  }
}

@Preview
@Component
struct TrainingLoadVisualPreviewHost {
  build() {
    Column() {
      TrainingLoadVisualComp({ visual: trainingLoadPreviewVisual() })
    }.width('100%').padding(16).backgroundColor(AppColors.HEALTH_CARD)
  }
}
