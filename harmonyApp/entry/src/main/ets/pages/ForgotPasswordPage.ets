import promptAction from '@ohos.promptAction';
import router from '@ohos.router';
import { getLoginViewModel } from '../login/LoginViewModelProvider';
import {
  COROS_BUTTON_RED,
  COROS_BLACK,
  COROS_WHITE
} from '../login/components/AuthColors';
import {
  AuthTitle,
  ErrorText,
  CorosButton,
  AuthHeader,
  UnderlineInput
} from '../login/components/AuthComponents';
import { AuthRoutes } from '../login/AuthRoutes';

@Entry
@Component
struct ForgotPasswordPage {
  private viewModel = getLoginViewModel();
  @State forgotAccount: string = '';
  @State localError: string = '';

  onBackPress(): boolean {
    router.back();
    return true;
  }

  build() {
    Scroll() {
      Column() {
        AuthHeader({ showBack: true, showFeedback: false,
          onBack: () => { router.back(); } });
        AuthTitle('找回密码');

        Blank().height(60)

        UnderlineInput({ placeholder: '输入手机号或邮箱', textValue: this.forgotAccount,
          inputType: InputType.Email, isPassword: false, passwordVisible: false,
          onChange: (value: string) => {
            this.forgotAccount = value.trim();
            this.localError = '';
          } });

        Blank().height(72)

        CorosButton({ textValue: '下一步', color: COROS_BUTTON_RED,
          enabledValue: this.forgotAccount.trim().length > 0, loading: false,
          onTap: () => { this.verifyForgotAccount(); } });

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

  private verifyForgotAccount(): void {
    let account: string = this.forgotAccount.trim();
    let isEmail: boolean = account.indexOf('@') >= 0;
    let normalizedAccount: string = isEmail ? this.viewModel.normalizeEmailInput(account) : account;
    let validationMessage: string = '';
    if (isEmail) {
      validationMessage = this.viewModel.validateEmailAccount(normalizedAccount);
    } else if (account !== this.viewModel.normalizePhoneInput(account)) {
      validationMessage = '请输入11位手机号';
    } else {
      validationMessage = this.viewModel.validatePhoneAccount(normalizedAccount);
    }
    if (validationMessage.length > 0) {
      this.localError = validationMessage;
      return;
    }
    if (!this.viewModel.hasAccount(normalizedAccount)) {
      this.localError = '账号不存在';
      return;
    }
    router.pushUrl({
      url: AuthRoutes.RESET_PASSWORD,
      params: { account: normalizedAccount }
    });
  }
}
