import { VerifyTargetKind } from '../login/components/AuthComponents';

export class AuthRoutes {
  static readonly ENTRANCE: string = 'pages/EntrancePage';
  static readonly LOGIN: string = 'pages/LoginFormPage';
  static readonly PHONE_REGISTER: string = 'pages/PhoneRegisterPage';
  static readonly EMAIL_REGISTER: string = 'pages/EmailRegisterPage';
  static readonly VERIFY_CODE: string = 'pages/VerifyCodePage';
  static readonly PASSWORD_SETUP: string = 'pages/PasswordSetupPage';
  static readonly FORGOT_PASSWORD: string = 'pages/ForgotPasswordPage';
  static readonly RESET_PASSWORD: string = 'pages/ResetPasswordPage';
  static readonly PROFILE_COMPLETION: string = 'pages/ProfileCompletionPage';
  static readonly SIGNED_IN: string = 'pages/SignedInPage';
  static readonly PRIVACY_POLICY: string = 'pages/PrivacyPolicyPage';
  static readonly SERVICE_TERMS: string = 'pages/ServiceTermsPage';
  static readonly DEBUG: string = 'pages/DebugStatePage';
}

export interface VerifyCodeParams {
  account: string;
  targetKind: number;
}

export interface PasswordSetupParams {
  targetKind: number;
}

export interface ResetPasswordParams {
  account: string;
}

export interface LegalDocumentParams {
  returnPage: string;
}
