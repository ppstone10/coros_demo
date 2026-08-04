import { LoginLogicAdapter } from '../../auth/logic/LoginLogicAdapter';
import { PreviewLoginAdapter } from './PreviewLoginAdapter';

type LoginLogicFactory = () => LoginLogicAdapter;

let adapterFactory: LoginLogicFactory = (): LoginLogicAdapter => new PreviewLoginAdapter();

export class LoginLogicProvider {
  static install(factory: LoginLogicFactory): void {
    adapterFactory = factory;
  }

  static create(): LoginLogicAdapter {
    return adapterFactory();
  }
}
