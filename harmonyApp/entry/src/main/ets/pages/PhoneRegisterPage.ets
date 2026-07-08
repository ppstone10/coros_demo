import promptAction from '@ohos.promptAction';
import router from '@ohos.router';
import {
  AuthMode,
  LoginActionType,
  LoginState
} from '../login/LoginState';
import { getLoginViewModel } from '../login/LoginViewModelProvider';
import {
  COROS_BUTTON_RED,
  COROS_BLACK,
  COROS_WHITE,
  COROS_RED,
  REGISTER_AGREEMENT_TOP_SPACING,
  REGISTER_ACTION_TOP_SPACING
} from '../login/components/AuthColors';
import {
  TermsPromptAction,
  AuthTitle,
  ErrorText,
  CorosButton,
  AuthHeader,
  AgreementRowComp,
  PhoneInputComp
} from '../login/components/AuthComponents';
import { AuthRoutes } from '../login/AuthRoutes';

@Entry
@Component
struct PhoneRegisterPage {
  private viewModel = getLoginViewModel();
  @State username: string = '';
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  @State localError: string = '';
  @State acceptedTerms: boolean = false;
  @State phoneCodeActionEnabled: boolean = false;
  @State termsPromptShown: boolean = false;

  aboutToAppear(): void {
    this.loadState();
    this.viewModel.dispatch({
      type: LoginActionType.ModeChanged, mode: AuthMode.Register, username: '', password: '',
      verifyCode: '', displayName: '', region: 'CN'
    });
  }

  onBackPress(): boolean {
    router.back();
    return true;
  }

  build() {
    Stack() {
      Scroll() {
        Column() {
          AuthHeader({ showBack: true, showFeedback: true,
            backRequested: () => { router.back(); },
            feedbackRequested: () => { this.showUnavailableFeature(); } });
          AuthTitle('手机号注册');

          Blank().height(60)

          PhoneInputComp({ countryCode: '+86', phoneValue: this.username,
            valueChanged: (value: string) => { this.onPhoneChanged(value); } });

          Blank().height(REGISTER_AGREEMENT_TOP_SPACING)

          AgreementRowComp({ accepted: this.acceptedTerms,
            acceptedChanged: (_: boolean) => { this.localError = ''; },
            privacyRequested: () => { this.openLegal(AuthRoutes.PRIVACY_POLICY); },
            serviceTermsRequested: () => { this.openLegal(AuthRoutes.SERVICE_TERMS); } });

          Blank().height(REGISTER_ACTION_TOP_SPACING)

          CorosButton({ textValue: '发送验证码', color: COROS_BUTTON_RED,
            enabledValue: this.phoneCodeActionEnabled, loading: this.isLoading,
            tapRequested: () => { this.requestPhoneVerifyCode(); } });

          ErrorText({ message: this.currentError() });

          Text('邮箱注册')
            .fontSize(18)
            .fontColor(COROS_RED)
            .width('100%')
            .textAlign(TextAlign.Center)
            .margin({ top: 26 })
            .onClick(() => {
              this.viewModel.dispatch({
                type: LoginActionType.UsernameChanged, mode: AuthMode.Register, username: '', password: '',
                verifyCode: '', displayName: '', region: 'CN'
              });
              router.replaceUrl({ url: AuthRoutes.EMAIL_REGISTER });
            })

          Blank().layoutWeight(1)
        }
        .width('100%')
        .height('100%')
        .padding({ left: 20, right: 20 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(COROS_BLACK)

      if (this.termsPromptShown) {
        this.TermsConsentSheet();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COROS_BLACK)
  }

  @Builder
  TermsConsentSheet() {
    Column() {
      Blank().layoutWeight(1)
      Column() {
        Row() {
          Image($r('app.media.ic_profile_close'))
            .width(34)
            .height(34)
            .objectFit(ImageFit.Contain)
        }
        .width('100%')
        .justifyContent(FlexAlign.End)
          .onClick(() => { this.termsPromptShown = false; })
        Text('阅读并同意以下条款，').fontSize(18).fontColor(COROS_WHITE).width('100%')
          .textAlign(TextAlign.Center).margin({ top: 12 })
        Row() {
          Text('《隐私政策》').fontSize(18).fontColor(COROS_RED)
            .onClick(() => { this.openLegal(AuthRoutes.PRIVACY_POLICY); })
          Text(' 和 ').fontSize(18).fontColor(COROS_WHITE)
          Text('《服务条款》').fontSize(18).fontColor(COROS_RED)
            .onClick(() => { this.openLegal(AuthRoutes.SERVICE_TERMS); })
        }
        .width('100%').justifyContent(FlexAlign.Center).margin({ top: 8 })
        Blank().height(42)
        CorosButton({ textValue: '同意并继续', color: COROS_RED, enabledValue: true, loading: false,
          tapRequested: () => {
            this.acceptedTerms = true;
            this.termsPromptShown = false;
            this.requestPhoneVerifyCode();
          } });
      }
      .width('100%')
      .padding({ left: 22, right: 22, top: 18, bottom: 18 })
      .backgroundColor('#1A1A1B')
      .borderRadius({ topLeft: 12, topRight: 12 })
    }
    .width('100%').height('100%').backgroundColor('#000000C7')
  }

  private openLegal(url: string): void {
    router.pushUrl({ url: url, params: { returnPage: AuthRoutes.PHONE_REGISTER } });
  }

  private showUnavailableFeature(): void {
    promptAction.showToast({ message: '该功能还在实现中' });
  }

  private onPhoneChanged(value: string): void {
    this.username = this.viewModel.normalizePhoneInput(value);
    this.localError = '';
    this.refreshActionStates();
  }

  private refreshActionStates(): void {
    let digits: string = '';
    for (let i = 0; i < this.username.length; i++) {
      let ch: string = this.username.charAt(i);
      if (ch >= '0' && ch <= '9') digits += ch;
    }
    this.phoneCodeActionEnabled = !this.isLoading && digits.length === 11;
  }

  private requestPhoneVerifyCode(): void {
    let validationMessage: string = this.viewModel.validatePhoneAccount(this.username);
    if (validationMessage.length > 0) {
      this.localError = validationMessage;
      return;
    }
    if (this.viewModel.hasAccount(this.username)) {
      this.localError = '账号已存在';
      return;
    }
    if (!this.acceptedTerms) {
      this.termsPromptShown = true;
      return;
    }
    let message: string = this.viewModel.requestVerifyCode(this.username);
    if (message.length > 0) {
      this.localError = message;
      return;
    }
    router.pushUrl({
      url: AuthRoutes.VERIFY_CODE,
      params: { account: this.username, targetKind: 0 }
    });
  }

  private currentError(): string {
    return this.localError.length > 0 ? this.localError : this.errorMessage;
  }

  private loadState(): void {
    let state: LoginState = this.viewModel.state;
    this.isLoading = state.isLoading;
    this.errorMessage = state.errorMessage;
  }
}
