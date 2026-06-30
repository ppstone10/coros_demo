export class LoginRequestDto {
  username: string = '';
  password: string = '';
}

export class UserDto {
  id: string = '';
  displayName: string = '';
  accessToken: string = '';
}

export class LoginState {
  username: string = '';
  password: string = '';
  isLoading: boolean = false;
  isLoggedIn: boolean = false;
  errorMessage: string = '';
}

export enum LoginActionType {
  UsernameChanged,
  PasswordChanged,
  SubmitClicked,
  EffectConsumed
}

export class LoginAction {
  type: LoginActionType = LoginActionType.SubmitClicked;
  username: string = '';
  password: string = '';
}

export enum LoginEffectType {
  NavigateHome,
  ShowMessage
}

export class LoginEffect {
  type: LoginEffectType = LoginEffectType.ShowMessage;
  user: UserDto = new UserDto();
  message: string = '';
}

export enum LoginResultType {
  Success,
  Failure
}

export class LoginResult {
  type: LoginResultType = LoginResultType.Failure;
  user: UserDto = new UserDto();
  code: string = '';
  message: string = '';
}

export function createInitialLoginState(): LoginState {
  let state: LoginState = new LoginState();
  state.username = '';
  state.password = '';
  state.isLoading = false;
  state.isLoggedIn = false;
  state.errorMessage = '';
  return state;
}

export function canSubmitLogin(state: LoginState): boolean {
  return state.username.trim().length > 0
    && state.password.length > 0
    && !state.isLoading;
}
