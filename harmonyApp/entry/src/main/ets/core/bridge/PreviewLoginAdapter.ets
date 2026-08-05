import { LoginLogicAdapter } from '../../auth/logic/LoginLogicAdapter';
import { AuthMode, AuthSession, LoginEffect, LoginEffectType, LoginState } from '../../auth/logic/LoginState';

/** Side-effect-free adapter used when ArkUI is hosted by DevEco Previewer. */
export class PreviewLoginAdapter implements LoginLogicAdapter {
  private state: LoginState = new LoginState();
  private effect: LoginEffect | null = null;

  getState(): LoginState { return this.state; }
  setMode(mode: AuthMode): void { this.state.mode = mode; this.state.errorMessage = ''; }
  setUsername(value: string): void { this.state.username = value; }
  setPassword(value: string): void { this.state.password = value; }
  setVerifyCode(value: string): void { this.state.verifyCode = value; }
  setDisplayName(value: string): void { this.state.displayName = value; }
  setRegion(value: string): void { this.state.selectedRegion = value; }

  async submit(): Promise<void> {
    this.state.isLoading = false;
    this.state.errorMessage = '';
  }

  logout(): void {
    this.state.currentSession = null;
    this.state.isLoggedIn = false;
    this.effect = this.createEffect(LoginEffectType.LoggedOut);
  }

  requestVerifyCode(_account: string): string { return ''; }
  requestResentVerifyCode(_account: string): string { return ''; }
  verifyCode(_account: string, code: string): string { return this.validateVerifyCode(code); }
  verifyCodeRemainingSeconds(_account: string): number { return 60; }
  normalizePhoneInput(value: string): string { return value.replace(/[^0-9]/g, '').slice(0, 11); }
  normalizeEmailInput(value: string): string { return value.trim().toLowerCase(); }
  normalizeVerifyCodeInput(value: string): string { return value.replace(/[^0-9]/g, '').slice(0, 4); }
  normalizePasswordInput(value: string): string { return value.slice(0, 32); }

  isLoginReady(account: string, password: string, isLoading: boolean): boolean {
    return !isLoading && this.validateLoginInput(account, password).length === 0;
  }

  validateLoginInput(account: string, password: string): string {
    if (account.trim().length === 0) return 'auth_account_required';
    if (password.length < 6) return 'auth_password_too_short';
    return '';
  }

  isPhoneAccountValid(account: string): boolean { return /^1[0-9]{10}$/.test(account); }
  isEmailAccountValid(email: string): boolean { return /^[^@]+@[^@]+\.[^@]+$/.test(email); }
  isRegisterPasswordReady(password: string, confirmPassword: string, isLoading: boolean): boolean {
    return !isLoading && this.validateRegisterPassword(password, confirmPassword).length === 0;
  }
  validatePhoneAccount(account: string): string { return this.isPhoneAccountValid(account) ? '' : 'auth_phone_invalid'; }
  validateEmailAccount(email: string): string { return this.isEmailAccountValid(email) ? '' : 'auth_email_invalid'; }
  validateVerifyCode(code: string): string { return /^[0-9]{4}$/.test(code) ? '' : 'auth_code_invalid'; }
  validateRegisterPassword(password: string, confirmPassword: string): string {
    if (password.length < 6) return 'auth_password_too_short';
    return password === confirmPassword ? '' : 'auth_password_mismatch';
  }
  hasAccount(_account: string): boolean { return false; }
  isResetPasswordReady(newPassword: string, confirmPassword: string, isLoading: boolean): boolean {
    return !isLoading && this.validateRegisterPassword(newPassword, confirmPassword).length === 0;
  }
  isProfileRequiredComplete(username: string, birthDate: string, heightCm: number, weightKg: number,
    gender: string, isLoading: boolean): boolean {
    return !isLoading && username.length > 0 && birthDate.length > 0 && heightCm > 0 && weightKg > 0 && gender.length > 0;
  }
  resetPassword(_account: string, _newPassword: string): string { return ''; }
  changePassword(_account: string, _oldPassword: string, _newPassword: string): string { return ''; }

  submitProfile(_avatarUri: string, username: string, birthDate: string, heightCm: number, weightKg: number,
    measurementSystem: string, phone: string, email: string, countryRegion: string, gender: string): void {
    const session: AuthSession = new AuthSession();
    session.account = phone.length > 0 ? phone : email;
    session.displayName = username;
    session.birthDate = birthDate;
    session.heightCm = heightCm;
    session.weightKg = weightKg;
    session.measurementSystem = measurementSystem;
    session.phone = phone;
    session.email = email;
    session.countryRegion = countryRegion;
    session.gender = gender;
    session.isValid = true;
    session.isProfileComplete = true;
    this.state.currentSession = session;
    this.state.isLoggedIn = true;
    this.effect = this.createEffect(LoginEffectType.ProfileSaved);
  }

  profileDefaultUsername(_account: string): string { return 'COROS user'; }
  profileDefaultPhone(account: string): string { return this.isPhoneAccountValid(account) ? account : ''; }
  profileDefaultEmail(account: string): string { return this.isEmailAccountValid(account) ? account : ''; }

  currentUserId(): string { return 'preview-user'; }
  deleteCurrentAccount(): string { this.logout(); return ''; }
  clearSessionSilently(): void { this.state.currentSession = null; this.state.isLoggedIn = false; }
  consumeEffect(): LoginEffect | null { const current = this.effect; this.effect = null; return current; }

  private createEffect(type: LoginEffectType): LoginEffect {
    const value: LoginEffect = new LoginEffect();
    value.type = type;
    return value;
  }
}
