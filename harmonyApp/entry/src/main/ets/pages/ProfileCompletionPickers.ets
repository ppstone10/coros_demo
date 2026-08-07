import { COROS_WHITE, COROS_MUTED } from '../auth/components/AuthColors';
import { AppColors } from '../core/resources/AppResources';

function pcBuildNumberRange(min: number, max: number, suffix: string = ''): string[] {
  let result: string[] = [];
  for (let i = min; i <= max; i++) {
    result.push(`${i}${suffix}`);
  }
  return result;
}

function pcClamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}

function pcPickerIndex(index: number | number[]): number {
  if (typeof index === 'number') {
    return index;
  }
  return index.length > 0 ? index[0] : 0;
}

function pcParseBirthDate(value: string): number[] {
  let matches: string[] | null = value.match(/\d+/g);
  let year: number = matches !== null && matches.length > 0 ? parseInt(matches[0]) : 2002;
  let month: number = matches !== null && matches.length > 1 ? parseInt(matches[1]) : 11;
  let day: number = matches !== null && matches.length > 2 ? parseInt(matches[2]) : 17;
  return [
    pcClamp(year, 1950, 2026),
    pcClamp(month, 1, 12),
    pcClamp(day, 1, 31)
  ];
}

@Component
struct PickerSheetHeaderComponent {
  @Prop title: ResourceStr = '';
  onDismiss: () => void = () => {};
  onConfirm: () => void = () => {};

  build() {
    Row() {
      Row() {
        Image($r('app.media.ic_profile_close'))
          .width(32)
          .height(32)
          .objectFit(ImageFit.Contain)
      }
      .width(70)
      .height(70)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .onClick(() => { this.onDismiss(); })

      Text(this.title)
        .layoutWeight(1)
        .fontSize(20)
        .fontColor(COROS_WHITE)
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center)

      Row() {
        Image($r('app.media.ic_profile_check'))
          .width(34)
          .height(34)
          .objectFit(ImageFit.Contain)
      }
      .width(70)
      .height(70)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .onClick(() => { this.onConfirm(); })
    }
    .width('100%')
    .height(70)
    .alignItems(VerticalAlign.Center)
  }
}

@Component
struct NumberWheelPickerComponent {
  @Link value: number;
  @Prop min: number = 0;
  @Prop max: number = 100;
  @Prop suffix: ResourceStr = '';
  @Prop pickerWidth: number = 140;

  private syncValue(index: number | number[]): void {
    this.value = this.min + pcPickerIndex(index);
  }

  private suffixText(): string {
    if (typeof this.suffix === 'string') {
      return this.suffix;
    }
    return getContext(this).resourceManager.getStringSync(this.suffix.id);
  }

  build() {
    TextPicker({
      range: pcBuildNumberRange(this.min, this.max, this.suffixText()),
      selected: pcClamp(this.value, this.min, this.max) - this.min
    })
      .width(this.pickerWidth)
      .height(248)
      .defaultPickerItemHeight(54)
      .canLoop(false)
      .selectedTextStyle({ color: COROS_WHITE, font: { size: 28, weight: FontWeight.Medium } })
      .textStyle({ color: AppColors.PROFILE_WHEEL_NEAR, font: { size: 23, weight: FontWeight.Normal } })
      .disappearTextStyle({ color: AppColors.PROFILE_WHEEL_FAR, font: { size: 18, weight: FontWeight.Normal } })
      .divider({ strokeWidth: 1, color: AppColors.PROFILE_WHEEL_BORDER, startMargin: 14, endMargin: 14 })
      .onChange((value: string | string[], index: number | number[]) => {
        this.syncValue(index);
      })
  }
}

@Component
struct BirthDatePickerSheetComponent {
  @Prop current: string = '';
  @State year: number = 2002;
  @State month: number = 11;
  @State day: number = 17;
  onDismiss: () => void = () => {};
  onConfirm: (value: string) => void = (_: string) => {};

  aboutToAppear(): void {
    let values: number[] = pcParseBirthDate(this.current);
    this.year = values[0];
    this.month = values[1];
    this.day = values[2];
  }

  private localized(resource: Resource): string {
    return getContext(this).resourceManager.getStringSync(resource.id);
  }

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(AppColors.AUTH_OVERLAY_SOFT)
        .onClick(() => { this.onDismiss(); })

