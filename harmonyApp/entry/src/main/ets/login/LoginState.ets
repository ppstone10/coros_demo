export enum AuthMode {
  Login,
  Register
}

export class AuthSession {
  account: string = '';
  displayName: string = '';
  region: string = 'CN';
  isValid: boolean = false;
}

export class LoginRequestDto {
  account: string = '';
  password: string = '';
}

export class RegisterRequestDto {
  account: string = '';
  password: string = '';
  verifyCode: string = '';
  region: string = 'CN';
  displayName: string = '';
}

export class UserDto {
  id: string = '';
  account: string = '';
  displayName: string = '';
  region: string = 'CN';
}

export class LoginState {
  mode: AuthMode = AuthMode.Login;
  username: string = '';
  password: string = '';
  verifyCode: string = '';
  displayName: string = '';
  selectedRegion: string = 'CN';
  currentSession: AuthSession | null = null;
  isLoading: boolean = false;
  isLoggedIn: boolean = false;
  errorMessage: string = '';
}

export enum LoginActionType {
  ModeChanged,
  UsernameChanged,
  PasswordChanged,
  VerifyCodeChanged,
  DisplayNameChanged,
  RegionChanged,
  SubmitClicked,
  LogoutClicked,
  EffectConsumed
}

export class LoginAction {
  type: LoginActionType = LoginActionType.SubmitClicked;
  mode: AuthMode = AuthMode.Login;
  username: string = '';
  password: string = '';
  verifyCode: string = '';
  displayName: string = '';
  region: string = 'CN';
}

export enum LoginEffectType {
  AuthSucceeded,
  LoggedOut,
  ShowMessage
}

export class LoginEffect {
  type: LoginEffectType = LoginEffectType.ShowMessage;
  mode: AuthMode = AuthMode.Login;
  session: AuthSession = new AuthSession();
  message: string = '';
}

export enum LoginResultType {
  Success,
  Failure
}

export class LoginResult {
  type: LoginResultType = LoginResultType.Failure;
  session: AuthSession = new AuthSession();
  code: string = '';
  message: string = '';
}

export function createInitialLoginState(): LoginState {
  let state: LoginState = new LoginState();
  state.selectedRegion = 'CN';
  return state;
}

export function canSubmitLogin(state: LoginState): boolean {
  if (state.isLoading || state.username.trim().length === 0 || state.password.length === 0) {
    return false;
  }

  if (state.mode === AuthMode.Login) {
    return true;
  }

  return state.verifyCode.length > 0 && state.selectedRegion.length > 0;
}
