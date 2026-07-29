import { AppColors } from '../../resources/AppResources';

@Component
export struct HealthWeightPickerSheetComp {
  @Prop current: number = 60.0;
  @State selectedIndex: number = 300;
  private weights: string[] = [];
  onDismiss: () => void = () => {};
  onConfirm: (weightKg: number) => void = (_weightKg: number) => {};

  aboutToAppear(): void {
    for (let value: number = 300; value <= 2000; value++) {
      this.weights.push((value / 10.0).toFixed(1));
    }
    this.selectedIndex = Math.max(0, Math.min(1700, Math.round(this.current * 10) - 300));
  }

  build() {
    Stack() {
      Column().width('100%').height('100%').backgroundColor(AppColors.AUTH_OVERLAY_SOFT)
        .onClick(() => { this.onDismiss(); })
      Column() {
        Row() {
          Text($r('app.string.common_cancel')).fontSize(15).fontColor(AppColors.WHITE)
            .onClick(() => { this.onDismiss(); })
          Blank()
          Text($r('app.string.profile_weight_picker')).fontSize(19)
            .fontWeight(FontWeight.Medium).fontColor(AppColors.WHITE)
          Blank()
          Text($r('app.string.common_confirm')).fontSize(15).fontColor(AppColors.WHITE)
            .onClick(() => {
              this.onConfirm((this.selectedIndex + 300) / 10.0);
            })
        }
        .width('100%').height(58).padding({ left: 20, right: 20 })
        TextPicker({ range: this.weights, selected: this.selectedIndex })
          .width('90%').height(240).defaultPickerItemHeight(54).canLoop(false)
          .selectedTextStyle({ color: AppColors.WHITE, font: { size: 28, weight: FontWeight.Medium } })
          .textStyle({ color: AppColors.PROFILE_WHEEL_NEAR, font: { size: 23, weight: FontWeight.Normal } })
          .disappearTextStyle({ color: AppColors.PROFILE_WHEEL_FAR, font: { size: 18, weight: FontWeight.Normal } })
          .divider({ strokeWidth: 1, color: AppColors.PROFILE_WHEEL_BORDER, startMargin: 14, endMargin: 14 })
          .onChange((_value: string | string[], index: number | number[]) => {
            this.selectedIndex = Array.isArray(index) ? (index[0] || 0) : index;
          })
        Blank().height(28)
      }
      .width('100%').backgroundColor(AppColors.AUTH_SHEET)
      .borderRadius({ topLeft: 14, topRight: 14 }).align(Alignment.Bottom)
    }
    .width('100%').height('100%')
  }
}
