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
  EmailRegister,
  VerifyCode,
  PasswordSetup,
  PrivacyPolicy,
  ServiceTerms,
  SignedIn
}

enum VerifyTargetKind {
  Phone,
  Email
}

enum TermsPromptAction {
  None,
  Login,
  PhoneCode,
  EmailCode
}

class LegalParagraph {
  text: string;
  isHeading: boolean;

  constructor(text: string, isHeading: boolean = false) {
    this.text = text;
    this.isHeading = isHeading;
  }
}

const COROS_RED: string = '#E9003D';
const COROS_BUTTON_RED: string = '#B80035';
const COROS_MUTED: string = '#8F8F96';
const COROS_LINE: string = '#1F1F22';
const COROS_FIELD: string = '#0E0E10';
const COROS_CODE_ACTIVE_FIELD: string = '#151517';
const COROS_LEGAL_TEXT: string = '#C9C9CC';
const AUTH_TITLE_TOP_PADDING: number = 18;
const AUTH_TITLE_SIZE: number = 32;
const REGISTER_AGREEMENT_TOP_SPACING: number = 44;
const REGISTER_ACTION_TOP_SPACING: number = 28;
const VERSION_TEXT: string = 'V4.8.1.14';

const PRIVACY_POLICY_PARAGRAPHS: LegalParagraph[] = [
  new LegalParagraph('最后更新时间：2025年12月24日'),
  new LegalParagraph('导言'),
  new LegalParagraph('广东高驰运动科技有限公司（以下简称"COROS"或"我们"）非常重视用户（或"您"）的隐私和个人信息保护，我们将按照法律法规的要求，尽力保护您的个人信息安全。'),
  new LegalParagraph('本个人信息保护政策（以下简称"本政策"）适用于您通过 COROS 网站、COROS 移动应用程序（"COROS App"）及其他 COROS 产品和服务使用我们的产品与服务。'),
  new LegalParagraph('本政策解释了我们如何收集、存储、使用、提供、删除您的信息，以及您享有的权利。请您认真阅读并充分理解本政策，特别是涉及个人敏感信息、系统权限、第三方共享和账号注销的条款。'),
  new LegalParagraph('一、我们如何收集和使用您的个人信息', true),
  new LegalParagraph('1. 我们将逐一说明所收集的个人信息类型及其对应用途，以便您了解每一项功能所处理的具体个人信息类别、处理目的及处理方式。'),
  new LegalParagraph('2. 为了向您提供运动记录、设备连接、账号登录、安全保障和客户支持等服务，我们可能会在获得授权后处理账号信息、设备信息、运动数据、网络状态以及必要的日志信息。'),
  new LegalParagraph('二、我们如何提供和共享您的个人信息', true),
  new LegalParagraph('除非经过您的同意，我们不会主动将您的个人信息提供至 COROS 以外的第三方。如确需对外提供，或您需要我们向任何第三方提供信息时，我们会直接征得您的同意，但法律法规另有规定的除外。'),
  new LegalParagraph('三、您如何管理自己的个人信息', true),
  new LegalParagraph('您可以通过本政策所列途径查询、更新、复制、删除您的个人信息，也可以撤回同意、注销账号、投诉举报。我们会在符合法律法规要求的期限内处理您的请求。'),
  new LegalParagraph('四、系统权限和敏感信息', true),
  new LegalParagraph('为了依据本政策收集您的信息、向您提供服务、优化我们的服务并保障您的账号安全，我们可能需要向您索取相关系统权限；其中位置等敏感权限不会默认开启，只有在您明确同意后，我们才会在您同意的范围内调用或使用。'),
  new LegalParagraph('五、本政策如何更新', true),
  new LegalParagraph('我们会持续保护您的个人信息，并根据产品功能、法律法规或监管要求更新本政策。若本政策发生重大变化，我们会以合理方式向您提示。')
];

