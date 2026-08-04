import { AppColors } from '../../core/resources/AppResources';
import { healthResource } from '../../core/resources/HealthLocalization';
import { HealthScenarioEntry } from '../HealthDashboardTypes';

@Component
export struct ScenarioPickerComp {
  @Prop selectedScenario: string = 'Normal';
  onSelect?: (name: string) => void;
  onDismiss?: () => void;

  @Prop scenarios: HealthScenarioEntry[] = [];

  build() {
    Column() {
      Column({ space: 8 }) {
        ForEach(this.scenarios, (scenario: HealthScenarioEntry) => {
          Row() {
            Text(healthResource(scenario.displayKey)).fontSize(15).fontColor(AppColors.WHITE)
            Blank().layoutWeight(1)
            if (scenario.code === this.selectedScenario) {
              Text('✓').fontSize(16).fontColor(AppColors.STEPS)
            }
          }
          .width('100%').padding(14)
          .onClick(() => {
            if (this.onSelect) this.onSelect(scenario.code);
          })
        }, (scenario: HealthScenarioEntry) => scenario.code)
      }
      .borderRadius(10).backgroundColor(AppColors.DIALOG_ALT).padding(12).margin({ left: 24, right: 24 })
    }
    .width('100%').height('100%').backgroundColor(AppColors.OVERLAY_62).justifyContent(FlexAlign.Center)
    .onClick(() => { if (this.onDismiss) this.onDismiss(); })
  }
}
