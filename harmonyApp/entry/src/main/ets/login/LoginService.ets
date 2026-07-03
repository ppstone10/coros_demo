import {
  AuthSession,
  LoginRequestDto,
  LoginResult,
  LoginResultType,
  RegisterRequestDto
} from './LoginState';

class MockAccount {
  account: string = '';
  password: string = '';
  displayName: string = '';
  region: string = 'CN';
}

class VerifyCodeState {
  account: string = '';
  code: string = '';
  expireAtEpochMs: number = 0;
}

export class LoginService {
  static readonly DefaultVerifyCode: string = '1234';
  static readonly ResentVerifyCode: string = '4321';
  private static readonly VerifyCodeTtlMs: number = 60 * 1000;

  private accounts: MockAccount[] = [
    this.createAccount('13107012029', '123456', 'COROS User', 'CN'),
    this.createAccount('2232591785@qq.com', '123456', 'COROS Email User', 'CN')
  ];
  private verifyCodes: VerifyCodeState[] = [];
  private currentSession: AuthSession | null = null;

  requestVerifyCode(account: string, code: string = LoginService.DefaultVerifyCode): string {
    let normalizedAccount: string = account.trim();
    let normalizedCode: string = code.trim();
    if (!this.isAccountFormatValid(normalizedAccount) || !/^[0-9]{4}$/.test(normalizedCode)) {
      return '请输入完整且有效的信息';
    }

    this.verifyCodes = this.verifyCodes.filter((item: VerifyCodeState) => {
      return item.account.toLowerCase() !== normalizedAccount.toLowerCase();
    });

    let codeState: VerifyCodeState = new VerifyCodeState();
    codeState.account = normalizedAccount;
    codeState.code = normalizedCode;
    codeState.expireAtEpochMs = Date.now() + LoginService.VerifyCodeTtlMs;
    this.verifyCodes.push(codeState);
    return '';
  }

  verifyCode(account: string, code: string): string {
    let normalizedAccount: string = account.trim().toLowerCase();
    let savedCode: VerifyCodeState | undefined = this.verifyCodes.find((item: VerifyCodeState) => {
      return item.account.toLowerCase() === normalizedAccount;
    });
    if (savedCode === undefined) {
      return '验证码不正确';
    }
    if (savedCode.expireAtEpochMs <= Date.now()) {
      return '验证码已过期，请重新获取';
    }
    return savedCode.code === code.trim() ? '' : '验证码不正确';
  }

  async login(request: LoginRequestDto): Promise<LoginResult> {
    let account: string = request.account.trim();
    if (!this.isAccountFormatValid(account) || request.password.length === 0) {
      return this.failure('AUTH_INVALID_PARAM', '请输入完整且有效的信息');
    }

    let savedAccount: MockAccount | undefined = this.accounts.find((item: MockAccount) => {
      return item.account.toLowerCase() === account.toLowerCase();
    });

    if (savedAccount === undefined) {
      return this.failure('AUTH_ACCOUNT_NOT_FOUND', '账号不存在');
    }

    if (savedAccount.password !== request.password) {
      return this.failure('AUTH_PASSWORD_INCORRECT', '密码不正确');
    }

    return this.success(savedAccount);
  }

  async register(request: RegisterRequestDto): Promise<LoginResult> {
    let account: string = request.account.trim();
    if (!this.isAccountFormatValid(account) || !this.isRegisterPasswordValid(request.password) || request.region.length === 0) {
      return this.failure('AUTH_INVALID_PARAM', '请输入完整且有效的信息');
    }

    let verifyMessage: string = this.verifyCode(account, request.verifyCode);
    if (verifyMessage.length > 0) {
      let code: string = verifyMessage.indexOf('过期') >= 0 ? 'AUTH_VERIFY_CODE_EXPIRED' : 'AUTH_VERIFY_CODE_INVALID';
      return this.failure(code, verifyMessage);
    }

    let isKnownRegion: boolean = request.region === 'CN' || request.region === 'US';
    if (!isKnownRegion) {
      return this.failure('AUTH_INVALID_PARAM', '请输入完整且有效的信息');
    }

    if (request.verifyCode.trim().length !== 4) {
      return this.failure('AUTH_VERIFY_CODE_INVALID', '验证码不正确');
    }

    let existed: boolean = this.accounts.some((item: MockAccount) => {
      return item.account.toLowerCase() === account.toLowerCase();
    });
    if (existed) {
      return this.failure('AUTH_ACCOUNT_EXISTS', '账号已存在');
    }

    let displayName: string = request.displayName.trim().length > 0 ? request.displayName.trim() : account;
    let newAccount: MockAccount = this.createAccount(account, request.password, displayName, request.region);
    this.accounts.push(newAccount);
    this.verifyCodes = this.verifyCodes.filter((item: VerifyCodeState) => {
      return item.account.toLowerCase() !== account.toLowerCase();
    });

    return this.success(newAccount);
  }

  clearSession(): void {
    this.currentSession = null;
  }

  private success(account: MockAccount): LoginResult {
    let session: AuthSession = new AuthSession();
    session.account = account.account;
    session.displayName = account.displayName;
    session.region = account.region;
    session.isValid = true;
    this.currentSession = session;

    let result: LoginResult = new LoginResult();
    result.type = LoginResultType.Success;
    result.session = session;
    return result;
  }

  private failure(code: string, message: string): LoginResult {
    let result: LoginResult = new LoginResult();
    result.type = LoginResultType.Failure;
    result.code = code;
    result.message = message;
    return result;
  }

  private createAccount(account: string, password: string, displayName: string, region: string): MockAccount {
    let model: MockAccount = new MockAccount();
    model.account = account;
    model.password = password;
    model.displayName = displayName;
    model.region = region;
    return model;
  }

  private isAccountFormatValid(account: string): boolean {
    let isEmailLike: boolean = account.indexOf('@') > 0 && account.substring(account.indexOf('@') + 1).indexOf('.') > 0;
    let isPhoneLike: boolean = account.length >= 5 && account.length <= 20 && /^[0-9+-]+$/.test(account);
    return isEmailLike || isPhoneLike;
  }

  private isRegisterPasswordValid(password: string): boolean {
    return password.length >= 6
      && password.length <= 20
      && /[A-Za-z]/.test(password)
      && /[0-9]/.test(password);
  }
}
