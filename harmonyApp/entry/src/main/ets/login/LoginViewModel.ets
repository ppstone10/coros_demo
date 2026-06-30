import {
  canSubmitLogin,
  createInitialLoginState,
  LoginAction,
  LoginActionType,
  LoginEffect,
  LoginEffectType,
  LoginRequestDto,
  LoginResult,
  LoginResultType,
  LoginState
} from './LoginState';
import { LoginService } from './LoginService';

export class LoginViewModel {
  private loginService: LoginService = new LoginService();
  private currentState: LoginState = createInitialLoginState();
  private pendingEffect: LoginEffect | null = null;

  get state(): LoginState {
    return this.currentState;
  }

  async dispatch(action: LoginAction): Promise<void> {
    switch (action.type) {
      case LoginActionType.UsernameChanged:
        this.updateUsername(action.username);
        break;
      case LoginActionType.PasswordChanged:
        this.updatePassword(action.password);
        break;
      case LoginActionType.SubmitClicked:
        await this.submit();
        break;
      case LoginActionType.EffectConsumed:
        this.pendingEffect = null;
        break;
      default:
        break;
    }
  }

  consumeEffect(): LoginEffect | null {
    let effect: LoginEffect | null = this.pendingEffect;
    this.pendingEffect = null;
    return effect;
  }

  private updateUsername(username: string): void {
    let newState: LoginState = this.copyCurrentState();
    newState.username = username;
    newState.errorMessage = '';
    this.currentState = newState;
  }

  private updatePassword(password: string): void {
    let newState: LoginState = this.copyCurrentState();
    newState.password = password;
    newState.errorMessage = '';
    this.currentState = newState;
  }

  private async submit(): Promise<void> {
    if (!canSubmitLogin(this.currentState)) {
      let message: string = '请输入用户名和密码';

      let newState: LoginState = this.copyCurrentState();
      newState.errorMessage = message;
      this.currentState = newState;

      let effect: LoginEffect = new LoginEffect();
      effect.type = LoginEffectType.ShowMessage;
      effect.message = message;
      this.pendingEffect = effect;
      return;
    }

    let loadingState: LoginState = this.copyCurrentState();
    loadingState.isLoading = true;
    loadingState.errorMessage = '';
    this.currentState = loadingState;

    let request: LoginRequestDto = new LoginRequestDto();
    request.username = this.currentState.username;
    request.password = this.currentState.password;

    let result: LoginResult = await this.loginService.login(request);

    if (result.type === LoginResultType.Success) {
      let successState: LoginState = this.copyCurrentState();
      successState.isLoading = false;
      successState.isLoggedIn = true;
      successState.errorMessage = '';
      this.currentState = successState;

      let effect: LoginEffect = new LoginEffect();
      effect.type = LoginEffectType.NavigateHome;
      effect.user = result.user;
      this.pendingEffect = effect;
      return;
    }

    let failureState: LoginState = this.copyCurrentState();
    failureState.isLoading = false;
    failureState.isLoggedIn = false;
    failureState.errorMessage = result.message;
    this.currentState = failureState;

    let effect: LoginEffect = new LoginEffect();
    effect.type = LoginEffectType.ShowMessage;
    effect.message = result.message;
    this.pendingEffect = effect;
  }

  private copyCurrentState(): LoginState {
    let newState: LoginState = new LoginState();
    newState.username = this.currentState.username;
    newState.password = this.currentState.password;
    newState.isLoading = this.currentState.isLoading;
    newState.isLoggedIn = this.currentState.isLoggedIn;
    newState.errorMessage = this.currentState.errorMessage;
    return newState;
  }
}
