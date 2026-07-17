export enum AuthMode {
  Login,
  Register
}

export class AuthSession {
  account: string = '';
  displayName: string = '';
  region: string = 'CN';
  isValid: boolean = false;
  isProfileComplete: boolean = false;
  avatarUri: string = '';
  birthDate: string = '';
  heightCm: number = 0;
  weightKg: number = 0;
  measurementSystem: string = 'Metric';
  phone: string = '';
  countryRegion: string = 'CN';
  gender: string = '';
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
  ProfileSaved,
  NavigateHome,
  LoggedOut,
  AccountDeleted,
  SessionExpired,
  ShowMessage
}

export class LoginEffect {
  type: LoginEffectType = LoginEffectType.ShowMessage;
  mode: AuthMode = AuthMode.Login;
  session: AuthSession = new AuthSession();
  message: string = '';
}
