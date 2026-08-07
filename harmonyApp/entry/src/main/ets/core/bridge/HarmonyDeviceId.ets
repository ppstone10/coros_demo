import preferences from '@ohos.data.preferences';
import hilog from '@ohos.hilog';

const TAG = 'demo_device';

const PREFS_NAME = 'demo_device_id';
const KEY_DEVICE_ID = 'device_id';

let cached: string = '';

function randomUuid(): string {
  const a: string = Date.now().toString(36);
  const b: string = Math.floor(Math.random() * 0xffffffff).toString(36);
  const c: string = Math.floor(Math.random() * 0xffffffff).toString(36);
  return a + '-' + b + '-' + c;
}

/** HARM-001：首次生成并持久化设备标识（harmony-<UUID>），供每个请求携带。 */
export async function initDeviceId(context: Context): Promise<string> {
  if (cached.length > 0) {
    return cached;
  }
  try {
    const prefs = await preferences.getPreferences(context, PREFS_NAME);
    const existing = prefs.getSync(KEY_DEVICE_ID, '') as string;
    if (existing.length > 0) {
      cached = existing;
      return cached;
    }
    const generated = 'harmony-' + randomUuid();
    prefs.putSync(KEY_DEVICE_ID, generated);
    prefs.flushSync();
    cached = generated;
    return cached;
  } catch (e) {
    hilog.error(0x0001, TAG, 'initDeviceId failed: ' + JSON.stringify(e));
    cached = 'harmony-default';
    return cached;
  }
}

/** 当前设备标识；未初始化时为 harmony-default（防御）。 */
export function deviceId(): string {
  return cached.length > 0 ? cached : 'harmony-default';
}
