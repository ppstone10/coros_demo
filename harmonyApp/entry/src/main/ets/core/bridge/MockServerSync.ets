import http from '@ohos.net.http';
import hilog from '@ohos.hilog';
import { getService, HarmonyLoginServiceContract } from './HarmonyServiceProvider';

const TAG = 'demo_mock_sync';

/**
 * Mock 服务器地址配置（MSRV-007）。
 * 注意：鸿蒙真机/模拟器不能使用 Android 模拟器的 10.0.2.2，必须填宿主机在局域网中的 IP
 * （与 mock server 同一网段，例如 192.168.x.x）。运行前按本机局域网 IP 修改。
 */
export const MOCK_SERVER_BASE_URL: string = 'http://192.168.33.204:3000';

interface SyncAuthResponse {
  store?: SyncAuthStore;
}

interface SyncHealthResponse {
  snapshots?: Object[];
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

interface SyncAuthRequestPayload {
  store: SyncAuthStore;
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

/** MSRV-019：sync 请求收到 SESSION_EXPIRED_ELSEWHERE 时回调（由登录 adapter 注册，清会话并跳登录页）。 */
let sessionKickedHandler: (() => void) | null = null;

export function setSessionKickedHandler(handler: (() => void) | null): void {
  sessionKickedHandler = handler;
}

function request(method: http.RequestMethod, url: string, body?: string): Promise<string> {
  return new Promise<string>((resolve, reject) => {
    const httpRequest = http.createHttp();
    const options: http.HttpRequestOptions = {
      method: method,
      header: { 'Content-Type': 'application/json' },
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
        if (code >= 200 && code < 300) {
          const result: string = data.result as string;
          resolve(result);
        } else {
          const result: string = data.result as string;
          if (result.indexOf('SESSION_EXPIRED_ELSEWHERE') >= 0 && sessionKickedHandler) {
            sessionKickedHandler();
          }
          hilog.error(0x0001, TAG, 'http status ' + code + ' url ' + url);
          reject(new Error('http status ' + code));
        }
      }
    );
  });
}

/**
 * 从服务器拉取权威 store/health 快照并同步给 KMP（MSRV-008）。
 * - 未登录时也拉取全部账号（登录发现），供本地登录预检查找到服务器账号；
 * - 已登录时按 userId 拉取并与本地合并（保留种子账号/其他账号，不整体替换）；
 * - 健康快照始终全量拉取合并。
 * 失败不阻断启动：沿用本地缓存。
 */
export async function syncFromServer(service?: HarmonyLoginServiceContract): Promise<boolean> {
  const svc: HarmonyLoginServiceContract = service ?? getService();
  try {
    await syncHealthFromServer(svc);

    const localStore: string = svc.exportStoreSnapshot();
    const localValid: boolean = thisHasValidSession(localStore);
    const currentUserId: string = currentUserIdOf(localStore);

    if (!localValid || currentUserId.length === 0) {
      // 未登录：拉取账号列表合并进本地，使登录预检查能发现服务器账号（MSRV-016/018）。
      // 用 mergeAccounts（不重建 facade），避免清空登录页已输入的账号/密码。
      const accountsBody = await request(http.RequestMethod.GET, `${MOCK_SERVER_BASE_URL}/api/sync/auth`);
      const accountsResp = JSON.parse(accountsBody) as SyncAuthResponse;
      if (accountsResp.store && Array.isArray(accountsResp.store.accounts)) {
        const merged = mergeAuthStores(localStore, accountsResp.store);
        svc.mergeAccounts(JSON.stringify(merged));
      }
      hilog.info(0x0001, TAG, 'syncFromServer (account discovery) completed');
      return true;
    }

    const authBody = await request(
      http.RequestMethod.GET,
      `${MOCK_SERVER_BASE_URL}/api/sync/auth?userId=${encodeURIComponent(currentUserId)}`
    );
    const auth: SyncAuthResponse = JSON.parse(authBody) as SyncAuthResponse;
    if (auth.store) {
      const serverStore: SyncAuthStore = auth.store;
      const hasServerAccount = serverStore.accounts !== undefined &&
        serverStore.accounts.length > 0;
      if (hasServerAccount) {
        // 合并（不整体替换），保留本地种子账号与其他账号
        const merged = mergeAuthStores(localStore, serverStore);
        svc.restoreStoreSnapshot(JSON.stringify(merged));
      }
    }
    hilog.info(0x0001, TAG, 'syncFromServer completed');
    return true;
  } catch (error) {
    hilog.warn(0x0001, TAG, 'syncFromServer skipped: ' + JSON.stringify(error));
    return false;
  }
}

/**
 * 仅同步健康快照（不重建 auth facade，不丢 pendingEffect）。
 * 用于登录/注册成功后拉取服务器健康数据，避免覆盖刚注册的 AuthSucceeded effect。
 */
export async function syncHealthFromServer(service?: HarmonyLoginServiceContract): Promise<boolean> {
  const svc: HarmonyLoginServiceContract = service ?? getService();
  try {
    const healthBody = await request(http.RequestMethod.GET, `${MOCK_SERVER_BASE_URL}/api/sync/health`);
    const health: SyncHealthResponse = JSON.parse(healthBody) as SyncHealthResponse;
    if (health.snapshots) {
      const payload: SyncHealthRequestPayload = { snapshots: health.snapshots };
      svc.restoreHealthSnapshot(JSON.stringify(payload));
    }
    hilog.info(0x0001, TAG, 'syncHealthFromServer completed');
    return true;
  } catch (error) {
    hilog.warn(0x0001, TAG, 'syncHealthFromServer skipped: ' + JSON.stringify(error));
    return false;
  }
}

/**
 * 把 KMP 当前 store/health 快照提交到服务器（MSRV-008-SYNC）。
 * 只提交当前登录用户的数据，避免覆盖其他用户（服务器端按 userId 合并）。
 * 失败不抛出：本地缓存仍保留，下次同步再补偿。
 */
export async function syncToServer(service?: HarmonyLoginServiceContract): Promise<boolean> {
  const svc: HarmonyLoginServiceContract = service ?? getService();
  try {
    const storeSnapshot: string = svc.exportStoreSnapshot();
    const healthSnapshot: string = svc.exportHealthSnapshot();
    const currentUserId: string = currentUserIdOf(storeSnapshot);

    // 认证：只提交当前会话用户的账号 + 会话，避免覆盖账号库其他用户
    if (currentUserId.length > 0) {
      const localStore = JSON.parse(storeSnapshot) as StoreSnapshotPayload;
      const targetAccount = (localStore.accounts ?? []).find((a) => a.userId === currentUserId);
      const storeDoc: SyncAuthStore = {
        accounts: targetAccount ? [targetAccount] : [],
        currentSession: localStore.currentSession,
        verifyCodes: [],
        defaultAccountsInitialized: true,
      };
      const payload: SyncAuthRequestPayload = { store: storeDoc };
      await request(
        http.RequestMethod.PUT,
        `${MOCK_SERVER_BASE_URL}/api/sync/auth`,
        JSON.stringify(payload)
      );
    }

    // 健康：只提交当前用户快照（服务器按 userId 合并，保留其他用户）
    if (currentUserId.length > 0) {
      try {
        const parsed = JSON.parse(healthSnapshot) as SyncHealthPayload;
        const mine: Object[] = (parsed.snapshots ?? []).filter((s) => {
          const item = s as SyncHealthItem;
          return item.userId === currentUserId;
        });
        const payload: SyncHealthRequestPayload = { snapshots: mine };
        await request(
          http.RequestMethod.PUT,
          `${MOCK_SERVER_BASE_URL}/api/sync/health`,
          JSON.stringify(payload)
        );
      } catch (e) {
        hilog.warn(0x0001, TAG, 'health filter skipped: ' + JSON.stringify(e));
      }
    }

    hilog.info(0x0001, TAG, 'syncToServer completed');
    return true;
  } catch (error) {
    hilog.warn(0x0001, TAG, 'syncToServer skipped: ' + JSON.stringify(error));
    return false;
  }
}
