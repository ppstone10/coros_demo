import http from '@ohos.net.http';
import hilog from '@ohos.hilog';
import { deviceId } from './HarmonyDeviceId';
import { getService, HarmonyLoginServiceContract } from './HarmonyServiceProvider';

const TAG = 'demo_mock_sync';

/**
 * Mock 服务器地址配置（MSRV-007）。
 * 注意：鸿蒙真机/模拟器不能使用 Android 模拟器的 10.0.2.2，必须填宿主机在局域网中的 IP
 * （与 mock server 同一网段，例如 192.168.x.x）。运行前按本机局域网 IP 修改。
 */
export const MOCK_SERVER_BASE_URL: string = 'http://192.168.33.204:3000';

interface HttpOutcome {
  status: number;
  body: string;
}

interface SyncAuthResponse {
  store?: SyncAuthStore;
}

interface SessionPayload {
  userId?: string;
  isValid?: boolean;
  account?: string;
  displayName?: string;
  region?: string;
}

interface AccountPayload {
  userId?: string;
  account?: string;
  displayName?: string;
  region?: string;
  passwordHash?: string;
  profile?: Object;
}

interface StoreSnapshotPayload {
  accounts?: AccountPayload[];
  currentSession?: SessionPayload;
  verifyCodes?: Object[];
  defaultAccountsInitialized?: boolean;
}

interface SyncAuthStore {
  accounts?: Object[];
  currentSession?: SessionPayload;
  verifyCodes?: Object[];
  defaultAccountsInitialized?: boolean;
}

interface SyncHealthItem {
  userId?: string;
}

interface SyncHealthRequestPayload {
  snapshots: Object[];
}

interface SyncHealthPayload {
  snapshots?: Object[];
}

interface SyncHealthSingleResponse {
  snapshot?: Object;
}

interface ErrorBody {
  code?: string;
  message?: string;
  activeDevice?: Object;
}

interface ErrorEnvelope {
  error?: ErrorBody;
}

interface SessionEnvelope {
  session?: Object;
}

interface LoginPayload {
  account: string;
  password: string;
  deviceId: string;
  force: boolean;
}

interface RegisterPayload {
  account: string;
  password: string;
  verifyCode: string;
  region: string;
  displayName: string;
  deviceId: string;
}

interface AccountOnlyPayload {
  account: string;
}

interface UserIdPayload {
  userId: string;
}

interface ChangePasswordPayload {
  account: string;
  oldPassword: string;
  newPassword: string;
}

interface ResetPasswordPayload {
  account: string;
  newPassword: string;
}

/** HARM-001：服务器登录结果（与 Android RemoteAuthRepository.login 语义对齐）。 */
export interface ServerLoginOutcome {
  kind: string;
  session?: Object;
  activeDevice?: Object;
  code?: string;
}

function currentUserIdOf(storeSnapshot: string): string {
  try {
    const parsed = JSON.parse(storeSnapshot) as StoreSnapshotPayload;
    return parsed.currentSession?.userId ?? '';
  } catch (e) {
    return '';
  }
}

function thisHasValidSession(storeSnapshot: string): boolean {
  try {
    const parsed = JSON.parse(storeSnapshot) as StoreSnapshotPayload;
    const session = parsed.currentSession;
    return session !== undefined && session !== null && session.isValid === true;
  } catch (e) {
    return false;
  }
}

function parseStorePayload(storeSnapshot: string): StoreSnapshotPayload {
  try {
    return JSON.parse(storeSnapshot) as StoreSnapshotPayload;
  } catch (e) {
    return {};
  }
}

/**
 * 合并本地与服务器 auth store：账号按 userId 去重（服务器优先），会话以本地有效会话为准
 * （服务器无效会话不清本地登录态）。避免"整体替换"丢失种子账号/其他账号，导致
 * 后续登录其他服务器账号时报"账号不存在"。
 */
