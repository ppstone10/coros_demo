import {
  LoginAction,
  LoginActionType,
  LoginEffect,
  LoginState
} from './LoginState';
import { LoginLogicAdapter } from './LoginLogicAdapter';
import { LoginLogicProvider } from './LoginLogicProvider';

export class LoginViewModel {
  private adapter: LoginLogicAdapter = LoginLogicProvider.create();

  get state(): LoginState {
    return this.adapter.getState();
  }

  async dispatch(action: LoginAction): Promise<void> {
    switch (action.type) {
      case LoginActionType.ModeChanged:
        this.adapter.setMode(action.mode);
        break;
      case LoginActionType.UsernameChanged:
        this.adapter.setUsername(action.username);
        break;
      case LoginActionType.PasswordChanged:
        this.adapter.setPassword(action.password);
        break;
      case LoginActionType.VerifyCodeChanged:
        this.adapter.setVerifyCode(action.verifyCode);
        break;
      case LoginActionType.DisplayNameChanged:
        this.adapter.setDisplayName(action.displayName);
        break;
      case LoginActionType.RegionChanged:
        this.adapter.setRegion(action.region);
        break;
      case LoginActionType.SubmitClicked:
        await this.adapter.submit();
        break;
      case LoginActionType.LogoutClicked:
        this.adapter.logout();
        break;
      case LoginActionType.EffectConsumed:
        this.adapter.consumeEffect();
        break;
      default:
        break;
    }
  }

  requestVerifyCode(account: string): string {
    return this.adapter.requestVerifyCode(account);
  }

  requestResentVerifyCode(account: string): string {
    return this.adapter.requestResentVerifyCode(account);
  }

  verifyCode(account: string, code: string): string {
    return this.adapter.verifyCode(account, code);
  }

  normalizePhoneInput(value: string): string {
    return this.adapter.normalizePhoneInput(value);
  }

  normalizeEmailInput(value: string): string {
    return this.adapter.normalizeEmailInput(value);
  }

  normalizeVerifyCodeInput(value: string): string {
    return this.adapter.normalizeVerifyCodeInput(value);
  }

  normalizePasswordInput(value: string): string {
    return this.adapter.normalizePasswordInput(value);
  }

  canSubmitLogin(): boolean {
    let state: LoginState = this.adapter.getState();
    return !state.isLoading && this.adapter.validateLoginInput(state.username, state.password).length === 0;
  }

  canRequestPhoneCode(): boolean {
    let state: LoginState = this.adapter.getState();
    return this.adapter.validatePhoneAccount(state.username).length === 0 && !state.isLoading;
  }

  canRequestEmailCode(email: string): boolean {
    let state: LoginState = this.adapter.getState();
    return this.adapter.validateEmailAccount(email).length === 0 && !state.isLoading;
  }

  canRegisterWithPassword(password: string, confirmPassword: string): boolean {
    let state: LoginState = this.adapter.getState();
    return !state.isLoading && this.adapter.validateRegisterPassword(password, confirmPassword).length === 0;
  }

  canSubmitResetPassword(newPassword: string, confirmPassword: string): boolean {
    let state: LoginState = this.adapter.getState();
    return this.adapter.isResetPasswordReady(newPassword, confirmPassword, state.isLoading);
  }

  canSubmitProfile(username: string, birthDate: string, heightCm: number, weightKg: number, gender: string): boolean {
    let state: LoginState = this.adapter.getState();
    return this.adapter.isProfileRequiredComplete(username, birthDate, heightCm, weightKg, gender, state.isLoading);
  }

  hasAccount(account: string): boolean {
    return this.adapter.hasAccount(account);
  }

  resetPasswordMessage(account: string, newPassword: string): string {
    return this.adapter.resetPassword(account, newPassword);
  }

  changePasswordMessage(account: string, oldPassword: string, newPassword: string): string {
    return this.adapter.changePassword(account, oldPassword, newPassword);
  }

  submitProfile(
    avatarUri: string, username: string, birthDate: string,
    heightCm: number, weightKg: number, measurementSystem: string,
    phone: string, countryRegion: string, gender: string
  ): void {
    this.adapter.submitProfile(avatarUri, username, birthDate, heightCm, weightKg, measurementSystem, phone, countryRegion, gender);
  }

  deleteCurrentAccountMessage(): string {
    return this.adapter.deleteCurrentAccount();
  }

  validateLoginInput(account: string, password: string): string {
    return this.adapter.validateLoginInput(account, password);
  }

  validatePhoneAccount(account: string): string {
    return this.adapter.validatePhoneAccount(account);
  }

  validateEmailAccount(email: string): string {
    return this.adapter.validateEmailAccount(email);
  }

  validateVerifyCode(code: string): string {
    return this.adapter.validateVerifyCode(code);
  }

  validateRegisterPassword(password: string, confirmPassword: string): string {
    return this.adapter.validateRegisterPassword(password, confirmPassword);
  }

  clearSessionSilently(): void {
    this.adapter.clearSessionSilently();
  }

  consumeEffect(): LoginEffect | null {
    return this.adapter.consumeEffect();
  }
}
