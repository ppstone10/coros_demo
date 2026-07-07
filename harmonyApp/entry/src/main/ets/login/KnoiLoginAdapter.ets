import {
  AuthMode,
  AuthSession,
  LoginEffect,
  LoginEffectType,
  LoginState
} from './LoginState';
import { LoginLogicAdapter } from './LoginLogicAdapter';
import { getHarmonyLoginService, HarmonyLoginService } from '../knoi/provider';
import { saveStoreSnapshot } from './StorePersister';

interface AuthSessionPayload {
  account: string;
  displayName: string;
  region: string;
  isValid: boolean;
  isProfileComplete: boolean;
}

interface LoginStatePayload {
  mode: string;
  username: string;
  password: string;
  verifyCode: string;
  displayName: string;
  selectedRegion: string;
  currentSession: AuthSessionPayload | null;
  isLoading: boolean;
  isLoggedIn: boolean;
  errorMessage: string;
}

interface LoginEffectPayload {
  type: string;
  mode: string;
  session: AuthSessionPayload | null;
  message: string;
}

export class KnoiLoginAdapter implements LoginLogicAdapter {
  private readonly harmonyLoginService: HarmonyLoginService = getHarmonyLoginService();
  private state: LoginState = new LoginState();

  constructor() {
    this.refreshState();
  }

  getState(): LoginState {
    this.refreshState();
    return this.cloneState(this.state);
  }

  setMode(mode: AuthMode): void {
    if (mode === AuthMode.Register) {
      this.harmonyLoginService.setRegisterMode();
    } else {
      this.harmonyLoginService.setLoginMode();
    }
    this.refreshState();
  }

  setUsername(value: string): void {
    this.harmonyLoginService.setUsername(value);
    this.refreshState();
  }

  setPassword(value: string): void {
    this.harmonyLoginService.setPassword(value);
    this.refreshState();
  }

  setVerifyCode(value: string): void {
    this.harmonyLoginService.setVerifyCode(value);
    this.refreshState();
  }

  setDisplayName(value: string): void {
    this.harmonyLoginService.setDisplayName(value);
    this.refreshState();
  }

  setRegion(value: string): void {
    this.harmonyLoginService.setRegion(value);
    this.refreshState();
  }

  async submit(): Promise<void> {
    try {
      this.harmonyLoginService.submit();
      this.refreshState();
      saveStoreSnapshot();
    } catch (error) {
      this.state.errorMessage = '提交失败，请重试';
    }
  }

  logout(): void {
    this.harmonyLoginService.logout();
    this.refreshState();
    saveStoreSnapshot();
  }

  requestVerifyCode(account: string): string {
    return this.harmonyLoginService.requestVerifyCode(account);
  }

  requestResentVerifyCode(account: string): string {
    return this.harmonyLoginService.requestResentVerifyCode(account);
  }

  verifyCode(account: string, code: string): string {
    return this.harmonyLoginService.verifyCode(account, code);
  }

  normalizePhoneInput(value: string): string {
    return this.harmonyLoginService.normalizePhoneInput(value);
  }

  normalizeEmailInput(value: string): string {
    return this.harmonyLoginService.normalizeEmailInput(value);
  }

  normalizeVerifyCodeInput(value: string): string {
    return this.harmonyLoginService.normalizeVerifyCodeInput(value);
  }

  normalizePasswordInput(value: string): string {
    return this.harmonyLoginService.normalizePasswordInput(value);
  }

  isLoginReady(account: string, password: string, isLoading: boolean): boolean {
    return this.harmonyLoginService.isLoginReady(account, password, isLoading);
  }

  validateLoginInput(account: string, password: string): string {
    return this.harmonyLoginService.validateLoginInput(account, password);
  }

  isPhoneAccountValid(account: string): boolean {
    return this.harmonyLoginService.isPhoneAccountValid(account);
  }

  isEmailAccountValid(email: string): boolean {
    return this.harmonyLoginService.isEmailAccountValid(email);
  }

  isRegisterPasswordReady(password: string, confirmPassword: string, isLoading: boolean): boolean {
    return this.harmonyLoginService.isRegisterPasswordReady(password, confirmPassword, isLoading);
  }

  validatePhoneAccount(account: string): string {
    return this.harmonyLoginService.validatePhoneAccount(account);
  }

  validateEmailAccount(email: string): string {
    return this.harmonyLoginService.validateEmailAccount(email);
  }

  validateVerifyCode(code: string): string {
    return this.harmonyLoginService.validateVerifyCode(code);
  }

  validateRegisterPassword(password: string, confirmPassword: string): string {
    return this.harmonyLoginService.validateRegisterPassword(password, confirmPassword);
  }

  hasAccount(account: string): boolean {
    return this.harmonyLoginService.hasAccount(account);
  }

  isResetPasswordReady(newPassword: string, confirmPassword: string, isLoading: boolean): boolean {
    return this.harmonyLoginService.isResetPasswordReady(newPassword, confirmPassword, isLoading);
  }

  isProfileRequiredComplete(
    username: string, birthDate: string, heightCm: number,
    weightKg: number, gender: string, isLoading: boolean
  ): boolean {
    return this.harmonyLoginService.isProfileRequiredComplete(username, birthDate, heightCm, weightKg, gender, isLoading);
  }

  resetPassword(account: string, newPassword: string): string {
    let message: string = this.harmonyLoginService.resetPassword(account, newPassword);
    this.refreshState();
    saveStoreSnapshot();
    return message;
  }