function mergeAuthStores(localJson: string, serverStore: SyncAuthStore): SyncAuthStore {
  const local = parseStorePayload(localJson);
  const byId: Map<string, AccountPayload> = new Map();
  (local.accounts ?? []).forEach((a) => {
    const item = a as AccountPayload;
    if (item && item.userId) byId.set(item.userId, item);
  });
  (serverStore.accounts ?? []).forEach((a) => {
    const item = a as AccountPayload;
    if (item && item.userId) byId.set(item.userId, item);
  });
  const accounts: Object[] = Array.from(byId.values());
  const localSession = local.currentSession;
  const session: SessionPayload | undefined =
    localSession && localSession.isValid ? localSession : undefined;
  return {
    accounts,
    currentSession: session,
    verifyCodes: serverStore.verifyCodes ?? [],
    defaultAccountsInitialized: true,
  };
}

/**
 * MSRV-019/HARM-007：显式会话被顶回调（由健康读写 401 触发）。
 * `kickNotified` 幂等守卫：同一"被顶事件"只通知一次，避免 saveStoreSnapshot →
 * syncToServer → 401 → 通知 → 再次 persist 的级联循环（弹窗不断弹出）；
 * 健康同步成功后复位，下次真实被顶可再次检测。
 */
let sessionKickedHandler: (() => void) | null = null;
let kickNotified: boolean = false;

export function setSessionKickedHandler(handler: (() => void) | null): void {
  sessionKickedHandler = handler;
}

export function resetKickNotified(): void {
  kickNotified = false;
}

function maybeNotifyKicked(status: number, body: string): void {
  if (status === 401 && body.indexOf('SESSION_EXPIRED_ELSEWHERE') >= 0) {
    if (kickNotified) {
      return;
    }
    kickNotified = true;
    if (sessionKickedHandler !== null) {
      sessionKickedHandler();
    }
  }
}

/** 统一请求入口：携带 X-Device-Id（HARM-001），仅网络错误 reject，HTTP 非 2xx 正常返回。 */
function request(method: http.RequestMethod, url: string, body?: string): Promise<HttpOutcome> {
  return new Promise<HttpOutcome>((resolve, reject) => {
    const httpRequest = http.createHttp();
    const options: http.HttpRequestOptions = {
      method: method,
      header: {
        'Content-Type': 'application/json',
        'X-Device-Id': deviceId(),
      },
      extraData: body,
      connectTimeout: 5000,
      readTimeout: 5000,
    };
    httpRequest.request(
      url,
      options,
      (err: Error, data: http.HttpResponse) => {
        httpRequest.destroy();
        if (err) {
          hilog.error(0x0001, TAG, 'request failed: ' + JSON.stringify(err));
          reject(err);
          return;
        }
        const code: number = data.responseCode;
        const result: string = data.result as string;
        hilog.info(0x0001, TAG, method + ' ' + url + ' -> ' + code);
        resolve({ status: code, body: result });
      }
    );
  });
}

function errorCodeOf(body: string): string {
  try {
    const parsed = JSON.parse(body) as ErrorEnvelope;
    const code = parsed.error?.code;
    return code !== undefined && code !== null && code.length > 0 ? code : 'AUTH_PERSIST_FAILED';
  } catch (e) {
    return 'AUTH_PERSIST_FAILED';
  }
}

function activeDeviceOf(body: string): Object | undefined {
  try {
    const parsed = JSON.parse(body) as ErrorEnvelope;
    return parsed.error?.activeDevice;
  } catch (e) {
    return undefined;
  }
}

function sessionOf(body: string): Object | undefined {
  try {
    const parsed = JSON.parse(body) as SessionEnvelope;
    return parsed.session;
  } catch (e) {
    return undefined;
  }
}

// ---- HARM-002/003/005：认证服务器调用（镜像 Android RemoteAuthRepository） ----

