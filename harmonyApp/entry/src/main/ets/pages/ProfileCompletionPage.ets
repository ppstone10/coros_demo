import promptAction from '@ohos.promptAction';
import photoAccessHelper from '@ohos.file.photoAccessHelper';
import router from '@ohos.router';
import {
  LoginEffect,
  LoginEffectType,
  LoginState
} from '../login/LoginState';
import { getLoginViewModel } from '../login/LoginViewModelProvider';
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
import { AuthRoutes } from '../login/AuthRoutes';


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
  @Prop title: string = '';
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
  @Prop suffix: string = '';
  @Prop pickerWidth: number = 140;

  private syncValue(index: number | number[]): void {
    this.value = this.min + pcPickerIndex(index);
  }

  build() {
    TextPicker({
      range: pcBuildNumberRange(this.min, this.max, this.suffix),
      selected: pcClamp(this.value, this.min, this.max) - this.min
    })
      .width(this.pickerWidth)
      .height(248)
      .defaultPickerItemHeight(54)
      .canLoop(false)
      .selectedTextStyle({ color: COROS_WHITE, font: { size: 28, weight: FontWeight.Medium } })
      .textStyle({ color: '#CFCFD4', font: { size: 23, weight: FontWeight.Normal } })
      .disappearTextStyle({ color: '#77777D', font: { size: 18, weight: FontWeight.Normal } })
      .divider({ strokeWidth: 1, color: '#34343A', startMargin: 14, endMargin: 14 })
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

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#B8000000')
        .onClick(() => { this.onDismiss(); })

      Column() {
        PickerSheetHeaderComponent({
          title: '出生日期',
          onDismiss: () => { this.onDismiss(); },
          onConfirm: () => {
            this.onConfirm(`${this.year}年${this.month}月${this.day}日`);
          }
        });

        Row() {
          NumberWheelPickerComponent({ value: $year, min: 1950, max: 2026, suffix: '年', pickerWidth: 110 })
            .layoutWeight(1)
          NumberWheelPickerComponent({ value: $month, min: 1, max: 12, suffix: '月', pickerWidth: 110 })
            .layoutWeight(1)
          NumberWheelPickerComponent({ value: $day, min: 1, max: 31, suffix: '日', pickerWidth: 110 })
            .layoutWeight(1)
        }
        .width('100%')
        .height(240)
        .alignItems(VerticalAlign.Center)
        .justifyContent(FlexAlign.SpaceEvenly)

        Blank().height(28)
      }
      .width('100%')
      .backgroundColor('#1A1A1B')
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
        .backgroundColor('#B8000000')
        .onClick(() => { this.onDismiss(); })

      Column() {
        PickerSheetHeaderComponent({
          title: '身高 (cm)',
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
      .backgroundColor('#1A1A1B')
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
        .backgroundColor('#B8000000')
        .onClick(() => { this.onDismiss(); })

      Column() {
        PickerSheetHeaderComponent({
          title: '体重 (kg)',
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
      .backgroundColor('#1A1A1B')
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
  OptionRow(textValue: string, value: string) {
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
      color: this.selected === value ? '#38383C' : '#00000000',
      radius: 8
    })
    .onClick(() => { this.selected = value; })
  }

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#B8000000')
        .onClick(() => { this.onDismiss(); })

      Column() {
        PickerSheetHeaderComponent({
          title: '公英制',
          onDismiss: () => { this.onDismiss(); },
          onConfirm: () => { this.onConfirm(this.selected); }
        });

        Column() {
          this.OptionRow('公制（km/m/cm/kg）', 'Metric');
          this.OptionRow('英制（mi/ft/inch/lb）', 'Imperial');
        }
        .width('100%')
        .height(240)
        .justifyContent(FlexAlign.Center)

        Blank().height(28)
      }
      .width('100%')
      .backgroundColor('#1A1A1B')
      .borderRadius({ topLeft: 14, topRight: 14 })
      .align(Alignment.Bottom)
    }
    .width('100%')
    .height('100%')
  }
}

@Component
struct CountryPickerSheetComponent {
  @Prop current: string = '中国';
  @State selected: string = '中国';
  onDismiss: () => void = () => {};
  onConfirm: (value: string) => void = (_: string) => {};

  aboutToAppear(): void {
    this.selected = this.current.length > 0 ? this.current : '中国';
  }

  @Builder
  OptionRow(textValue: string) {
    Row() {
      Text(textValue)
        .fontSize(this.selected === textValue ? 22 : 18)
        .fontColor(this.selected === textValue ? COROS_WHITE : COROS_MUTED)
    }
    .width('100%')
    .height(56)
    .justifyContent(FlexAlign.Center)
    .margin({ left: 20, right: 20 })
    .border({
      width: this.selected === textValue ? 1 : 0,
      color: this.selected === textValue ? '#38383C' : '#00000000',
      radius: 8
    })
    .onClick(() => { this.selected = textValue; })
  }

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#B8000000')
        .onClick(() => { this.onDismiss(); })

      Column() {
        PickerSheetHeaderComponent({
          title: '国家与地区',
          onDismiss: () => { this.onDismiss(); },
          onConfirm: () => { this.onConfirm(this.selected); }
        });

        Column() {
          this.OptionRow('中国');
          this.OptionRow('美国');
          this.OptionRow('英国');
          this.OptionRow('日本');
        }
        .width('100%')
        .height(240)
        .justifyContent(FlexAlign.Center)

        Blank().height(28)
      }
      .width('100%')
      .backgroundColor('#1A1A1B')
      .borderRadius({ topLeft: 14, topRight: 14 })
      .align(Alignment.Bottom)
    }
    .width('100%')
    .height('100%')
  }
}



