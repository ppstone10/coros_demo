import {
  COROS_RED,
  COROS_BLACK,
  COROS_WHITE,
  COROS_MUTED,
  COROS_LINE
} from '../auth/components/AuthColors';
import { AppColors } from '../core/resources/AppResources';

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
export struct ProfilePickerRowComponent {
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
export struct ProfileTextRowComponent {
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
export struct ProfileGenderRowComponent {
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
export struct UnavailableFeatureDialogComponent {
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
