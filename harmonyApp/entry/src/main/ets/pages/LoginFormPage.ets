import promptAction from '@ohos.promptAction';
import router from '@ohos.router';
import {
  AuthMode,
  LoginAction,
  LoginActionType,
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
  VERSION_TEXT
} from '../login/components/AuthColors';
import {
  TermsPromptAction,
  AuthTitle,
  ErrorText,
  CorosButton,
  AuthHeader,
  UnderlineInput,
  AgreementRowComp,
  ThirdPartyAreaComp
} from '../login/components/AuthComponents';
import { AuthRoutes } from '../login/AuthRoutes';
import { navigate, NavOperation } from '../login/AuthNavigator';
import { handleAuthEffect } from '../login/AuthEffectHandler';

@Entry
@Component
struct LoginFormPage {
  private viewModel = getLoginViewModel();
  @State username: string = '';
  @State password: string = '';
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  @State localError: string = '';
  @State acceptedTerms: boolean = false;
  @State loginPasswordVisible: boolean = false;
  @State loginActionEnabled: boolean = false;
  @State termsPromptShown: boolean = false;

  @State fromRegistration: boolean = false;

  aboutToAppear(): void {
    this.syncState();
    let params = router.getParams();
    if (params !== undefined && params !== null && (params as Record<string, Object>)['fromRegistration'] === true) {
      this.fromRegistration = true;
    }
    this.viewModel.dispatch({
      type: LoginActionType.ModeChanged, mode: AuthMode.Login, username: '', password: '',
      verifyCode: '', displayName: '', region: 'CN'
    });
    this.syncState();
  }

  onBackPress(): boolean {
    if (this.fromRegistration) {
      navigate(NavOperation.ResetTo, AuthRoutes.ENTRANCE);
    } else {
      navigate(NavOperation.Pop, '');
    }
    return true;
  }

  build() {
    Stack() {
      Scroll() {
        Column() {
          AuthHeader({ showBack: true, showFeedback: true,
            backRequested: () => { navigate(NavOperation.Pop, ''); },
            feedbackRequested: () => { this.showUnavailableFeature(); } });
          AuthTitle('账号登录');

          Blank().height(45)

          UnderlineInput({ placeholder: '输入手机号或邮箱', textValue: this.username,
            inputType: InputType.Email, isPassword: false, passwordVisible: false,
            valueChanged: (value: string) => { this.onUsernameChanged(value); } });

          Blank().height(16)

          UnderlineInput({ placeholder: '密码', textValue: this.password,
            inputType: this.loginPasswordVisible ? InputType.Normal : InputType.Password,
            isPassword: true, passwordVisible: this.loginPasswordVisible,
            valueChanged: (value: string) => { this.onPasswordChanged(value); },
            passwordToggleRequested: () => { this.loginPasswordVisible = !this.loginPasswordVisible; } });

          Blank().height(59)

          AgreementRowComp({ accepted: this.acceptedTerms,
            acceptedChanged: (_: boolean) => { this.localError = ''; },
            privacyRequested: () => { this.openLegal(AuthRoutes.PRIVACY_POLICY); },
            serviceTermsRequested: () => { this.openLegal(AuthRoutes.SERVICE_TERMS); } });

          Blank().height(12)

          CorosButton({ textValue: '登录', color: COROS_BUTTON_RED,
            enabledValue: this.loginActionEnabled, loading: this.isLoading,
            tapRequested: () => { this.submitLogin(); } });

          ErrorText({ message: this.currentError() });

          Text('忘记密码?')
            .fontSize(14)
            .fontColor(COROS_MUTED)
            .margin({ top: 16 })
            .onClick(() => { navigate(NavOperation.Push, AuthRoutes.FORGOT_PASSWORD); })

          Blank().layoutWeight(1)

          ThirdPartyAreaComp({ unavailableRequested: () => { this.showUnavailableFeature(); } });

          Text(VERSION_TEXT)
            .fontSize(16)
            .fontColor(COROS_MUTED)
            .width('100%')
            .textAlign(TextAlign.Center)
            .margin({ top: 22, bottom: 12 })
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
            this.submitLogin();
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
    navigate(NavOperation.Push, url);
  }

  private showUnavailableFeature(): void {
    promptAction.showToast({ message: '该功能还在实现中' });
  }

  private onUsernameChanged(value: string): void {
    this.username = value;
    this.localError = '';
    this.refreshActionStates();
    this.viewModel.dispatch({
      type: LoginActionType.UsernameChanged, mode: AuthMode.Login, username: value, password: '',
      verifyCode: '', displayName: '', region: 'CN'
    });
  }

  private onPasswordChanged(value: string): void {
    this.password = value;
    this.localError = '';
    this.refreshActionStates();
    this.viewModel.dispatch({
      type: LoginActionType.PasswordChanged, mode: AuthMode.Login, username: '', password: value,
      verifyCode: '', displayName: '', region: 'CN'
    });
  }

  private async submitLogin(): Promise<void> {
    if (!this.acceptedTerms) {
      this.termsPromptShown = true;
      return;
    }
    this.viewModel.dispatch({
      type: LoginActionType.ModeChanged, mode: AuthMode.Login, username: '', password: '',
      verifyCode: '', displayName: '', region: 'CN'
    });
    this.viewModel.dispatch({
      type: LoginActionType.SubmitClicked, mode: AuthMode.Login, username: '', password: '',
      verifyCode: '', displayName: '', region: 'CN'
    });
    this.syncState();
    this.handleLoginEffect();
  }

  private handleLoginEffect(): void {
    let effect: LoginEffect | null = this.viewModel.consumeEffect();
    if (effect === null) {
      let state: LoginState = this.viewModel.state;
      if (state.errorMessage.length > 0) {
        this.localError = state.errorMessage;
      }
      return;
    }
    this.localError = '';
    this.syncState();
    handleAuthEffect(effect);
  }

  private syncState(): void {
    let state: LoginState = this.viewModel.state;
    this.username = state.username;
    this.password = state.password;
    this.isLoading = state.isLoading;
    this.errorMessage = state.errorMessage;
    this.refreshActionStates();
  }

  private refreshActionStates(): void {
    this.loginActionEnabled = !this.isLoading && this.username.trim().length > 0 && this.password.length >= 6;
  }

  private currentError(): string {
    return this.localError.length > 0 ? this.localError : this.errorMessage;
  }

  private showMessage(message: string): void {
    try {
      promptAction.showToast({ message: message });
    } catch (error) {
      console.error('showToast failed');
    }
  }
}
