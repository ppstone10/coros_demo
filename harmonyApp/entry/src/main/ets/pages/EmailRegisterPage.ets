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
  COROS_OVERLAY_COLOR,
  REGISTER_AGREEMENT_TOP_SPACING,
  REGISTER_ACTION_TOP_SPACING
} from '../login/components/AuthColors';
import {
  TermsPromptAction,
  VerifyTargetKind,
  AuthTitle,
  ErrorText,
  CorosButton,
  AuthHeader,
  UnderlineInput,
  AgreementRowComp
} from '../login/components/AuthComponents';
import { AuthRoutes } from '../login/AuthRoutes';
import { navigate, navigateWithParams, NavOperation } from '../login/AuthNavigator';
import { AppColors } from '../resources/AppResources';

@Entry
@Component
struct EmailRegisterPage {
  private viewModel = getLoginViewModel();
  @State emailInput: string = '';
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  @State localError: string = '';
  @State acceptedTerms: boolean = false;
  @State emailCodeActionEnabled: boolean = false;
  @State termsPromptShown: boolean = false;

  aboutToAppear(): void {
    this.loadState();
    this.viewModel.dispatch({
      type: LoginActionType.ModeChanged, mode: AuthMode.Register, username: '', password: '',
      verifyCode: '', displayName: '', region: 'CN'
    });
  }

  onBackPress(): boolean {
    navigate(NavOperation.Pop, '');
    return true;
  }

  build() {
    Stack() {
      Scroll() {
        Column() {
          AuthHeader({ showBack: true, showFeedback: true,
            backRequested: () => { navigate(NavOperation.Pop, ''); },
            feedbackRequested: () => { this.showUnavailableFeature(); } });
          AuthTitle($r('app.string.auth_email_register'));

          Blank().height(60)

          UnderlineInput({ placeholder: $r('app.string.auth_email_placeholder'), textValue: this.emailInput,
            inputType: InputType.Email, isPassword: false, passwordVisible: false,
            valueChanged: (value: string) => { this.onEmailChanged(value); } });

          Blank().height(REGISTER_AGREEMENT_TOP_SPACING)

          AgreementRowComp({ accepted: this.acceptedTerms,
            acceptedChanged: (_: boolean) => { this.localError = ''; },
            privacyRequested: () => { this.openLegal(AuthRoutes.PRIVACY_POLICY); },
            serviceTermsRequested: () => { this.openLegal(AuthRoutes.SERVICE_TERMS); } });

          Blank().height(REGISTER_ACTION_TOP_SPACING)

          CorosButton({ textValue: $r('app.string.auth_send_code'), color: COROS_BUTTON_RED,
            enabledValue: this.emailCodeActionEnabled, loading: this.isLoading,
            tapRequested: () => { this.requestEmailVerifyCode(); } });

          ErrorText({ message: this.currentError() });

          Text($r('app.string.auth_phone_register'))
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
              navigate(NavOperation.ReplaceTop, AuthRoutes.PHONE_REGISTER);
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
    Stack({ alignContent: Alignment.Bottom }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(COROS_OVERLAY_COLOR)
        .onClick(() => { })
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
        Text($r('app.string.auth_read_terms')).fontSize(18).fontColor(COROS_WHITE).width('100%')
          .textAlign(TextAlign.Center).margin({ top: 12 })
        Row() {
          Text($r('app.string.auth_privacy_policy_link')).fontSize(18).fontColor(COROS_RED)
            .onClick(() => { this.openLegal(AuthRoutes.PRIVACY_POLICY); })
          Text($r('app.string.auth_terms_joiner')).fontSize(18).fontColor(COROS_WHITE)
          Text($r('app.string.auth_service_terms_link')).fontSize(18).fontColor(COROS_RED)
            .onClick(() => { this.openLegal(AuthRoutes.SERVICE_TERMS); })
        }
        .width('100%').justifyContent(FlexAlign.Center).margin({ top: 8 })
        Blank().height(42)
        CorosButton({ textValue: $r('app.string.auth_agree_and_continue'), color: COROS_RED, enabledValue: true, loading: false,
          tapRequested: () => {
            this.acceptedTerms = true;
            this.termsPromptShown = false;
            this.requestEmailVerifyCode();
          } });
      }
      .width('100%')
      .padding({ left: 22, right: 22, top: 18, bottom: 18 })
      .backgroundColor(AppColors.AUTH_SHEET)
      .borderRadius({ topLeft: 12, topRight: 12 })
    }
    .width('100%').height('100%').zIndex(1)
  }

  private openLegal(url: string): void {
    navigate(NavOperation.Push, url);
  }

  private showUnavailableFeature(): void {
    promptAction.showToast({ message: $r('app.string.auth_unavailable') });
  }

  private onEmailChanged(value: string): void {
    this.emailInput = this.viewModel.normalizeEmailInput(value);
    this.localError = '';
    this.refreshActionStates();
  }

  private refreshActionStates(): void {
    let trimmed: string = this.emailInput.trim();
    let atIndex: number = trimmed.indexOf('@');
    let domain: string = atIndex >= 0 ? trimmed.substring(atIndex + 1) : '';
    this.emailCodeActionEnabled = !this.isLoading && atIndex > 0 && domain.indexOf('.') > 0;
  }

  private requestEmailVerifyCode(): void {
    let email: string = this.emailInput.trim();
    let validationMessage: string = this.viewModel.validateEmailAccount(email);
    if (validationMessage.length > 0) {
      this.localError = validationMessage;
      return;
    }
    if (this.viewModel.hasAccount(email)) {
      this.localError = 'auth_error_account_exists';
      return;
    }
    if (!this.acceptedTerms) {
      this.termsPromptShown = true;
      return;
    }
    let message: string = this.viewModel.requestVerifyCode(email);
    if (message.length > 0) {
      this.localError = message;
      return;
    }
    navigateWithParams(NavOperation.Push, AuthRoutes.toVerifyCode(email, VerifyTargetKind.Email));
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
