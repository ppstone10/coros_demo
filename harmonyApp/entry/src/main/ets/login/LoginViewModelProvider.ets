import { LoginViewModel } from './LoginViewModel';

const loginViewModel: LoginViewModel = new LoginViewModel();

export function getLoginViewModel(): LoginViewModel {
  return loginViewModel;
}
