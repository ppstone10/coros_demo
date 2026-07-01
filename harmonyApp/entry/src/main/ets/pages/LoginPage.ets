import promptAction from '@ohos.promptAction';
import {
  AuthMode,
  LoginAction,
  LoginActionType,
  LoginEffect,
  LoginEffectType,
  LoginState
} from '../login/LoginState';
import { LoginViewModel } from '../login/LoginViewModel';

enum AuthPage {
  Entrance,
  Login,
  PhoneRegister,
  VerifyCode,
  PasswordSetup,
  SignedIn
}

const COROS_RED: string = '#E9003D';
const COROS_BUTTON_RED: string = '#B80035';
const COROS_MUTED: string = '#8F8F96';
const COROS_LINE: string = '#1F1F22';
const COROS_FIELD: string = '#0E0E10';

@Entry
@Component
struct LoginPage {
  private viewModel: LoginViewModel = new LoginViewModel();

  @State page: AuthPage = AuthPage.Entrance;
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
  @State setupPassword: string = '';
  @State confirmPassword: string = '';

  aboutToAppear(): void {
    this.syncState();
    this.page = this.isLoggedIn ? AuthPage.SignedIn : AuthPage.Entrance;
  }

  build() {
    Stack() {
      if (this.page === AuthPage.Entrance) {
        this.EntrancePage();
      } else if (this.page === AuthPage.Login) {
        this.LoginFormPage();
      } else if (this.page === AuthPage.PhoneRegister) {
        this.PhoneRegisterPage();
      } else if (this.page === AuthPage.VerifyCode) {
        this.VerifyCodePage();
      } else if (this.page === AuthPage.PasswordSetup) {
        this.PasswordSetupPage();
      } else {
        this.SignedInPage();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
  }

  @Builder
  private EntrancePage() {
    Column() {
      Image($r('app.media.coros_logo'))
        .width(260)
        .height(64)
        .objectFit(ImageFit.Contain)
        .margin({ top: 84 })

      Blank()

      Column({ space: 28 }) {
        this.CorosButton('注册', COROS_RED, true, async () => {
          await this.setMode(AuthMode.Register);
          this.localError = '';
          this.page = AuthPage.PhoneRegister;
        });
        this.CorosButton('登录', '#2E2E2E', true, async () => {
          await this.setMode(AuthMode.Login);
          this.localError = '';
          this.page = AuthPage.Login;
        });
      }
      .width('100%')
      .padding({ left: 30, right: 30, bottom: 82 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#111111')
  }

  @Builder
  private LoginFormPage() {
    Scroll() {
      Column() {
      this.AuthHeader(true);

      Text('账号登录')
        .fontSize(38)
        .fontWeight(FontWeight.Regular)
        .fontColor('#FFFFFF')
        .margin({ top: 56 })

      Blank()
        .height(76)

      this.UnderlineInput('输入手机号或邮箱', this.username, InputType.Email, false, async (value: string) => {
        await this.updateUsername(value);
      });

      Blank()
        .height(28)

      this.UnderlineInput('密码', this.password, InputType.Password, true, async (value: string) => {
        await this.updatePassword(value);
      });

      Blank()
        .height(82)

      this.AgreementRow();

      Blank()
        .height(22)

      this.CorosButton('登录', COROS_BUTTON_RED, this.canLogin(), async () => {
        await this.submitLogin();
      });

      this.ErrorText();

      Text('忘记密码?')
        .fontSize(20)
        .fontColor(COROS_MUTED)
        .margin({ top: 24 })

      Blank()

      this.ThirdPartyArea();

      Text('V4.8.1.14')
        .fontSize(20)
        .fontColor(COROS_MUTED)
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ top: 22, bottom: 12 })
      }
      .width('100%')
      .height('100%')
      .padding({ left: 30, right: 30 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
  }

  @Builder
  private PhoneRegisterPage() {
    Scroll() {
      Column() {
      this.AuthHeader(true);

      Text('手机号注册')
        .fontSize(38)
        .fontWeight(FontWeight.Regular)
        .fontColor('#FFFFFF')
        .margin({ top: 56 })

      Blank()
        .height(78)

      this.PhoneInput();

      Blank()
        .height(66)

      this.AgreementRow();

      Blank()
        .height(42)

      this.CorosButton('发送验证码', COROS_BUTTON_RED, this.canSendCode(), async () => {
        await this.sendCode();
      });

      this.ErrorText();

      Text('邮箱注册')
        .fontSize(22)
        .fontColor(COROS_RED)
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ top: 26 })
        .onClick(() => {
          this.localError = '当前先实现手机号注册';
        })

      Blank()

      this.HomeIndicator();
      }
      .width('100%')
      .height('100%')
      .padding({ left: 30, right: 30 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
  }

  @Builder
  private VerifyCodePage() {
    Scroll() {
      Column() {
      this.AuthHeader(false);

      Text('输入验证码')
        .fontSize(38)
        .fontWeight(FontWeight.Regular)
        .fontColor('#FFFFFF')
        .margin({ top: 56 })

      Text(`验证码已发送至你的手机+86-${this.username}，有效期10分钟`)
        .fontSize(20)
        .fontColor('#D8D8DD')
        .lineHeight(28)
        .margin({ top: 20 })

      Blank()
        .height(56)

      this.CodeBoxes();

      Row() {
        Text('重新发送')
          .fontSize(20)
          .fontColor(COROS_MUTED)
        Text('（55s）')
          .fontSize(20)
          .fontColor(COROS_RED)
      }
      .margin({ top: 58 })

      this.ErrorText();

      Blank()
        .height(36)

      this.CorosButton(this.isLoading ? '处理中' : '完成', COROS_BUTTON_RED, !this.isLoading, async () => {
        await this.submitCode();
      });

      Blank()

      this.HomeIndicator();
      }
      .width('100%')
      .height('100%')
      .padding({ left: 30, right: 30 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
  }

  @Builder
  private PasswordSetupPage() {
    Scroll() {
      Column() {
      this.AuthHeader(false);

      Text('设置登录密码')
        .fontSize(38)
        .fontWeight(FontWeight.Regular)
        .fontColor('#FFFFFF')
        .margin({ top: 56 })

      Blank()
        .height(82)

      this.UnderlineInput('输入新的密码', this.setupPassword, InputType.Password, true, async (value: string) => {
        this.setupPassword = value.substring(0, 20);
        this.localError = '';
      });

      Blank()
        .height(52)

      this.UnderlineInput('再次输入密码', this.confirmPassword, InputType.Password, true, async (value: string) => {
        this.confirmPassword = value.substring(0, 20);
        this.localError = '';
      });

      Text('6-20位必须包含字母和数字')
        .fontSize(16)
        .fontColor('#D8D8DD')
        .margin({ top: 8 })

      Blank()
        .height(80)

      this.CorosButton(this.isLoading ? '注册中' : '注册', COROS_BUTTON_RED, this.canRegister(), async () => {
        await this.submitRegister();
      });

      this.ErrorText();

      Blank()

      this.HomeIndicator();
      }
      .width('100%')
      .height('100%')
      .padding({ left: 30, right: 30 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
  }

  @Builder
  private SignedInPage() {
    Scroll() {
      Column() {
      this.AuthHeader(false);

      Image($r('app.media.coros_logo'))
        .width(260)
        .height(64)
        .objectFit(ImageFit.Contain)
        .alignSelf(ItemAlign.Center)
        .margin({ top: 80 })

      Blank()
        .height(96)

      Text(`欢迎使用 COROS\n${this.sessionAccount}`)
        .fontSize(26)
        .fontColor('#FFFFFF')
        .lineHeight(36)
        .textAlign(TextAlign.Center)
        .width('100%')

      Blank()
        .height(48)

      this.CorosButton('退出登录', COROS_BUTTON_RED, true, async () => {
        await this.logout();
      });
      }
      .width('100%')
      .height('100%')
      .padding({ left: 30, right: 30 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
  }

  @Builder
  private AuthHeader(showFeedback: boolean) {
    Row() {
      Text('‹')
        .fontSize(44)
        .fontColor('#FFFFFF')
        .onClick(() => {
          this.handleBack();
        })
      Blank()
      if (showFeedback) {
        Text('◔ 建议&反馈')
          .fontSize(18)
          .fontColor(COROS_MUTED)
      }
    }
    .width('100%')
    .height(52)
  }

  @Builder
  private UnderlineInput(
    placeholder: string,
    textValue: string,
    inputType: InputType,
    isPassword: boolean,
    onChange: (value: string) => Promise<void>
  ) {
    TextInput({ placeholder: placeholder, text: textValue })
      .type(inputType)
      .fontSize(21)
      .fontColor('#FFFFFF')
      .placeholderColor(COROS_MUTED)
      .caretColor(COROS_RED)
      .backgroundColor('#000000')
      .height(53)
      .padding(0)
      .border({ width: { bottom: 1 }, color: COROS_LINE })
      .onChange(async (value: string) => {
        await onChange(value);
      })
  }

  @Builder
  private PhoneInput() {
    Column() {
      Row({ space: 24 }) {
        Text('+86')
          .fontSize(22)
          .fontColor('#FFFFFF')
        TextInput({ placeholder: '输入手机号', text: this.username })
          .type(InputType.PhoneNumber)
          .fontSize(22)
          .fontColor('#FFFFFF')
          .placeholderColor(COROS_MUTED)
          .caretColor(COROS_RED)
          .backgroundColor('#000000')
          .padding(0)
          .layoutWeight(1)
          .onChange(async (value: string) => {
            let nextValue: string = value.replace(/[^0-9]/g, '').substring(0, 11);
            await this.updateUsername(nextValue);
          })
      }
      .height(53)
      .width('100%')

      Divider()
        .color(COROS_LINE)
    }
    .width('100%')
  }

  @Builder
  private AgreementRow() {
    Row({ space: 6 }) {
      Text(this.acceptedTerms ? '✓' : '')
        .fontSize(12)
        .fontColor('#FFFFFF')
        .textAlign(TextAlign.Center)
        .width(18)
        .height(18)
        .border({ width: 1, color: '#FFFFFF', radius: 9 })
        .backgroundColor(this.acceptedTerms ? COROS_RED : '#000000')
        .margin({ top: 6 })

      Text('我已阅读并同意COROS的 《隐私政策》 和 《服务条款》')
        .fontSize(20)
        .fontColor('#FFFFFF')
        .lineHeight(30)
        .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .onClick(() => {
      this.acceptedTerms = !this.acceptedTerms;
      this.localError = '';
    })
  }

  @Builder
  private CorosButton(textValue: string, color: string, enabledValue: boolean, onTap: () => Promise<void>) {
    Button(textValue)
      .fontSize(24)
      .fontColor('#FFFFFF')
      .width('100%')
      .height(66)
      .borderRadius(9)
      .backgroundColor(enabledValue ? color : this.disabledColor(color))
      .enabled(enabledValue)
      .onClick(async () => {
        await onTap();
      })
  }

  @Builder
  private CodeBoxes() {
    Stack() {
      Row({ space: 28 }) {
        ForEach([0, 1, 2, 3], (index: number) => {
          Text(this.codeInput.length > index ? this.codeInput.charAt(index) : (index === this.codeInput.length ? '|' : ''))
            .fontSize(30)
            .fontColor(index === this.codeInput.length && this.codeInput.length < 4 ? COROS_RED : '#FFFFFF')
            .textAlign(TextAlign.Center)
            .width('20%')
            .aspectRatio(1)
            .backgroundColor(COROS_FIELD)
            .border({ width: 2, color: '#3A3A3D', radius: 12 })
        }, (index: number) => index.toString())
      }
      .width('100%')

      TextInput({ text: this.codeInput })
        .type(InputType.Number)
        .fontColor('#00000000')
        .caretColor('#00000000')
        .backgroundColor('#00000000')
        .width('100%')
        .height(80)
        .opacity(0.02)
        .onChange((value: string) => {
          this.codeInput = value.replace(/[^0-9]/g, '').substring(0, 4);
          this.localError = '';
        })
    }
    .width('100%')
  }

  @Builder
  private ThirdPartyArea() {
    Column({ space: 28 }) {
      Row({ space: 12 }) {
        Divider()
          .width(140)
          .color(COROS_LINE)
        Text('第三方账号')
          .fontSize(20)
          .fontColor(COROS_MUTED)
        Divider()
          .width(140)
          .color(COROS_LINE)
      }
      .justifyContent(FlexAlign.Center)
      .width('100%')

      Row({ space: 54 }) {
        this.ThirdPartyCircle('☘');
        this.ThirdPartyCircle('···');
      }
      .justifyContent(FlexAlign.Center)
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  private ThirdPartyCircle(textValue: string) {
    Text(textValue)
      .fontSize(24)
      .fontColor('#FFFFFF')
      .textAlign(TextAlign.Center)
      .width(48)
      .height(48)
      .border({ width: 1, color: '#303036', radius: 24 })
  }

  @Builder
  private HomeIndicator() {
    Row() {
      Blank()
      Divider()
        .width(150)
        .height(5)
        .color('#FFFFFF')
      Blank()
    }
    .width('100%')
    .margin({ bottom: 14 })
  }

  @Builder
  private ErrorText() {
    if (this.currentError().length > 0) {
      Text(this.currentError())
        .fontSize(15)
        .fontColor(COROS_RED)
        .margin({ top: 10 })
    }
  }

  private async setMode(mode: AuthMode): Promise<void> {
    let action: LoginAction = new LoginAction();
    action.type = LoginActionType.ModeChanged;
    action.mode = mode;
    await this.viewModel.dispatch(action);
    this.syncState();
  }

  private async updateUsername(value: string): Promise<void> {
    let action: LoginAction = new LoginAction();
    action.type = LoginActionType.UsernameChanged;
    action.username = value;
    await this.viewModel.dispatch(action);
    this.localError = '';
    this.syncState();
  }

  private async updatePassword(value: string): Promise<void> {
    let action: LoginAction = new LoginAction();
    action.type = LoginActionType.PasswordChanged;
    action.password = value;
    await this.viewModel.dispatch(action);
    this.localError = '';
    this.syncState();
  }

  private async sendCode(): Promise<void> {
    if (this.username.length !== 11) {
      this.localError = '请输入11位手机号';
      return;
    }
    if (!this.acceptedTerms) {
      this.localError = '请先阅读并同意隐私政策和服务条款';
      return;
    }

    let message: string = this.viewModel.requestVerifyCode(this.username);
    if (message.length > 0) {
      this.localError = message;
      return;
    }

    await this.setMode(AuthMode.Register);
    let displayAction: LoginAction = new LoginAction();
    displayAction.type = LoginActionType.DisplayNameChanged;
    displayAction.displayName = this.username;
    await this.viewModel.dispatch(displayAction);
    this.codeInput = '';
    this.localError = '';
    this.syncState();
    this.page = AuthPage.VerifyCode;
  }

  private async submitCode(): Promise<void> {
    if (this.codeInput.length < 4) {
      this.localError = '请输入验证码';
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
    await this.viewModel.dispatch(action);
    this.setupPassword = '';
    this.confirmPassword = '';
    this.localError = '';
    this.syncState();
    this.page = AuthPage.PasswordSetup;
  }

  private async submitLogin(): Promise<void> {
    if (!this.acceptedTerms) {
      this.localError = '请先阅读并同意隐私政策和服务条款';
      return;
    }

    await this.setMode(AuthMode.Login);
    let action: LoginAction = new LoginAction();
    action.type = LoginActionType.SubmitClicked;
    await this.viewModel.dispatch(action);
    this.syncState();
    this.handleEffect(AuthMode.Login);
  }

  private async submitRegister(): Promise<void> {
    if (this.setupPassword.length < 6 || this.setupPassword.length > 20) {
      this.localError = '密码需要为6-20位';
      return;
    }
    if (!/[A-Za-z]/.test(this.setupPassword) || !/[0-9]/.test(this.setupPassword)) {
      this.localError = '密码需要包含字母和数字';
      return;
    }
    if (this.setupPassword !== this.confirmPassword) {
      this.localError = '两次输入的密码不一致';
      return;
    }

    await this.setMode(AuthMode.Register);
    await this.updatePassword(this.setupPassword);
    let action: LoginAction = new LoginAction();
    action.type = LoginActionType.VerifyCodeChanged;
    action.verifyCode = this.codeInput;
    await this.viewModel.dispatch(action);

    let submitAction: LoginAction = new LoginAction();
    submitAction.type = LoginActionType.SubmitClicked;
    await this.viewModel.dispatch(submitAction);
    this.syncState();
    this.handleEffect(AuthMode.Register);
  }

  private async logout(): Promise<void> {
    let action: LoginAction = new LoginAction();
    action.type = LoginActionType.LogoutClicked;
    await this.viewModel.dispatch(action);
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
        this.syncState();
        this.page = AuthPage.Login;
        this.showMessage('注册成功');
      } else {
        this.page = AuthPage.SignedIn;
        this.showMessage('登录成功');
      }
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

  private handleBack(): void {
    this.localError = '';
    if (this.page === AuthPage.Login || this.page === AuthPage.PhoneRegister) {
      this.page = AuthPage.Entrance;
    } else if (this.page === AuthPage.VerifyCode) {
      this.page = AuthPage.PhoneRegister;
    } else if (this.page === AuthPage.PasswordSetup) {
      this.page = AuthPage.VerifyCode;
    }
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
  }

  private currentError(): string {
    return this.localError.length > 0 ? this.localError : this.errorMessage;
  }

  private canLogin(): boolean {
    return this.username.length > 0 && this.password.length >= 6 && this.acceptedTerms && !this.isLoading;
  }

  private canSendCode(): boolean {
    return this.username.length === 11 && this.acceptedTerms && !this.isLoading;
  }

  private canRegister(): boolean {
    return this.setupPassword.length >= 6
      && this.setupPassword.length <= 20
      && /[A-Za-z]/.test(this.setupPassword)
      && /[0-9]/.test(this.setupPassword)
      && this.setupPassword === this.confirmPassword
      && !this.isLoading;
  }

  private disabledColor(color: string): string {
    if (color === COROS_BUTTON_RED) {
      return '#5C001B';
    }
    if (color === COROS_RED) {
      return '#74001E';
    }
    return '#1D1D1D';
  }

  private showMessage(message: string): void {
    try {
      promptAction.showToast({ message: message });
    } catch (error) {
      console.error('showToast failed');
    }
  }
}
