import { LoginViewModel } from './LoginViewModel';

let loginViewModel: LoginViewModel | null = null;

export function getLoginViewModel(): LoginViewModel {
  if (loginViewModel === null) {
    loginViewModel = new LoginViewModel();
  }
  return loginViewModel;
}
