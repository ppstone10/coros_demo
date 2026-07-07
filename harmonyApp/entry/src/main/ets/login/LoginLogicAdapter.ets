import {
  AuthMode,
  LoginEffect,
  LoginState
} from './LoginState';

export interface LoginLogicAdapter {
  getState(): LoginState;
  setMode(mode: AuthMode): void;
  setUsername(value: string): void;
  setPassword(value: string): void;
  setVerifyCode(value: string): void;
  setDisplayName(value: string): void;
  setRegion(value: string): void;
  submit(): Promise<void>;
  logout(): void;
  requestVerifyCode(account: string): string;
  requestResentVerifyCode(account: string): string;
  verifyCode(account: string, code: string): string;
  normalizePhoneInput(value: string): string;
  normalizeEmailInput(value: string): string;
  normalizeVerifyCodeInput(value: string): string;
  normalizePasswordInput(value: string): string;
  isLoginReady(account: string, password: string, isLoading: boolean): boolean;
  validateLoginInput(account: string, password: string): string;
  isPhoneAccountValid(account: string): boolean;
  isEmailAccountValid(email: string): boolean;
  isRegisterPasswordReady(password: string, confirmPassword: string, isLoading: boolean): boolean;
  validatePhoneAccount(account: string): string;
  validateEmailAccount(email: string): string;
  validateVerifyCode(code: string): string;
  validateRegisterPassword(password: string, confirmPassword: string): string;
  hasAccount(account: string): boolean;
  isResetPasswordReady(newPassword: string, confirmPassword: string, isLoading: boolean): boolean;
  isProfileRequiredComplete(username: string, birthDate: string, heightCm: number, weightKg: number, gender: string, isLoading: boolean): boolean;
  resetPassword(account: string, newPassword: string): string;
  changePassword(account: string, oldPassword: string, newPassword: string): string;
  submitProfile(avatarUri: string, username: string, birthDate: string, heightCm: number, weightKg: number, measurementSystem: string, phone: string, countryRegion: string, gender: string): void;
  deleteCurrentAccount(): string;
  clearSessionSilently(): void;
  consumeEffect(): LoginEffect | null;
}
