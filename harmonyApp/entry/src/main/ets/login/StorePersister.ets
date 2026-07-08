import preferences from '@ohos.data.preferences';
import { getHarmonyLoginService } from '../knoi/provider';

const PREFERENCES_NAME = 'mock_auth_store';
const KEY_STORE_JSON = 'store_json';
let prefsInstance: preferences.Preferences | null = null;
let initialized: boolean = false;

export async function initPersistence(context: Context): Promise<void> {
  try {
    prefsInstance = await preferences.getPreferences(context, PREFERENCES_NAME);
    initialized = true;
    const json = prefsInstance.getSync(KEY_STORE_JSON, '') as string;
    if (json.length > 0) {
      const restored = getHarmonyLoginService().restoreStoreSnapshot(json);
      if (!restored) {
        console.error('restore login store snapshot failed');
      } else if (!getHarmonyLoginService().validateCurrentStoreSnapshotRoundTrip()) {
        console.error('restored login store snapshot is not round-trip stable');
      }
    }
  } catch (error) {
    prefsInstance = null;
    initialized = false;
    console.error('init persistence failed: ' + error);
  }
}

export function saveStoreSnapshot(): boolean {
  if (prefsInstance === null) {
    if (initialized) {
      console.error('persist skipped because preferences instance is unavailable');
    }
    return false;
  }
  try {
    const json = getHarmonyLoginService().exportStoreSnapshot();
    if (!getHarmonyLoginService().validateStoreSnapshotRoundTrip(json)) {
      console.error('skip persist because login store snapshot is not round-trip stable');
      return false;
    }
    prefsInstance.putSync(KEY_STORE_JSON, json);
    prefsInstance.flushSync();
    return true;
  } catch (error) {
    console.error('persist failed: ' + error);
    return false;
  }
}