      Column() {
        PickerSheetHeaderComponent({
          title: $r('app.string.profile_birth_date'),
          onDismiss: () => { this.onDismiss(); },
          onConfirm: () => {
            this.onConfirm(`${this.year}${this.localized($r('app.string.profile_date_year_suffix'))}` +
              `${this.month}${this.localized($r('app.string.profile_date_month_suffix'))}` +
              `${this.day}${this.localized($r('app.string.profile_date_day_suffix'))}`);
          }
        });

        Row() {
          NumberWheelPickerComponent({ value: $year, min: 1950, max: 2026, suffix: $r('app.string.profile_date_year_suffix'), pickerWidth: 110 })
            .layoutWeight(1)
          NumberWheelPickerComponent({ value: $month, min: 1, max: 12, suffix: $r('app.string.profile_date_month_suffix'), pickerWidth: 110 })
            .layoutWeight(1)
          NumberWheelPickerComponent({ value: $day, min: 1, max: 31, suffix: $r('app.string.profile_date_day_suffix'), pickerWidth: 110 })
            .layoutWeight(1)
        }
        .width('100%')
        .height(240)
        .alignItems(VerticalAlign.Center)
        .justifyContent(FlexAlign.SpaceEvenly)

        Blank().height(28)
      }
      .width('100%')
      .backgroundColor(AppColors.AUTH_SHEET)
      .borderRadius({ topLeft: 14, topRight: 14 })
      .align(Alignment.Bottom)
    }
    .width('100%')
    .height('100%')
  }
}

@Component
struct HeightPickerSheetComponent {
  @Prop current: number = 175;
  @State heightCm: number = 175;
  onDismiss: () => void = () => {};
  onConfirm: (value: number) => void = (_: number) => {};

  aboutToAppear(): void {
    this.heightCm = pcClamp(this.current, 100, 230);
  }

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(AppColors.AUTH_OVERLAY_SOFT)
        .onClick(() => { this.onDismiss(); })

      Column() {
        PickerSheetHeaderComponent({
          title: $r('app.string.profile_height_picker'),
          onDismiss: () => { this.onDismiss(); },
          onConfirm: () => { this.onConfirm(this.heightCm); }
        });

        Row() {
          NumberWheelPickerComponent({ value: $heightCm, min: 100, max: 230, suffix: '', pickerWidth: 140 })
        }
        .width('100%')
        .height(240)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)

        Blank().height(28)
      }
      .width('100%')
      .backgroundColor(AppColors.AUTH_SHEET)
      .borderRadius({ topLeft: 14, topRight: 14 })
      .align(Alignment.Bottom)
    }
    .width('100%')
    .height('100%')
  }
}

@Component
struct WeightPickerSheetComponent {
  @Prop current: number = 60.0;
  @State integerPart: number = 60;
  @State decimalPart: number = 0;
  onDismiss: () => void = () => {};
  onConfirm: (value: number) => void = (_: number) => {};

  aboutToAppear(): void {
    let safeCurrent: number = isNaN(this.current) ? 60.0 : this.current;
    let integerValue: number = Math.floor(safeCurrent);
    let decimalValue: number = Math.round((safeCurrent - integerValue) * 10);
    this.integerPart = pcClamp(integerValue, 30, 200);
    this.decimalPart = pcClamp(decimalValue, 0, 9);
  }

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(AppColors.AUTH_OVERLAY_SOFT)
        .onClick(() => { this.onDismiss(); })

      Column() {
        PickerSheetHeaderComponent({
          title: $r('app.string.profile_weight_picker'),
          onDismiss: () => { this.onDismiss(); },
          onConfirm: () => {
            this.onConfirm(this.integerPart + this.decimalPart / 10.0);
          }
        });

        Row() {
          NumberWheelPickerComponent({ value: $integerPart, min: 30, max: 200, suffix: '', pickerWidth: 140 })

          Text('.')
            .fontSize(32)
            .fontColor(COROS_WHITE)
            .padding({ left: 16, right: 16 })

          NumberWheelPickerComponent({ value: $decimalPart, min: 0, max: 9, suffix: '', pickerWidth: 140 })
        }
        .width('100%')
        .height(240)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)

