import hilog from '@ohos.hilog';
import {
  ActiveDeviceInfo,
  AuthMode,
  AuthSession,
  LoginEffect,
  LoginEffectType,
  LoginState
} from '../../auth/logic/LoginState';
import { LoginLogicAdapter } from '../../auth/logic/LoginLogicAdapter';
import { saveStoreSnapshot } from './StorePersister';
import {
  syncFromServer,
  syncHealthFromServer,
  setSessionKickedHandler,
  serverLogin,
  serverRegister,
  serverVerifyCode,
  serverLogout,
  serverProfilePut,
  serverSessionCheck,
  serverChangePassword,
  serverResetPassword,
  serverDeleteAccount
} from './MockServerSync';
import { getService, HarmonyLoginServiceContract } from './HarmonyServiceProvider';

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
  email?: string;
  countryRegion?: string;
  gender?: string;
}

interface CurrentUserSessionPayload {
  userId?: string;
}

interface CurrentUserPayload {
  currentSession?: CurrentUserSessionPayload;
}

interface ActiveDeviceInfoPayload {
  deviceId?: string;
  deviceName?: string;
}

interface ProfilePayload {
  avatarUri: string | null;
  username: string;
  birthDate: string;
  heightCm: number | null;
  weightKg: number | null;
  measurementSystem: string;
  phone: string;
  email: string;
  countryRegion: string;
  gender: string | null;
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
  confirmForceLogin: boolean;
  forceLoginActiveDevice: ActiveDeviceInfoPayload | null;
  kickedDialogShown: boolean;
}

interface LoginEffectPayload {
  type: string;
  mode: string;
  session: AuthSessionPayload | null;
  message: string;
  nextRoute?: string;
}

export class KnoiLoginAdapter implements LoginLogicAdapter {
  private readonly harmonyLoginService: HarmonyLoginServiceContract = getService();
  private state: LoginState = new LoginState();

  constructor() {
    this.refreshState();
    // MSRV-019：sync 请求被顶时清会话并回登录页
    setSessionKickedHandler(() => this.handleSessionKicked());
  }

  /** MSRV-019/HARM-007：服务器健康同步 401 被顶时弹确认窗（不持久化，避免级联 syncToServer 再触发 401）。 */
  private handleSessionKicked(): void {
    this.harmonyLoginService.onSessionKicked();
    this.refreshState();
  }

  loadHealthDashboard(): Record<string, Object> | null {
    try {
      const json: string = this.harmonyLoginService.loadHealthSnapshot();
      return JSON.parse(json) as Record<string, Object>;
    } catch (e) { return null; }
  }

  selectHealthScenario(name: string): boolean {
    try {
      const json: string = this.harmonyLoginService.selectHealthScene(name);
      return json === 'true';
    } catch (e) { return false; }
  }

  refreshHealthDashboard(): Record<string, Object> | null {
    try {
      const json: string = this.harmonyLoginService.refreshHealthSnapshot();
      return JSON.parse(json) as Record<string, Object>;
    } catch (e) { return null; }
  }

  saveCardConfiguration(typeNamesCsv: string): Record<string, Object> | null {
    try {
      const json: string = this.harmonyLoginService.saveCardConfig(typeNamesCsv);
      const parsed: Record<string, Object> = JSON.parse(json) as Record<string, Object>;
      const err: Object | undefined = parsed['error'];
      if (err !== undefined) {
        this._lastSaveError = err as string;
        return null;
      }
      this._lastSaveError = '';
      return parsed;
    } catch (e) { return null; }
  }

  healthCardSaveError(): string {
    const err: string = this._lastSaveError;
    this._lastSaveError = '';
    return err;
  }

