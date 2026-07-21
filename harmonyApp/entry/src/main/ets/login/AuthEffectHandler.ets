import { LoginEffect, LoginEffectType, AuthMode } from './LoginState';
import { AuthRoutes } from './AuthRoutes';
import { navigate, NavOperation, showToast } from './AuthNavigator';

export function handleAuthEffect(effect: LoginEffect): void {
  switch (effect.type) {
    case LoginEffectType.AuthSucceeded: {
      const target = effect.nextRoute === 'SignedIn'
        ? AuthRoutes.SIGNED_IN : AuthRoutes.PROFILE_COMPLETION;
      navigate(NavOperation.ResetTo, target);
      showToast(effect.mode === AuthMode.Register ? 'auth_register_success' : 'auth_login_success');
      break;
    }
    case LoginEffectType.NavigateHome:
      navigate(NavOperation.ResetTo, AuthRoutes.SIGNED_IN);
      showToast('auth_login_success');
      break;
    case LoginEffectType.ProfileSaved:
      navigate(NavOperation.ResetTo, AuthRoutes.SIGNED_IN);
      showToast('profile_saved');
      break;
    case LoginEffectType.LoggedOut:
      navigate(NavOperation.ResetTo, AuthRoutes.ENTRANCE);
      showToast('account_logout_success');
      break;
    case LoginEffectType.AccountDeleted:
      navigate(NavOperation.ResetTo, AuthRoutes.ENTRANCE);
      showToast('account_delete_success');
      break;
    case LoginEffectType.SessionExpired:
      navigate(NavOperation.ResetKeepingEntranceAndPush, AuthRoutes.LOGIN);
      showToast('auth_session_expired');
      break;
    case LoginEffectType.ShowMessage:
      showToast(effect.message);
      break;
  }
}
