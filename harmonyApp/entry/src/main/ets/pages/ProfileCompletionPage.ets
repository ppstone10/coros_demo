import promptAction from '@ohos.promptAction';
import photoAccessHelper from '@ohos.file.photoAccessHelper';
import router from '@ohos.router';
import {
  LoginEffect,
  LoginEffectType,
  LoginState
} from '../login/LoginState';
import { getLoginViewModel } from '../login/LoginViewModelProvider';
import { navigate, NavOperation, showToast } from '../login/AuthNavigator';
import {
  COROS_BUTTON_RED,
  COROS_BLACK,
  COROS_WHITE,
  COROS_RED,
  COROS_MUTED,
  COROS_LINE
} from '../login/components/AuthColors';
import {
  AuthTitle,
  ErrorText,
  CorosButton,
  AuthHeader
} from '../login/components/AuthComponents';
import { AuthRoutes, ProfilePageParams } from '../login/AuthRoutes';
import { handleAuthEffect } from '../login/AuthEffectHandler';
import { AppColors } from '../resources/AppResources';


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
struct RequiredLabelComponent {
  @Prop label: ResourceStr = '';
  @Prop required: boolean = false;

  build() {
    Row() {
      Text(this.label).fontSize(16).fontColor(COROS_WHITE)
      if (this.required) {
        Text('*').fontSize(13).fontColor(COROS_RED)
      }
    }
    .alignItems(VerticalAlign.Center)
  }
}

@Component
struct ProfilePickerRowComponent {
  @Prop label: ResourceStr = '';
  @Prop required: boolean = false;
  @Prop value: string = '';
  @Prop placeholder: ResourceStr = '';
  tapRequested: () => void = () => {};

  build() {
    Column() {
      Row() {
        RequiredLabelComponent({ label: this.label, required: this.required });
        Blank().layoutWeight(1)
        Text(this.value.length > 0 ? this.value : this.placeholder)
          .fontSize(15)
          .fontColor(this.value.length > 0 ? AppColors.PROFILE_VALUE : COROS_MUTED)
          .textAlign(TextAlign.End)
        Image($r('app.media.right_more'))
          .width(19)
          .height(19)
          .objectFit(ImageFit.Contain)
          .margin({ left: 12 })
      }
      .width('100%')
      .height(56)
      .alignItems(VerticalAlign.Center)
      .onClick(() => { this.tapRequested(); })

      Divider().color(COROS_LINE)
    }
    .width('100%')
  }
}

@Component
struct ProfileTextRowComponent {
  @Prop label: ResourceStr = '';
  @Prop required: boolean = false;
  @Prop placeholder: ResourceStr = '';
  @Link value: string;
  valueChanged: (value: string) => string = (value: string) => value;

  private updateValue(value: string): void {
    this.value = this.valueChanged(value);
  }

  build() {
    Column() {
      Row() {
        RequiredLabelComponent({ label: this.label, required: this.required });
        TextInput({ text: this.value, placeholder: this.placeholder })
          .fontSize(15)
          .fontColor(COROS_WHITE)
          .placeholderColor(COROS_MUTED)
          .caretColor(COROS_RED)
          .backgroundColor(COROS_BLACK)
          .textAlign(TextAlign.End)
          .layoutWeight(1)
          .padding(0)
          .height(56)
          .onChange((value: string) => {
            this.updateValue(value);
          })
      }
      .width('100%')
      .height(56)
      .alignItems(VerticalAlign.Center)

      Divider().color(COROS_LINE)
    }
    .width('100%')
  }
}

@Component
struct ProfileAvatarComponent {
  @Prop avatarUri: string = '';
  tapRequested: () => void = () => {};

  build() {
    Stack({ alignContent: Alignment.Center }) {
      if (this.avatarUri.length > 0) {
        Image(this.avatarUri)
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
      } else {
        Image($r('app.media.icon_camera'))
          .width(76)
          .height(76)
          .objectFit(ImageFit.Contain)
      }
    }
    .width(76)
    .height(76)
    .borderRadius(38)
    .backgroundColor(AppColors.PROFILE_AVATAR)
    .clip(true)
    .alignSelf(ItemAlign.Center)
    .onClick(() => { this.tapRequested(); })
  }
}

@Component
struct ProfileGenderRowComponent {
  @Link gender: string;
  valueChanged: (value: string) => void = (_: string) => {};

  private selectGender(value: string): void {
    this.gender = this.gender === value ? '' : value;
    this.valueChanged(this.gender);
  }