@Component
struct RequiredLabelComponent {
  @Prop label: string = '';
  @Prop required: boolean = false;

  build() {
    Row() {
      Text(this.label).fontSize(20).fontColor(COROS_WHITE)
      if (this.required) {
        Text('*').fontSize(16).fontColor(COROS_RED)
      }
    }
    .alignItems(VerticalAlign.Center)
  }
}

@Component
struct ProfilePickerRowComponent {
  @Prop label: string = '';
  @Prop required: boolean = false;
  @Prop value: string = '';
  @Prop placeholder: string = '';
  tapRequested: () => void = () => {};

  build() {
    Column() {
      Row() {
        RequiredLabelComponent({ label: this.label, required: this.required });
        Blank().layoutWeight(1)
        Text(this.value.length > 0 ? this.value : this.placeholder)
          .fontSize(18)
          .fontColor(this.value.length > 0 ? '#DADAE0' : COROS_MUTED)
          .textAlign(TextAlign.End)
        Image($r('app.media.right_more'))
          .width(24)
          .height(24)
          .objectFit(ImageFit.Contain)
          .margin({ left: 12 })
      }
      .width('100%')
      .height(66)
      .alignItems(VerticalAlign.Center)
      .onClick(() => { this.tapRequested(); })

      Divider().color(COROS_LINE)
    }
    .width('100%')
  }
}

