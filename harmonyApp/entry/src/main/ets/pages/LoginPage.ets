import promptAction from '@ohos.promptAction';
import {
  canSubmitLogin,
  LoginAction,
  LoginActionType,
  LoginEffect,
  LoginEffectType,
  LoginState
} from '../login/LoginState';
import { LoginViewModel } from '../login/LoginViewModel';

@Entry
@Component
struct LoginPage {
  private viewModel: LoginViewModel = new LoginViewModel();

  @State username: string = '';
  @State password: string = '';
  @State isLoading: boolean = false;
  @State isLoggedIn: boolean = false;
  @State errorMessage: string = '';

  aboutToAppear(): void {
    this.syncState();
  }

  build() {
    Column({ space: 16 }) {
      Blank()

      Text('登录')
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .width('100%')

      Text('请输入账号完成登录')
        .fontSize(14)
        .fontColor('#666666')
        .width('100%')

      TextInput({ placeholder: '用户名', text: this.username })
        .width('100%')
        .onChange(async (value: string) => {
          let action: LoginAction = new LoginAction();
          action.type = LoginActionType.UsernameChanged;
          action.username = value;

          await this.viewModel.dispatch(action);
          this.syncState();
        })

      TextInput({ placeholder: '密码', text: this.password })
        .type(InputType.Password)
        .width('100%')
        .onChange(async (value: string) => {
          let action: LoginAction = new LoginAction();
          action.type = LoginActionType.PasswordChanged;
          action.password = value;

          await this.viewModel.dispatch(action);
          this.syncState();
        })

      if (this.errorMessage.length > 0) {
        Text(this.errorMessage)
          .fontSize(12)
          .fontColor('#BA1A1A')
          .width('100%')
      }

      Button(this.isLoading ? '登录中' : '登录')
        .width('100%')
        .enabled(this.canSubmit())
        .onClick(async () => {
          let action: LoginAction = new LoginAction();
          action.type = LoginActionType.SubmitClicked;

          await this.viewModel.dispatch(action);
          this.syncState();
          this.handleEffect();
        })

      Blank()
    }
    .width('100%')
    .height('100%')
    .padding(24)
  }

  private syncState(): void {
    let state: LoginState = this.viewModel.state;
    this.username = state.username;
    this.password = state.password;
    this.isLoading = state.isLoading;
    this.isLoggedIn = state.isLoggedIn;
    this.errorMessage = state.errorMessage;
  }

  private canSubmit(): boolean {
    let state: LoginState = new LoginState();
    state.username = this.username;
    state.password = this.password;
    state.isLoading = this.isLoading;
    state.isLoggedIn = this.isLoggedIn;
    state.errorMessage = this.errorMessage;
    return canSubmitLogin(state);
  }

  private handleEffect(): void {
    let effect: LoginEffect | null = this.viewModel.consumeEffect();
    if (effect === null) {
      return;
    }

    if (effect.type === LoginEffectType.NavigateHome) {
      this.showMessage(`登录成功：${effect.user.displayName}`);
      return;
    }

    this.showMessage(effect.message);
  }

  private showMessage(message: string): void {
    try {
      promptAction.showToast({ message: message });
    } catch (error) {
      console.error('showToast failed');
    }
  }
}
