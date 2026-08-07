import { AppColors } from '../../core/resources/AppResources';
import { MOCK_SERVER_BASE_URL } from '../../core/bridge/MockServerSync';
import { deviceId } from '../../core/bridge/HarmonyDeviceId';
import http from '@ohos.net.http';
import fs from '@ohos.file.fs';
import util from '@ohos.util';
import {
  downloadAvatarToCache,
  hasAvatarCache,
  readAvatarCacheBytes,
  writeAvatarCache
} from './AvatarCache';

/** 头像缩放后的最大边长（像素）。控制上传体积。 */
export const AVATAR_MAX_DIMENSION: number = 512;

/** 头像在 mock server 的相对路径（MSRV-015：真实图片文件 + URL 展示）。 */
export function avatarServerPath(userId: string): string {
  return `/api/avatar/${userId}`;
}

function readFileBytes(uri: string): Uint8Array {
  const file = fs.openSync(uri, fs.OpenMode.READ_ONLY);
  const stat = fs.statSync(file.fd);
  const buffer = new ArrayBuffer(stat.size);
  fs.readSync(file.fd, buffer);
  fs.closeSync(file);
  return new Uint8Array(buffer);
}

function bytesToBase64(bytes: Uint8Array): string {
  const helper = new util.Base64Helper();
  return helper.encodeToStringSync(bytes);
}

function putBinary(url: string, bytes: Uint8Array): Promise<boolean> {
  return new Promise<boolean>((resolve) => {
    const httpRequest = http.createHttp();
    httpRequest.request(
      url,
      {
        method: http.RequestMethod.PUT,
        header: {
          'Content-Type': 'image/jpeg',
          'X-Device-Id': deviceId(),
        },
        extraData: bytes.buffer,
        connectTimeout: 5000,
        readTimeout: 5000,
      },
      (err: Error, data: http.HttpResponse) => {
        httpRequest.destroy();
        if (err) {
          resolve(false);
          return;
        }
        const code: number = data.responseCode;
        resolve(code >= 200 && code < 300);
      }
    );
  });
}

/**
 * 上传头像字节到 mock server（MSRV-018：需本人有效会话 + 设备匹配，携带 X-Device-Id），
 * 成功后覆盖当前头像本地文件（对齐 Android/iOS）。
 * 返回相对路径 `/api/avatar/{userId}`；失败返回空字符串。
 */
export async function uploadAvatarBytesToServer(bytes: Uint8Array, userId: string): Promise<string> {
  if (bytes.length === 0) {
    return '';
  }
  const path: string = avatarServerPath(userId);
  const ok: boolean = await putBinary(`${MOCK_SERVER_BASE_URL}${path}`, bytes);
  if (ok) {
    writeAvatarCache(bytes);
  }
  return ok ? path : '';
}

/**
 * 读取相册图片字节 → 上传到 mock server（信息完善界面选图即用）。
 * 返回相对路径 `/api/avatar/{userId}`；失败返回空字符串。
 */
export async function uploadAvatarToServer(uri: string, userId: string): Promise<string> {
  try {
    return await uploadAvatarBytesToServer(readFileBytes(uri), userId);
  } catch (error) {
    console.error(`uploadAvatarToServer failed: ${JSON.stringify(error)}`);
    return '';
  }
}

/**
 * 头像展示组件：本地当前头像文件优先（即时、无闪烁），未命中再下载并写入缓存。
 * avatarUri 为服务器相对路径 `/api/avatar/...`，空值显示占位。
 *
 * 关键：文件路径恒定（`avatar_current.jpg`），ArkUI Image 会按 source 字符串缓存解码结果，
 * 因此源改用**内容寻址的 base64 data URI**（内容变则字符串变 → 强制重解码）；
 * `avatarRevision` 变化（@Watch）或 `avatarUri` 变化时重新读取本地文件，换头像后即时刷新。
 * Preview 下未初始化缓存时回退服务器 URL。
 */
@Component
export struct AvatarImage {
  @Prop @Watch('onAvatarInputChanged') avatarUri: string = '';
  @Prop avatarSize: number = 58;
  @Prop @Watch('onAvatarInputChanged') avatarRevision: number = 0;
  @State avatarSource: string = '';
  @State cacheLoaded: boolean = false;

  aboutToAppear(): void {
    this.resolveSource();
  }

  private onAvatarInputChanged(): void {
    this.resolveSource();
  }

  private resolveSource(): void {
    if (hasAvatarCache()) {
      const bytes: Uint8Array = readAvatarCacheBytes();
      if (bytes.length > 0) {
        this.avatarSource = 'data:image/jpeg;base64,' + bytesToBase64(bytes);
        this.cacheLoaded = true;
        return;
      }
    }
    this.cacheLoaded = false;
    if (this.avatarUri.startsWith('/api/avatar/')) {
      downloadAvatarToCache(this.avatarUri).then(() => {
        const bytes: Uint8Array = readAvatarCacheBytes();
        if (bytes.length > 0) {
          this.avatarSource = 'data:image/jpeg;base64,' + bytesToBase64(bytes);
          this.cacheLoaded = true;
        }
      });
    }
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      if (this.cacheLoaded && this.avatarSource.length > 0) {
        Image(this.avatarSource)
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
      } else if (this.avatarUri.length > 0 && this.avatarUri.startsWith('/api/avatar/')) {
        Image(MOCK_SERVER_BASE_URL + this.avatarUri)
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
      } else {
        Text('')
          .fontSize(20)
          .fontColor(AppColors.WHITE)
      }
    }
    .width(this.avatarSize)
    .height(this.avatarSize)
    .borderRadius(this.avatarSize / 2)
    .backgroundColor(AppColors.ACCOUNT_AVATAR)
    .clip(true)
  }
}
