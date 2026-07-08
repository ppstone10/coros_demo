import {
  COROS_RED,
  COROS_BUTTON_RED,
  COROS_BLACK,
  COROS_WHITE,
  COROS_MUTED,
  COROS_LINE,
  COROS_FIELD,
  COROS_CODE_ACTIVE_FIELD,
  COROS_BUTTON_DISABLED_TEXT,
  COROS_RED_DISABLED,
  COROS_BUTTON_RED_DISABLED,
  COROS_DIALOG_BG,
  COROS_SHEET_BG,
  COROS_OVERLAY_COLOR,
  COROS_SUBTITLE_COLOR,
  AUTH_TITLE_TOP_PADDING,
  AUTH_TITLE_SIZE
} from './AuthColors';
import { LegalParagraph } from './LegalContent';

export enum TermsPromptAction {
  None,
  Login,
  PhoneCode,
  EmailCode
}

export enum VerifyTargetKind {
  Phone,
  Email
}

export function verifyCodeMessage(account: string, targetKind: VerifyTargetKind): string {
  if (targetKind === VerifyTargetKind.Email) {
    return '验证码已发送至你的邮箱 ' + account + '，有效期10分钟';
  }
  return '验证码已发送至你的手机+86-' + account + '，有效期10分钟';
}

function disabledColor(color: string): string {
  if (color === COROS_BUTTON_RED) {
    return COROS_BUTTON_RED_DISABLED;
  }
  if (color === COROS_RED) {
    return COROS_RED_DISABLED;
  }
  return '#1D1D1D';
}

// ========== 非交互式 @Builder（无回调，安全） ==========

@Builder
export function AuthTitle(title: string) {
  Text(title)
    .fontSize(AUTH_TITLE_SIZE)
    .fontWeight(FontWeight.Lighter)
    .fontColor(COROS_WHITE)
    .margin({ top: AUTH_TITLE_TOP_PADDING })
}

@Component
export struct ErrorText {
  @Prop message: string = '';

  build() {
    if (this.message.length > 0) {
      Text(this.message)
        .fontSize(15)
        .fontColor(COROS_RED)
        .margin({ top: 10 })
    }
  }
}

@Builder
export function BlockingLoadingOverlay() {
  Column() {
    Blank().layoutWeight(1)
    LoadingProgress()
      .width(36)
      .height(36)
      .color('#D8D8DD')
      .padding(30)
      .backgroundColor('#3A3A3C')
      .borderRadius(8)
    Blank().layoutWeight(1)
  }
  .width('100%')
  .height('100%')
  .backgroundColor('#000000B8')
}

