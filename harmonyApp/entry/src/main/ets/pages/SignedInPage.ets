import promptAction from '@ohos.promptAction';
import {
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
  ErrorText,
  CorosButton,
  AuthHeader
} from '../login/components/AuthComponents';
import { handleAuthEffect } from '../login/AuthEffectHandler';

@Entry
@Component
struct SignedInPage {
  private viewModel = getLoginViewModel();
  @State sessionAccount: string = '';
  @State localError: string = '';
  @State showDeleteDialog: boolean = false;

  aboutToAppear(): void {
    this.syncState();
  }

  onBackPress(): boolean {
    return true;
  }

  build() {
    Stack() {
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

      if (this.showDeleteDialog) {
        this.DeleteAccountDialog();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COROS_BLACK)
  }

  @Builder
  DeleteAccountDialog() {
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

  private confirmDeleteAccount(): void {
    let message: string = this.viewModel.deleteCurrentAccountMessage();
    if (message.length > 0) {
      this.localError = message;
      this.showDeleteDialog = false;
      return;
    }
    this.showDeleteDialog = false;
    this.syncState();
    let effect: LoginEffect | null = this.viewModel.consumeEffect();
    if (effect !== null && effect.type === LoginEffectType.AccountDeleted) {
      handleAuthEffect(effect);
    }
  }

  private async logout(): Promise<void> {
    this.viewModel.dispatch({
      type: LoginActionType.LogoutClicked, mode: 0, username: '', password: '',
      verifyCode: '', displayName: '', region: 'CN'
    });
    this.syncState();
    let effect: LoginEffect | null = this.viewModel.consumeEffect();
    if (effect !== null && effect.type === LoginEffectType.LoggedOut) {
      handleAuthEffect(effect);
    }
  }

  private syncState(): void {
    let state: LoginState = this.viewModel.state;
    if (state.currentSession === null) {
      this.sessionAccount = '';
      return;
    }
    this.sessionAccount = state.currentSession.displayName.length > 0 ?
      state.currentSession.displayName : state.currentSession.account;
  }

  private showMessage(message: string): void {
    try {
      promptAction.showToast({ message: message });
    } catch (error) {
      console.error('showToast failed');
    }
  }
}
