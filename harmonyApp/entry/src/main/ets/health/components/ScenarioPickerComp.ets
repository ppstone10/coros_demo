import { AppColors } from '../../resources/AppResources';
import { getService } from '../../login/HarmonyServiceProvider';

@Component
export struct ScenarioPickerComp {
  @Prop selectedScenario: string = 'Normal';
  onSelect?: (name: string) => void;
  onDismiss?: () => void;

  private scenarios: string[] = ['Normal', 'PartialMissing', 'AllEmpty', 'Abnormal', 'ReadFailure'];

  build() {
    Column() {
      Column({ space: 8 }) {
        ForEach(this.scenarios, (scenario: string) => {
          Row() {
            Text(this.scenarioLabel(scenario)).fontSize(15).fontColor(AppColors.WHITE)
            Blank().layoutWeight(1)
            if (scenario === this.selectedScenario) {
              Text('✓').fontSize(16).fontColor(AppColors.STEPS)
            }
          }
          .width('100%').padding(14)
          .onClick(() => {
            if (this.onSelect) this.onSelect(scenario);
          })
        }, (scenario: string) => scenario)
      }
      .borderRadius(10).backgroundColor(AppColors.DIALOG_ALT).padding(12).margin({ left: 24, right: 24 })
    }
    .width('100%').height('100%').backgroundColor(AppColors.OVERLAY_62).justifyContent(FlexAlign.Center)
    .onClick(() => { if (this.onDismiss) this.onDismiss(); })
  }

  private scenarioLabel(name: string): ResourceStr {
    switch (name) {
      case 'Normal': return $r('app.string.health_scenario_normal');
      case 'PartialMissing': return $r('app.string.health_scenario_partial_missing');
      case 'AllEmpty': return $r('app.string.health_scenario_all_empty');
      case 'Abnormal': return $r('app.string.health_scenario_abnormal');
      case 'ReadFailure': return $r('app.string.health_scenario_read_failure');
      default: return name;
    }
  }
}
