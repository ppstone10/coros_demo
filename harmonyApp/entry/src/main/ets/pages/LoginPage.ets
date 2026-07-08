import hilog from '@ohos.hilog';
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
import { LoginViewModel } from '../login/LoginViewModel';
import {
  COROS_RED,
  COROS_BUTTON_RED,
  COROS_BLACK,
  COROS_WHITE,
  COROS_MUTED,
  COROS_LINE,
  REGISTER_AGREEMENT_TOP_SPACING,
  REGISTER_ACTION_TOP_SPACING,
  VERSION_TEXT
} from '../login/components/AuthColors';
import {
  TermsPromptAction,
  VerifyTargetKind,
  verifyCodeMessage,
  AuthTitle,
  ErrorText,
  BlockingLoadingOverlay,
  LegalDocumentPage,
  CorosButton,
  AuthHeader,
  UnderlineInput,
  PhoneInputComp,
  DisabledUnderlineValue,
  AgreementRowComp,
  CodeBoxesComp,
  ThirdPartyAreaComp
} from '../login/components/AuthComponents';
import {
  PRIVACY_POLICY_PARAGRAPHS,
  SERVICE_TERMS_PARAGRAPHS
} from '../login/components/LegalContent';

enum AuthPage {
  Entrance,
  Login,
  PhoneRegister,
  EmailRegister,
  VerifyCode,
  PasswordSetup,
  ForgotPassword,
  ResetPassword,
  PrivacyPolicy,
  ServiceTerms,
  ProfileCompletion,
  SignedIn
}

@Entry
@Component
struct LoginPage {
  private viewModel: LoginViewModel = new LoginViewModel();
  private countdownTimer: number = -1;

  @State page: AuthPage = AuthPage.Entrance;
  @State legalReturnPage: AuthPage = AuthPage.PhoneRegister;
  @State verifyTargetKind: VerifyTargetKind = VerifyTargetKind.Phone;
  @State termsPromptAction: TermsPromptAction = TermsPromptAction.None;
  @State unavailableDialogVisible: boolean = false;
  @State username: string = '';
  @State password: string = '';
  @State verifyCode: string = '';
  @State displayName: string = '';
  @State selectedRegion: string = 'CN';
  @State sessionAccount: string = '';
  @State isLoading: boolean = false;
  @State isLoggedIn: boolean = false;
  @State errorMessage: string = '';
  @State localError: string = '';
  @State acceptedTerms: boolean = false;
  @State codeInput: string = '';
  @State emailInput: string = '';
  @State setupPassword: string = '';
  @State confirmPassword: string = '';
  @State countdown: number = 60;
  @State resendLoading: boolean = false;
  @State loginPasswordVisible: boolean = false;
  @State setupPasswordVisible: boolean = false;
  @State confirmPasswordVisible: boolean = false;
  @State loginActionEnabled: boolean = false;
  @State phoneCodeActionEnabled: boolean = false;
  @State emailCodeActionEnabled: boolean = false;
  @State registerActionEnabled: boolean = false;
  @State showDeleteDialog: boolean = false;

  @State profileUsername: string = '';
  @State profileBirthDate: string = '';
  @State profileHeightCm: string = '';
  @State profileWeightKg: string = '';
  @State profileGender: string = '';
  @State profileMeasurementSystem: string = 'Metric';
  @State profileCountry: string = '中国';
  @State profilePhone: string = '';
  @State profileActionEnabled: boolean = false;

  @State forgotAccount: string = '';
  @State resetNewPassword: string = '';
  @State resetConfirmPassword: string = '';
  @State resetPasswordVisible: boolean = false;
  @State resetConfirmVisible: boolean = false;

  aboutToAppear(): void {
    hilog.info(0x0001, 'demo_persist', 'LoginPage aboutToAppear, isLoggedIn=' + JSON.stringify(this.isLoggedIn) + ' sessionAccount="' + this.sessionAccount + '"');
    this.syncState();
    this.page = this.isLoggedIn && this.sessionAccount.length > 0 ? AuthPage.SignedIn : AuthPage.Entrance;
    hilog.info(0x0001, 'demo_persist', 'LoginPage start page=' + JSON.stringify(this.page));
  }

  aboutToDisappear(): void {
    this.stopCountdown();
  }

  onBackPress(): boolean {
    return this.navigateBack();
  }