/** HARM-002：登录走服务器（force 顶号二次确认）。 */
export async function serverLogin(account: string, password: string, force: boolean): Promise<ServerLoginOutcome> {
  try {
    const payload: LoginPayload = {
      account: account,
      password: password,
      deviceId: deviceId(),
      force: force,
    };
    const resp = await request(
      http.RequestMethod.POST,
      `${MOCK_SERVER_BASE_URL}/api/auth/login`,
      JSON.stringify(payload)
    );
    if (resp.status === 409 && resp.body.indexOf('SESSION_ACTIVE_ELSEWHERE') >= 0) {
      return { kind: 'conflict', activeDevice: activeDeviceOf(resp.body) };
    }
    if (resp.status >= 200 && resp.status < 300) {
      return { kind: 'ok', session: sessionOf(resp.body) };
    }
    return { kind: 'error', code: errorCodeOf(resp.body) };
  } catch (e) {
    return { kind: 'error', code: 'NETWORK_ERROR' };
  }
}

/** HARM-003：注册走服务器。 */
export async function serverRegister(
  account: string,
  password: string,
  verifyCode: string,
  region: string,
  displayName: string
): Promise<ServerLoginOutcome> {
  try {
    const payload: RegisterPayload = {
      account: account,
      password: password,
      verifyCode: verifyCode,
      region: region,
      displayName: displayName,
      deviceId: deviceId(),
    };
    const resp = await request(
      http.RequestMethod.POST,
      `${MOCK_SERVER_BASE_URL}/api/auth/register`,
      JSON.stringify(payload)
    );
    if (resp.status >= 200 && resp.status < 300) {
      return { kind: 'ok', session: sessionOf(resp.body) };
    }
    return { kind: 'error', code: errorCodeOf(resp.body) };
  } catch (e) {
    return { kind: 'error', code: 'NETWORK_ERROR' };
  }
}

/** 发送验证码到服务器（注册/找回密码时服务器侧生成）。 */
export async function serverVerifyCode(account: string): Promise<boolean> {
  try {
    const payload: AccountOnlyPayload = { account: account };
    const resp = await request(
      http.RequestMethod.POST,
      `${MOCK_SERVER_BASE_URL}/api/auth/verify-code`,
      JSON.stringify(payload)
    );
    return resp.status >= 200 && resp.status < 300;
  } catch (e) {
    return false;
  }
}

/** HARM-005：登出走服务器（按 userId 作用域化）。 */
export async function serverLogout(userId: string): Promise<boolean> {
  try {
    const payload: UserIdPayload = { userId: userId };
    const resp = await request(
      http.RequestMethod.POST,
      `${MOCK_SERVER_BASE_URL}/api/auth/logout`,
      JSON.stringify(payload)
    );
    return resp.status >= 200 && resp.status < 300;
  } catch (e) {
    return false;
  }
}

/** HARM-005：资料提交走服务器（成功返回空串，失败返回错误码）。 */
export async function serverProfilePut(userId: string, profileJson: string): Promise<string> {
  try {
    const body = `{"userId":${JSON.stringify(userId)},"profile":${profileJson}}`;
    const resp = await request(http.RequestMethod.PUT, `${MOCK_SERVER_BASE_URL}/api/auth/profile`, body);
    if (resp.status >= 200 && resp.status < 300) {
      return '';
    }
    return errorCodeOf(resp.body);
  } catch (e) {
    return 'NETWORK_ERROR';
  }
}

/** 修改密码走服务器（成功返回空串，失败返回错误码）。 */
export async function serverChangePassword(account: string, oldPassword: string, newPassword: string): Promise<string> {
  try {
    const payload: ChangePasswordPayload = {
      account: account,
      oldPassword: oldPassword,
      newPassword: newPassword,
    };
    const resp = await request(
      http.RequestMethod.POST,
      `${MOCK_SERVER_BASE_URL}/api/auth/password/change`,
      JSON.stringify(payload)
    );
    if (resp.status >= 200 && resp.status < 300) {
      return '';
    }
    return errorCodeOf(resp.body);
  } catch (e) {
    return 'NETWORK_ERROR';
  }
}