        Blank().height(28)
      }
      .width('100%')
      .backgroundColor(AppColors.AUTH_SHEET)
      .borderRadius({ topLeft: 14, topRight: 14 })
      .align(Alignment.Bottom)
    }
    .width('100%')
    .height('100%')
  }
}

@Component
struct UnitPickerSheetComponent {
  @Prop current: string = 'Metric';
  @State selected: string = 'Metric';
  onDismiss: () => void = () => {};
  onConfirm: (value: string) => void = (_: string) => {};

  aboutToAppear(): void {
    this.selected = this.current === 'Imperial' ? 'Imperial' : 'Metric';
  }

  @Builder
  OptionRow(textValue: ResourceStr, value: string) {
    Row() {
      Text(textValue)
        .fontSize(this.selected === value ? 22 : 18)
        .fontColor(this.selected === value ? COROS_WHITE : COROS_MUTED)
    }
    .width('100%')
    .height(56)
    .justifyContent(FlexAlign.Center)
    .margin({ left: 20, right: 20 })
    .border({
      width: this.selected === value ? 1 : 0,
      color: this.selected === value ? AppColors.PROFILE_SELECTED_BORDER : AppColors.TRANSPARENT,
      radius: 8
    })
    .onClick(() => { this.selected = value; })
  }

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(AppColors.AUTH_OVERLAY_SOFT)
        .onClick(() => { this.onDismiss(); })

      Column() {
        PickerSheetHeaderComponent({
          title: $r('app.string.profile_measurement'),
          onDismiss: () => { this.onDismiss(); },
          onConfirm: () => { this.onConfirm(this.selected); }
        });

        Column() {
          this.OptionRow($r('app.string.profile_unit_metric'), 'Metric');
          this.OptionRow($r('app.string.profile_unit_imperial'), 'Imperial');
        }
        .width('100%')
        .height(240)
        .justifyContent(FlexAlign.Center)

        Blank().height(28)
      }
      .width('100%')
      .backgroundColor(AppColors.AUTH_SHEET)
      .borderRadius({ topLeft: 14, topRight: 14 })
      .align(Alignment.Bottom)
    }
    .width('100%')
    .height('100%')
  }
}

@Component
struct CountryPickerSheetComponent {
  @Prop current: string = '';
  @State selected: string = '';
  onDismiss: () => void = () => {};
  onConfirm: (value: string) => void = (_: string) => {};

  aboutToAppear(): void {
    this.selected = this.current.length > 0 ? this.current : 'CN';
  }

  private localized(resource: Resource): string {
    return getContext(this).resourceManager.getStringSync(resource.id);
  }

  @Builder
  OptionRow(textValue: ResourceStr, value: string) {
    Row() {
      Text(textValue)
        .fontSize(this.selected === value ? 22 : 18)
        .fontColor(this.selected === value ? COROS_WHITE : COROS_MUTED)
    }
    .width('100%')
    .height(56)
    .justifyContent(FlexAlign.Center)
    .margin({ left: 20, right: 20 })
    .border({
      width: this.selected === value ? 1 : 0,
      color: this.selected === value ? AppColors.PROFILE_SELECTED_BORDER : AppColors.TRANSPARENT,
      radius: 8
    })
    .onClick(() => { this.selected = value; })
  }

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(AppColors.AUTH_OVERLAY_SOFT)
        .onClick(() => { this.onDismiss(); })

      Column() {
        PickerSheetHeaderComponent({
          title: $r('app.string.profile_country_region'),
          onDismiss: () => { this.onDismiss(); },
          onConfirm: () => { this.onConfirm(this.selected); }
        });

        Column() {
          this.OptionRow($r('app.string.common_china'), 'CN');
          this.OptionRow($r('app.string.common_united_states'), 'US');
          this.OptionRow($r('app.string.common_united_kingdom'), 'GB');
          this.OptionRow($r('app.string.common_japan'), 'JP');
        }
        .width('100%')
        .height(240)
        .justifyContent(FlexAlign.Center)

        Blank().height(28)
      }
      .width('100%')
      .backgroundColor(AppColors.AUTH_SHEET)
      .borderRadius({ topLeft: 14, topRight: 14 })
      .align(Alignment.Bottom)
    }
    .width('100%')
    .height('100%')
  }
}