  build() {
    Row() {
      RequiredLabelComponent({ label: $r('app.string.profile_gender'), required: true });
      Blank().layoutWeight(1)
      Row() {
        Row() {
          Image($r('app.media.icon_female'))
            .width(18)
            .height(18)
            .objectFit(ImageFit.Contain)
          Blank().width(8)
          Text($r('app.string.common_female'))
            .fontSize(16)
            .fontColor(this.gender === 'Female' ? COROS_RED : AppColors.AUTH_INPUT_TEXT)
            .fontWeight(FontWeight.Medium)
        }
        .width(72)
        .height(40)
        .justifyContent(FlexAlign.Center)
        .border({
          width: this.gender === 'Female' ? 1 : 0,
          color: this.gender === 'Female' ? COROS_RED : AppColors.TRANSPARENT,
          radius: 9
        })
        .backgroundColor(AppColors.PROFILE_CONTROL)
        .onClick(() => { this.selectGender('Female'); })

        Blank().width(10)

        Row() {
          Image($r('app.media.icon_male'))
            .width(18)
            .height(18)
            .objectFit(ImageFit.Contain)
          Blank().width(8)
          Text($r('app.string.common_male'))
            .fontSize(16)
            .fontColor(this.gender === 'Male' ? COROS_RED : AppColors.AUTH_INPUT_TEXT)
            .fontWeight(FontWeight.Medium)
        }
        .width(72)
        .height(40)
        .justifyContent(FlexAlign.Center)
        .border({
          width: this.gender === 'Male' ? 1 : 0,
          color: this.gender === 'Male' ? COROS_RED : AppColors.TRANSPARENT,
          radius: 9
        })
        .backgroundColor(AppColors.PROFILE_CONTROL)
        .onClick(() => { this.selectGender('Male'); })
      }
    }
    .width('100%')
    .height(62)
    .alignItems(VerticalAlign.Center)
  }
}

@Component
struct AvatarActionSheetComponent {
  @Link visible: boolean;
  photoRequested: () => void = () => {};
  albumRequested: () => void = () => {};

  private dismiss(): void {
    this.visible = false;
  }

  @Builder
  SheetAction(textValue: ResourceStr, tapRequested: () => void) {
    Row() {
      Text(textValue)
        .fontSize(20)
        .fontColor(COROS_WHITE)
    }
    .width('100%')
    .height(64)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .onClick(() => { tapRequested(); })
  }

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(AppColors.OVERLAY_42)
        .onClick(() => { this.dismiss(); })

      Column() {
        this.SheetAction($r('app.string.profile_take_photo'), () => {
          this.dismiss();
          this.photoRequested();
        });
        Divider().color(COROS_LINE)
        this.SheetAction($r('app.string.profile_album'), () => {
          this.dismiss();
          this.albumRequested();
        });
        Blank().width('100%').height(8).backgroundColor(AppColors.PROFILE_ACTION_DIVIDER)
        this.SheetAction($r('app.string.common_cancel'), () => {
          this.dismiss();
        });
      }
      .width('100%')
      .backgroundColor(AppColors.PROFILE_ACTION_SHEET)
      .borderRadius({ topLeft: 10, topRight: 10 })
      .align(Alignment.Bottom)
    }
    .width('100%')
    .height('100%')
  }
}

@Component
struct UnavailableFeatureDialogComponent {
  @Link visible: boolean;

  build() {
    Column() {
      Blank().layoutWeight(1)
      Column({ space: 20 }) {
        Text($r('app.string.auth_unavailable')).fontSize(16).fontColor(COROS_WHITE).textAlign(TextAlign.Center)
        Text($r('app.string.auth_got_it')).fontSize(16).fontColor(COROS_RED)
          .onClick(() => { this.visible = false; })
      }
      .padding({ left: 28, right: 28, top: 24, bottom: 24 })
      .backgroundColor(AppColors.AUTH_DIALOG)
      .borderRadius(12)
      .margin({ left: 42, right: 42 })
      Blank().layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.OVERLAY_62)
    .onClick(() => { this.visible = false; })
  }
}

