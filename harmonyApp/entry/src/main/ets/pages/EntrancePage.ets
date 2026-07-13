import router from '@ohos.router';
import { AuthMode, LoginState } from '../login/LoginState';
import { getLoginViewModel } from '../login/LoginViewModelProvider';
import { COROS_RED, COROS_BLACK } from '../login/components/AuthColors';
import { CorosButton } from '../login/components/AuthComponents';
import { AuthRoutes } from '../login/AuthRoutes';
import { navigate, NavOperation } from '../login/AuthNavigator';
import { handleAuthEffect } from '../login/AuthEffectHandler';

@Entry @Component
struct EntrancePage {
  private viewModel = getLoginViewModel();
  @State isLoggedIn: boolean = false;
  @State sessionAccount: string = '';

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
        AuthRoutes.SIGNED_IN : AuthRoutes.PROFILE_COMPLETION;
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

        Image($r('app.media.coros_logo'))
          .width(260)
          .height(48)
          .objectFit(ImageFit.Contain)

        Blank().layoutWeight(1)

        Column({ space: 20 }) {
          CorosButton({ textValue: '注册', color: COROS_RED, enabledValue: true, loading: false,
            tapRequested: () => {
              this.viewModel.dispatch({ type: 0, mode: AuthMode.Register, username: '', password: '', verifyCode: '', displayName: '', region: 'CN' });
              navigate(NavOperation.Push, AuthRoutes.PHONE_REGISTER);
            } });
          CorosButton({ textValue: '登录', color: '#424242', enabledValue: true, loading: false,
            tapRequested: () => { navigate(NavOperation.Push, AuthRoutes.LOGIN); } });
        }
        .width('100%')
        .padding({ left: 20, right: 20, bottom: 60 })
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COROS_BLACK)
  }

  private syncState(): void {
    let state: LoginState = this.viewModel.state;
    this.isLoggedIn = state.isLoggedIn;
    if (state.currentSession !== null) {
      this.sessionAccount = state.currentSession.account;
    }
  }
}