@Component
export struct BirthDatePickerSheetV2 {
  @Link profileBirthDate: string;
  @Link activePicker: string;
  @State year: number = 2002;
  @State month: number = 11;
  @State day: number = 17;

  aboutToAppear(): void {
    let values: number[] = pcParseBirthDate(this.profileBirthDate);
    this.year = values[0];
    this.month = values[1];
    this.day = values[2];
  }

  private close(): void {
    this.activePicker = '';
  }

  private localized(resource: Resource): string {
    return getContext(this).resourceManager.getStringSync(resource.id);
  }

  private confirm(): void {
    this.profileBirthDate = `${this.year}${this.localized($r('app.string.profile_date_year_suffix'))}` +
      `${this.month}${this.localized($r('app.string.profile_date_month_suffix'))}` +
      `${this.day}${this.localized($r('app.string.profile_date_day_suffix'))}`;
    this.activePicker = '';
  }

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(AppColors.AUTH_OVERLAY_SOFT)
        .onClick(() => { this.close(); })

      Column() {
        PickerSheetHeaderComponent({
          title: $r('app.string.profile_birth_date'),
          onDismiss: () => { this.close(); },
          onConfirm: () => { this.confirm(); }
        })

        Row() {
          NumberWheelPickerComponent({ value: $year, min: 1950, max: 2026, suffix: $r('app.string.profile_date_year_suffix'), pickerWidth: 110 })
            .layoutWeight(1)
          NumberWheelPickerComponent({ value: $month, min: 1, max: 12, suffix: $r('app.string.profile_date_month_suffix'), pickerWidth: 110 })
            .layoutWeight(1)
          NumberWheelPickerComponent({ value: $day, min: 1, max: 31, suffix: $r('app.string.profile_date_day_suffix'), pickerWidth: 110 })
            .layoutWeight(1)
        }
        .width('100%')
        .height(240)
        .alignItems(VerticalAlign.Center)
        .justifyContent(FlexAlign.SpaceEvenly)

        Blank().height(28)
      }
      .width('100%')
      .backgroundColor(AppColors.AUTH_SHEET)
      .borderRadius({ topLeft: 14, topRight: 14 })
      .align(Alignment.Bottom)
    }
    .width('100%')
    .height('100%')
  }
}

@Component
export struct HeightPickerSheetV2 {
  @Link profileHeightCm: string;
  @Link activePicker: string;
  @State heightCm: number = 175;

  aboutToAppear(): void {
    let current: number = this.profileHeightCm.length > 0 ? parseInt(this.profileHeightCm) : 175;
    this.heightCm = pcClamp(current, 100, 230);
  }

  private close(): void {
    this.activePicker = '';
  }

  private confirm(): void {
    this.profileHeightCm = `${this.heightCm}`;
    this.activePicker = '';
  }

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(AppColors.AUTH_OVERLAY_SOFT)
        .onClick(() => { this.close(); })

      Column() {
        PickerSheetHeaderComponent({
          title: $r('app.string.profile_height_picker'),
          onDismiss: () => { this.close(); },
          onConfirm: () => { this.confirm(); }
        })

        Row() {
          NumberWheelPickerComponent({ value: $heightCm, min: 100, max: 230, suffix: '', pickerWidth: 140 })
        }
        .width('100%')
        .height(240)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)

        Blank().height(28)
      }
      .width('100%')
      .backgroundColor(AppColors.AUTH_SHEET)
      .borderRadius({ topLeft: 14, topRight: 14 })
      .align(Alignment.Bottom)
    }
    .width('100%')
    .height('100%')
  }
}

@Component
export struct WeightPickerSheetV2 {
  @Link profileWeightKg: string;
  @Link activePicker: string;
  @State integerPart: number = 60;
  @State decimalPart: number = 0;

  aboutToAppear(): void {
    let current: number = this.profileWeightKg.length > 0 ? parseFloat(this.profileWeightKg) : 60.0;
    if (isNaN(current)) {
      current = 60.0;
    }
    let integerValue: number = Math.floor(current);
    let decimalValue: number = Math.round((current - integerValue) * 10);
    this.integerPart = pcClamp(integerValue, 30, 200);
    this.decimalPart = pcClamp(decimalValue, 0, 9);
  }

  private close(): void {
    this.activePicker = '';
  }