  changePassword(account: string, oldPassword: string, newPassword: string): string {
    return this.harmonyLoginService.changePassword(account, oldPassword, newPassword);
  }

  submitProfile(
    avatarUri: string, username: string, birthDate: string,
    heightCm: number, weightKg: number, measurementSystem: string,
    phone: string, countryRegion: string, gender: string
  ): void {
    this.harmonyLoginService.submitProfile(
      avatarUri, username, birthDate, heightCm, weightKg,
      measurementSystem, phone, countryRegion, gender
    );
    this.refreshState();
    saveStoreSnapshot();
  }

  deleteCurrentAccount(): string {
    let message: string = this.harmonyLoginService.deleteCurrentAccount();
    this.refreshState();
    saveStoreSnapshot();
    return message;
  }

  clearSessionSilently(): void {
    this.harmonyLoginService.clearSessionSilently();
    this.refreshState();
    saveStoreSnapshot();
  }

  consumeEffect(): LoginEffect | null {
    let snapshot: string = this.harmonyLoginService.consumeEffectSnapshot();
    let payload: LoginEffectPayload = this.parseEffectPayload(snapshot);
    if (payload.type === 'None') {
      return null;
    }

    let effect: LoginEffect = new LoginEffect();
    effect.message = payload.message;
    effect.mode = this.parseMode(payload.mode);
    if (payload.session !== null) {
      effect.session = this.mapSession(payload.session);
    }

    if (payload.type === 'AuthSucceeded' || payload.type === 'ProfileSaved') {
      effect.type = LoginEffectType.AuthSucceeded;
    } else if (payload.type === 'LoggedOut') {
      effect.type = LoginEffectType.LoggedOut;
    } else {
      effect.type = LoginEffectType.ShowMessage;
    }
    return effect;
  }

  private refreshState(): void {
    this.state = this.mapState(this.parseStatePayload(this.harmonyLoginService.stateSnapshot()));
  }

  private parseStatePayload(snapshot: string): LoginStatePayload {
    try {
      return JSON.parse(snapshot) as LoginStatePayload;
    } catch (error) {
      let fallback: LoginStatePayload = {
        mode: 'Login',
        username: '',
        password: '',
        verifyCode: '',
        displayName: '',
        selectedRegion: 'CN',
        currentSession: null,
        isLoading: false,
        isLoggedIn: false,
        errorMessage: '鸿蒙 KMP 登录状态解析失败'
      };
      return fallback;
    }
  }

  private parseEffectPayload(snapshot: string): LoginEffectPayload {
    try {
      let payload: LoginEffectPayload = JSON.parse(snapshot) as LoginEffectPayload;
      return this.normalizeEffectPayload(payload);
    } catch (error) {
      let fallback: LoginEffectPayload = {
        type: 'ShowMessage',
        mode: 'Login',
        session: null,
        message: '鸿蒙 KMP 登录结果解析失败'
      };
      return fallback;
    }
  }

  private normalizeEffectPayload(payload: LoginEffectPayload): LoginEffectPayload {
    let normalized: LoginEffectPayload = {
      type: payload.type,
      mode: payload.mode === undefined ? 'Login' : payload.mode,
      session: payload.session === undefined ? null : payload.session,
      message: payload.message === undefined ? '' : payload.message
    };
    return normalized;
  }

  private mapState(payload: LoginStatePayload): LoginState {
    let state: LoginState = new LoginState();
    state.mode = this.parseMode(payload.mode);
    state.username = payload.username;
    state.password = payload.password;
    state.verifyCode = payload.verifyCode;
    state.displayName = payload.displayName;
    state.selectedRegion = payload.selectedRegion.length > 0 ? payload.selectedRegion : 'CN';
    state.currentSession = payload.currentSession === null ? null : this.mapSession(payload.currentSession);
    state.isLoading = payload.isLoading;
    state.isLoggedIn = payload.isLoggedIn;
    state.errorMessage = payload.errorMessage;
    return state;
  }

  private mapSession(payload: AuthSessionPayload): AuthSession {
    let session: AuthSession = new AuthSession();
    session.account = payload.account;
    session.displayName = payload.displayName;
    session.region = payload.region.length > 0 ? payload.region : 'CN';
    session.isValid = payload.isValid;
    session.isProfileComplete = payload.isProfileComplete === undefined ? false : payload.isProfileComplete;
    return session;
  }

  private parseMode(value: string): AuthMode {
    return value === 'Register' ? AuthMode.Register : AuthMode.Login;
  }

  private cloneState(source: LoginState): LoginState {
    let snapshot: LoginState = new LoginState();
    snapshot.mode = source.mode;
    snapshot.username = source.username;
    snapshot.password = source.password;
    snapshot.verifyCode = source.verifyCode;
    snapshot.displayName = source.displayName;
    snapshot.selectedRegion = source.selectedRegion;
    snapshot.currentSession = source.currentSession === null ? null : this.cloneSession(source.currentSession);
    snapshot.isLoading = source.isLoading;
    snapshot.isLoggedIn = source.isLoggedIn;
    snapshot.errorMessage = source.errorMessage;
    return snapshot;
  }

  private cloneSession(source: AuthSession): AuthSession {
    let snapshot: AuthSession = new AuthSession();
    snapshot.account = source.account;
    snapshot.displayName = source.displayName;
    snapshot.region = source.region;
    snapshot.isValid = source.isValid;
    snapshot.isProfileComplete = source.isProfileComplete;
    return snapshot;
  }
}
