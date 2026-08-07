import { LoginEffect, LoginEffectType, AuthMode } from '../logic/LoginState';
import { AuthRoutes } from './AuthRoutes';
import { navigate, NavOperation, showToast } from './AuthNavigator';
import { markPendingStaleRefresh } from '../../health/HealthDashboardViewModel';
import { refreshAvatarFromServer } from '../../home/account/AvatarCache';

export function handleAuthEffect(effect: LoginEffect): void {
  switch (effect.type) {
    case LoginEffectType.AuthSucceeded: {
      markPendingStaleRefresh();
      // MSRV-015：登录/切换账号后用服务器头像覆盖内部目录当前头像
      refreshAvatarFromServer(effect.session.avatarUri);
      const target = effect.nextRoute === 'SignedIn'
        ? AuthRoutes.home.SIGNED_IN : AuthRoutes.auth.PROFILE_COMPLETION;
      navigate(NavOperation.ResetTo, target);
      showToast(effect.mode === AuthMode.Register ? 'auth_register_success' : 'auth_login_success');
      break;
    }
    case LoginEffectType.NavigateHome:
      navigate(NavOperation.ResetTo, AuthRoutes.home.SIGNED_IN);
      showToast('auth_login_success');
      break;
    case LoginEffectType.ProfileSaved:
      navigate(NavOperation.ResetTo, AuthRoutes.home.SIGNED_IN);
      showToast('profile_saved');
      break;
    case LoginEffectType.LoggedOut:
      markPendingStaleRefresh();
      navigate(NavOperation.ResetTo, AuthRoutes.auth.ENTRANCE);
      showToast('account_logout_success');
      break;
    case LoginEffectType.AccountDeleted:
      navigate(NavOperation.ResetTo, AuthRoutes.auth.ENTRANCE);
      showToast('account_delete_success');
      break;
    case LoginEffectType.SessionExpired:
      navigate(NavOperation.ResetKeepingEntranceAndPush, AuthRoutes.auth.LOGIN);
      showToast('auth_session_expired');
      break;
    case LoginEffectType.SessionKicked:
      // MSRV-019：被顶弹窗已提示，确认后静默回登录页
      navigate(NavOperation.ResetKeepingEntranceAndPush, AuthRoutes.auth.LOGIN);
      break;
    case LoginEffectType.ShowForceLoginDialog:
      // 二次确认弹窗由页面按 state.confirmForceLogin 渲染，effect 仅驱动
      break;
    case LoginEffectType.ShowMessage:
      showToast(effect.message);
      break;
  }
}
