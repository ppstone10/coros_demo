import hilog from '@ohos.hilog';
import preferences from '@ohos.data.preferences';
import { getService, HarmonyLoginServiceContract } from './HarmonyServiceProvider';
import { syncFromServer, syncToServer } from './MockServerSync';

const PREFERENCES_NAME = 'mock_auth_store';
const KEY_STORE_JSON = 'store_json';
const KEY_HEALTH_JSON = 'health_json';
let prefsInstance: preferences.Preferences | null = null;
let initialized: boolean = false;

export async function initPersistence(context: Context): Promise<void> {
  hilog.info(0x0001, 'demo_persist', 'initPersistence called');
  try {
    prefsInstance = await preferences.getPreferences(context, PREFERENCES_NAME);
    initialized = true;
    hilog.info(0x0001, 'demo_persist', 'preferences opened');
    const json = prefsInstance.getSync(KEY_STORE_JSON, '') as string;
    hilog.info(0x0001, 'demo_persist', 'stored json length=' + JSON.stringify(json.length));
    if (json.length > 0) {
      const restored = getService().restoreStoreSnapshot(json);
      hilog.info(0x0001, 'demo_persist', 'restoreStoreSnapshot result=' + JSON.stringify(restored));
    }
    const healthJson = prefsInstance.getSync(KEY_HEALTH_JSON, '') as string;
    if (healthJson.length > 0) {
      getService().restoreHealthSnapshot(healthJson);
    }
    // MSRV-008：启动时从 mock 服务器拉取权威快照（失败沿用本地缓存）
    await syncFromServer(getService());
    hilog.info(0x0001, 'demo_persist', 'initPersistence completed');
  } catch (error) {
    prefsInstance = null;
    initialized = false;
    hilog.error(0x0001, 'demo_persist', 'init persistence failed: ' + JSON.stringify(error));
  }
}

export function saveStoreSnapshot(service?: HarmonyLoginServiceContract): boolean {
  hilog.info(0x0001, 'demo_persist', 'saveStoreSnapshot called');
  if (prefsInstance === null) {
    hilog.warn(0x0001, 'demo_persist', 'saveStoreSnapshot skipped: prefsInstance is null');
    return false;
  }
  try {
    const svc: HarmonyLoginServiceContract = service ?? getService();
    const json = svc.exportStoreSnapshot();
    prefsInstance.putSync(KEY_STORE_JSON, json);
    const healthJson = svc.exportHealthSnapshot();
    prefsInstance.putSync(KEY_HEALTH_JSON, healthJson);
    prefsInstance.flushSync();
    // MSRV-008：写操作成功后异步提交到服务器，失败保留本地缓存待补偿
    syncToServer(svc).catch(() => {
      hilog.warn(0x0001, 'demo_persist', 'syncToServer skipped');
    });
    return true;
  } catch (error) {
    hilog.error(0x0001, 'demo_persist', 'persist failed: ' + JSON.stringify(error));
    return false;
  }
}
