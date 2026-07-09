import promptAction from '@ohos.promptAction';
import router from '@ohos.router';
import { getLoginViewModel } from '../login/LoginViewModelProvider';
import {
  COROS_BUTTON_RED,
  COROS_BLACK
} from '../login/components/AuthColors';
import {
  AuthTitle,
  ErrorText,
  CorosButton,
  AuthHeader,
  UnderlineInput,
  DisabledUnderlineValue
} from '../login/components/AuthComponents';
import { AuthRoutes, ResetPasswordParams } from '../login/AuthRoutes';
import { navigate, NavOperation } from '../login/AuthNavigator';

@Entry
@Component
struct ResetPasswordPage {
  private viewModel = getLoginViewModel();
  @State account: string = '';
  @State resetNewPassword: string = '';
  @State resetConfirmPassword: string = '';
  @State localError: string = '';
  @State resetPasswordVisible: boolean = false;
  @State resetConfirmVisible: boolean = false;

  aboutToAppear(): void {
    let params = router.getParams() as ResetPasswordParams;
    if (params !== null && params !== undefined) {
      this.account = params.account;
    }
  }

  onBackPress(): boolean {
    navigate(NavOperation.Pop, '');
    return true;
  }

  build() {
    Scroll() {
      Column() {
        AuthHeader({ showBack: true, showFeedback: false,
          backRequested: () => { navigate(NavOperation.Pop, ''); } });
        AuthTitle('设置新密码');

        Blank().height(42)

        Text('账号').fontSize(14).fontColor('#D8D8DD')
        Blank().height(8)

        DisabledUnderlineValue({ value: this.account, placeholder: '账号' });

        Blank().height(42)

        UnderlineInput({ placeholder: '输入新的密码', textValue: this.resetNewPassword,
          inputType: this.resetPasswordVisible ? InputType.Normal : InputType.Password,
          isPassword: true, passwordVisible: this.resetPasswordVisible,
          valueChanged: (value: string) => {
            this.resetNewPassword = this.viewModel.normalizePasswordInput(value);
            this.localError = '';
          },
          passwordToggleRequested: () => { this.resetPasswordVisible = !this.resetPasswordVisible; } });

        Blank().height(42)

        UnderlineInput({ placeholder: '再次输入新密码', textValue: this.resetConfirmPassword,
          inputType: this.resetConfirmVisible ? InputType.Normal : InputType.Password,
          isPassword: true, passwordVisible: this.resetConfirmVisible,
          valueChanged: (value: string) => {
            this.resetConfirmPassword = this.viewModel.normalizePasswordInput(value);
            this.localError = '';
          },
          passwordToggleRequested: () => { this.resetConfirmVisible = !this.resetConfirmVisible; } });

        Text('6-20位，必须包含字母和数字')
          .fontSize(14)
          .fontColor('#D8D8DD')
          .margin({ top: 8 })

        Blank().height(72)

        CorosButton({ textValue: '完成', color: COROS_BUTTON_RED,
          enabledValue: this.viewModel.canSubmitResetPassword(this.resetNewPassword, this.resetConfirmPassword),
          loading: false,
          tapRequested: () => { this.submitResetPassword(); } });

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

  private submitResetPassword(): void {
    let validationMessage: string = this.viewModel.validateRegisterPassword(this.resetNewPassword, this.resetConfirmPassword);
    if (validationMessage.length > 0) {
      this.localError = validationMessage;
      return;
    }
    let message: string = this.viewModel.resetPasswordMessage(this.account, this.resetNewPassword);
    if (message.length > 0) {
      this.localError = message;
      return;
    }
    this.localError = '';
    navigate(NavOperation.ResetKeepingEntranceAndPush, AuthRoutes.LOGIN);
    this.showMessage('密码已更新');
  }

  private showMessage(message: string): void {
    try {
      promptAction.showToast({ message: message });
    } catch (error) {
      console.error('showToast failed');
    }
  }
}
