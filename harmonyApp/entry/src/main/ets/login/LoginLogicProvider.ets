import { LoginLogicAdapter } from './LoginLogicAdapter';
import { KnoiLoginAdapter } from './KnoiLoginAdapter';

export class LoginLogicProvider {
  static create(): LoginLogicAdapter {
    return new KnoiLoginAdapter();
  }
}