@Component
struct BirthDatePickerSheetV2 {
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
struct HeightPickerSheetV2 {
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
struct WeightPickerSheetV2 {
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
struct UnitPickerSheetV2 {
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
struct CountryPickerSheetV2 {
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
struct GenderPickerSheetV2 {
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


@Entry
@Component
struct ProfileCompletionPage {
  private viewModel = getLoginViewModel();
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  @State localError: string = '';
  @State profileAvatarUri: string = '';
  @State profileUsername: string = '';
  @State profileBirthDate: string = '';
  @State profileHeightCm: string = '';
  @State profileWeightKg: string = '';
  @State profileGender: string = '';
  @State profileMeasurementSystem: string = 'Metric';
  @State profileCountry: string = '';
  @State profilePhone: string = '';
  @State unavailableDialogVisible: boolean = false;
  @State avatarSheetVisible: boolean = false;
  @State activePicker: string = '';
  @State editMode: boolean = false;
  @State originalAvatarUri: string = '';
  @State originalUsername: string = '';
  @State originalBirthDate: string = '';
  @State originalHeightCm: string = '';
  @State originalWeightKg: string = '';
  @State originalGender: string = '';
  @State originalCountry: string = '';

  aboutToAppear(): void {
    let params = router.getParams() as ProfilePageParams;
    this.editMode = params !== null && params !== undefined && params.editMode === true;
    this.syncState();
    this.captureOriginalProfile();
  }

  onBackPress(): boolean {
    this.handleProfileBack();
    return true;
  }