@Component
struct ProfileTextRowComponent {
  @Prop label: string = '';
  @Prop required: boolean = false;
  @Prop placeholder: string = '';
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
          .fontSize(18)
          .fontColor(COROS_WHITE)
          .placeholderColor(COROS_MUTED)
          .caretColor(COROS_RED)
          .backgroundColor(COROS_BLACK)
          .textAlign(TextAlign.End)
          .layoutWeight(1)
          .padding(0)
          .height(66)
          .onChange((value: string) => {
            this.updateValue(value);
          })
      }
      .width('100%')
      .height(66)
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
          .width(92)
          .height(92)
          .objectFit(ImageFit.Contain)
      }
    }
    .width(92)
    .height(92)
    .borderRadius(46)
    .backgroundColor('#171719')
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
      RequiredLabelComponent({ label: '性别', required: true });
      Blank().layoutWeight(1)
      Row() {
        Row() {
          Image($r('app.media.icon_female'))
            .width(22)
            .height(22)
            .objectFit(ImageFit.Contain)
          Blank().width(8)
          Text('女')
            .fontSize(20)
            .fontColor(this.gender === 'Female' ? COROS_RED : '#D8D8DD')
            .fontWeight(FontWeight.Medium)
        }
        .width(82)
        .height(48)
        .justifyContent(FlexAlign.Center)
        .border({
          width: this.gender === 'Female' ? 1 : 0,
          color: this.gender === 'Female' ? COROS_RED : '#00000000',
          radius: 9
        })
        .backgroundColor('#19191B')
        .onClick(() => { this.selectGender('Female'); })

        Blank().width(10)

        Row() {
          Image($r('app.media.icon_male'))
            .width(22)
            .height(22)
            .objectFit(ImageFit.Contain)
          Blank().width(8)
          Text('男')
            .fontSize(20)
            .fontColor(this.gender === 'Male' ? COROS_RED : '#D8D8DD')
            .fontWeight(FontWeight.Medium)
        }
        .width(82)
        .height(48)
        .justifyContent(FlexAlign.Center)
        .border({
          width: this.gender === 'Male' ? 1 : 0,
          color: this.gender === 'Male' ? COROS_RED : '#00000000',
          radius: 9
        })
        .backgroundColor('#19191B')
        .onClick(() => { this.selectGender('Male'); })
      }
    }
    .width('100%')
    .height(78)
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
  SheetAction(textValue: string, tapRequested: () => void) {
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
        .backgroundColor('#6B000000')
        .onClick(() => { this.dismiss(); })

      Column() {
        this.SheetAction('拍照片', () => {
          this.dismiss();
          this.photoRequested();
        });
        Divider().color(COROS_LINE)
        this.SheetAction('相册', () => {
          this.dismiss();
          this.albumRequested();
        });
        Blank().width('100%').height(8).backgroundColor('#101012')
        this.SheetAction('取消', () => {
          this.dismiss();
        });
      }
      .width('100%')
      .backgroundColor('#18181A')
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
        Text('抱歉，该功能还在实现中').fontSize(16).fontColor(COROS_WHITE).textAlign(TextAlign.Center)
        Text('知道了').fontSize(16).fontColor(COROS_RED)
          .onClick(() => { this.visible = false; })
      }
      .padding({ left: 28, right: 28, top: 24, bottom: 24 })
      .backgroundColor('#222224')
      .borderRadius(12)
      .margin({ left: 42, right: 42 })
      Blank().layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0000009E')
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

  private confirm(): void {
    this.profileBirthDate = `${this.year}年${this.month}月${this.day}日`;
    this.activePicker = '';
  }

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#B8000000')
        .onClick(() => { this.close(); })

      Column() {
        PickerSheetHeaderComponent({
          title: '出生日期',
          onDismiss: () => { this.close(); },
          onConfirm: () => { this.confirm(); }
        })

        Row() {
          NumberWheelPickerComponent({ value: $year, min: 1950, max: 2026, suffix: '年', pickerWidth: 110 })
            .layoutWeight(1)
          NumberWheelPickerComponent({ value: $month, min: 1, max: 12, suffix: '月', pickerWidth: 110 })
            .layoutWeight(1)
          NumberWheelPickerComponent({ value: $day, min: 1, max: 31, suffix: '日', pickerWidth: 110 })
            .layoutWeight(1)
        }
        .width('100%')
        .height(240)
        .alignItems(VerticalAlign.Center)
        .justifyContent(FlexAlign.SpaceEvenly)

        Blank().height(28)
      }
      .width('100%')
      .backgroundColor('#1A1A1B')
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
        .backgroundColor('#B8000000')
        .onClick(() => { this.close(); })

      Column() {
        PickerSheetHeaderComponent({
          title: '身高 (cm)',
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
      .backgroundColor('#1A1A1B')
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
        .backgroundColor('#B8000000')
        .onClick(() => { this.close(); })

      Column() {
        PickerSheetHeaderComponent({
          title: '体重 (kg)',
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
      .backgroundColor('#1A1A1B')
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
  private labels: string[] = ['公制（km/m/cm/kg）', '英制（mi/ft/inch/lb）'];
  private values: string[] = ['Metric', 'Imperial'];

  aboutToAppear(): void {
    this.selectedIndex = this.profileMeasurementSystem === 'Imperial' ? 1 : 0;
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
        .backgroundColor('#B8000000')
        .onClick(() => { this.close(); })

      Column() {
        PickerSheetHeaderComponent({
          title: '公英制',
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
            .textStyle({ color: '#CFCFD4', font: { size: 20, weight: FontWeight.Normal } })
            .disappearTextStyle({ color: '#77777D', font: { size: 18, weight: FontWeight.Normal } })
            .divider({ strokeWidth: 1, color: '#34343A', startMargin: 14, endMargin: 14 })
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
      .backgroundColor('#1A1A1B')
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
  private countries: string[] = ['中国', '美国', '英国', '日本'];

  aboutToAppear(): void {
    let index: number = this.countries.indexOf(this.profileCountry);
    this.selectedIndex = index >= 0 ? index : 0;
  }

  private close(): void {
    this.activePicker = '';
  }

  private confirm(): void {
    this.profileCountry = this.countries[this.selectedIndex];
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
        .backgroundColor('#B8000000')
        .onClick(() => { this.close(); })

      Column() {
        PickerSheetHeaderComponent({
          title: '国家与地区',
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
            .textStyle({ color: '#CFCFD4', font: { size: 23, weight: FontWeight.Normal } })
            .disappearTextStyle({ color: '#77777D', font: { size: 18, weight: FontWeight.Normal } })
            .divider({ strokeWidth: 1, color: '#34343A', startMargin: 14, endMargin: 14 })
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
      .backgroundColor('#1A1A1B')
      .borderRadius({ topLeft: 14, topRight: 14 })
      .align(Alignment.Bottom)
    }
    .width('100%')
    .height('100%')
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
  @State profileCountry: string = '中国';
  @State profilePhone: string = '';
  @State unavailableDialogVisible: boolean = false;
  @State avatarSheetVisible: boolean = false;
  @State activePicker: string = '';

  aboutToAppear(): void {
    this.syncState();
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
            AuthHeader({ showBack: true, showFeedback: false,
              backRequested: () => { this.handleProfileBack(); } });

            Blank().height(22)

            Text('完善个人信息')
              .fontSize(36)
              .fontColor(COROS_WHITE)
              .lineHeight(44)
              .fontWeight(FontWeight.Lighter)

            Blank().height(12)

            Text('以下信息可以帮助我们对体育科学做出更准确的预测，请仔细填写。')
              .fontSize(18)
              .fontColor('#E8E8EC')
              .lineHeight(28)

            Blank().height(28)

            ProfileAvatarComponent({
              avatarUri: this.profileAvatarUri,
              tapRequested: () => { this.avatarSheetVisible = true; }
            });

            Blank().height(28)

            ProfileTextRowComponent({
              label: '用户名',
              required: true,
              value: $profileUsername,
              placeholder: '输入用户名',
              valueChanged: (value: string) => {
                return value.substring(0, 20);
              }
            });
            ProfilePickerRowComponent({
              label: '出生日期',
              required: true,
              value: this.profileBirthDate,
              placeholder: '去填写',
              tapRequested: () => { this.activePicker = 'BirthDate'; }
            });
            ProfilePickerRowComponent({
              label: '身高',
              required: true,
              value: this.profileHeightCm.length > 0 ? `${this.profileHeightCm} cm` : '',
              placeholder: '去填写',
              tapRequested: () => { this.activePicker = 'Height'; }
            });
            ProfilePickerRowComponent({
              label: '体重',
              required: true,
              value: this.profileWeightKg.length > 0 ? `${this.formatWeightText(this.profileWeightKg)} kg` : '',
              placeholder: '去填写',
              tapRequested: () => { this.activePicker = 'Weight'; }
            });
            ProfilePickerRowComponent({
              label: '公英制',
              required: false,
              value: this.measurementLabel(),
              placeholder: '',
              tapRequested: () => { this.activePicker = 'Unit'; }
            });
            ProfileTextRowComponent({
              label: '手机',
              required: false,
              value: $profilePhone,
              placeholder: '输入手机号',
              valueChanged: (value: string) => {
                return value.replace(/[^0-9+\-]/g, '').substring(0, 20);
              }
            });
            ProfilePickerRowComponent({
              label: '国家与地区',
              required: false,
              value: this.profileCountry,
              placeholder: '中国',
              tapRequested: () => { this.activePicker = 'Country'; }
            });
            ProfileGenderRowComponent({
              gender: $profileGender,
              valueChanged: (_: string) => {}
            });

            Blank().height(16)
          }
          .width('100%')
          .padding({ left: 20, right: 20 })
        }
        .layoutWeight(1)

        Column() {
          ErrorText({ message: this.localError });
          Blank().height(8)
          CorosButton({ textValue: '完成', color: COROS_BUTTON_RED,
            enabledValue: this.isProfileActionEnabled(), loading: this.isLoading,
            tapRequested: () => { this.submitProfile(); } });
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 14, bottom: 18 })
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
    this.viewModel.clearSessionSilently();
    this.syncState();
    router.clear();
    router.replaceUrl({ url: AuthRoutes.ENTRANCE });
  }


  private isProfileActionEnabled(): boolean {
    let heightCm: number = this.profileHeightCm.length > 0 ? parseInt(this.profileHeightCm) : 0;
    let weightKg: number = this.profileWeightKg.length > 0 ? parseFloat(this.profileWeightKg) : 0;
    return this.viewModel.canSubmitProfile(
      this.profileUsername, this.profileBirthDate, heightCm, weightKg, this.profileGender
    );
  }

  private submitProfile(): void {
    let heightCm: number = this.profileHeightCm.length > 0 ? parseInt(this.profileHeightCm) : 0;
    let weightKg: number = this.profileWeightKg.length > 0 ? parseFloat(this.profileWeightKg) : 0;
    this.viewModel.submitProfile(
      this.profileAvatarUri, this.profileUsername, this.profileBirthDate,
      heightCm, weightKg, this.profileMeasurementSystem,
      this.profilePhone, this.profileCountry, this.profileGender
    );
    this.syncState();
    let effect: LoginEffect | null = this.viewModel.consumeEffect();
    if (effect !== null && effect.type === LoginEffectType.ProfileSaved) {
      router.clear();
      router.replaceUrl({ url: AuthRoutes.SIGNED_IN });
      this.showMessage('资料已保存');
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
        this.showMessage('选择头像失败');
      });
    } catch (error) {
      console.error(`pickAvatarFromAlbum failed: ${JSON.stringify(error)}`);
      this.showMessage('选择头像失败');
    }
  }

  private takeAvatarPhoto(): void {
    this.showMessage('拍照功能待接入系统相机');
  }

  private measurementLabel(): string {
    return this.profileMeasurementSystem === 'Imperial' ? '英制（mi/ft/inch/lb）' : '公制（km/m/cm/kg）';
  }

  private syncState(): void {
    let state: LoginState = this.viewModel.state;
    this.isLoading = state.isLoading;
    this.errorMessage = state.errorMessage;
    if (state.currentSession !== null) {
      this.profileUsername = state.currentSession.displayName;
    }
  }

  private showMessage(message: string): void {
    try {
      promptAction.showToast({ message: message });
    } catch (error) {
      console.error('showToast failed');
    }
  }
}