  private confirm(): void {
    this.profileWeightKg = (this.integerPart + this.decimalPart / 10.0).toFixed(1);
    this.activePicker = '';
  }

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(AppColors.AUTH_OVERLAY_SOFT)
        .onClick(() => { this.close(); })

      Column() {
        PickerSheetHeaderComponent({
          title: $r('app.string.profile_weight_picker'),
          onDismiss: () => { this.close(); },
          onConfirm: () => { this.confirm(); }
        })

        Row() {
          NumberWheelPickerComponent({ value: $integerPart, min: 30, max: 200, suffix: '', pickerWidth: 140 })

          Text('.')
            .fontSize(32)
            .fontColor(COROS_WHITE)
            .padding({ left: 16, right: 16 })

          NumberWheelPickerComponent({ value: $decimalPart, min: 0, max: 9, suffix: '', pickerWidth: 140 })
        }
        .width('100%')
        .height(240)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)

        Blank().height(28)
      }
      .width('100%')
      .backgroundColor(AppColors.AUTH_SHEET)
      .borderRadius({ topLeft: 14, topRight: 14 })
      .align(Alignment.Bottom)
    }
    .width('100%')
    .height('100%')
  }
}

@Component
export struct UnitPickerSheetV2 {
  @Link profileMeasurementSystem: string;
  @Link activePicker: string;
  @State selectedIndex: number = 0;
  private labels: string[] = [];
  private values: string[] = ['Metric', 'Imperial'];

  aboutToAppear(): void {
    this.labels = [
      this.localized($r('app.string.profile_unit_metric')),
      this.localized($r('app.string.profile_unit_imperial'))
    ];
    this.selectedIndex = this.profileMeasurementSystem === 'Imperial' ? 1 : 0;
  }

  private localized(resource: Resource): string {
    return getContext(this).resourceManager.getStringSync(resource.id);
  }

  private close(): void {
    this.activePicker = '';
  }

  private confirm(): void {
    this.profileMeasurementSystem = this.values[this.selectedIndex];
    this.activePicker = '';
  }

  private sync(index: number | number[]): void {
    this.selectedIndex = pcClamp(pcPickerIndex(index), 0, this.values.length - 1);
  }

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(AppColors.AUTH_OVERLAY_SOFT)
        .onClick(() => { this.close(); })

      Column() {
        PickerSheetHeaderComponent({
          title: $r('app.string.profile_measurement'),
          onDismiss: () => { this.close(); },
          onConfirm: () => { this.confirm(); }
        })

        Row() {
          TextPicker({ range: this.labels, selected: this.selectedIndex })
            .width('90%')
            .height(248)
            .defaultPickerItemHeight(54)
            .canLoop(true)
            .selectedTextStyle({ color: COROS_WHITE, font: { size: 24, weight: FontWeight.Medium } })
            .textStyle({ color: AppColors.PROFILE_WHEEL_NEAR, font: { size: 20, weight: FontWeight.Normal } })
            .disappearTextStyle({ color: AppColors.PROFILE_WHEEL_FAR, font: { size: 18, weight: FontWeight.Normal } })
            .divider({ strokeWidth: 1, color: AppColors.PROFILE_WHEEL_BORDER, startMargin: 14, endMargin: 14 })
            .onChange((value: string | string[], index: number | number[]) => {
              this.sync(index);
            })
        }
        .width('100%')
        .height(240)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)

        Blank().height(28)
      }
      .width('100%')
      .backgroundColor(AppColors.AUTH_SHEET)
      .borderRadius({ topLeft: 14, topRight: 14 })
      .align(Alignment.Bottom)
    }
    .width('100%')
    .height('100%')
  }
}

@Component
export struct CountryPickerSheetV2 {
  @Link profileCountry: string;
  @Link activePicker: string;
  @State selectedIndex: number = 0;
  private countryCodes: string[] = ['CN', 'US', 'GB', 'JP'];
  private countries: string[] = [];

  aboutToAppear(): void {
    this.countries = [
      this.localized($r('app.string.common_china')),
      this.localized($r('app.string.common_united_states')),
      this.localized($r('app.string.common_united_kingdom')),
      this.localized($r('app.string.common_japan'))
    ];
    let index: number = this.countryCodes.indexOf(this.profileCountry);
    this.selectedIndex = index >= 0 ? index : 0;
  }

