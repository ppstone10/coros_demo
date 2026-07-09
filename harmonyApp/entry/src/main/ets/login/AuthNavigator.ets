import promptAction from '@ohos.promptAction';
import router from '@ohos.router';
import { AuthRoutes } from './AuthRoutes';

export enum NavOperation {
  Push,
  Pop,
  ReplaceTop,
  ResetTo,
  ResetKeepingEntranceAndPush
}

export function navigate(operation: NavOperation, target: string): void {
  switch (operation) {
    case NavOperation.Push:
      router.pushUrl({ url: target });
      break;
    case NavOperation.Pop:
      router.back();
      break;
    case NavOperation.ReplaceTop:
      router.replaceUrl({ url: target });
      break;
    case NavOperation.ResetTo:
      router.clear();
      router.replaceUrl({ url: target });
      break;
    case NavOperation.ResetKeepingEntranceAndPush:
      router.clear();
      router.replaceUrl({ url: AuthRoutes.ENTRANCE });
      router.pushUrl({ url: target });
      break;
  }
}

export function navigateWithParams(operation: NavOperation, options: router.RouterOptions): void {
  switch (operation) {
    case NavOperation.Push:
      router.pushUrl(options);
      break;
    case NavOperation.Pop:
      router.back();
      break;
    case NavOperation.ReplaceTop:
      router.replaceUrl(options);
      break;
    case NavOperation.ResetTo:
      router.clear();
      router.replaceUrl(options);
      break;
    case NavOperation.ResetKeepingEntranceAndPush:
      router.clear();
      router.replaceUrl({ url: AuthRoutes.ENTRANCE });
      router.pushUrl(options);
      break;
  }
}

export function showToast(message: string): void {
  try {
    promptAction.showToast({ message: message });
  } catch (error) {
    console.error('showToast failed');
  }
}