@Builder
export function LegalDocumentPage(title: string, paragraphs: LegalParagraph[], backRequested: () => void) {
  Column() {
    Stack() {
      Row() {
        Text('‹')
          .fontSize(44)
          .fontColor(COROS_WHITE)
          .textAlign(TextAlign.Center)
          .width(48)
          .height(52)
          .onClick(() => { backRequested(); })
        Blank()
      }
      .width('100%')
      .height(52)

      Text(title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(COROS_WHITE)
        .width('100%')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height(52)
    .padding({ left: 20, right: 20 })

    Scroll() {
      Column({ space: 12 }) {
        ForEach(paragraphs, (paragraph: LegalParagraph) => {
          Text(paragraph.text)
            .fontSize(paragraph.isHeading ? 19 : 18)
            .fontWeight(paragraph.isHeading ? FontWeight.Bold : FontWeight.Regular)
            .fontColor(paragraph.isHeading ? COROS_WHITE : '#C9C9CC')
            .lineHeight(paragraph.isHeading ? 28 : 30)
        }, (paragraph: LegalParagraph) => paragraph.text)
      }
      .width('100%')
      .padding({ top: 58, left: 20, right: 32, bottom: 32 })
    }
    .layoutWeight(1)
  }
  .width('100%')
  .height('100%')
  .backgroundColor(COROS_BLACK)
}

// ========== 交互式 @Component（@Prop 展示，@Link 回写） ==========

@Component
export struct CorosButton {
  @Prop textValue: string = '';
  @Prop color: string = '';
  @Prop enabledValue: boolean = true;
  @Prop loading: boolean = false;
  tapRequested: () => void = () => {};

  build() {
    Button(this.loading ? '处理中' : this.textValue, { type: ButtonType.Normal })
      .fontSize(18)
      .fontColor(this.enabledValue ? COROS_WHITE : COROS_BUTTON_DISABLED_TEXT)
      .width('100%')
      .height(48)
      .borderRadius(9)
      .backgroundColor(this.enabledValue ? this.color : disabledColor(this.color))
      .enabled(!this.loading && this.enabledValue)
      .onClick(() => {
        if (this.enabledValue && !this.loading) {
          this.tapRequested();
        }
      })
  }
}

@Component
export struct AuthHeader {
  @Prop showBack: boolean = true;
  @Prop showFeedback: boolean = false;
  backRequested: () => void = () => {};
  feedbackRequested: () => void = () => {};

  build() {
    Row() {
      if (this.showBack) {
        Text('‹')
          .fontSize(44)
          .fontColor(COROS_WHITE)
          .textAlign(TextAlign.Center)
          .width(48)
          .height(52)
          .onClick(() => { this.backRequested(); })
      }
      Blank()
      if (this.showFeedback) {
        Text('◔ 建议&反馈')
          .fontSize(14)
          .fontColor(COROS_MUTED)
          .onClick(() => { this.feedbackRequested(); })
      }
    }
    .width('100%')
    .height(52)
    .alignItems(VerticalAlign.Center)
  }
}

@Component
export struct UnderlineInput {
  @Prop placeholder: string = '';
  @Link textValue: string;
  @Prop inputType: InputType = InputType.Normal;
  @Prop isPassword: boolean = false;
  @Prop passwordVisible: boolean = false;
  valueChanged: (value: string) => void = () => {};
  passwordToggleRequested: () => void = () => {};

  private commitValue(value: string): void {
    this.textValue = value;
    this.valueChanged(value);
  }

  build() {
    Column() {
      Row({ space: 6 }) {
        TextInput({ placeholder: this.placeholder, text: this.textValue })
          .type(this.inputType)
          .fontSize(17)
          .fontColor(COROS_WHITE)
          .placeholderColor(COROS_MUTED)
          .caretColor(COROS_RED)
          .backgroundColor(COROS_BLACK)
          .height(48)
          .padding(0)
          .layoutWeight(1)
          .onChange((value: string) => { this.commitValue(value); })

        if (this.textValue.length > 0) {
          Image($r('app.media.icon_delete'))
            .width(34)
            .height(34)
            .objectFit(ImageFit.Contain)
            .onClick(() => { this.commitValue(''); })
        }

        if (this.isPassword && this.textValue.length > 0) {
          Image($r('app.media.icon_uneye'))
            .width(34)
            .height(34)
            .objectFit(ImageFit.Contain)
            .opacity(this.passwordVisible ? 0.45 : 1)
            .onClick(() => { this.passwordToggleRequested(); })
        }
      }
      .width('100%')
      .height(48)
      .alignItems(VerticalAlign.Center)

      Divider().color(COROS_LINE)
    }
    .width('100%')
  }
}

@Component
export struct PhoneInputComp {
  @Prop countryCode: string = '+86';
  @Link phoneValue: string;
  valueChanged: (value: string) => void = () => {};

  private commitValue(value: string): void {
    this.phoneValue = value;
    this.valueChanged(value);
  }

  build() {
    Column() {
      Row({ space: 24 }) {
        Text(this.countryCode)
          .fontSize(17)
          .fontColor(COROS_WHITE)
        TextInput({ placeholder: '输入手机号', text: this.phoneValue })
          .type(InputType.PhoneNumber)
          .maxLength(11)
          .fontSize(17)
          .fontColor(COROS_WHITE)
          .placeholderColor(COROS_MUTED)
          .caretColor(COROS_RED)
          .backgroundColor(COROS_BLACK)
          .padding(0)
          .layoutWeight(1)
          .onChange((value: string) => { this.commitValue(value); })
        if (this.phoneValue.length > 0) {
          Image($r('app.media.icon_delete'))
            .width(34)
            .height(34)
            .objectFit(ImageFit.Contain)
            .onClick(() => { this.commitValue(''); })
        }
      }
      .height(48)
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Divider().color(COROS_LINE)
    }
    .width('100%')
  }
}

@Component
export struct DisabledUnderlineValue {
  @Prop value: string = '';
  @Prop placeholder: string = '';

  build() {
    Column() {
      Row() {
        Text(this.value.length > 0 ? this.value : this.placeholder)
          .fontSize(17)
          .fontColor(this.value.length > 0 ? COROS_WHITE : COROS_MUTED)
          .opacity(0.62)
      }
      .height(48)
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Divider().color(COROS_LINE)
    }
    .width('100%')
  }
}

@Component
export struct AgreementRowComp {
  @Link accepted: boolean;
  acceptedChanged: (accepted: boolean) => void = (_: boolean) => {};
  privacyRequested: () => void = () => {};
  serviceTermsRequested: () => void = () => {};

  private toggleAccepted(): void {
    this.accepted = !this.accepted;
    this.acceptedChanged(this.accepted);
  }

  build() {
    Row({ space: 8 }) {
      Stack({ alignContent: Alignment.Center }) {
        if (this.accepted) {
          Image($r('app.media.ic_profile_check'))
            .width(12)
            .height(12)
            .objectFit(ImageFit.Contain)
        }
      }
        .width(18)
        .height(18)
        .border({ width: 1, color: this.accepted ? COROS_RED : '#D0D0D0', radius: 9 })
        .backgroundColor(this.accepted ? COROS_RED : COROS_BLACK)
        .margin({ top: 2 })
        .onClick(() => { this.toggleAccepted(); })

      Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap }) {
        Text('我已阅读并同意COROS的 ')
          .fontSize(14)
          .fontColor(COROS_WHITE)
          .lineHeight(24)
        Text('《隐私政策》')
          .fontSize(14)
          .fontColor(COROS_RED)
          .lineHeight(24)
          .onClick(() => { this.privacyRequested(); })
        Text(' 和 ')
          .fontSize(14)
          .fontColor(COROS_WHITE)
          .lineHeight(24)
        Text('《服务条款》')
          .fontSize(14)
          .fontColor(COROS_RED)
          .lineHeight(24)
          .onClick(() => { this.serviceTermsRequested(); })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }
}

@Component
export struct CodeBoxesComp {
  @Link codeValue: string;
  @Prop hasError: boolean = false;
  valueChanged: (value: string) => void = () => {};

  private commitValue(value: string): void {
    this.codeValue = value;
    this.valueChanged(value);
  }

  build() {
    Stack() {
      Row({ space: 28 }) {
        ForEach([0, 1, 2, 3], (index: number) => {
          Text(this.codeValue.length > index ? this.codeValue.charAt(index) : (index === this.codeValue.length ? '|' : ''))
            .fontSize(30)
            .fontColor(index === this.codeValue.length && this.codeValue.length < 4 ? COROS_RED : COROS_WHITE)
            .textAlign(TextAlign.Center)
            .width('20%')
            .aspectRatio(1)
            .backgroundColor(index === this.codeValue.length ? COROS_CODE_ACTIVE_FIELD : COROS_FIELD)
            .border({ width: 2, color: this.hasError ? COROS_RED : '#3A3A3D', radius: 12 })
        }, (index: number) => index.toString())
      }
      .width('100%')

      TextInput({ text: this.codeValue })
        .type(InputType.Number)
        .maxLength(4)
        .fontColor('#00000000')
        .caretColor('#00000000')
        .backgroundColor('#00000000')
        .width('100%')
        .height(80)
        .opacity(0.02)
        .onChange((value: string) => { this.commitValue(value); })
    }
    .width('100%')
  }
}

@Component
export struct ThirdPartyAreaComp {
  unavailableRequested: () => void = () => {};

  build() {
    Column({ space: 24 }) {
      Row({ space: 12 }) {
        Divider().layoutWeight(1).color(COROS_LINE)
        Text('第三方账号')
          .fontSize(14)
          .fontColor(COROS_MUTED)
        Divider().layoutWeight(1).color(COROS_LINE)
      }
      .justifyContent(FlexAlign.Center)
      .width('100%')

      Row({ space: 54 }) {
        Text('☘')
          .fontSize(20)
          .fontColor(COROS_WHITE)
          .textAlign(TextAlign.Center)
          .width(34)
          .height(34)
          .border({ width: 1, color: '#303036', radius: 17 })
          .onClick(() => { this.unavailableRequested(); })
        Text('···')
          .fontSize(20)
          .fontColor(COROS_WHITE)
          .textAlign(TextAlign.Center)
          .width(34)
          .height(34)
          .border({ width: 1, color: '#303036', radius: 17 })
          .onClick(() => { this.unavailableRequested(); })
      }
      .justifyContent(FlexAlign.Center)
      .width('100%')
    }
    .width('100%')
  }
}
