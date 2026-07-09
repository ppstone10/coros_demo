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
  COROS_WHITE
} from '../login/components/AuthColors';
import {
  VerifyTargetKind,
  AuthTitle,
  ErrorText,
  CorosButton,
  AuthHeader,
  UnderlineInput
} from '../login/components/AuthComponents';
import { AuthRoutes, PasswordSetupParams } from '../login/AuthRoutes';
import { navigate, NavOperation } from '../login/AuthNavigator';
import { handleAuthEffect } from '../login/AuthEffectHandler';

@Entry
@Component
struct PasswordSetupPage {
  private viewModel = getLoginViewModel();
  @State targetKind: VerifyTargetKind = VerifyTargetKind.Phone;
  @State setupPassword: string = '';
  @State confirmPassword: string = '';
  @State isLoading: boolean = false;
  @State localError: string = '';
  @State registerActionEnabled: boolean = false;
  @State setupPasswordVisible: boolean = false;
  @State confirmPasswordVisible: boolean = false;

  aboutToAppear(): void {
    let params = router.getParams() as PasswordSetupParams;
    if (params !== null && params !== undefined) {
      this.targetKind = params.targetKind as VerifyTargetKind;
    }
    this.syncState();
  }

  onBackPress(): boolean {
    const target = this.targetKind === VerifyTargetKind.Email ? AuthRoutes.EMAIL_REGISTER : AuthRoutes.PHONE_REGISTER
    navigate(NavOperation.ReplaceTop, target);
    return true;
  }

  build() {
    Scroll() {
      Column() {
        AuthHeader({ showBack: true, showFeedback: false,
          backRequested: () => {
            const target = this.targetKind === VerifyTargetKind.Email ? AuthRoutes.EMAIL_REGISTER : AuthRoutes.PHONE_REGISTER
            navigate(NavOperation.ReplaceTop, target);
          } });
        AuthTitle('设置登录密码');

        Blank().height(60)

        UnderlineInput({ placeholder: '输入新的密码', textValue: this.setupPassword,
          inputType: this.setupPasswordVisible ? InputType.Normal : InputType.Password,
          isPassword: true, passwordVisible: this.setupPasswordVisible,
          valueChanged: (value: string) => {
            this.setupPassword = this.viewModel.normalizePasswordInput(value);
            this.localError = '';
            this.refreshActionStates();
          },
          passwordToggleRequested: () => { this.setupPasswordVisible = !this.setupPasswordVisible; } });

        Blank().height(48)

        UnderlineInput({ placeholder: '再次输入密码', textValue: this.confirmPassword,
          inputType: this.confirmPasswordVisible ? InputType.Normal : InputType.Password,
          isPassword: true, passwordVisible: this.confirmPasswordVisible,
          valueChanged: (value: string) => {
            this.confirmPassword = this.viewModel.normalizePasswordInput(value);
            this.localError = '';
            this.refreshActionStates();
          },
          passwordToggleRequested: () => { this.confirmPasswordVisible = !this.confirmPasswordVisible; } });

        Text('6-20位必须包含字母和数字')
          .fontSize(14)
          .fontColor('#D8D8DD')
          .margin({ top: 8 })

        Blank().height(80)

        CorosButton({ textValue: '注册', color: COROS_BUTTON_RED,
          enabledValue: this.registerActionEnabled, loading: this.isLoading,
          tapRequested: () => { this.submitRegister(); } });

        ErrorText({ message: this.localError });

        Blank().layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .padding({ left: 20, right: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COROS_BLACK)
  }

  private async submitRegister(): Promise<void> {
    let validationMessage: string = this.viewModel.validateRegisterPassword(this.setupPassword, this.confirmPassword);
    if (validationMessage.length > 0) {
      this.localError = validationMessage;
      return;
    }
    this.viewModel.dispatch({
      type: LoginActionType.ModeChanged, mode: AuthMode.Register, username: '', password: '',
      verifyCode: '', displayName: '', region: 'CN'
    });
    this.viewModel.dispatch({
      type: LoginActionType.PasswordChanged, mode: AuthMode.Register, username: '', password: this.setupPassword,
      verifyCode: '', displayName: '', region: 'CN'
    });
    try {
      await this.viewModel.dispatch({
        type: LoginActionType.SubmitClicked, mode: AuthMode.Register, username: '', password: '',
        verifyCode: '', displayName: '', region: 'CN'
      });
    } catch (error) {
      this.localError = '提交失败，请重试';
      return;
    }
    this.syncState();
    this.handleRegisterEffect();
  }

  private handleRegisterEffect(): void {
    let effect: LoginEffect | null = this.viewModel.consumeEffect();
    if (effect === null || effect.type !== LoginEffectType.AuthSucceeded) {
      let state: LoginState = this.viewModel.state;
      if (state.errorMessage.length > 0) {
        this.localError = state.errorMessage;
      }
      return;
    }
    this.viewModel.clearSessionSilently();
    this.setupPassword = '';
    this.confirmPassword = '';
    this.syncState();
    handleAuthEffect(effect);
  }

  private syncState(): void {
    let state: LoginState = this.viewModel.state;
    this.isLoading = state.isLoading;
  }

  private refreshActionStates(): void {
    this.registerActionEnabled = !this.isLoading && this.setupPassword.length >= 6 && this.setupPassword === this.confirmPassword;
  }

  private showMessage(message: string): void {
    try {
      promptAction.showToast({ message: message });
    } catch (error) {
      console.error('showToast failed');
    }
  }
}