/** 重置密码走服务器（成功返回空串，失败返回错误码）。 */
export async function serverResetPassword(account: string, newPassword: string): Promise<string> {
  try {
    const payload: ResetPasswordPayload = {
      account: account,
      newPassword: newPassword,
    };
    const resp = await request(
      http.RequestMethod.POST,
      `${MOCK_SERVER_BASE_URL}/api/auth/password/reset`,
      JSON.stringify(payload)
    );
    if (resp.status >= 200 && resp.status < 300) {
      return '';
    }
    return errorCodeOf(resp.body);
  } catch (e) {
    return 'NETWORK_ERROR';
  }
}

/** 注销账号走服务器（成功返回空串，失败返回错误码）。 */
export async function serverDeleteAccount(userId: string): Promise<string> {
  try {
    const resp = await request(
      http.RequestMethod.DELETE,
      `${MOCK_SERVER_BASE_URL}/api/auth/account`,
      JSON.stringify({ userId: userId })
    );
    if (resp.status >= 200 && resp.status < 300) {
      return '';
    }
    return errorCodeOf(resp.body);
  } catch (e) {
    return 'NETWORK_ERROR';
  }
}

/** HARM-004：会话懒校验三态（MSRV-019）。网络失败返回 offline（沿用本地）。 */
export async function serverSessionCheck(userId: string): Promise<string> {
  try {
    const resp = await request(
      http.RequestMethod.GET,
      `${MOCK_SERVER_BASE_URL}/api/auth/session?userId=${encodeURIComponent(userId)}`
    );
    if (resp.status >= 200 && resp.status < 300) {
      return 'ok';
    }
    if (resp.status === 401) {
      if (resp.body.indexOf('SESSION_EXPIRED_ELSEWHERE') >= 0) {
        return 'kicked';
      }
      if (resp.body.indexOf('AUTH_REQUIRED') >= 0) {
        return 'expired';
      }
    }
    return 'offline';
  } catch (e) {
    return 'offline';
  }
}

/** HARM-004：冷启动/回前台会话懒校验（服务器三态，MSRV-019）。被顶弹窗，失效清本地会话。 */
export async function performColdStartSessionCheck(): Promise<void> {
  try {
    const svc: HarmonyLoginServiceContract = getService();
    const snapshot: string = svc.exportStoreSnapshot();
    if (!thisHasValidSession(snapshot)) {
      return;
    }
    const userId: string = currentUserIdOf(snapshot);
    if (userId.length === 0) {
      return;
    }
    const outcome: string = await serverSessionCheck(userId);
    if (outcome === 'kicked') {
      svc.onSessionKicked();
    } else if (outcome === 'expired') {
      svc.clearSessionSilently();
    }
  } catch (e) {
    // 网络失败沿用本地会话，不登出
  }
}

/**
 * HARM-006：从服务器拉取健康快照（GET /api/health/:userId）。
 * 失败不阻断：沿用本地缓存。
 */
export async function syncHealthFromServer(service?: HarmonyLoginServiceContract): Promise<boolean> {
  const svc: HarmonyLoginServiceContract = service ?? getService();
  try {
    const storeSnapshot: string = svc.exportStoreSnapshot();
    const currentUserId: string = currentUserIdOf(storeSnapshot);
    if (currentUserId.length === 0) {
      return false;
    }
    const resp = await request(
      http.RequestMethod.GET,
      `${MOCK_SERVER_BASE_URL}/api/health/${encodeURIComponent(currentUserId)}`
    );
    if (resp.status >= 200 && resp.status < 300) {
      const health: SyncHealthSingleResponse = JSON.parse(resp.body) as SyncHealthSingleResponse;
      if (health.snapshot) {
        const payload: SyncHealthRequestPayload = { snapshots: [health.snapshot] };
        svc.restoreHealthSnapshot(JSON.stringify(payload));
      }
      resetKickNotified();
      hilog.info(0x0001, TAG, 'syncHealthFromServer completed');
      return true;
    }
    maybeNotifyKicked(resp.status, resp.body);
    hilog.warn(0x0001, TAG, 'syncHealthFromServer http ' + resp.status);
    return false;
  } catch (error) {
    hilog.warn(0x0001, TAG, 'syncHealthFromServer skipped: ' + JSON.stringify(error));
    return false;
  }
}