  private localized(resource: Resource): string {
    return getContext(this).resourceManager.getStringSync(resource.id);
  }

  private close(): void {
    this.activePicker = '';
  }

  private confirm(): void {
    this.profileCountry = this.countryCodes[this.selectedIndex];
    this.activePicker = '';
  }

  private sync(index: number | number[]): void {
    this.selectedIndex = pcClamp(pcPickerIndex(index), 0, this.countries.length - 1);
  }

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(AppColors.AUTH_OVERLAY_SOFT)
        .onClick(() => { this.close(); })

      Column() {
        PickerSheetHeaderComponent({
          title: $r('app.string.profile_country_region'),
          onDismiss: () => { this.close(); },
          onConfirm: () => { this.confirm(); }
        })

        Row() {
          TextPicker({ range: this.countries, selected: this.selectedIndex })
            .width(180)
            .height(248)
            .defaultPickerItemHeight(54)
            .canLoop(true)
            .selectedTextStyle({ color: COROS_WHITE, font: { size: 28, weight: FontWeight.Medium } })
            .textStyle({ color: AppColors.PROFILE_WHEEL_NEAR, font: { size: 23, weight: FontWeight.Normal } })
            .disappearTextStyle({ color: AppColors.PROFILE_WHEEL_FAR, font: { size: 18, weight: FontWeight.Normal } })
            .divider({ strokeWidth: 1, color: AppColors.PROFILE_WHEEL_BORDER, startMargin: 14, endMargin: 14 })
            .onChange((value: string | string[], index: number | number[]) => {
              this.sync(index);
            })
        }
        .width('100%')
        .height(240)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)

        Blank().height(28)
      }
      .width('100%')
      .backgroundColor(AppColors.AUTH_SHEET)
      .borderRadius({ topLeft: 14, topRight: 14 })
      .align(Alignment.Bottom)
    }
    .width('100%')
    .height('100%')
  }
}

@Component
export struct GenderPickerSheetV2 {
  @Link profileGender: string;
  @Link activePicker: string;
  @State selectedIndex: number = 0;
  private labels: string[] = [];
  private values: string[] = ['Female', 'Male'];

  aboutToAppear(): void {
    this.labels = [
      this.localized($r('app.string.common_female')),
      this.localized($r('app.string.common_male'))
    ];
    let index: number = this.values.indexOf(this.profileGender);
    this.selectedIndex = index >= 0 ? index : 0;
  }

  private localized(resource: Resource): string {
    return getContext(this).resourceManager.getStringSync(resource.id);
  }

  private close(): void {
    this.activePicker = '';
  }

  private confirm(): void {
    this.profileGender = this.values[this.selectedIndex];
    this.activePicker = '';
  }

  build() {
    Stack() {
      Column().width('100%').height('100%').backgroundColor(AppColors.AUTH_OVERLAY_SOFT)
        .onClick(() => { this.close(); })

      Column() {
        PickerSheetHeaderComponent({
          title: $r('app.string.profile_gender'),
          onDismiss: () => { this.close(); },
          onConfirm: () => { this.confirm(); }
        })
        TextPicker({ range: this.labels, selected: this.selectedIndex })
          .width('90%').height(240).defaultPickerItemHeight(54).canLoop(false)
          .selectedTextStyle({ color: COROS_WHITE, font: { size: 28, weight: FontWeight.Medium } })
          .textStyle({ color: AppColors.PROFILE_WHEEL_NEAR, font: { size: 23, weight: FontWeight.Normal } })
          .disappearTextStyle({ color: AppColors.PROFILE_WHEEL_FAR, font: { size: 18, weight: FontWeight.Normal } })
          .divider({ strokeWidth: 1, color: AppColors.PROFILE_WHEEL_BORDER, startMargin: 14, endMargin: 14 })
          .onChange((_value: string | string[], index: number | number[]) => {
            this.selectedIndex = pcClamp(pcPickerIndex(index), 0, this.values.length - 1);
          })
        Blank().height(28)
      }
      .width('100%').backgroundColor(AppColors.AUTH_SHEET)
      .borderRadius({ topLeft: 14, topRight: 14 }).align(Alignment.Bottom)
    }
    .width('100%').height('100%')
  }
}
