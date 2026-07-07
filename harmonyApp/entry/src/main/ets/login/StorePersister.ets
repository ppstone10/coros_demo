import preferences from '@ohos.data.preferences';
import { getHarmonyLoginService } from '../knoi/provider';

const PREFERENCES_NAME = 'mock_auth_store';
const KEY_STORE_JSON = 'store_json';
let prefsInstance: preferences.Preferences | null = null;

export async function initPersistence(context: Context): Promise<void> {
  prefsInstance = await preferences.getPreferences(context, PREFERENCES_NAME);
  const json = prefsInstance.getSync(KEY_STORE_JSON, '') as string;
  if (json.length > 0) {
    try {
      getHarmonyLoginService().restoreStoreSnapshot(json);
    } catch (error) {
      console.error('restore failed: ' + error);
    }
  }
}

export function saveStoreSnapshot(): void {
  if (prefsInstance === null) {
    return;
  }
  try {
    const json = getHarmonyLoginService().exportStoreSnapshot();
    prefsInstance.putSync(KEY_STORE_JSON, json);
    prefsInstance.flush();
  } catch (error) {
    console.error('persist failed: ' + error);
  }
}