  build() {
    Stack() {
      Column() {
        Scroll() {
          Column() {
            if (this.editMode) {
              Row() {
                Text($r('app.string.common_back')).fontSize(34).fontColor(COROS_WHITE).width(64)
                  .onClick(() => { this.handleProfileBack(); })
                Text($r('app.string.profile_personal_info')).fontSize(18).fontColor(COROS_WHITE).fontWeight(FontWeight.Medium)
                  .layoutWeight(1).textAlign(TextAlign.Center)
                Text($r('app.string.common_save')).fontSize(14).fontColor(COROS_WHITE).width(64).textAlign(TextAlign.Center)
                  .padding({ top: 8, bottom: 8 })
                  .backgroundColor(this.isProfileActionEnabled() ? AppColors.ACTION : AppColors.PROFILE_SAVE_DISABLED)
                  .borderRadius(6)
                  .enabled(this.isProfileActionEnabled())
                  .onClick(() => {
                    if (this.isProfileActionEnabled()) this.submitProfile();
                  })
              }
              .width('100%').height(62).alignItems(VerticalAlign.Center)
              Blank().height(20)
            } else {
              AuthHeader({ showBack: true, showFeedback: false,
                backRequested: () => { this.handleProfileBack(); } });

              Blank().height(14)

              Text($r('app.string.profile_completion_title'))
                .fontSize(28)
                .fontColor(COROS_WHITE)
                .lineHeight(34)
                .fontWeight(FontWeight.Lighter)

              Blank().height(8)

              Text($r('app.string.profile_completion_description'))
                .fontSize(14)
                .fontColor(AppColors.PROFILE_DESCRIPTION)
                .lineHeight(20)

              Blank().height(20)
            }

            ProfileAvatarComponent({
              avatarUri: this.profileAvatarUri,
              tapRequested: () => { this.avatarSheetVisible = true; }
            });

            Blank().height(20)

            ProfileTextRowComponent({
              label: $r('app.string.profile_username'),
              required: true,
              value: $profileUsername,
              placeholder: $r('app.string.profile_username_placeholder'),
              valueChanged: (value: string) => {
                return value.substring(0, 20);
              }
            });
            if (this.editMode) {
              ProfilePickerRowComponent({
                label: $r('app.string.profile_gender'),
                required: true,
                value: this.genderLabel(),
                placeholder: $r('app.string.profile_fill_in'),
                tapRequested: () => { this.activePicker = 'Gender'; }
              });
            }
            ProfilePickerRowComponent({
              label: $r('app.string.profile_birth_date'),
              required: true,
              value: this.profileBirthDate,
              placeholder: $r('app.string.profile_fill_in'),
              tapRequested: () => { this.activePicker = 'BirthDate'; }
            });
            ProfilePickerRowComponent({
              label: $r('app.string.profile_height'),
              required: true,
              value: this.profileHeightCm.length > 0 ? `${this.profileHeightCm} cm` : '',
              placeholder: $r('app.string.profile_fill_in'),
              tapRequested: () => { this.activePicker = 'Height'; }
            });
            ProfilePickerRowComponent({
              label: $r('app.string.profile_weight'),
              required: true,
              value: this.profileWeightKg.length > 0 ? `${this.formatWeightText(this.profileWeightKg)} kg` : '',
              placeholder: $r('app.string.profile_fill_in'),
              tapRequested: () => { this.activePicker = 'Weight'; }
            });
            if (!this.editMode) {
              ProfilePickerRowComponent({
                label: $r('app.string.profile_measurement'),
                required: false,
                value: this.measurementLabel(),
                placeholder: '',
                tapRequested: () => { this.activePicker = 'Unit'; }
              });
              ProfileTextRowComponent({
                label: $r('app.string.profile_phone'),
                required: false,
                value: $profilePhone,
                placeholder: $r('app.string.profile_phone_placeholder'),
                valueChanged: (value: string) => {
                  return value.replace(/[^0-9+\-]/g, '').substring(0, 20);
                }
              });
            }
            ProfilePickerRowComponent({
              label: $r('app.string.profile_country_region'),
              required: false,
              value: this.countryLabel(this.profileCountry),
              placeholder: $r('app.string.common_china'),
              tapRequested: () => { this.activePicker = 'Country'; }
            });
            if (!this.editMode) {
              ProfileGenderRowComponent({
                gender: $profileGender,
                valueChanged: (_: string) => {}
              });
            }

            Blank().height(16)
          }
          .width('100%')
          .padding({ left: 18, right: 18 })
        }
        .layoutWeight(1)

        if (!this.editMode) {
          Column() {
            ErrorText({ message: this.localError });
            Blank().height(5)
            CorosButton({ textValue: $r('app.string.common_complete'), color: COROS_BUTTON_RED,
              enabledValue: this.isProfileActionEnabled(), loading: this.isLoading,
              tapRequested: () => { this.submitProfile(); } });
          }
          .width('100%')
          .padding({ left: 18, right: 18, top: 8, bottom: 10 })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(COROS_BLACK)

      if (this.activePicker === 'BirthDate') {
        BirthDatePickerSheetV2({ profileBirthDate: $profileBirthDate, activePicker: $activePicker });
      }
      if (this.activePicker === 'Height') {
        HeightPickerSheetV2({ profileHeightCm: $profileHeightCm, activePicker: $activePicker });
      }
      if (this.activePicker === 'Weight') {
        WeightPickerSheetV2({ profileWeightKg: $profileWeightKg, activePicker: $activePicker });
      }
      if (this.activePicker === 'Unit') {
        UnitPickerSheetV2({ profileMeasurementSystem: $profileMeasurementSystem, activePicker: $activePicker });
      }
      if (this.activePicker === 'Country') {
        CountryPickerSheetV2({ profileCountry: $profileCountry, activePicker: $activePicker });
      }
      if (this.activePicker === 'Gender') {
        GenderPickerSheetV2({ profileGender: $profileGender, activePicker: $activePicker });
      }
      if (this.avatarSheetVisible) {
        AvatarActionSheetComponent({
          visible: $avatarSheetVisible,
          photoRequested: () => { this.takeAvatarPhoto(); },
          albumRequested: () => { this.pickAvatarFromAlbum(); }
        });
      }
      if (this.unavailableDialogVisible) {
        UnavailableFeatureDialogComponent({ visible: $unavailableDialogVisible });
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COROS_BLACK)
  }

  private handleProfileBack(): void {
    this.localError = '';
    if (this.editMode) {
      navigate(NavOperation.Pop, '');
      return;
    }
    this.viewModel.clearSessionSilently();
    this.syncState();
    navigate(NavOperation.ResetTo, AuthRoutes.ENTRANCE);
  }


  private isProfileActionEnabled(): boolean {
    let heightCm: number = this.profileHeightCm.length > 0 ? parseInt(this.profileHeightCm) : 0;
    let weightKg: number = this.profileWeightKg.length > 0 ? parseFloat(this.profileWeightKg) : 0;
    let valid: boolean = this.viewModel.canSubmitProfile(
      this.profileUsername, this.profileBirthDate, heightCm, weightKg, this.profileGender
    );
    return valid && (!this.editMode || this.hasProfileChanges());
  }

  private submitProfile(): void {
    let heightCm: number = this.profileHeightCm.length > 0 ? parseInt(this.profileHeightCm) : 0;
    let weightKg: number = this.profileWeightKg.length > 0 ? parseFloat(this.profileWeightKg) : 0;
    this.viewModel.submitProfile(
      this.profileAvatarUri, this.profileUsername, this.profileBirthDate,
      heightCm, weightKg, this.profileMeasurementSystem,
      this.profilePhone, this.profileCountry, this.profileGender
    );
    let effect: LoginEffect | null = this.viewModel.consumeEffect();
    if (effect !== null) {
      if (this.editMode && effect.type === LoginEffectType.ProfileSaved) {
        showToast('profile_saved');
        navigate(NavOperation.Pop, '');
      } else {
        handleAuthEffect(effect);
      }
    } else {
      let state: LoginState = this.viewModel.state;
      if (state.errorMessage.length > 0) {
        this.localError = state.errorMessage;
      }
    }
  }

  private formatWeightText(value: string): string {
    let weight: number = value.length > 0 ? parseFloat(value) : 0;
    if (isNaN(weight)) {
      return '';
    }
    return weight.toFixed(1);
  }

  private pickAvatarFromAlbum(): void {
    try {
      let photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
      photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      photoSelectOptions.maxSelectNumber = 1;

      let photoPicker = new photoAccessHelper.PhotoViewPicker();
      photoPicker.select(photoSelectOptions).then((result: photoAccessHelper.PhotoSelectResult) => {
        if (result.photoUris.length > 0) {
          this.profileAvatarUri = result.photoUris[0];
        }
      }).catch((error: Error) => {
        console.error(`pickAvatarFromAlbum failed: ${JSON.stringify(error)}`);
        this.showMessage('profile_avatar_selection_failed');
      });
    } catch (error) {
      console.error(`pickAvatarFromAlbum failed: ${JSON.stringify(error)}`);
      this.showMessage('profile_avatar_selection_failed');
    }
  }

  private takeAvatarPhoto(): void {
    this.showMessage('profile_camera_pending');
  }

  private measurementLabel(): string {
    return this.profileMeasurementSystem === 'Imperial'
      ? this.localized($r('app.string.profile_unit_imperial'))
      : this.localized($r('app.string.profile_unit_metric'));
  }

  private genderLabel(): string {
    if (this.profileGender === 'Female') return this.localized($r('app.string.common_female'));
    if (this.profileGender === 'Male') return this.localized($r('app.string.common_male'));
    return '';
  }

  private syncState(): void {
    let state: LoginState = this.viewModel.state;
    this.isLoading = state.isLoading;
    this.errorMessage = state.errorMessage;
    if (state.currentSession !== null) {
      this.profileUsername = state.currentSession.displayName;
      this.profileAvatarUri = state.currentSession.avatarUri;
      this.profileBirthDate = state.currentSession.birthDate;
      this.profileHeightCm = state.currentSession.heightCm > 0 ? `${state.currentSession.heightCm}` : '';
      this.profileWeightKg = state.currentSession.weightKg > 0 ? state.currentSession.weightKg.toFixed(1) : '';
      this.profileMeasurementSystem = state.currentSession.measurementSystem;
      this.profilePhone = state.currentSession.phone;
      this.profileCountry = state.currentSession.countryRegion.length > 0 ? state.currentSession.countryRegion :
        (state.currentSession.region === 'US' ? 'US' : 'CN');
      this.profileGender = state.currentSession.gender;
    }
  }

  private captureOriginalProfile(): void {
    this.originalAvatarUri = this.profileAvatarUri;
    this.originalUsername = this.profileUsername;
    this.originalBirthDate = this.profileBirthDate;
    this.originalHeightCm = this.profileHeightCm;
    this.originalWeightKg = this.profileWeightKg;
    this.originalGender = this.profileGender;
    this.originalCountry = this.profileCountry;
  }

  private hasProfileChanges(): boolean {
    return this.profileAvatarUri !== this.originalAvatarUri ||
      this.profileUsername !== this.originalUsername ||
      this.profileBirthDate !== this.originalBirthDate ||
      this.profileHeightCm !== this.originalHeightCm ||
      this.profileWeightKg !== this.originalWeightKg ||
      this.profileGender !== this.originalGender ||
      this.profileCountry !== this.originalCountry;
  }

  private showMessage(message: string): void {
    showToast(message);
  }

  private localized(resource: Resource): string {
    return getContext(this).resourceManager.getStringSync(resource.id);
  }

  private countryLabel(code: string): string {
    switch (code.trim().toUpperCase()) {
      case 'US': return this.localized($r('app.string.common_united_states'));
      case 'GB':
      case 'UK': return this.localized($r('app.string.common_united_kingdom'));
      case 'JP': return this.localized($r('app.string.common_japan'));
      default: return this.localized($r('app.string.common_china'));
    }
  }
}