  private _lastSaveError: string = '';

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
      // HARM-002/003：登录/注册前先做账号发现同步（本地 store 具备服务器账号，MSRV-018 例外），
      // 然后走服务器校验（服务器为权威），staging 服务器结果后驱动 KMP 状态机。
      const typedMode: AuthMode = this.state.mode;
      const typedAccount: string = this.state.username;
      const typedPassword: string = this.state.password;
      const typedVerifyCode: string = this.state.verifyCode;
      const typedDisplayName: string = this.state.displayName;
      const typedRegion: string = this.state.selectedRegion;
      await syncFromServer(this.harmonyLoginService);
      if (typedMode === AuthMode.Register) {
        this.harmonyLoginService.setRegisterMode();
      } else {
        this.harmonyLoginService.setLoginMode();
      }
      this.harmonyLoginService.setUsername(typedAccount);
      this.harmonyLoginService.setPassword(typedPassword);
      this.harmonyLoginService.setVerifyCode(typedVerifyCode);
      this.harmonyLoginService.setDisplayName(typedDisplayName);
      this.harmonyLoginService.setRegion(typedRegion);

      if (typedMode === AuthMode.Register) {
        const outcome = await serverRegister(
          typedAccount, typedPassword, typedVerifyCode, typedRegion, typedDisplayName);
        if (outcome.kind === 'ok' && outcome.session !== undefined) {
          this.stageSession(outcome.session);
        } else if (outcome.kind === 'error') {
          this.stageError(outcome.code ?? 'NETWORK_ERROR');
        }
        this.harmonyLoginService.submit();
      } else {
        const outcome = await serverLogin(typedAccount, typedPassword, false);
        if (outcome.kind === 'ok' && outcome.session !== undefined) {
          this.stageSession(outcome.session);
        } else if (outcome.kind === 'conflict') {
          this.stageForceLogin(outcome.activeDevice);
        } else {
          this.stageError(outcome.code ?? 'NETWORK_ERROR');
        }
        this.harmonyLoginService.submit();
      }
      const storeAfter: string = this.harmonyLoginService.exportStoreSnapshot();
      hilog.info(0x0001, 'demo_persist', 'store after submit: ' + storeAfter);
      this.refreshState();
      this.persistSnapshot();
      // HARM-006：登录成功后拉取服务器健康数据，使鸿蒙与 Android/iOS 互通。
      // 注意：只同步健康，不同步 auth——auth 拉取会重建 facade 丢失 AuthSucceeded effect。
      if (this.state.currentSession !== null && this.state.currentSession.isValid) {
        await syncHealthFromServer(this.harmonyLoginService);
        this.refreshState();
      }
    } catch (error) {
      this.state.errorMessage = 'auth_submit_failed';
      hilog.error(0x0001, 'demo_persist', 'submit failed');
    }
  }

  /** HARM-002：二次确认通过——先服务器 force 顶号，再驱动 KMP 状态机。 */
  async confirmForceLogin(): Promise<void> {
    hilog.info(0x0001, 'demo_persist', 'KnoiLoginAdapter.confirmForceLogin() called');
    try {
      const account: string = this.state.username;
      const password: string = this.state.password;
      const outcome = await serverLogin(account, password, true);
      if (outcome.kind === 'ok' && outcome.session !== undefined) {
        this.stageSession(outcome.session);
      } else {
        this.stageError(outcome.code ?? 'NETWORK_ERROR');
      }
      this.harmonyLoginService.confirmForceLogin();
      this.refreshState();
      this.persistSnapshot();
    } catch (error) {
      this.state.errorMessage = 'auth_submit_failed';
      hilog.error(0x0001, 'demo_persist', 'confirmForceLogin failed');
    }
  }

  /** HARM-002：取消二次确认——清 staging 并复位状态机。 */
  cancelForceLogin(): void {
    this.harmonyLoginService.clearStaged();
    this.harmonyLoginService.cancelForceLogin();
    this.refreshState();
  }

  logout(): void {
    const userId: string = this.currentUserId();
    if (userId.length > 0) {
      serverLogout(userId).catch(() => {
        hilog.warn(0x0001, 'demo_persist', 'serverLogout failed');
      });
    }
    this.harmonyLoginService.logout();
    this.refreshState();
    this.persistSnapshot();
  }

  requestVerifyCode(account: string): string {
    serverVerifyCode(account).catch(() => {
      hilog.warn(0x0001, 'demo_persist', 'serverVerifyCode failed');
    });
    let message: string = this.harmonyLoginService.requestVerifyCode(account);
    this.saveSnapshotIfSucceeded(message);
    return message;
  }

  requestResentVerifyCode(account: string): string {
    serverVerifyCode(account).catch(() => {
      hilog.warn(0x0001, 'demo_persist', 'serverVerifyCode failed');
    });
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
    serverResetPassword(account, newPassword).catch(() => {
      hilog.warn(0x0001, 'demo_persist', 'serverResetPassword skipped');
    });
    let message: string = this.harmonyLoginService.resetPassword(account, newPassword);
    this.refreshState();
    this.persistSnapshot();
    return message;
  }

  changePassword(account: string, oldPassword: string, newPassword: string): string {
    serverChangePassword(account, oldPassword, newPassword).catch(() => {
      hilog.warn(0x0001, 'demo_persist', 'serverChangePassword skipped');
    });
    let message: string = this.harmonyLoginService.changePassword(account, oldPassword, newPassword);
    this.saveSnapshotIfSucceeded(message);
    return message;
  }

  submitProfile(
    avatarUri: string, username: string, birthDate: string,
    heightCm: number, weightKg: number, measurementSystem: string,
    phone: string, email: string, countryRegion: string, gender: string
  ): void {
    // HARM-005：尽力同步资料到服务器（服务器为权威），本地提交保证 UI 即时更新。
    const userId: string = this.currentUserId();
    if (userId.length > 0) {
      const profileJson: string = this.buildProfileJson(
        avatarUri, username, birthDate, heightCm, weightKg,
        measurementSystem, phone, email, countryRegion, gender);
      serverProfilePut(userId, profileJson).then((code: string) => {
        if (code.length === 0) {
          hilog.info(0x0001, 'demo_persist', 'serverProfilePut completed');
        } else {
          hilog.warn(0x0001, 'demo_persist', 'serverProfilePut failed: ' + code);
        }
      }).catch(() => {
        hilog.warn(0x0001, 'demo_persist', 'serverProfilePut skipped');
      });
    }
    this.harmonyLoginService.submitProfile(
      avatarUri, username, birthDate, heightCm, weightKg,
      measurementSystem, phone, email, countryRegion, gender
    );
    this.refreshState();
    this.persistSnapshot();
  }

  profileDefaultUsername(account: string): string { return this.harmonyLoginService.profileDefaultUsername(account); }
  profileDefaultPhone(account: string): string { return this.harmonyLoginService.profileDefaultPhone(account); }
  profileDefaultEmail(account: string): string { return this.harmonyLoginService.profileDefaultEmail(account); }

  currentUserId(): string {
    try {
      const snapshot: string = this.harmonyLoginService.exportStoreSnapshot();
      const parsed: CurrentUserPayload = JSON.parse(snapshot) as CurrentUserPayload;
      return parsed.currentSession?.userId ?? '';
    } catch (e) {
      return '';
    }
  }

  deleteCurrentAccount(): string {
    const userId: string = this.currentUserId();
    if (userId.length > 0) {
      serverDeleteAccount(userId).catch(() => {
        hilog.warn(0x0001, 'demo_persist', 'serverDeleteAccount skipped');
      });
    }
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

  /** MSRV-019：被顶弹窗确认，清会话并回登录页。 */
  confirmKickedDialog(): void {
    this.harmonyLoginService.confirmKickedDialog();
    this.refreshState();
    this.persistSnapshot();
  }

  /** HARM-004：前台周期性会话校验（服务器懒校验三态，MSRV-019）。 */
  checkSessionOnForeground(): void {
    this.performSessionCheck().catch(() => {
      hilog.warn(0x0001, 'demo_persist', 'session check failed');
    });
  }

  private async performSessionCheck(): Promise<void> {
    if (!this.state.isLoggedIn) {
      return;
    }
    const userId: string = this.currentUserId();
    if (userId.length === 0) {
      return;
    }
    const outcome: string = await serverSessionCheck(userId);
    if (outcome === 'kicked') {
      this.harmonyLoginService.onSessionKicked();
      this.refreshState();
      this.persistSnapshot();
    } else if (outcome === 'expired') {
      this.harmonyLoginService.stageSessionExpired();
      this.harmonyLoginService.checkSessionOnForeground();
      this.refreshState();
    } else {
      this.harmonyLoginService.checkSessionOnForeground();
      this.refreshState();
    }
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

    effect.nextRoute = payload.nextRoute || 'SignedIn';

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
    } else if (payload.type === 'SessionKicked') {
      effect.type = LoginEffectType.SessionKicked;
    } else if (payload.type === 'ShowForceLoginDialog') {
      effect.type = LoginEffectType.ShowForceLoginDialog;
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
        errorMessage: 'auth_submit_failed',
        confirmForceLogin: false,
        forceLoginActiveDevice: null,
        kickedDialogShown: false
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
      message: payload.message === undefined ? '' : payload.message,
      nextRoute: payload.nextRoute === undefined ? 'SignedIn' : payload.nextRoute
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
    state.confirmForceLogin = payload.confirmForceLogin === undefined ? false : payload.confirmForceLogin;
    state.forceLoginActiveDevice = this.mapActiveDevice(payload.forceLoginActiveDevice);
    state.kickedDialogShown = payload.kickedDialogShown === undefined ? false : payload.kickedDialogShown;
    return state;
  }

  private mapActiveDevice(payload: ActiveDeviceInfoPayload | null | undefined): ActiveDeviceInfo | null {
    if (payload === null || payload === undefined) {
      return null;
    }
    const device: ActiveDeviceInfo = new ActiveDeviceInfo();
    device.deviceId = payload.deviceId === undefined ? '' : payload.deviceId;
    device.deviceName = payload.deviceName === undefined ? '' : payload.deviceName;
    return device;
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
    session.email = payload.email === undefined ? '' : payload.email;
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
    snapshot.confirmForceLogin = source.confirmForceLogin;
    snapshot.forceLoginActiveDevice = source.forceLoginActiveDevice === null ? null : this.cloneActiveDevice(source.forceLoginActiveDevice);
    snapshot.kickedDialogShown = source.kickedDialogShown;
    return snapshot;
  }

  private cloneActiveDevice(source: ActiveDeviceInfo): ActiveDeviceInfo {
    const clone: ActiveDeviceInfo = new ActiveDeviceInfo();
    clone.deviceId = source.deviceId;
    clone.deviceName = source.deviceName;
    return clone;
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
    snapshot.email = source.email;
    snapshot.countryRegion = source.countryRegion;
    snapshot.gender = source.gender;
    return snapshot;
  }

  /** HARM-002/003：把服务器会话装入 staging（mini store 形态，桥复用 MockAuthStoreJson）。 */
  private stageSession(session: Object): void {
    const payload = `{"accounts":[],"currentSession":${JSON.stringify(session)},"verifyCodes":[],"defaultAccountsInitialized":true}`;
    const staged: boolean = this.harmonyLoginService.stageServerLoginResult(payload);
    hilog.info(0x0001, 'demo_persist', 'stageServerLoginResult=' + JSON.stringify(staged));
  }

  /** HARM-002：把服务器 409 activeDevice 装入 staging。 */
  private stageForceLogin(activeDevice: Object | undefined): void {
    if (activeDevice === undefined) {
      this.harmonyLoginService.stageForceLogin('{}');
    } else {
      this.harmonyLoginService.stageForceLogin(JSON.stringify(activeDevice));
    }
  }

  /** HARM-002/003：把服务器业务错误码装入 staging（桥映射到既有 MockError 语义）。 */
  private stageError(code: string): void {
    this.harmonyLoginService.stageServerError(code);
  }

  /** HARM-005：构造服务器 /api/auth/profile 需要的 profile JSON。 */
  private buildProfileJson(
    avatarUri: string, username: string, birthDate: string,
    heightCm: number, weightKg: number, measurementSystem: string,
    phone: string, email: string, countryRegion: string, gender: string
  ): string {
    const profile: ProfilePayload = {
      avatarUri: avatarUri.length > 0 ? avatarUri : null,
      username: username,
      birthDate: birthDate,
      heightCm: heightCm > 0 ? heightCm : null,
      weightKg: weightKg > 0 ? weightKg : null,
      measurementSystem: measurementSystem === 'Imperial' ? 'IMPERIAL' : 'METRIC',
      phone: phone,
      email: email,
      countryRegion: countryRegion,
      gender: gender === 'Female' ? 'FEMALE' : (gender === 'Male' ? 'MALE' : null)
    };
    return JSON.stringify(profile);
  }
}
