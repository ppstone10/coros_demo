import hilog from '@ohos.hilog';
import {
  AuthMode,
  AuthSession,
  LoginEffect,
  LoginEffectType,
  LoginState
} from './LoginState';
import { LoginLogicAdapter } from './LoginLogicAdapter';
import { HarmonyLoginService } from '../knoi/provider';
import { saveStoreSnapshot } from './StorePersister';
import { getService } from './HarmonyServiceProvider';

interface AuthSessionPayload {
  account: string;
  displayName: string;
  region: string;
  isValid: boolean;
  isProfileComplete: boolean;
  avatarUri?: string;
  birthDate?: string;
  heightCm?: number;
  weightKg?: number;
  measurementSystem?: string;
  phone?: string;
  countryRegion?: string;
  gender?: string;
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
  private readonly harmonyLoginService: HarmonyLoginService = getService();
  private state: LoginState = new LoginState();

  constructor() {
    this.refreshState();
  }

  loadHealthDashboard(): object | null {
    try {
      const json = this.harmonyLoginService.loadHealthSnapshot();
      return JSON.parse(json);
    } catch (e) { return null; }
  }

  selectHealthScenario(name: string): object | null {
    try {
      const json = this.harmonyLoginService.selectHealthScene(name);
      return JSON.parse(json);
    } catch (e) { return null; }
  }

  saveCardConfiguration(typeNamesCsv: string): object | null {
    try {
      const json = this.harmonyLoginService.saveCardConfig(typeNamesCsv);
      return JSON.parse(json);
    } catch (e) { return null; }
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
    hilog.info(0x0001, 'demo_persist', 'KnoiLoginAdapter.submit() called');
    try {
      this.harmonyLoginService.submit();
      const storeAfter: string = this.harmonyLoginService.exportStoreSnapshot();
      hilog.info(0x0001, 'demo_persist', 'store after submit: ' + storeAfter);
      this.refreshState();
      this.persistSnapshot();
    } catch (error) {
      this.state.errorMessage = 'auth_submit_failed';
      hilog.error(0x0001, 'demo_persist', 'submit failed');
    }
  }

  logout(): void {
    this.harmonyLoginService.logout();
    this.refreshState();
    this.persistSnapshot();
  }

  requestVerifyCode(account: string): string {
    let message: string = this.harmonyLoginService.requestVerifyCode(account);
    this.saveSnapshotIfSucceeded(message);
    return message;
  }

  requestResentVerifyCode(account: string): string {
    let message: string = this.harmonyLoginService.requestResentVerifyCode(account);
    this.saveSnapshotIfSucceeded(message);
    return message;
  }

  verifyCode(account: string, code: string): string {
    return this.harmonyLoginService.verifyCode(account, code);
  }

  verifyCodeRemainingSeconds(account: string): number {
    return this.harmonyLoginService.verifyCodeRemainingSeconds(account);
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
    this.persistSnapshot();
    return message;
  }

  changePassword(account: string, oldPassword: string, newPassword: string): string {
    let message: string = this.harmonyLoginService.changePassword(account, oldPassword, newPassword);
    this.saveSnapshotIfSucceeded(message);
    return message;
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
    this.persistSnapshot();
  }

  deleteCurrentAccount(): string {
    let message: string = this.harmonyLoginService.deleteCurrentAccount();
    this.refreshState();
    this.persistSnapshot();
    return message;
  }

  clearSessionSilently(): void {
    this.harmonyLoginService.clearSessionSilently();
    this.refreshState();
    this.persistSnapshot();
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

    if (payload.type === 'AuthSucceeded') {
      effect.type = LoginEffectType.AuthSucceeded;
    } else if (payload.type === 'ProfileSaved') {
      effect.type = LoginEffectType.ProfileSaved;
    } else if (payload.type === 'NavigateHome') {
      effect.type = LoginEffectType.NavigateHome;
    } else if (payload.type === 'LoggedOut') {
      effect.type = LoginEffectType.LoggedOut;
    } else if (payload.type === 'AccountDeleted') {
      effect.type = LoginEffectType.AccountDeleted;
    } else if (payload.type === 'SessionExpired') {
      effect.type = LoginEffectType.SessionExpired;
    } else {
      effect.type = LoginEffectType.ShowMessage;
    }
    return effect;
  }

  private refreshState(): void {
    this.state = this.mapState(this.parseStatePayload(this.harmonyLoginService.stateSnapshot()));
  }

  private saveSnapshotIfSucceeded(message: string): void {
    if (message.length === 0) {
      this.persistSnapshot();
    }
  }

  private persistSnapshot(): void {
    hilog.info(0x0001, 'demo_persist', 'persistSnapshot called');
    if (!saveStoreSnapshot(this.harmonyLoginService)) {
      hilog.error(0x0001, 'demo_persist', 'persistSnapshot: saveStoreSnapshot returned false');
      console.error('login store snapshot was not persisted');
    }
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
        errorMessage: 'auth_submit_failed'
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
        message: 'auth_submit_failed'
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
    session.avatarUri = payload.avatarUri === undefined ? '' : payload.avatarUri;
    session.birthDate = payload.birthDate === undefined ? '' : payload.birthDate;
    session.heightCm = payload.heightCm === undefined ? 0 : payload.heightCm;
    session.weightKg = payload.weightKg === undefined ? 0 : payload.weightKg;
    session.measurementSystem = payload.measurementSystem === undefined ? 'Metric' : payload.measurementSystem;
    session.phone = payload.phone === undefined ? '' : payload.phone;
    session.countryRegion = payload.countryRegion === undefined || payload.countryRegion.length === 0 ?
      session.region : payload.countryRegion;
    session.gender = payload.gender === undefined ? '' : payload.gender;
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
    snapshot.avatarUri = source.avatarUri;
    snapshot.birthDate = source.birthDate;
    snapshot.heightCm = source.heightCm;
    snapshot.weightKg = source.weightKg;
    snapshot.measurementSystem = source.measurementSystem;
    snapshot.phone = source.phone;
    snapshot.countryRegion = source.countryRegion;
    snapshot.gender = source.gender;
    return snapshot;
  }
}
