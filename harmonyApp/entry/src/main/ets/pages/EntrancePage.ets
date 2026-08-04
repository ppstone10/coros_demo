import router from '@ohos.router';
import { AuthMode, LoginState } from '../auth/logic/LoginState';
import { getLoginViewModel } from '../auth/viewmodel/LoginViewModelProvider';
import { COROS_RED, COROS_BLACK } from '../auth/components/AuthColors';
import { CorosButton } from '../auth/components/AuthComponents';
import { AuthRoutes } from '../auth/navigation/AuthRoutes';
import { navigate, NavOperation } from '../auth/navigation/AuthNavigator';
import { handleAuthEffect } from '../auth/navigation/AuthEffectHandler';
import { AppColors } from '../core/resources/AppResources';
import {
  APP_LANGUAGE_CHINESE,
  APP_LANGUAGE_ENGLISH,
  selectAppLanguage
} from '../core/resources/AppLanguage';

@Preview
@Entry
@Component
struct EntrancePage {
  private viewModel = getLoginViewModel();
  @State isLoggedIn: boolean = false;
  @State sessionAccount: string = '';
  @StorageLink('app_language') appLanguage: string = APP_LANGUAGE_CHINESE;
  @StorageLink('app_language_version') languageVersion: number = 0;
  @State showLanguageDialog: boolean = false;

  aboutToAppear(): void {
    this.syncState();
    const effect = this.viewModel.consumeEffect();
    if (effect !== null) {
      handleAuthEffect(effect);
      return;
    }
    if (this.isLoggedIn && this.sessionAccount.length > 0) {
      let state: LoginState = this.viewModel.state;
      let targetUrl: string = state.currentSession !== null && state.currentSession.isProfileComplete ?
        AuthRoutes.home.SIGNED_IN : AuthRoutes.auth.PROFILE_COMPLETION;
      navigate(NavOperation.ResetTo, targetUrl);
    }
  }

  onBackPress(): boolean {
    return true;
  }

  build() {
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
        Blank().height(52)

        this.EntranceTopBar()

        Blank().layoutWeight(1)

        Column({ space: 20 }) {
          CorosButton({ textValue: $r('app.string.auth_register'), color: COROS_RED, enabledValue: true, loading: false,
            tapRequested: () => {
              this.viewModel.dispatch({ type: 0, mode: AuthMode.Register, username: '', password: '', verifyCode: '', displayName: '', region: 'CN' });
              navigate(NavOperation.Push, AuthRoutes.auth.PHONE_REGISTER);
            } });
          CorosButton({ textValue: $r('app.string.auth_login'), color: AppColors.AUTH_ENTRANCE_BUTTON, enabledValue: true, loading: false,
            tapRequested: () => { navigate(NavOperation.Push, AuthRoutes.auth.LOGIN); } });
        }
        .width('100%')
        .padding({ left: 20, right: 20, bottom: 60 })
      }
      .width('100%')
      .height('100%')

      if (this.showLanguageDialog) {
        this.LanguageDialog();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COROS_BLACK)
  }

  @Builder
  EntranceTopBar() {
    Stack() {
      Image($r('app.media.coros_logo'))
        .width(260)
        .height(48)
        .objectFit(ImageFit.Contain)

      Row() {
        Blank().layoutWeight(1)
        SymbolGlyph($r('sys.symbol.worldclock'))
          .fontSize(26)
          .fontColor([AppColors.WHITE])
          .width(48)
          .height(48)
          .accessibilityText($r('app.string.language_switch'))
          .onClick(() => { this.showLanguageDialog = true; })
      }
      .width('100%')
      .height(48)
      .padding({ right: 12 })
    }
    .width('100%')
    .height(48)
  }

  @Builder
  LanguageDialog() {
    Column() {
      Column({ space: 4 }) {
        Text($r('app.string.language_select_title'))
          .fontSize(19).fontColor(AppColors.WHITE).fontWeight(FontWeight.Medium)
          .width('100%').padding({ left: 20, right: 20, top: 16, bottom: 10 })
        this.LanguageOption($r('app.string.language_chinese'), APP_LANGUAGE_CHINESE);
        this.LanguageOption($r('app.string.language_english'), APP_LANGUAGE_ENGLISH);
      }
      .width('84%').padding({ bottom: 12 }).backgroundColor(AppColors.ACCOUNT_DIALOG).borderRadius(14)
    }
    .width('100%').height('100%').justifyContent(FlexAlign.Center).backgroundColor(AppColors.OVERLAY_62)
  }

  @Builder
  LanguageOption(label: ResourceStr, language: string) {
    Row() {
      Text(label).fontSize(16).fontColor(AppColors.WHITE)
      Blank().layoutWeight(1)
      if (this.appLanguage === language) {
        Text('✓').fontSize(18).fontColor(AppColors.COMPLETE)
      }
    }
    .width('100%').height(52).padding({ left: 22, right: 22 })
    .onClick(() => {
      selectAppLanguage(language);
      this.showLanguageDialog = false;
    })
  }

  private syncState(): void {
    let state: LoginState = this.viewModel.state;
    this.isLoggedIn = state.isLoggedIn;
    if (state.currentSession !== null) {
      this.sessionAccount = state.currentSession.account;
    }
  }
}