/**
 * HARM-006：把当前用户健康快照提交到服务器（PUT /api/health/:userId）。
 * 只提交当前登录用户的数据，避免覆盖其他用户。失败不抛出：本地缓存保留。
 */
export async function syncToServer(service?: HarmonyLoginServiceContract): Promise<boolean> {
  const svc: HarmonyLoginServiceContract = service ?? getService();
  try {
    const storeSnapshot: string = svc.exportStoreSnapshot();
    const currentUserId: string = currentUserIdOf(storeSnapshot);
    if (currentUserId.length === 0) {
      return false;
    }
    const healthSnapshot: string = svc.exportHealthSnapshot();
    let target: Object | undefined = undefined;
    try {
      const parsed = JSON.parse(healthSnapshot) as SyncHealthPayload;
      const mine: Object[] = (parsed.snapshots ?? []).filter((s) => {
        const item = s as SyncHealthItem;
        return item.userId === currentUserId;
      });
      if (mine.length > 0) {
        target = mine[0];
      }
    } catch (e) {
      hilog.warn(0x0001, TAG, 'health filter skipped: ' + JSON.stringify(e));
    }
    if (target === undefined) {
      return false;
    }
    const resp = await request(
      http.RequestMethod.PUT,
      `${MOCK_SERVER_BASE_URL}/api/health/${encodeURIComponent(currentUserId)}`,
      JSON.stringify(target)
    );
    if (resp.status >= 200 && resp.status < 300) {
      resetKickNotified();
      hilog.info(0x0001, TAG, 'syncToServer completed');
      return true;
    }
    maybeNotifyKicked(resp.status, resp.body);
    hilog.warn(0x0001, TAG, 'syncToServer http ' + resp.status);
    return false;
  } catch (error) {
    hilog.warn(0x0001, TAG, 'syncToServer skipped: ' + JSON.stringify(error));
    return false;
  }
}

/**
 * 启动/登录前同步（MSRV-008-SYNC/HARM-006）：
 * - 未登录：拉取账号列表合并进本地（登录发现，MSRV-018 例外），不重建 facade；
 * - 已登录：仅拉健康数据（不再整文档拉 auth，避免重建 facade 与设备误判）。
 * 失败不阻断启动：沿用本地缓存。
 */
export async function syncFromServer(service?: HarmonyLoginServiceContract): Promise<boolean> {
  const svc: HarmonyLoginServiceContract = service ?? getService();
  try {
    const localStore: string = svc.exportStoreSnapshot();
    const localValid: boolean = thisHasValidSession(localStore);
    const currentUserId: string = currentUserIdOf(localStore);

    if (!localValid || currentUserId.length === 0) {
      const accountsResp = await request(http.RequestMethod.GET, `${MOCK_SERVER_BASE_URL}/api/sync/auth`);
      if (accountsResp.status >= 200 && accountsResp.status < 300) {
        const parsed = JSON.parse(accountsResp.body) as SyncAuthResponse;
        if (parsed.store && Array.isArray(parsed.store.accounts)) {
          const merged = mergeAuthStores(localStore, parsed.store);
          svc.mergeAccounts(JSON.stringify(merged));
        }
      }
      hilog.info(0x0001, TAG, 'syncFromServer (account discovery) completed');
      return true;
    }

    await syncHealthFromServer(svc);
    hilog.info(0x0001, TAG, 'syncFromServer completed');
    return true;
  } catch (error) {
    hilog.warn(0x0001, TAG, 'syncFromServer skipped: ' + JSON.stringify(error));
    return false;
  }
}
