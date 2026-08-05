import http from '@ohos.net.http';
import hilog from '@ohos.hilog';
import { getService, HarmonyLoginServiceContract } from './HarmonyServiceProvider';

const TAG = 'demo_mock_sync';

/**
 * Mock 服务器地址配置（MSRV-007）。模拟器/真机访问宿主机需与服务器同一局域网。
 */
export const MOCK_SERVER_BASE_URL: string = 'http://10.0.2.2:3000';

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
          hilog.error(0x0001, TAG, 'http status ' + code + ' url ' + url);
          reject(new Error('http status ' + code));
        }
      }
    );
  });
}

/**
 * 从服务器拉取权威 store/health 快照并同步给 KMP（MSRV-008）。
 * - 本地有有效会话（已登录）时拉取认证 store；
 * - 未登录时跳过认证拉取（避免空 userId 查询与空 store 覆盖本地）；
 * - 健康快照始终全量拉取合并。
 * 失败不阻断启动：沿用本地缓存。
 */
export async function syncFromServer(service?: HarmonyLoginServiceContract): Promise<boolean> {
  const svc: HarmonyLoginServiceContract = service ?? getService();
  try {
    const localStore: string = svc.exportStoreSnapshot();
    const localValid: boolean = thisHasValidSession(localStore);
    const currentUserId: string = currentUserIdOf(localStore);

    if (localValid && currentUserId.length > 0) {
      const authBody = await request(
        http.RequestMethod.GET,
        `${MOCK_SERVER_BASE_URL}/api/sync/auth?userId=${encodeURIComponent(currentUserId)}`
      );
      const auth: SyncAuthResponse = JSON.parse(authBody) as SyncAuthResponse;
      if (auth.store) {
        const serverStore: SyncAuthStore = auth.store;
        const hasServerAccount = serverStore.accounts !== undefined &&
          serverStore.accounts.length > 0;
        // 服务器尚无该用户账号（鸿蒙首次本地注册）时不覆盖本地登录态
        if (hasServerAccount) {
          if (serverStore.currentSession !== undefined && !serverStore.currentSession.isValid) {
            // 服务器会话已失效：仅同步账号数据，不恢复会话
            const merged: SyncAuthStore = {
              accounts: serverStore.accounts,
              verifyCodes: serverStore.verifyCodes,
              currentSession: undefined
            };
            svc.restoreStoreSnapshot(JSON.stringify(merged));
          } else {
            svc.restoreStoreSnapshot(JSON.stringify(serverStore));
          }
        }
      }
    }

    const healthBody = await request(http.RequestMethod.GET, `${MOCK_SERVER_BASE_URL}/api/sync/health`);
    const health: SyncHealthResponse = JSON.parse(healthBody) as SyncHealthResponse;
    if (health.snapshots) {
      const payload: SyncHealthRequestPayload = { snapshots: health.snapshots };
      svc.restoreHealthSnapshot(JSON.stringify(payload));
    }
    hilog.info(0x0001, TAG, 'syncFromServer completed');
    return true;
  } catch (error) {
    hilog.warn(0x0001, TAG, 'syncFromServer skipped: ' + JSON.stringify(error));
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
