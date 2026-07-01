import {
  AuthMode,
  canSubmitLogin,
  createInitialLoginState,
  LoginAction,
  LoginActionType,
  LoginEffect,
  LoginEffectType,
  LoginRequestDto,
  LoginResult,
  LoginResultType,
  LoginState,
  RegisterRequestDto
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
      case LoginActionType.ModeChanged:
        this.updateMode(action.mode);
        break;
      case LoginActionType.UsernameChanged:
        this.updateUsername(action.username);
        break;
      case LoginActionType.PasswordChanged:
        this.updatePassword(action.password);
        break;
      case LoginActionType.VerifyCodeChanged:
        this.updateVerifyCode(action.verifyCode);
        break;
      case LoginActionType.DisplayNameChanged:
        this.updateDisplayName(action.displayName);
        break;
      case LoginActionType.RegionChanged:
        this.updateRegion(action.region);
        break;
      case LoginActionType.SubmitClicked:
        await this.submit();
        break;
      case LoginActionType.LogoutClicked:
        this.logout();
        break;
      case LoginActionType.EffectConsumed:
        this.pendingEffect = null;
        break;
      default:
        break;
    }
  }

  requestVerifyCode(account: string): string {
    return this.loginService.requestVerifyCode(account);
  }

  verifyCode(account: string, code: string): string {
    return this.loginService.verifyCode(account, code);
  }

  clearSessionSilently(): void {
    this.loginService.clearSession();
    let state: LoginState = this.copyCurrentState();
    state.currentSession = null;
    state.isLoggedIn = false;
    state.password = '';
    state.verifyCode = '';
    state.errorMessage = '';
    this.currentState = state;
  }

  consumeEffect(): LoginEffect | null {
    let effect: LoginEffect | null = this.pendingEffect;
    this.pendingEffect = null;
    return effect;
  }

  private updateMode(mode: AuthMode): void {
    let state: LoginState = this.copyCurrentState();
    state.mode = mode;
    state.errorMessage = '';
    this.currentState = state;
  }

  private updateUsername(username: string): void {
    let state: LoginState = this.copyCurrentState();
    state.username = username;
    state.errorMessage = '';
    this.currentState = state;
  }

  private updatePassword(password: string): void {
    let state: LoginState = this.copyCurrentState();
    state.password = password;
    state.errorMessage = '';
    this.currentState = state;
  }

  private updateVerifyCode(verifyCode: string): void {
    let state: LoginState = this.copyCurrentState();
    state.verifyCode = verifyCode;
    state.errorMessage = '';
    this.currentState = state;
  }

  private updateDisplayName(displayName: string): void {
    let state: LoginState = this.copyCurrentState();
    state.displayName = displayName;
    state.errorMessage = '';
    this.currentState = state;
  }

  private updateRegion(region: string): void {
    let state: LoginState = this.copyCurrentState();
    state.selectedRegion = region;
    state.errorMessage = '';
    this.currentState = state;
  }

  private async submit(): Promise<void> {
    if (!canSubmitLogin(this.currentState)) {
      let message: string = this.currentState.mode === AuthMode.Register ? '请输入账号、密码、区域和验证码' : '请输入账号和密码';
      this.failLocal(message);
      return;
    }

    let loadingState: LoginState = this.copyCurrentState();
    loadingState.isLoading = true;
    loadingState.errorMessage = '';
    this.currentState = loadingState;

    let result: LoginResult = this.currentState.mode === AuthMode.Register
      ? await this.submitRegister()
      : await this.submitLogin();

    if (result.type === LoginResultType.Success) {
      let successState: LoginState = this.copyCurrentState();
      successState.isLoading = false;
      successState.isLoggedIn = true;
      successState.currentSession = result.session;
      successState.password = '';
      successState.verifyCode = '';
      successState.errorMessage = '';
      this.currentState = successState;

      let effect: LoginEffect = new LoginEffect();
      effect.type = LoginEffectType.AuthSucceeded;
      effect.mode = this.currentState.mode;
      effect.session = result.session;
      this.pendingEffect = effect;
      return;
    }

    let failureState: LoginState = this.copyCurrentState();
    failureState.isLoading = false;
    failureState.isLoggedIn = false;
    failureState.currentSession = null;
    failureState.errorMessage = result.message;
    this.currentState = failureState;

    let effect: LoginEffect = new LoginEffect();
    effect.type = LoginEffectType.ShowMessage;
    effect.message = result.message;
    this.pendingEffect = effect;
  }

  private async submitLogin(): Promise<LoginResult> {
    let request: LoginRequestDto = new LoginRequestDto();
    request.account = this.currentState.username;
    request.password = this.currentState.password;
    return this.loginService.login(request);
  }

  private async submitRegister(): Promise<LoginResult> {
    let request: RegisterRequestDto = new RegisterRequestDto();
    request.account = this.currentState.username;
    request.password = this.currentState.password;
    request.verifyCode = this.currentState.verifyCode;
    request.region = this.currentState.selectedRegion;
    request.displayName = this.currentState.displayName;
    return this.loginService.register(request);
  }

  private logout(): void {
    this.loginService.clearSession();
    let state: LoginState = this.copyCurrentState();
    state.currentSession = null;
    state.isLoggedIn = false;
    state.password = '';
    state.verifyCode = '';
    state.errorMessage = '';
    this.currentState = state;

    let effect: LoginEffect = new LoginEffect();
    effect.type = LoginEffectType.LoggedOut;
    effect.message = '已退出登录';
    this.pendingEffect = effect;
  }

  private failLocal(message: string): void {
    let state: LoginState = this.copyCurrentState();
    state.errorMessage = message;
    this.currentState = state;

    let effect: LoginEffect = new LoginEffect();
    effect.type = LoginEffectType.ShowMessage;
    effect.message = message;
    this.pendingEffect = effect;
  }

  private copyCurrentState(): LoginState {
    let state: LoginState = new LoginState();
    state.mode = this.currentState.mode;
    state.username = this.currentState.username;
    state.password = this.currentState.password;
    state.verifyCode = this.currentState.verifyCode;
    state.displayName = this.currentState.displayName;
    state.selectedRegion = this.currentState.selectedRegion;
    state.currentSession = this.currentState.currentSession;
    state.isLoading = this.currentState.isLoading;
    state.isLoggedIn = this.currentState.isLoggedIn;
    state.errorMessage = this.currentState.errorMessage;
    return state;
  }
}
