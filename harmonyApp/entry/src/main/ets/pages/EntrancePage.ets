import router from '@ohos.router';
import {
  AuthMode,
  LoginState
} from '../login/LoginState';
import { getLoginViewModel } from '../login/LoginViewModelProvider';
import {
  COROS_RED,
  COROS_BLACK
} from '../login/components/AuthColors';
import {
  CorosButton
} from '../login/components/AuthComponents';
import { AuthRoutes } from '../login/AuthRoutes';

@Entry
@Component
struct EntrancePage {
  private viewModel = getLoginViewModel();
  @State isLoggedIn: boolean = false;
  @State sessionAccount: string = '';

  aboutToAppear(): void {
    this.syncState();
    if (this.isLoggedIn && this.sessionAccount.length > 0) {
      router.replaceUrl({ url: AuthRoutes.SIGNED_IN });
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
        Row() {
          Text('DEBUG')
            .fontSize(11)
            .fontColor('#FFFFFF80')
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor('#FFFFFF20')
            .borderRadius(4)
            .onClick(() => { router.pushUrl({ url: AuthRoutes.DEBUG }); })
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
            onTap: () => {
              this.viewModel.dispatch({
                type: 0, mode: AuthMode.Register, username: '', password: '',
                verifyCode: '', displayName: '', region: 'CN'
              });
              this.viewModel.state;
              router.pushUrl({ url: AuthRoutes.PHONE_REGISTER });
            } });
          CorosButton({ textValue: '登录', color: '#424242', enabledValue: true, loading: false,
            onTap: () => { router.pushUrl({ url: AuthRoutes.LOGIN }); } });
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

  private syncState(): void {
    let state: LoginState = this.viewModel.state;
    this.isLoggedIn = state.isLoggedIn;
    this.sessionAccount = state.currentSession === null ? '' : state.currentSession.account;
  }
}
