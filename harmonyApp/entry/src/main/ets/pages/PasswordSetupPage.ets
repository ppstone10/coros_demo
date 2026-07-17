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
import { AppColors } from '../resources/AppResources';

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
  @State selectedRegion: string = 'CN';
  @State regionPickerVisible: boolean = false;
  @State regionPickerIndex: number = 0;
  private regionCountries: string[] = [];

  aboutToAppear(): void {
    this.regionCountries = [
      this.localized($r('app.string.common_china')),
      this.localized($r('app.string.common_united_states'))
    ];
    let params = router.getParams() as PasswordSetupParams;
    if (params !== null && params !== undefined) {
      this.targetKind = params.targetKind as VerifyTargetKind;
    }
    this.syncState();
  }

  private localized(resource: Resource): string {
    return getContext(this).resourceManager.getStringSync(resource.id);
  }

  onBackPress(): boolean {
    const target = this.targetKind === VerifyTargetKind.Email ? AuthRoutes.EMAIL_REGISTER : AuthRoutes.PHONE_REGISTER
    navigate(NavOperation.ResetKeepingEntranceAndPush, target);
    return true;
  }

  build() {
    Stack() {
      Scroll() {
        Column() {
        AuthHeader({ showBack: true, showFeedback: false,
          backRequested: () => {
            const target = this.targetKind === VerifyTargetKind.Email ? AuthRoutes.EMAIL_REGISTER : AuthRoutes.PHONE_REGISTER
            navigate(NavOperation.ResetKeepingEntranceAndPush, target);
          } });
        AuthTitle($r('app.string.auth_set_login_password'));

        Blank().height(60)

        UnderlineInput({ placeholder: $r('app.string.auth_new_password_placeholder'), textValue: this.setupPassword,
          inputType: this.setupPasswordVisible ? InputType.Normal : InputType.Password,
          isPassword: true, passwordVisible: this.setupPasswordVisible,
          valueChanged: (value: string) => {
            this.setupPassword = this.viewModel.normalizePasswordInput(value);
            this.localError = '';
            this.refreshActionStates();
          },
          passwordToggleRequested: () => { this.setupPasswordVisible = !this.setupPasswordVisible; } });

        Blank().height(48)

        UnderlineInput({ placeholder: $r('app.string.auth_confirm_password_placeholder'), textValue: this.confirmPassword,
          inputType: this.confirmPasswordVisible ? InputType.Normal : InputType.Password,
          isPassword: true, passwordVisible: this.confirmPasswordVisible,
          valueChanged: (value: string) => {
            this.confirmPassword = this.viewModel.normalizePasswordInput(value);
            this.localError = '';
            this.refreshActionStates();
          },
          passwordToggleRequested: () => { this.confirmPasswordVisible = !this.confirmPasswordVisible; } });

        Text($r('app.string.auth_password_rule'))
          .fontSize(14)
          .fontColor(AppColors.AUTH_INPUT_TEXT)
          .margin({ top: 8 })

        Blank().height(12)

        Row() {
          Text($r('app.string.profile_country_region'))
            .fontSize(19)
            .fontColor(COROS_WHITE)
          Blank().layoutWeight(1)
          Text(this.selectedRegion === 'US' ? $r('app.string.common_united_states') : $r('app.string.common_china'))
            .fontSize(19)
            .fontColor(AppColors.PROFILE_VALUE)
          Image($r('app.media.right_more'))
            .width(24)
            .height(24)
            .margin({ left: 12 })
        }
        .width('100%')
        .height(66)
        .border({ width: { bottom: 1 }, color: AppColors.ACCOUNT_AVATAR })
        .onClick(() => {
          this.regionPickerIndex = this.selectedRegion === 'US' ? 1 : 0;
          this.regionPickerVisible = true;
        })

        Blank().height(44)

        CorosButton({ textValue: $r('app.string.auth_register'), color: COROS_BUTTON_RED,
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

      if (this.regionPickerVisible) {
        Stack() {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(AppColors.AUTH_OVERLAY_SOFT)
          .onClick(() => { this.regionPickerVisible = false; })

        Column() {
          Row() {
            Text($r('app.string.common_cancel'))
              .fontSize(18)
              .fontColor(COROS_WHITE)
              .onClick(() => { this.regionPickerVisible = false; })
            Blank().layoutWeight(1)
            Text($r('app.string.profile_country_region'))
              .fontSize(20)
              .fontWeight(FontWeight.Medium)
              .fontColor(COROS_WHITE)
            Blank().layoutWeight(1)
            Text($r('app.string.common_confirm'))
              .fontSize(18)
              .fontColor(COROS_WHITE)
              .onClick(() => {
                this.selectedRegion = this.regionPickerIndex === 1 ? 'US' : 'CN';
                this.regionPickerVisible = false;
                this.localError = '';
              })
          }
          .width('100%')
          .height(70)
          .padding({ left: 22, right: 22 })

          TextPicker({ range: this.regionCountries, selected: this.regionPickerIndex })
            .width(180)
            .height(240)
            .defaultPickerItemHeight(54)
            .canLoop(true)
            .selectedTextStyle({ color: COROS_WHITE, font: { size: 28, weight: FontWeight.Medium } })
            .textStyle({ color: AppColors.PROFILE_WHEEL_NEAR, font: { size: 23, weight: FontWeight.Normal } })
            .divider({ strokeWidth: 1, color: AppColors.PROFILE_WHEEL_BORDER, startMargin: 14, endMargin: 14 })
            .onChange((value: string | string[], index: number | number[]) => {
              this.regionPickerIndex = typeof index === 'number' ? index : 0;
            })

          Blank().height(28)
        }
        .width('100%')
        .backgroundColor(AppColors.AUTH_SHEET)
        .borderRadius({ topLeft: 14, topRight: 14 })
        .align(Alignment.Bottom)
      }
      .width('100%')
      .height('100%')
    }
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
      verifyCode: '', displayName: '', region: this.selectedRegion
    });
    this.viewModel.dispatch({
      type: LoginActionType.PasswordChanged, mode: AuthMode.Register, username: '', password: this.setupPassword,
      verifyCode: '', displayName: '', region: this.selectedRegion
    });
    try {
      await this.viewModel.dispatch({
        type: LoginActionType.SubmitClicked, mode: AuthMode.Register, username: '', password: '',
        verifyCode: '', displayName: '', region: this.selectedRegion
      });
    } catch (error) {
      this.localError = 'auth_submit_failed';
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
    this.setupPassword = '';
    this.confirmPassword = '';
    this.syncState();
    handleAuthEffect(effect);
  }

  private syncState(): void {
    let state: LoginState = this.viewModel.state;
    this.isLoading = state.isLoading;
    this.selectedRegion = state.selectedRegion.length > 0 ? state.selectedRegion : 'CN';
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
