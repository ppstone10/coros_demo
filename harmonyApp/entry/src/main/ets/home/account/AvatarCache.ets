import fs from '@ohos.file.fs';
import http from '@ohos.net.http';
import { MOCK_SERVER_BASE_URL } from '../../core/bridge/MockServerSync';
import { deviceId } from '../../core/bridge/HarmonyDeviceId';

/**
 * 当前账号头像本地单文件（对齐 Android/iOS，MSRV-015）：
 * `filesDir/avatar_current.jpg`。
 * - 登录/切换账号：先清除旧头像，再用服务器头像覆盖（refreshAvatarFromServer）；
 * - 换新头像：信息完善页选图即上传并覆盖；信息修改页选图仅写本地预览、保存才上传并覆盖；
 * - 显示一律读本文件，即时无闪烁。
 * Preview 下未初始化 filesDir 时所有操作安全返回空/失败，回退服务器 URL。
 */

let filesDir: string = '';

/** 由 EntryAbility 启动时注入应用 filesDir。 */
export function initAvatarCache(dir: string): void {
  filesDir = dir;
}

function cacheFile(): string {
  return `${filesDir}/avatar_current.jpg`;
}

export function hasAvatarCache(): boolean {
  if (filesDir.length === 0) return false;
  try {
    return fs.accessSync(cacheFile());
  } catch (e) {
    return false;
  }
}

/** 当前头像本地文件 URI（供 Image 直接展示）。 */
export function avatarCacheUri(): string {
  return `file://${cacheFile()}`;
}

export function clearAvatarCache(): void {
  if (filesDir.length === 0) return;
  try {
    if (fs.accessSync(cacheFile())) {
      fs.unlinkSync(cacheFile());
    }
  } catch (e) {
    // ignore
  }
}

export function writeAvatarCache(bytes: Uint8Array): void {
  if (filesDir.length === 0 || bytes.length === 0) return;
  try {
    const file = fs.openSync(cacheFile(), fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
    fs.writeSync(file.fd, bytes.buffer);
    fs.closeSync(file);
  } catch (e) {
    // ignore
  }
}

export function readAvatarCacheBytes(): Uint8Array {
  if (filesDir.length === 0 || !hasAvatarCache()) {
    return new Uint8Array(0);
  }
  try {
    const file = fs.openSync(cacheFile(), fs.OpenMode.READ_ONLY);
    const stat = fs.statSync(file.fd);
    const buffer = new ArrayBuffer(stat.size);
    fs.readSync(file.fd, buffer);
    fs.closeSync(file);
    return new Uint8Array(buffer);
  } catch (e) {
    return new Uint8Array(0);
  }
}

/**
 * 登录/切换账号后刷新当前头像：先清除旧头像，再按 avatarUri 从服务器拉取覆盖。
 * avatarUri 非服务器路径时仅清除。
 */
export function refreshAvatarFromServer(avatarUri: string): void {
  clearAvatarCache();
  if (filesDir.length === 0 || !avatarUri.startsWith('/api/avatar/')) {
    return;
  }
  const url: string = MOCK_SERVER_BASE_URL + avatarUri;
  const httpRequest = http.createHttp();
  httpRequest.request(
    url,
    { method: http.RequestMethod.GET, readTimeout: 5000, header: { 'X-Device-Id': deviceId() } },
    (err: Error, data: http.HttpResponse) => {
      httpRequest.destroy();
      if (err) {
        return;
      }
      if (data.responseCode >= 200 && data.responseCode < 300) {
        const bytes = new Uint8Array(data.result as ArrayBuffer);
        writeAvatarCache(bytes);
      }
    }
  );
}

/** 从服务器下载头像写入本地缓存（显示未命中时用）。 */
export function downloadAvatarToCache(avatarUri: string): Promise<void> {
  return new Promise<void>((resolve) => {
    if (filesDir.length === 0 || !avatarUri.startsWith('/api/avatar/')) {
      resolve();
      return;
    }
    const url: string = MOCK_SERVER_BASE_URL + avatarUri;
    const httpRequest = http.createHttp();
    httpRequest.request(
      url,
      { method: http.RequestMethod.GET, readTimeout: 5000, header: { 'X-Device-Id': deviceId() } },
      (err: Error, data: http.HttpResponse) => {
        httpRequest.destroy();
        if (!err && data.responseCode >= 200 && data.responseCode < 300) {
          writeAvatarCache(new Uint8Array(data.result as ArrayBuffer));
        }
        resolve();
      }
    );
  });
}
