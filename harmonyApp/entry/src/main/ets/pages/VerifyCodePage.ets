import promptAction from '@ohos.promptAction';
import router from '@ohos.router';
import {
  AuthMode,
  LoginActionType,
  LoginState
} from '../login/LoginState';
import { getLoginViewModel } from '../login/LoginViewModelProvider';
import {
  COROS_RED,
  COROS_BLACK,
  COROS_WHITE,
  COROS_MUTED
} from '../login/components/AuthColors';
import {
  VerifyTargetKind,
  verifyCodeMessage,
  AuthTitle,
  ErrorText,
  AuthHeader,
  CodeBoxesComp,
  BlockingLoadingOverlay
} from '../login/components/AuthComponents';
import { AuthRoutes, VerifyCodeParams } from '../login/AuthRoutes';
import { navigate, navigateWithParams, NavOperation } from '../login/AuthNavigator';

@Entry
@Component
struct VerifyCodePage {
  private viewModel = getLoginViewModel();
  private countdownTimer: number = -1;

  @State account: string = '';
  @State targetKind: VerifyTargetKind = VerifyTargetKind.Phone;
  @State codeInput: string = '';
  @State localError: string = '';
  @State countdown: number = 60;
  @State resendLoading: boolean = false;
  @State unavailableDialogVisible: boolean = false;

  aboutToAppear(): void {
    let params = router.getParams() as VerifyCodeParams;
    if (params !== null && params !== undefined) {
      this.account = params.account;
      this.targetKind = params.targetKind as VerifyTargetKind;
    }
    this.viewModel.dispatch({
      type: LoginActionType.ModeChanged, mode: AuthMode.Register, username: '', password: '',
      verifyCode: '', displayName: '', region: 'CN'
    });
    this.viewModel.dispatch({
      type: LoginActionType.UsernameChanged, mode: AuthMode.Register, username: this.account, password: '',
      verifyCode: '', displayName: '', region: 'CN'
    });
    this.startCountdown();
  }

  aboutToDisappear(): void {
    this.stopCountdown();
  }

  onBackPress(): boolean {
    navigate(NavOperation.Pop, '');
    return true;
  }

  build() {
    Stack() {
      Scroll() {
        Column() {
          AuthHeader({ showBack: true, showFeedback: false,
            backRequested: () => { navigate(NavOperation.Pop, ''); } });
          AuthTitle('输入验证码');

          Text(verifyCodeMessage(this.account, this.targetKind))
            .fontSize(16)
            .fontColor('#D8D8DD')
            .lineHeight(24)
            .margin({ top: 14 })

          Blank().height(56)

          CodeBoxesComp({ codeValue: this.codeInput, hasError: this.localError.length > 0,
            valueChanged: (value: string) => {
              this.codeInput = this.viewModel.normalizeVerifyCodeInput(value);
              this.localError = '';
              if (this.codeInput.length === 4) {
                this.submitCode();
              }
            } });

          ErrorText({ message: this.localError });

          Blank().height(58)

          Row() {
            if (this.countdown > 0) {
              Text('重新发送').fontSize(16).fontColor(COROS_MUTED)
              Text('（' + this.countdown + 's）').fontSize(16).fontColor(COROS_RED)
            } else {
              Text('获取验证码')
                .fontSize(16)
                .fontColor(COROS_RED)
                .onClick(() => { this.resendVerifyCode(); })
            }
            Blank()
            Text('收不到验证码?')
              .fontSize(16)
              .fontColor(COROS_MUTED)
              .onClick(() => { this.showUnavailableFeature(); })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Blank().layoutWeight(1)
        }
        .width('100%')
        .height('100%')
        .padding({ left: 20, right: 20 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(COROS_BLACK)

      if (this.resendLoading) {
        BlockingLoadingOverlay();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COROS_BLACK)
  }

  private showUnavailableFeature(): void {
    promptAction.showToast({ message: '该功能还在实现中' });
  }

  private submitCode(): void {
    let validationMessage: string = this.viewModel.validateVerifyCode(this.codeInput);
    if (validationMessage.length > 0) {
      this.localError = validationMessage;
      return;
    }
    let message: string = this.viewModel.verifyCode(this.account, this.codeInput);
    if (message.length > 0) {
      this.localError = message;
      return;
    }
    this.viewModel.dispatch({
      type: LoginActionType.VerifyCodeChanged, mode: AuthMode.Register, username: '', password: '',
      verifyCode: this.codeInput, displayName: '', region: 'CN'
    });
    navigateWithParams(NavOperation.Push, AuthRoutes.toPasswordSetup(this.targetKind));
  }

  private async resendVerifyCode(): Promise<void> {
    this.resendLoading = true;
    let message: string = this.viewModel.requestResentVerifyCode(this.account);
    if (message.length > 0) {
      this.localError = message;
      this.resendLoading = false;
      return;
    }
    this.codeInput = '';
    this.localError = '';
    this.resendLoading = false;
    this.startCountdown();
  }

  private startCountdown(): void {
    this.stopCountdown();
    this.countdown = 60;
    this.countdownTimer = setInterval(() => {
      if (this.countdown <= 0) {
        this.stopCountdown();
        return;
      }
      this.countdown -= 1;
    }, 1000);
  }

  private stopCountdown(): void {
    if (this.countdownTimer >= 0) {
      clearInterval(this.countdownTimer);
      this.countdownTimer = -1;
    }
  }
}