const SERVICE_TERMS_PARAGRAPHS: LegalParagraph[] = [
  new LegalParagraph('最后更新日期：2023年9月4日'),
  new LegalParagraph('特别提示：'),
  new LegalParagraph('本《COROS 用户协议》（以下简称"本协议"）是您（或"用户"）与广东高驰运动科技股份有限公司（以下简称"COROS"或"我们"）签订的，就使用 COROS 网站、COROS 移动应用程序（"COROS App"）及其他 COROS 产品和服务（统称为"COROS产品和服务"）等事宜订立的协议。'),
  new LegalParagraph('请您认真阅读并充分理解本协议，特别是以加粗形式提示您注意的免除或减轻 COROS 责任的条款。您有权选择同意或不同意本协议，除非您接受本协议的全部条款，否则您无权注册、登录或使用 COROS 产品和服务。'),
  new LegalParagraph('一旦您点击"本人已阅读并同意接受本协议的全部内容"并完成注册流程，即视为您已充分阅读、理解并在您点击接受当时接受本协议的所有内容，本协议即在您与 COROS 之间成立并发生法律效力，您同意接受本协议各项条款的约束。'),
  new LegalParagraph('请注意，本协议内容包括所有我们已经发布或未来可能变更或发布的各类协议、规则、公告或通知。除非法律规定或本协议有相反规定，前述内容一经公布即自动生效并成为本协议不可分割的组成部分，无需另行通知。'),
  new LegalParagraph('如您不同意本协议的内容或在您同意本协议之后我们发布生效的任何协议、规则、公告或通知，您应立即取消登录、注销账号、停止使用 COROS 产品和服务；如您继续使用，则视为您始终同意本协议的所有内容并同意遵守。'),
  new LegalParagraph('一、服务范围', true),
  new LegalParagraph('1. 我们就使用 COROS 产品和服务给予您一项个人的、不可转让的、不可转授权的、非独占性的、可撤销的许可。'),
  new LegalParagraph('2. 您应按照法律法规、本协议以及 COROS 发布的规则使用产品和服务，不得利用服务从事违法违规或侵犯他人合法权益的行为。'),
  new LegalParagraph('3. 我们可能根据产品运营情况对服务内容进行调整、更新或优化，并会在合理范围内向您提供必要提示。'),
  new LegalParagraph('二、账号与安全', true),
  new LegalParagraph('1. 您应对您账号下的所有行为负责，并妥善保管账号、密码和验证码等信息。'),
  new LegalParagraph('2. 如发现账号存在异常使用、被盗用或其他安全风险，请及时联系我们处理。'),
  new LegalParagraph('三、协议变更', true),
  new LegalParagraph('我们可能根据法律法规变化、业务调整或服务优化需要修改本协议。更新后的协议公布后即生效；如您继续使用 COROS 产品和服务，视为您同意接受更新后的协议。')
];

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

  aboutToAppear(): void {
    this.syncState();
    this.page = this.isLoggedIn && this.sessionAccount.length > 0 ? AuthPage.SignedIn : AuthPage.Entrance;
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
      } else if (this.page === AuthPage.PrivacyPolicy) {
        this.LegalDocumentPage('隐私政策', PRIVACY_POLICY_PARAGRAPHS);
      } else if (this.page === AuthPage.ServiceTerms) {
        this.LegalDocumentPage('服务条款', SERVICE_TERMS_PARAGRAPHS);
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
        this.BlockingLoadingOverlay();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
  }

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
        Image($r('app.media.coros_logo'))
          .width(260)
          .height(48)
          .objectFit(ImageFit.Contain)
          .margin({ top: 62 })

        Blank()
          .layoutWeight(1)

        Column({ space: 20 }) {
          this.CorosButton('注册', COROS_RED, true, false, async () => {
            await this.showPhoneRegister();
          });
          this.CorosButton('登录', '#424242', true, false, async () => {
            await this.showLogin();
          });
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
        this.AuthHeader(true);
        this.AuthTitle('账号登录');

        Blank()
          .height(45)

        this.UnderlineInput('输入手机号或邮箱', this.username, InputType.Email, false, false, async (value: string) => {
          await this.updateUsername(value);
        });

        Blank()
          .height(16)

        this.UnderlineInput('密码', this.password, this.loginPasswordVisible ? InputType.Normal : InputType.Password, true, this.loginPasswordVisible, async (value: string) => {
          await this.updatePassword(value);
        }, () => {
          this.loginPasswordVisible = !this.loginPasswordVisible;
        });

        Blank()
          .height(59)

        this.AgreementRow();

        Blank()
          .height(12)

        this.CorosButton('登录', COROS_BUTTON_RED, this.canLogin(), this.isLoading, async () => {
          await this.submitLogin();
        });

        this.ErrorText();

        Text('忘记密码?')
          .fontSize(14)
          .fontColor(COROS_MUTED)
          .margin({ top: 16 })
          .onClick(() => {
            this.showUnavailableFeature();
          })

        Blank()
          .layoutWeight(1)

        this.ThirdPartyArea();

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
    .backgroundColor('#000000')
  }

  @Builder
  private PhoneRegisterPage() {
    Scroll() {
      Column() {
        this.AuthHeader(true);
        this.AuthTitle('手机号注册');

        Blank()
          .height(60)

        this.PhoneInput();

        Blank()
          .height(REGISTER_AGREEMENT_TOP_SPACING)

        this.AgreementRow();

        Blank()
          .height(REGISTER_ACTION_TOP_SPACING)

        this.CorosButton('发送验证码', COROS_BUTTON_RED, this.canSendPhoneCode(), this.isLoading, async () => {
          await this.requestPhoneVerifyCode();
        });

        this.ErrorText();

        Text('邮箱注册')
          .fontSize(18)
          .fontColor(COROS_RED)
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ top: 26 })
          .onClick(async () => {
            await this.showEmailRegister();
          })

        Blank()
          .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .padding({ left: 20, right: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
  }

  @Builder
  private EmailRegisterPage() {
    Scroll() {
      Column() {
        this.AuthHeader(true);
        this.AuthTitle('邮箱注册');

        Blank()
          .height(60)

        this.UnderlineInput('请输入邮箱', this.emailInput, InputType.Email, false, false, async (value: string) => {
          this.emailInput = this.normalizeEmailInput(value);
          this.localError = '';
        });

        Blank()
          .height(REGISTER_AGREEMENT_TOP_SPACING)

        this.AgreementRow();

        Blank()
          .height(REGISTER_ACTION_TOP_SPACING)

        this.CorosButton('发送验证码', COROS_BUTTON_RED, this.canSendEmailCode(), this.isLoading, async () => {
          await this.requestEmailVerifyCode();
        });

        this.ErrorText();

        Text('手机号注册')
          .fontSize(18)
          .fontColor(COROS_RED)
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ top: 26 })
          .onClick(async () => {
            await this.showPhoneRegisterFromEmail();
          })

        Blank()
          .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .padding({ left: 20, right: 20 })
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
        this.AuthTitle('输入验证码');

        Text(this.verifyCodeMessage())
          .fontSize(16)
          .fontColor('#D8D8DD')
          .lineHeight(24)
          .margin({ top: 14 })

        Blank()
          .height(56)

        this.CodeBoxes();

        this.ErrorText();

        Blank()
          .height(58)

        Row() {
          if (this.countdown > 0) {
            Text('重新发送')
              .fontSize(16)
              .fontColor(COROS_MUTED)
            Text(`（${this.countdown}s）`)
              .fontSize(16)
              .fontColor(COROS_RED)
          } else {
            Text('获取验证码')
              .fontSize(16)
              .fontColor(COROS_RED)
              .onClick(async () => {
                await this.resendVerifyCode();
              })
          }

          Blank()

          Text('收不到验证码?')
            .fontSize(16)
            .fontColor(COROS_MUTED)
            .onClick(() => {
              this.showUnavailableFeature();
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Blank()
          .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .padding({ left: 20, right: 20 })
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
        this.AuthTitle('设置登录密码');

        Blank()
          .height(60)

        this.UnderlineInput('输入新的密码', this.setupPassword, this.setupPasswordVisible ? InputType.Normal : InputType.Password, true, this.setupPasswordVisible, async (value: string) => {
          this.setupPassword = this.normalizePasswordInput(value);
          this.localError = '';
        }, () => {
          this.setupPasswordVisible = !this.setupPasswordVisible;
        });

        Blank()
          .height(48)

        this.UnderlineInput('再次输入密码', this.confirmPassword, this.confirmPasswordVisible ? InputType.Normal : InputType.Password, true, this.confirmPasswordVisible, async (value: string) => {
          this.confirmPassword = this.normalizePasswordInput(value);
          this.localError = '';
        }, () => {
          this.confirmPasswordVisible = !this.confirmPasswordVisible;
        });

        Text('6-20位必须包含字母和数字')
          .fontSize(14)
          .fontColor('#D8D8DD')
          .margin({ top: 8 })

        Blank()
          .height(80)

        this.CorosButton('注册', COROS_BUTTON_RED, this.canRegister(), this.isLoading, async () => {
          await this.submitRegister();
        });

        this.ErrorText();

        Blank()
          .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .padding({ left: 20, right: 20 })
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
          .height(48)
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

        this.CorosButton('退出登录', COROS_BUTTON_RED, true, false, async () => {
          await this.logout();
        });
      }
      .width('100%')
      .height('100%')
      .padding({ left: 20, right: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
  }

  @Builder
  private LegalDocumentPage(title: string, paragraphs: LegalParagraph[]) {
    Column() {
      Stack() {
        Row() {
          this.BackButton(() => {
            this.localError = '';
            this.page = this.legalReturnPage;
          });
          Blank()
        }
        .width('100%')
        .height(52)

        Text(title)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
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
              .fontColor(paragraph.isHeading ? '#FFFFFF' : COROS_LEGAL_TEXT)
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
    .backgroundColor('#000000')
  }

  @Builder
  private AuthHeader(showFeedback: boolean) {
    Row() {
      this.BackButton(() => {
        this.handleBack();
      });
      Blank()
      if (showFeedback) {
        Text('◔ 建议&反馈')
          .fontSize(14)
          .fontColor(COROS_MUTED)
          .onClick(() => {
            this.showUnavailableFeature();
          })
      }
    }
    .width('100%')
    .height(52)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  private BackButton(onTap: () => void) {
    Text('‹')
      .fontSize(44)
      .fontColor('#FFFFFF')
      .textAlign(TextAlign.Center)
      .width(48)
      .height(52)
      .onClick(() => {
        onTap();
      })
  }

  @Builder
  private AuthTitle(title: string) {
    Text(title)
      .fontSize(AUTH_TITLE_SIZE)
      .fontWeight(FontWeight.Lighter)
      .fontColor('#FFFFFF')
      .margin({ top: AUTH_TITLE_TOP_PADDING })
  }

  @Builder
  private UnderlineInput(
    placeholder: string,
    textValue: string,
    inputType: InputType,
    isPassword: boolean,
    passwordVisible: boolean,
    onChange: (value: string) => Promise<void>,
    onPasswordToggle?: () => void
  ) {
    Column() {
      Row({ space: 6 }) {
        TextInput({ placeholder: placeholder, text: textValue })
          .type(inputType)
          .fontSize(17)
          .fontColor('#FFFFFF')
          .placeholderColor(COROS_MUTED)
          .caretColor(COROS_RED)
          .backgroundColor('#000000')
          .height(48)
          .padding(0)
          .layoutWeight(1)
          .onChange(async (value: string) => {
            await onChange(value);
          })

        if (textValue.length > 0) {
          Image($r('app.media.icon_delete'))
            .width(34)
            .height(34)
            .objectFit(ImageFit.Contain)
            .onClick(async () => {
              await onChange('');
            })
        }

        if (isPassword && textValue.length > 0) {
          Image($r('app.media.icon_uneye'))
            .width(34)
            .height(34)
            .objectFit(ImageFit.Contain)
            .opacity(passwordVisible ? 0.45 : 1)
            .onClick(() => {
              if (onPasswordToggle !== undefined) {
                onPasswordToggle();
              }
            })
        }
      }
      .width('100%')
      .height(48)
      .alignItems(VerticalAlign.Center)

      Divider()
        .color(COROS_LINE)
    }
    .width('100%')
  }

  @Builder
  private PhoneInput() {
    Column() {
      Row({ space: 24 }) {
        Text('+86')
          .fontSize(17)
          .fontColor('#FFFFFF')
        TextInput({ placeholder: '输入手机号', text: this.username })
          .type(InputType.PhoneNumber)
          .maxLength(11)
          .fontSize(17)
          .fontColor('#FFFFFF')
          .placeholderColor(COROS_MUTED)
          .caretColor(COROS_RED)
          .backgroundColor('#000000')
          .padding(0)
          .layoutWeight(1)
          .onChange(async (value: string) => {
            await this.updateUsername(this.normalizePhoneInput(value));
          })
        if (this.username.length > 0) {
          Image($r('app.media.icon_delete'))
            .width(34)
            .height(34)
            .objectFit(ImageFit.Contain)
            .onClick(async () => {
              await this.updateUsername('');
            })
        }
      }
      .height(48)
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Divider()
        .color(COROS_LINE)
    }
    .width('100%')
  }

  @Builder
  private AgreementRow() {
    Row({ space: 8 }) {
      Text(this.acceptedTerms ? '✓' : '')
        .fontSize(9)
        .fontColor('#FFFFFF')
        .textAlign(TextAlign.Center)
        .width(18)
        .height(18)
        .border({ width: 1, color: this.acceptedTerms ? COROS_RED : '#D0D0D0', radius: 9 })
        .backgroundColor(this.acceptedTerms ? COROS_RED : '#000000')
        .margin({ top: 2 })
        .onClick(() => {
          this.acceptedTerms = !this.acceptedTerms;
          this.localError = '';
        })

      Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap }) {
        Text('我已阅读并同意COROS的 ')
          .fontSize(14)
          .fontColor('#FFFFFF')
          .lineHeight(24)
        Text('《隐私政策》')
          .fontSize(14)
          .fontColor(COROS_RED)
          .lineHeight(24)
          .onClick(() => {
            this.openPrivacyPolicy();
          })
        Text(' 和 ')
          .fontSize(14)
          .fontColor('#FFFFFF')
          .lineHeight(24)
        Text('《服务条款》')
          .fontSize(14)
          .fontColor(COROS_RED)
          .lineHeight(24)
          .onClick(() => {
            this.openServiceTerms();
          })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  private CorosButton(textValue: string, color: string, enabledValue: boolean, loading: boolean, onTap: () => Promise<void>) {
    Button(loading ? '处理中' : textValue, { type: ButtonType.Normal })
      .fontSize(18)
      .fontColor(enabledValue ? '#FFFFFF' : '#FFFFFF66')
      .width('100%')
      .height(48)
      .borderRadius(9)
      .backgroundColor(enabledValue ? color : this.disabledColor(color))
      .enabled(enabledValue && !loading)
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
            .backgroundColor(index === this.codeInput.length ? COROS_CODE_ACTIVE_FIELD : COROS_FIELD)
            .border({ width: 2, color: this.currentError().length > 0 ? COROS_RED : '#3A3A3D', radius: 12 })
        }, (index: number) => index.toString())
      }
      .width('100%')

      TextInput({ text: this.codeInput })
        .type(InputType.Number)
        .maxLength(4)
        .fontColor('#00000000')
        .caretColor('#00000000')
        .backgroundColor('#00000000')
        .width('100%')
        .height(80)
        .opacity(0.02)
        .onChange(async (value: string) => {
          this.codeInput = this.normalizeVerifyCodeInput(value);
          this.localError = '';
          if (this.codeInput.length === 4) {
            await this.submitCode();
          }
        })
    }
    .width('100%')
  }

  @Builder
  private ThirdPartyArea() {
    Column({ space: 24 }) {
      Row({ space: 12 }) {
        Divider()
          .layoutWeight(1)
          .color(COROS_LINE)
        Text('第三方账号')
          .fontSize(14)
          .fontColor(COROS_MUTED)
        Divider()
          .layoutWeight(1)
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
      .fontSize(20)
      .fontColor('#FFFFFF')
      .textAlign(TextAlign.Center)
      .width(34)
      .height(34)
      .border({ width: 1, color: '#303036', radius: 17 })
      .onClick(() => {
        this.showUnavailableFeature();
      })
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

  @Builder
  private TermsConsentSheet() {
    Column() {
      Blank()
        .layoutWeight(1)

      Column() {
        Text('×')
          .fontSize(34)
          .fontColor('#FFFFFF')
          .width('100%')
          .textAlign(TextAlign.End)
          .onClick(() => {
            this.termsPromptAction = TermsPromptAction.None;
          })

        Text('阅读并同意以下条款，')
          .fontSize(18)
          .fontColor('#FFFFFF')
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ top: 12 })

        Row() {
          Text('《隐私政策》')
            .fontSize(18)
            .fontColor(COROS_RED)
            .onClick(() => {
              this.openPrivacyPolicy();
            })
          Text(' 和 ')
            .fontSize(18)
            .fontColor('#FFFFFF')
          Text('《服务条款》')
            .fontSize(18)
            .fontColor(COROS_RED)
            .onClick(() => {
              this.openServiceTerms();
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ top: 8 })

        Blank()
          .height(42)

        this.CorosButton('同意并继续', COROS_RED, true, false, async () => {
          await this.acceptTermsPromptAndContinue();
        });
      }
      .width('100%')
      .padding({ left: 22, right: 22, top: 18, bottom: 18 })
      .backgroundColor('#1A1A1B')
      .borderRadius({ topLeft: 12, topRight: 12 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000C7')
  }

  @Builder
  private UnavailableFeatureDialog() {
    Column() {
      Blank()
        .layoutWeight(1)
      Column({ space: 20 }) {
        Text('抱歉，该功能还在实现中')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .textAlign(TextAlign.Center)
        Text('知道了')
          .fontSize(16)
          .fontColor(COROS_RED)
          .onClick(() => {
            this.unavailableDialogVisible = false;
          })
      }
      .padding({ left: 28, right: 28, top: 24, bottom: 24 })
      .backgroundColor('#222224')
      .borderRadius(12)
      .margin({ left: 42, right: 42 })
      Blank()
        .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0000009E')
    .onClick(() => {
      this.unavailableDialogVisible = false;
    })
  }

  @Builder
  private BlockingLoadingOverlay() {
    Column() {
      Blank()
        .layoutWeight(1)
      LoadingProgress()
        .width(36)
        .height(36)
        .color('#D8D8DD')
        .padding(30)
        .backgroundColor('#3A3A3C')
        .borderRadius(8)
      Blank()
        .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000B8')
  }

  private async showLogin(): Promise<void> {
    await this.setMode(AuthMode.Login);
    this.localError = '';
    this.page = AuthPage.Login;
  }

  private async showPhoneRegister(): Promise<void> {
    await this.setMode(AuthMode.Register);
    this.localError = '';
    this.page = AuthPage.PhoneRegister;
  }

  private async showEmailRegister(): Promise<void> {
    await this.setMode(AuthMode.Register);
    await this.updateUsername('');
    this.emailInput = '';
    this.localError = '';
    this.page = AuthPage.EmailRegister;
  }

  private async showPhoneRegisterFromEmail(): Promise<void> {
    await this.updateUsername('');
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

  private showUnavailableFeature(): void {
    this.unavailableDialogVisible = true;
  }

  private async acceptTermsPromptAndContinue(): Promise<void> {
    let action: TermsPromptAction = this.termsPromptAction;
    this.acceptedTerms = true;
    this.termsPromptAction = TermsPromptAction.None;

    if (action === TermsPromptAction.Login) {
      await this.submitLogin(true);
    } else if (action === TermsPromptAction.PhoneCode) {
      await this.requestPhoneVerifyCode(true);
    } else if (action === TermsPromptAction.EmailCode) {
      await this.requestEmailVerifyCode(true);
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
    this.username = value;
    let action: LoginAction = new LoginAction();
    action.type = LoginActionType.UsernameChanged;
    action.username = value;
    await this.viewModel.dispatch(action);
    this.localError = '';
    this.syncState();
  }

  private async updatePassword(value: string): Promise<void> {
    this.password = value;
    let action: LoginAction = new LoginAction();
    action.type = LoginActionType.PasswordChanged;
    action.password = value;
    await this.viewModel.dispatch(action);
    this.localError = '';
    this.syncState();
  }

  private async updateDisplayName(value: string): Promise<void> {
    let action: LoginAction = new LoginAction();
    action.type = LoginActionType.DisplayNameChanged;
    action.displayName = value;
    await this.viewModel.dispatch(action);
    this.syncState();
  }

  private async updateVerifyCode(value: string): Promise<void> {
    let action: LoginAction = new LoginAction();
    action.type = LoginActionType.VerifyCodeChanged;
    action.verifyCode = value;
    await this.viewModel.dispatch(action);
    this.syncState();
  }

  private async requestPhoneVerifyCode(skipTerms: boolean = false): Promise<void> {
    let validationMessage: string = this.validatePhoneAccount(this.username);
    if (validationMessage.length > 0) {
      this.localError = validationMessage;
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
    let validationMessage: string = this.validateEmailAccount(email);
    if (validationMessage.length > 0) {
      this.localError = validationMessage;
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
    await this.setMode(AuthMode.Register);
    await this.updateUsername(account);
    await this.updateDisplayName(account);
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
    let validationMessage: string = this.validateVerifyCode(this.codeInput);
    if (validationMessage.length > 0) {
      this.localError = validationMessage;
      return;
    }

    let message: string = this.viewModel.verifyCode(this.username, this.codeInput);
    if (message.length > 0) {
      this.localError = message;
      return;
    }

    await this.updateVerifyCode(this.codeInput);
    this.setupPassword = '';
    this.confirmPassword = '';
    this.localError = '';
    this.page = AuthPage.PasswordSetup;
  }

  private async submitLogin(skipTerms: boolean = false): Promise<void> {
    if (!skipTerms && !this.acceptedTerms) {
      this.termsPromptAction = TermsPromptAction.Login;
      return;
    }

    await this.updateUsername(this.username);
    await this.updatePassword(this.password);
    await this.setMode(AuthMode.Login);
    let action: LoginAction = new LoginAction();
    action.type = LoginActionType.SubmitClicked;
    await this.viewModel.dispatch(action);
    this.syncState();
    this.handleEffect(AuthMode.Login);
  }

  private async submitRegister(): Promise<void> {
    let validationMessage: string = this.validateRegisterPassword(this.setupPassword, this.confirmPassword);
    if (validationMessage.length > 0) {
      this.localError = validationMessage;
      return;
    }

    await this.setMode(AuthMode.Register);
    await this.updatePassword(this.setupPassword);
    await this.updateVerifyCode(this.codeInput);

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

  private verifyCodeMessage(): string {
    if (this.verifyTargetKind === VerifyTargetKind.Email) {
      return `验证码已发送至你的邮箱 ${this.username}，有效期10分钟`;
    }
    return `验证码已发送至你的手机+86-${this.username}，有效期10分钟`;
  }

  private canLogin(): boolean {
    return !this.isLoading && this.username.trim().length > 0 && this.password.length >= 6;
  }

  private canSendPhoneCode(): boolean {
    return this.validatePhoneAccount(this.username).length === 0 && !this.isLoading;
  }

  private canSendEmailCode(): boolean {
    return this.validateEmailAccount(this.emailInput).length === 0 && !this.isLoading;
  }

  private canRegister(): boolean {
    return this.validateRegisterPassword(this.setupPassword, this.confirmPassword).length === 0 && !this.isLoading;
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

  private validatePhoneAccount(account: string): string {
    return this.viewModel.validatePhoneAccount(account);
  }

  private validateEmailAccount(email: string): string {
    return this.viewModel.validateEmailAccount(email);
  }

  private validateVerifyCode(code: string): string {
    return this.viewModel.validateVerifyCode(code);
  }

  private validateRegisterPassword(passwordValue: string, confirmPasswordValue: string): string {
    return this.viewModel.validateRegisterPassword(passwordValue, confirmPasswordValue);
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