  build() {
    Stack() {
      if (this.page === AuthPage.Entrance) {
        this.EntrancePage();
      } else if (this.page === AuthPage.Login) {
        this.LoginFormPage();
      } else if (this.page === AuthPage.PhoneRegister) {
        this.PhoneRegisterPage();
      } else if (this.page === AuthPage.EmailRegister) {
        this.EmailRegisterPage();
      } else if (this.page === AuthPage.VerifyCode) {
        this.VerifyCodePage();
      } else if (this.page === AuthPage.PasswordSetup) {
        this.PasswordSetupPage();
      } else if (this.page === AuthPage.ForgotPassword) {
        this.ForgotPasswordPage();
      } else if (this.page === AuthPage.ResetPassword) {
        this.ResetPasswordPage();
      } else if (this.page === AuthPage.PrivacyPolicy) {
        LegalDocumentPage('隐私政策', PRIVACY_POLICY_PARAGRAPHS, () => { this.handleLegalBack(); });
      } else if (this.page === AuthPage.ServiceTerms) {
        LegalDocumentPage('服务条款', SERVICE_TERMS_PARAGRAPHS, () => { this.handleLegalBack(); });
      } else if (this.page === AuthPage.ProfileCompletion) {
        this.ProfileCompletionPage();
      } else {
        this.SignedInPage();
      }

      if (this.termsPromptAction !== TermsPromptAction.None) {
        this.TermsConsentSheet();
      }

      if (this.unavailableDialogVisible) {
        this.UnavailableFeatureDialog();
      }

      if (this.resendLoading) {
        BlockingLoadingOverlay();
      }

      if (this.showDeleteDialog) {
        this.DeleteAccountDialog();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COROS_BLACK)
  }

  // ========== 页面构建器 ==========

  @Builder
  private EntrancePage() {
    Stack() {
      Video({ src: $rawfile('home.mp4') })
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .autoPlay(true)
        .loop(true)
        .controls(false)
        .muted(true)

      Column() {
        Row() {
          Text('DEBUG')
            .fontSize(11)
            .fontColor('#FFFFFF80')
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor('#FFFFFF20')
            .borderRadius(4)
            .onClick(() => { router.pushUrl({ url: 'pages/DebugStatePage' }); })
          Blank()
        }
        .width('100%')
        .height(52)
        .padding({ left: 20, right: 20 })
        .alignItems(VerticalAlign.Center)

        Image($r('app.media.coros_logo'))
          .width(260)
          .height(48)
          .objectFit(ImageFit.Contain)

        Blank().layoutWeight(1)

        Column({ space: 20 }) {
          CorosButton({ textValue: '注册', color: COROS_RED, enabledValue: true, loading: false,
            tapRequested: () => { this.showPhoneRegister(); } });
          CorosButton({ textValue: '登录', color: '#424242', enabledValue: true, loading: false,
            tapRequested: () => { this.showLogin(); } });
        }
        .width('100%')
        .padding({ left: 20, right: 20, bottom: 60 })
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#111111')
  }

  @Builder
  private LoginFormPage() {
    Scroll() {
      Column() {
        AuthHeader({ showBack: true, showFeedback: true,
          backRequested: () => { this.handleBack(); },
          feedbackRequested: () => { this.showUnavailableFeature(); } });
        AuthTitle('账号登录');

        Blank().height(45)

        UnderlineInput({ placeholder: '输入手机号或邮箱', textValue: this.username,
          inputType: InputType.Email, isPassword: false, passwordVisible: false,
          valueChanged: (value: string) => { this.updateUsername(value); } });

        Blank().height(16)

        UnderlineInput({ placeholder: '密码', textValue: this.password,
          inputType: this.loginPasswordVisible ? InputType.Normal : InputType.Password,
          isPassword: true, passwordVisible: this.loginPasswordVisible,
          valueChanged: (value: string) => { this.updatePassword(value); },
          passwordToggleRequested: () => { this.loginPasswordVisible = !this.loginPasswordVisible; } });

        Blank().height(59)

        AgreementRowComp({ accepted: this.acceptedTerms,
          acceptedChanged: (_: boolean) => { this.localError = ''; },
          privacyRequested: () => { this.openPrivacyPolicy(); },
          serviceTermsRequested: () => { this.openServiceTerms(); } });

        Blank().height(12)

        CorosButton({ textValue: '登录', color: COROS_BUTTON_RED,
          enabledValue: this.loginActionEnabled, loading: this.isLoading,
          tapRequested: () => { this.submitLogin(); } });

ErrorText({ message: this.currentError() });

          Text('忘记密码?')
          .fontSize(14)
          .fontColor(COROS_MUTED)
          .margin({ top: 16 })
          .onClick(() => { this.openForgotPassword(); })

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
  }

  @Builder
  private PhoneRegisterPage() {
    Scroll() {
      Column() {
        AuthHeader({ showBack: true, showFeedback: true,
          backRequested: () => { this.handleBack(); },
          feedbackRequested: () => { this.showUnavailableFeature(); } });
        AuthTitle('手机号注册');

        Blank().height(60)

        PhoneInputComp({ countryCode: '+86', phoneValue: this.username,
          valueChanged: (value: string) => { this.updateUsername(this.normalizePhoneInput(value)); } });

        Blank().height(REGISTER_AGREEMENT_TOP_SPACING)

        AgreementRowComp({ accepted: this.acceptedTerms,
          acceptedChanged: (_: boolean) => { this.localError = ''; },
          privacyRequested: () => { this.openPrivacyPolicy(); },
          serviceTermsRequested: () => { this.openServiceTerms(); } });

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
          .onClick(() => { this.showEmailRegister(); })

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

  @Builder
  private EmailRegisterPage() {
    Scroll() {
      Column() {
        AuthHeader({ showBack: true, showFeedback: true,
          backRequested: () => { this.handleBack(); },
          feedbackRequested: () => { this.showUnavailableFeature(); } });
        AuthTitle('邮箱注册');

        Blank().height(60)

        UnderlineInput({ placeholder: '请输入邮箱', textValue: this.emailInput,
          inputType: InputType.Email, isPassword: false, passwordVisible: false,
          valueChanged: (value: string) => {
            this.emailInput = this.normalizeEmailInput(value);
            this.localError = '';
            this.refreshActionStates();
          } });

        Blank().height(REGISTER_AGREEMENT_TOP_SPACING)

        AgreementRowComp({ accepted: this.acceptedTerms,
          acceptedChanged: (_: boolean) => { this.localError = ''; },
          privacyRequested: () => { this.openPrivacyPolicy(); },
          serviceTermsRequested: () => { this.openServiceTerms(); } });

        Blank().height(REGISTER_ACTION_TOP_SPACING)

        CorosButton({ textValue: '发送验证码', color: COROS_BUTTON_RED,
          enabledValue: this.emailCodeActionEnabled, loading: this.isLoading,
          tapRequested: () => { this.requestEmailVerifyCode(); } });

        ErrorText({ message: this.currentError() });

        Text('手机号注册')
          .fontSize(18)
          .fontColor(COROS_RED)
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ top: 26 })
          .onClick(() => { this.showPhoneRegisterFromEmail(); })

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

  @Builder
  private VerifyCodePage() {
    Scroll() {
      Column() {
        AuthHeader({ showBack: true, showFeedback: false,
          backRequested: () => { this.handleBack(); } });
        AuthTitle('输入验证码');

        Text(verifyCodeMessage(this.username, this.verifyTargetKind))
          .fontSize(16)
          .fontColor('#D8D8DD')
          .lineHeight(24)
          .margin({ top: 14 })

        Blank().height(56)

        CodeBoxesComp({ codeValue: this.codeInput, hasError: this.currentError().length > 0,
          valueChanged: (value: string) => {
            this.codeInput = this.normalizeVerifyCodeInput(value);
            this.localError = '';
            if (this.codeInput.length === 4) {
              this.submitCode();
            }
          } });

        ErrorText({ message: this.currentError() });

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
  }

  @Builder
  private PasswordSetupPage() {
    Scroll() {
      Column() {
        AuthHeader({ showBack: true, showFeedback: false,
          backRequested: () => { this.handleBack(); } });
        AuthTitle('设置登录密码');

        Blank().height(60)

        UnderlineInput({ placeholder: '输入新的密码', textValue: this.setupPassword,
          inputType: this.setupPasswordVisible ? InputType.Normal : InputType.Password,
          isPassword: true, passwordVisible: this.setupPasswordVisible,
          valueChanged: (value: string) => {
            this.setupPassword = this.normalizePasswordInput(value);
            this.localError = '';
            this.refreshActionStates();
          },
          passwordToggleRequested: () => { this.setupPasswordVisible = !this.setupPasswordVisible; } });

        Blank().height(48)

        UnderlineInput({ placeholder: '再次输入密码', textValue: this.confirmPassword,
          inputType: this.confirmPasswordVisible ? InputType.Normal : InputType.Password,
          isPassword: true, passwordVisible: this.confirmPasswordVisible,
          valueChanged: (value: string) => {
            this.confirmPassword = this.normalizePasswordInput(value);
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

        ErrorText({ message: this.currentError() });

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

  @Builder
  private ForgotPasswordPage() {
    Scroll() {
      Column() {
        AuthHeader({ showBack: true, showFeedback: false,
          backRequested: () => { this.handleBack(); } });
        AuthTitle('找回密码');

        Blank().height(60)

        UnderlineInput({ placeholder: '输入手机号或邮箱', textValue: this.forgotAccount,
          inputType: InputType.Email, isPassword: false, passwordVisible: false,
          valueChanged: (value: string) => {
            this.forgotAccount = value.trim();
            this.localError = '';
          } });

        Blank().height(72)

        CorosButton({ textValue: '下一步', color: COROS_BUTTON_RED,
          enabledValue: this.forgotAccount.trim().length > 0, loading: false,
          tapRequested: () => { this.verifyForgotAccount(); } });

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

  @Builder
  private ResetPasswordPage() {
    Scroll() {
      Column() {
        AuthHeader({ showBack: true, showFeedback: false,
          backRequested: () => { this.handleBack(); } });
        AuthTitle('设置新密码');

        Blank().height(42)

        Text('账号').fontSize(14).fontColor('#D8D8DD')
        Blank().height(8)

        DisabledUnderlineValue({ value: this.forgotAccount, placeholder: '账号' });

        Blank().height(42)

        UnderlineInput({ placeholder: '输入新的密码', textValue: this.resetNewPassword,
          inputType: this.resetPasswordVisible ? InputType.Normal : InputType.Password,
          isPassword: true, passwordVisible: this.resetPasswordVisible,
          valueChanged: (value: string) => {
            this.resetNewPassword = this.normalizePasswordInput(value);
            this.localError = '';
          },
          passwordToggleRequested: () => { this.resetPasswordVisible = !this.resetPasswordVisible; } });

        Blank().height(42)

        UnderlineInput({ placeholder: '再次输入新密码', textValue: this.resetConfirmPassword,
          inputType: this.resetConfirmVisible ? InputType.Normal : InputType.Password,
          isPassword: true, passwordVisible: this.resetConfirmVisible,
          valueChanged: (value: string) => {
            this.resetConfirmPassword = this.normalizePasswordInput(value);
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

  @Builder
  private ProfileCompletionPage() {
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

          this.ProfileTextRow('用户名', true, this.profileUsername, '输入用户名', (value: string) => {
            this.profileUsername = value.substring(0, 20);
          });
          this.ProfileTextRow('出生日期', true, this.profileBirthDate, '例如：2002年11月17日', (value: string) => {
            this.profileBirthDate = value;
          });
          this.ProfileTextRow('身高（cm）', true, this.profileHeightCm, '例如：175', (value: string) => {
            this.profileHeightCm = value.replace(/[^0-9]/g, '').substring(0, 3);
          });
          this.ProfileTextRow('体重（kg）', true, this.profileWeightKg, '例如：60.0', (value: string) => {
            this.profileWeightKg = value.replace(/[^0-9.]/g, '').substring(0, 5);
          });
          this.ProfilePickerRow('公英制', false, this.measurementLabel(), '', () => { this.toggleMeasurementSystem(); });
          this.ProfileTextRow('手机', false, this.profilePhone, '输入手机号', (value: string) => {
            this.profilePhone = value.replace(/[^0-9+\-]/g, '').substring(0, 20);
          });
          this.ProfilePickerRow('国家与地区', false, this.profileCountry, '中国', () => { this.showUnavailableFeature(); });
          this.GenderRow();

          Blank().height(16)
        }
        .width('100%')
        .padding({ left: 20, right: 20 })
      }
      .layoutWeight(1)

      Column() {
        ErrorText({ message: this.errorMessage });
        Blank().height(8)
        CorosButton({ textValue: '完成', color: COROS_BUTTON_RED,
          enabledValue: this.profileActionEnabled, loading: this.isLoading,
          tapRequested: () => { this.submitProfile(); } });
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 14, bottom: 18 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COROS_BLACK)
  }

  @Builder
  private ProfileTextRow(label: string, required: boolean, value: string, placeholder: string, valueChanged: (v: string) => void) {
    Row() {
      this.RequiredLabel(label, required);
      TextInput({ text: value, placeholder: placeholder })
        .fontSize(18).fontColor(COROS_WHITE).placeholderColor(COROS_MUTED)
        .caretColor(COROS_RED).backgroundColor(COROS_BLACK).textAlign(TextAlign.End)
        .layoutWeight(1).padding(0).height(66)
        .onChange((v: string) => { valueChanged(v); this.refreshProfileActionState(); })
    }
    .width('100%').height(66).alignItems(VerticalAlign.Center)
    Divider().color(COROS_LINE)
  }

  @Builder
  private ProfilePickerRow(label: string, required: boolean, value: string, placeholder: string, onClick: () => void) {
    Row() {
      this.RequiredLabel(label, required);
      Blank().layoutWeight(1)
      Text(value.length > 0 ? value : placeholder)
        .fontSize(18).fontColor(value.length > 0 ? '#DADAE0' : COROS_MUTED).textAlign(TextAlign.End)
      Image($r('app.media.right_more'))
        .width(18)
        .height(18)
        .objectFit(ImageFit.Contain)
        .margin({ left: 12 })
    }
    .width('100%').height(66).alignItems(VerticalAlign.Center)
    .onClick(() => { onClick(); })
    Divider().color(COROS_LINE)
  }

  @Builder
  private GenderRow() {
    Row() {
      this.RequiredLabel('性别', true);
      Blank().layoutWeight(1)
      Row() {
        this.GenderButton('女', this.profileGender === 'Female', () => {
          this.profileGender = this.profileGender === 'Female' ? '' : 'Female';
          this.refreshProfileActionState();
        });
        Blank().width(10)
        this.GenderButton('男', this.profileGender === 'Male', () => {
          this.profileGender = this.profileGender === 'Male' ? '' : 'Male';
          this.refreshProfileActionState();
        });
      }
    }
    .width('100%').height(78).alignItems(VerticalAlign.Center)
  }

  @Builder
  private GenderButton(labelText: string, selected: boolean, onClick: () => void) {
    Row() {
      if (labelText === '女') {
        Image($r('app.media.icon_female'))
          .width(22)
          .height(22)
          .objectFit(ImageFit.Contain)
      } else {
        Image($r('app.media.icon_male'))
          .width(22)
          .height(22)
          .objectFit(ImageFit.Contain)
      }
      Blank().width(8)
      Text(labelText).fontSize(20).fontColor(selected ? COROS_RED : '#D8D8DD').fontWeight(FontWeight.Medium)
    }
    .width(82).height(48).justifyContent(FlexAlign.Center)
    .border({ width: selected ? 1 : 0, color: selected ? COROS_RED : '#00000000', radius: 9 })
    .backgroundColor('#19191B')
    .onClick(() => { onClick(); })
  }

  @Builder
  private RequiredLabel(textLabel: string, required: boolean) {
    Row() {
      Text(textLabel).fontSize(20).fontColor(COROS_WHITE)
      if (required) {
        Text('*').fontSize(16).fontColor(COROS_RED)
      }
    }
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  private SignedInPage() {
    Column() {
      AuthHeader({ showBack: false, showFeedback: false, backRequested: () => {} });

      Scroll() {
        Column() {
          Image($r('app.media.coros_logo'))
            .width(260).height(48).objectFit(ImageFit.Contain)
            .alignSelf(ItemAlign.Center).margin({ top: 60 })

          Blank().height(96)

          Text('欢迎使用 COROS\n' + this.sessionAccount)
            .fontSize(26).fontColor(COROS_WHITE).lineHeight(36)
            .textAlign(TextAlign.Center).width('100%')

          Blank().height(48)

          CorosButton({ textValue: '退出登录', color: COROS_BUTTON_RED, enabledValue: true, loading: false,
            tapRequested: () => { this.logout(); } });

          Blank().height(16)

          CorosButton({ textValue: '注销账户', color: '#2A2A2E', enabledValue: true, loading: false,
            tapRequested: () => { this.showDeleteDialog = true; } });

          ErrorText({ message: this.localError });
        }
        .width('100%')
        .padding({ left: 20, right: 20 })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COROS_BLACK)
  }

  // ========== 弹窗构建器（直接引用 this，响应式正常） ==========

  @Builder
  private TermsConsentSheet() {
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
          .onClick(() => { this.termsPromptAction = TermsPromptAction.None; })
        Text('阅读并同意以下条款，').fontSize(18).fontColor(COROS_WHITE).width('100%')
          .textAlign(TextAlign.Center).margin({ top: 12 })
        Row() {
          Text('《隐私政策》').fontSize(18).fontColor(COROS_RED).onClick(() => { this.openPrivacyPolicy(); })
          Text(' 和 ').fontSize(18).fontColor(COROS_WHITE)
          Text('《服务条款》').fontSize(18).fontColor(COROS_RED).onClick(() => { this.openServiceTerms(); })
        }
        .width('100%').justifyContent(FlexAlign.Center).margin({ top: 8 })
        Blank().height(42)
        CorosButton({ textValue: '同意并继续', color: COROS_RED, enabledValue: true, loading: false,
          tapRequested: () => { this.acceptTermsPromptAndContinue(); } });
      }
      .width('100%')
      .padding({ left: 22, right: 22, top: 18, bottom: 18 })
      .backgroundColor('#1A1A1B')
      .borderRadius({ topLeft: 12, topRight: 12 })
    }
    .width('100%').height('100%').backgroundColor('#000000C7')
  }

  @Builder
  private UnavailableFeatureDialog() {
    Column() {
      Blank().layoutWeight(1)
      Column({ space: 20 }) {
        Text('抱歉，该功能还在实现中').fontSize(16).fontColor(COROS_WHITE).textAlign(TextAlign.Center)
        Text('知道了').fontSize(16).fontColor(COROS_RED)
          .onClick(() => { this.unavailableDialogVisible = false; })
      }
      .padding({ left: 28, right: 28, top: 24, bottom: 24 })
      .backgroundColor('#222224').borderRadius(12).margin({ left: 42, right: 42 })
      Blank().layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor('#0000009E')
    .onClick(() => { this.unavailableDialogVisible = false; })
  }

  @Builder
  private DeleteAccountDialog() {
    Column() {
      Blank().layoutWeight(1)
      Column({ space: 24 }) {
        Text('是否确认注销账号').fontSize(18).fontColor(COROS_WHITE).textAlign(TextAlign.Center)
        Row({ space: 14 }) {
          Button('取消', { type: ButtonType.Normal }).fontSize(16).fontColor(COROS_WHITE)
            .layoutWeight(1).height(44).borderRadius(8).backgroundColor('#343438')
            .onClick(() => { this.showDeleteDialog = false; })
          Button('确认', { type: ButtonType.Normal }).fontSize(16).fontColor(COROS_WHITE)
            .layoutWeight(1).height(44).borderRadius(8).backgroundColor(COROS_BUTTON_RED)
            .onClick(() => { this.confirmDeleteAccount(); })
        }
        .width('100%')
      }
      .padding({ left: 24, right: 24, top: 22, bottom: 22 })
      .backgroundColor('#202023').borderRadius(12).margin({ left: 42, right: 42 })
      Blank().layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor('#0000009E')
    .onClick(() => { this.showDeleteDialog = false; })
  }

  // ========== 业务逻辑方法 ==========

  private showLogin(): void {
    this.setMode(AuthMode.Login);
    this.localError = '';
    this.page = AuthPage.Login;
  }

  private showPhoneRegister(): void {
    this.setMode(AuthMode.Register);
    this.localError = '';
    this.page = AuthPage.PhoneRegister;
  }

  private showEmailRegister(): void {
    this.setMode(AuthMode.Register);
    this.updateUsername('');
    this.emailInput = '';
    this.localError = '';
    this.page = AuthPage.EmailRegister;
  }

  private showPhoneRegisterFromEmail(): void {
    this.updateUsername('');
    this.localError = '';
    this.page = AuthPage.PhoneRegister;
  }

  private openPrivacyPolicy(): void {
    this.legalReturnPage = this.page;
    this.termsPromptAction = TermsPromptAction.None;
    this.localError = '';
    this.page = AuthPage.PrivacyPolicy;
  }

  private openServiceTerms(): void {
    this.legalReturnPage = this.page;
    this.termsPromptAction = TermsPromptAction.None;
    this.localError = '';
    this.page = AuthPage.ServiceTerms;
  }

  private openForgotPassword(): void {
    this.forgotAccount = '';
    this.localError = '';
    this.page = AuthPage.ForgotPassword;
  }

  private showUnavailableFeature(): void {
    this.unavailableDialogVisible = true;
  }

  private handleLegalBack(): void {
    this.localError = '';
    this.page = this.legalReturnPage;
  }

  private acceptTermsPromptAndContinue(): void {
    let action: TermsPromptAction = this.termsPromptAction;
    this.acceptedTerms = true;
    this.termsPromptAction = TermsPromptAction.None;
    if (action === TermsPromptAction.Login) {
      this.submitLogin(true);
    } else if (action === TermsPromptAction.PhoneCode) {
      this.requestPhoneVerifyCode(true);
    } else if (action === TermsPromptAction.EmailCode) {
      this.requestEmailVerifyCode(true);
    }
  }

  private verifyForgotAccount(): void {
    let account: string = this.forgotAccount.trim();
    let isEmail: boolean = account.indexOf('@') >= 0;
    let normalizedAccount: string = isEmail ? this.normalizeEmailInput(account) : account;
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
    this.forgotAccount = normalizedAccount;
    this.resetNewPassword = '';
    this.resetConfirmPassword = '';
    this.localError = '';
    this.page = AuthPage.ResetPassword;
  }

  private submitResetPassword(): void {
    let validationMessage: string = this.viewModel.validateRegisterPassword(this.resetNewPassword, this.resetConfirmPassword);
    if (validationMessage.length > 0) {
      this.localError = validationMessage;
      return;
    }
    let message: string = this.viewModel.resetPasswordMessage(this.forgotAccount, this.resetNewPassword);
    if (message.length > 0) {
      this.localError = message;
      return;
    }
    this.localError = '';
    this.page = AuthPage.Login;
    this.showMessage('密码已更新');
  }

  private confirmDeleteAccount(): void {
    let message: string = this.viewModel.deleteCurrentAccountMessage();
    if (message.length > 0) {
      this.localError = message;
      this.showDeleteDialog = false;
      return;
    }
    this.showDeleteDialog = false;
    this.syncState();
    this.page = AuthPage.Entrance;
    this.showMessage('账户已注销');
  }

  private handleProfileBack(): void {
    this.localError = '';
    this.viewModel.clearSessionSilently();
    this.syncState();
    this.page = AuthPage.Entrance;
  }

  private submitProfile(): void {
    let heightCm: number = this.profileHeightCm.length > 0 ? parseInt(this.profileHeightCm) : 0;
    let weightKg: number = this.profileWeightKg.length > 0 ? parseFloat(this.profileWeightKg) : 0;
    this.viewModel.submitProfile(
      '', this.profileUsername, this.profileBirthDate,
      heightCm, weightKg, this.profileMeasurementSystem,
      this.profilePhone, this.profileCountry, this.profileGender
    );
    this.syncState();
    this.handleProfileEffect();
  }

  private refreshProfileActionState(): void {
    let heightCm: number = this.profileHeightCm.length > 0 ? parseInt(this.profileHeightCm) : 0;
    let weightKg: number = this.profileWeightKg.length > 0 ? parseFloat(this.profileWeightKg) : 0;
    this.profileActionEnabled = this.viewModel.canSubmitProfile(
      this.profileUsername, this.profileBirthDate, heightCm, weightKg, this.profileGender
    );
  }

  private measurementLabel(): string {
    return this.profileMeasurementSystem === 'Imperial' ? '英制（mi/ft/inch/lb）' : '公制（km/m/cm/kg）';
  }

  private toggleMeasurementSystem(): void {
    this.profileMeasurementSystem = this.profileMeasurementSystem === 'Imperial' ? 'Metric' : 'Imperial';
  }

  private setMode(mode: AuthMode): void {
    let action: LoginAction = new LoginAction();
    action.type = LoginActionType.ModeChanged;
    action.mode = mode;
    this.viewModel.dispatch(action);
    this.syncState();
  }

  private updateUsername(value: string): void {
    this.username = value;
    this.localError = '';
    this.refreshActionStates();
    let action: LoginAction = new LoginAction();
    action.type = LoginActionType.UsernameChanged;
    action.username = value;
    this.viewModel.dispatch(action);
  }

  private updatePassword(value: string): void {
    this.password = value;
    this.localError = '';
    this.refreshActionStates();
    let action: LoginAction = new LoginAction();
    action.type = LoginActionType.PasswordChanged;
    action.password = value;
    this.viewModel.dispatch(action);
  }

  private async requestPhoneVerifyCode(skipTerms: boolean = false): Promise<void> {
    let validationMessage: string = this.viewModel.validatePhoneAccount(this.username);
    if (validationMessage.length > 0) {
      this.localError = validationMessage;
      return;
    }
    if (this.viewModel.hasAccount(this.username)) {
      this.localError = '账号已存在';
      return;
    }
    if (!skipTerms && !this.acceptedTerms) {
      this.termsPromptAction = TermsPromptAction.PhoneCode;
      return;
    }
    let message: string = this.viewModel.requestVerifyCode(this.username);
    if (message.length > 0) {
      this.localError = message;
      return;
    }
    await this.openVerifyPage(this.username, VerifyTargetKind.Phone);
  }

  private async requestEmailVerifyCode(skipTerms: boolean = false): Promise<void> {
    let email: string = this.normalizeEmailInput(this.emailInput);
    let validationMessage: string = this.viewModel.validateEmailAccount(email);
    if (validationMessage.length > 0) {
      this.localError = validationMessage;
      return;
    }
    if (this.viewModel.hasAccount(email)) {
      this.localError = '账号已存在';
      return;
    }
    if (!skipTerms && !this.acceptedTerms) {
      this.termsPromptAction = TermsPromptAction.EmailCode;
      return;
    }
    let message: string = this.viewModel.requestVerifyCode(email);
    if (message.length > 0) {
      this.localError = message;
      return;
    }
    await this.openVerifyPage(email, VerifyTargetKind.Email);
  }

  private async openVerifyPage(account: string, targetKind: VerifyTargetKind): Promise<void> {
    this.setMode(AuthMode.Register);
    this.updateUsername(account);
    let action: LoginAction = new LoginAction();
    action.type = LoginActionType.DisplayNameChanged;
    action.displayName = account;
    this.viewModel.dispatch(action);
    this.verifyTargetKind = targetKind;
    this.codeInput = '';
    this.localError = '';
    this.page = AuthPage.VerifyCode;
    this.startCountdown();
  }

  private async resendVerifyCode(): Promise<void> {
    this.resendLoading = true;
    let message: string = this.viewModel.requestResentVerifyCode(this.username);
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

  private async submitCode(): Promise<void> {
    let validationMessage: string = this.viewModel.validateVerifyCode(this.codeInput);
    if (validationMessage.length > 0) {
      this.localError = validationMessage;
      return;
    }
    let message: string = this.viewModel.verifyCode(this.username, this.codeInput);
    if (message.length > 0) {
      this.localError = message;
      return;
    }
    let action: LoginAction = new LoginAction();
    action.type = LoginActionType.VerifyCodeChanged;
    action.verifyCode = this.codeInput;
    this.viewModel.dispatch(action);
    this.setupPassword = '';
    this.confirmPassword = '';
    this.localError = '';
    this.page = AuthPage.PasswordSetup;
  }

  private async submitLogin(skipTerms: boolean = false): Promise<void> {
    hilog.info(0x0001, 'demo_persist', 'submitLogin called, skipTerms=' + JSON.stringify(skipTerms));
    if (!skipTerms && !this.acceptedTerms) {
      this.termsPromptAction = TermsPromptAction.Login;
      return;
    }
    this.updateUsername(this.username);
    this.updatePassword(this.password);
    this.setMode(AuthMode.Login);
    let action: LoginAction = new LoginAction();
    action.type = LoginActionType.SubmitClicked;
    this.viewModel.dispatch(action);
    this.syncState();
    this.handleEffect(AuthMode.Login);
  }

  private async submitRegister(): Promise<void> {
    hilog.info(0x0001, 'demo_persist', 'submitRegister called');
    let validationMessage: string = this.viewModel.validateRegisterPassword(this.setupPassword, this.confirmPassword);
    if (validationMessage.length > 0) {
      this.localError = validationMessage;
      return;
    }
    this.setMode(AuthMode.Register);
    this.updatePassword(this.setupPassword);
    this.syncState();
    let submitAction: LoginAction = new LoginAction();
    submitAction.type = LoginActionType.SubmitClicked;
    this.viewModel.dispatch(submitAction);
    this.syncState();
    this.handleEffect(AuthMode.Register);
  }

  private async logout(): Promise<void> {
    let action: LoginAction = new LoginAction();
    action.type = LoginActionType.LogoutClicked;
    this.viewModel.dispatch(action);
    this.syncState();
    this.handleEffect(AuthMode.Login);
  }

  private handleEffect(contextMode: AuthMode): void {
    let effect: LoginEffect | null = this.viewModel.consumeEffect();
    if (effect === null) {
      return;
    }
    if (effect.type === LoginEffectType.AuthSucceeded) {
      if (contextMode === AuthMode.Register) {
        this.viewModel.clearSessionSilently();
        this.acceptedTerms = false;
        this.setupPassword = '';
        this.confirmPassword = '';
        this.codeInput = '';
        this.syncState();
        this.page = AuthPage.Login;
        this.showMessage('注册成功');
      } else {
        this.page = AuthPage.SignedIn;
        this.showMessage('登录成功');
      }
      this.localError = '';
      return;
    }
    if (effect.type === LoginEffectType.LoggedOut) {
      this.acceptedTerms = false;
      this.page = AuthPage.Entrance;
      this.showMessage('已退出登录');
      return;
    }
    this.showMessage(effect.message);
  }

  private handleProfileEffect(): void {
    let effect: LoginEffect | null = this.viewModel.consumeEffect();
    if (effect === null) {
      return;
    }
    if (effect.type === LoginEffectType.AuthSucceeded) {
      this.page = AuthPage.SignedIn;
      this.showMessage('资料已保存');
      return;
    }
    this.showMessage(effect.message);
  }

  private handleBack(): void {
    this.navigateBack();
  }

  private navigateBack(): boolean {
    this.localError = '';
    if (this.page === AuthPage.Login || this.page === AuthPage.PhoneRegister || this.page === AuthPage.EmailRegister) {
      this.page = AuthPage.Entrance;
      return true;
    } else if (this.page === AuthPage.VerifyCode) {
      this.page = this.verifyTargetKind === VerifyTargetKind.Email ? AuthPage.EmailRegister : AuthPage.PhoneRegister;
      return true;
    } else if (this.page === AuthPage.PasswordSetup) {
      this.page = AuthPage.VerifyCode;
      return true;
    } else if (this.page === AuthPage.ForgotPassword) {
      this.page = AuthPage.Login;
      return true;
    } else if (this.page === AuthPage.ResetPassword) {
      this.page = AuthPage.ForgotPassword;
      return true;
    } else if (this.page === AuthPage.PrivacyPolicy || this.page === AuthPage.ServiceTerms) {
      this.page = this.legalReturnPage;
      return true;
    }
    return false;
  }

  private syncState(): void {
    let state: LoginState = this.viewModel.state;
    this.username = state.username;
    this.password = state.password;
    this.verifyCode = state.verifyCode;
    this.displayName = state.displayName;
    this.selectedRegion = state.selectedRegion;
    this.sessionAccount = state.currentSession === null ? '' : state.currentSession.account;
    this.isLoading = state.isLoading;
    this.isLoggedIn = state.isLoggedIn;
    this.errorMessage = state.errorMessage;
    this.refreshActionStates();
  }

  private refreshActionStates(): void {
    this.loginActionEnabled = !this.isLoading && this.localValidateLoginInput(this.username, this.password).length === 0;
    this.phoneCodeActionEnabled = !this.isLoading && this.localValidatePhoneAccount(this.username).length === 0;
    this.emailCodeActionEnabled = !this.isLoading && this.localValidateEmailAccount(this.emailInput).length === 0;
    this.registerActionEnabled = !this.isLoading && this.localValidateRegisterPassword(this.setupPassword, this.confirmPassword).length === 0;
  }

  private localValidateLoginInput(account: string, password: string): string {
    if (account.trim().length === 0) return '请输入账号';
    if (password.length === 0) return '请输入密码';
    if (password.length < 6) return '密码需要为6-20位';
    return '';
  }

  private localValidatePhoneAccount(account: string): string {
    let digits: string = '';
    for (let i = 0; i < account.length; i++) {
      let ch: string = account.charAt(i);
      if (ch >= '0' && ch <= '9') digits += ch;
    }
    if (digits.length !== 11) return '请输入11位手机号';
    return '';
  }

  private localValidateEmailAccount(email: string): string {
    let trimmed: string = email.trim();
    let atIndex: number = trimmed.indexOf('@');
    if (atIndex <= 0) return '请输入有效邮箱';
    let domain: string = trimmed.substring(atIndex + 1);
    if (domain.indexOf('.') <= 0) return '请输入有效邮箱';
    return '';
  }

  private localValidateRegisterPassword(password: string, confirmPassword: string): string {
    if (password.length < 6 || password.length > 20) return '密码需要为6-20位';
    let hasLetter: boolean = false;
    let hasDigit: boolean = false;
    for (let i = 0; i < password.length; i++) {
      let ch: string = password.charAt(i);
      if ((ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z')) hasLetter = true;
      else if (ch >= '0' && ch <= '9') hasDigit = true;
      else return '密码只能包含字母和数字';
    }
    if (!hasLetter || !hasDigit) return '密码需要包含字母和数字';
    if (password !== confirmPassword) return '两次输入的密码不一致';
    return '';
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

  private currentError(): string {
    return this.localError.length > 0 ? this.localError : this.errorMessage;
  }

  private normalizePhoneInput(value: string): string {
    return this.viewModel.normalizePhoneInput(value);
  }

  private normalizeEmailInput(value: string): string {
    return this.viewModel.normalizeEmailInput(value);
  }

  private normalizeVerifyCodeInput(value: string): string {
    return this.viewModel.normalizeVerifyCodeInput(value);
  }

  private normalizePasswordInput(value: string): string {
    return this.viewModel.normalizePasswordInput(value);
  }

  private showMessage(message: string): void {
    try {
      promptAction.showToast({ message: message });
    } catch (error) {
      console.error('showToast failed');
    }
  }
}
