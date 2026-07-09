import hilog from '@ohos.hilog';
import preferences from '@ohos.data.preferences';
import { HarmonyLoginService } from '../knoi/provider';
import { getService } from './HarmonyServiceProvider';

const PREFERENCES_NAME = 'mock_auth_store';
const KEY_STORE_JSON = 'store_json';
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
      if (!restored) {
        console.error('restore login store snapshot failed');
      }
    }
    hilog.info(0x0001, 'demo_persist', 'initPersistence completed');
  } catch (error) {
    prefsInstance = null;
    initialized = false;
    hilog.error(0x0001, 'demo_persist', 'init persistence failed: ' + JSON.stringify(error));
    console.error('init persistence failed: ' + error);
  }
}

export function saveStoreSnapshot(service?: HarmonyLoginService): boolean {
  hilog.info(0x0001, 'demo_persist', 'saveStoreSnapshot called');
  if (prefsInstance === null) {
    hilog.warn(0x0001, 'demo_persist', 'saveStoreSnapshot skipped: prefsInstance is null, initialized=' + JSON.stringify(initialized));
    if (initialized) {
      console.error('persist skipped because preferences instance is unavailable');
    } else {
      console.warn('persist skipped: persistence not initialized (initPersistence may have failed)');
    }
    return false;
  }
  try {
    const svc: HarmonyLoginService = service ?? getService();
    const json = svc.exportStoreSnapshot();
    hilog.info(0x0001, 'demo_persist', 'exported snapshot length=' + JSON.stringify(json.length));
    prefsInstance.putSync(KEY_STORE_JSON, json);
    prefsInstance.flushSync();
    hilog.info(0x0001, 'demo_persist', 'save succeeded, json length=' + JSON.stringify(json.length));
    return true;
  } catch (error) {
    hilog.error(0x0001, 'demo_persist', 'persist failed: ' + JSON.stringify(error));
    console.error('persist failed: ' + error);
    return false;
  }
}
