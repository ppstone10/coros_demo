import { LoginEffect, LoginEffectType, AuthMode } from './LoginState';
import { AuthRoutes } from './AuthRoutes';
import { navigate, NavOperation, showToast } from './AuthNavigator';

export function handleAuthEffect(effect: LoginEffect): void {
  switch (effect.type) {
    case LoginEffectType.AuthSucceeded:
      if (effect.mode === AuthMode.Register) {
        navigate(NavOperation.ResetKeepingEntranceAndPush, AuthRoutes.LOGIN);
        showToast('注册成功');
      } else {
        const target = effect.session.isProfileComplete
          ? AuthRoutes.SIGNED_IN : AuthRoutes.PROFILE_COMPLETION;
        navigate(NavOperation.ResetTo, target);
        showToast('登录成功');
      }
      break;
    case LoginEffectType.NavigateHome:
      navigate(NavOperation.ResetTo, AuthRoutes.SIGNED_IN);
      showToast('登录成功');
      break;
    case LoginEffectType.ProfileSaved:
      navigate(NavOperation.ResetTo, AuthRoutes.SIGNED_IN);
      showToast('资料已保存');
      break;
    case LoginEffectType.LoggedOut:
      navigate(NavOperation.ResetTo, AuthRoutes.ENTRANCE);
      showToast('已退出登录');
      break;
    case LoginEffectType.AccountDeleted:
      navigate(NavOperation.ResetTo, AuthRoutes.ENTRANCE);
      showToast('账户已注销');
      break;
    case LoginEffectType.SessionExpired:
      navigate(NavOperation.ResetKeepingEntranceAndPush, AuthRoutes.LOGIN);
      showToast('会话已失效，请重新登录');
      break;
    case LoginEffectType.ShowMessage:
      showToast(effect.message);
      break;
  }
}
