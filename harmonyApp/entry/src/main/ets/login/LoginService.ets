import {
  LoginRequestDto,
  LoginResult,
  LoginResultType,
  UserDto
} from './LoginState';

export class LoginService {
  async login(request: LoginRequestDto): Promise<LoginResult> {
    let username: string = request.username.trim();

    if (username === 'demo' && request.password === 'demo123') {
      let user: UserDto = new UserDto();
      user.id = 'user-demo';
      user.displayName = 'Demo User';
      user.accessToken = 'fake-token-demo';

      let result: LoginResult = new LoginResult();
      result.type = LoginResultType.Success;
      result.user = user;
      result.code = '';
      result.message = '';
      return result;
    }

    let result: LoginResult = new LoginResult();
    result.type = LoginResultType.Failure;
    result.code = 'AUTH_INVALID_CREDENTIALS';
    result.message = '用户名或密码不正确';
    return result;
  }
}
