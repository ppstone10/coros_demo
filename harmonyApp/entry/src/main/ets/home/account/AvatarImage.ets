import { AppColors } from '../../core/resources/AppResources';
import { MOCK_SERVER_BASE_URL } from '../../core/bridge/MockServerSync';
import http from '@ohos.net.http';
import fs from '@ohos.file.fs';

/** 头像缩放后的最大边长（像素）。控制上传体积。 */
export const AVATAR_MAX_DIMENSION: number = 512;

/** 头像在 mock server 的相对路径（MSRV-015：真实图片文件 + URL 展示）。 */
export function avatarServerPath(userId: string): string {
  return `/api/avatar/${userId}`;
}

/**
 * 读取相册图片字节 → 直接 PUT 到 mock server。
 * 返回相对路径 `/api/avatar/{userId}`；失败返回空字符串。
 */
export async function uploadAvatarToServer(uri: string, userId: string): Promise<string> {
  try {
    const bytes: Uint8Array = readFileBytes(uri);
    if (bytes.length === 0) {
      return '';
    }
    const path: string = avatarServerPath(userId);
    const ok: boolean = await putBinary(`${MOCK_SERVER_BASE_URL}${path}`, bytes);
    return ok ? path : '';
  } catch (error) {
    console.error(`uploadAvatarToServer failed: ${JSON.stringify(error)}`);
    return '';
  }
}

function readFileBytes(uri: string): Uint8Array {
  const file = fs.openSync(uri, fs.OpenMode.READ_ONLY);
  const stat = fs.statSync(file.fd);
  const buffer = new ArrayBuffer(stat.size);
  fs.readSync(file.fd, buffer);
  fs.closeSync(file);
  return new Uint8Array(buffer);
}

function putBinary(url: string, bytes: Uint8Array): Promise<boolean> {
  return new Promise<boolean>((resolve) => {
    const httpRequest = http.createHttp();
    httpRequest.request(
      url,
      {
        method: http.RequestMethod.PUT,
        header: { 'Content-Type': 'image/jpeg' },
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
 * 头像展示组件：avatarUri 为服务器相对路径（`/api/avatar/...`）时拼 base URL 加载；
 * 空值显示占位。纯 ArkTS 契约，不依赖 KNOI/native，可 Preview。
 */
@Component
export struct AvatarImage {
  @Prop avatarUri: string = '';
  @Prop avatarSize: number = 58;

  build() {
    Stack({ alignContent: Alignment.Center }) {
      if (this.avatarUri.length > 0 && this.avatarUri.startsWith('/api/avatar/')) {
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
