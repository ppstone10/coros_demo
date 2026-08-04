import router from '@ohos.router';
import { VerifyTargetKind } from '../components/AuthComponents';

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
  static readonly HEALTH_DETAIL: string = 'pages/HealthDetailPage';
  static readonly HEALTH_EDITOR: string = 'pages/HealthCardEditorPage';
  static readonly NORMAL_DATA_EDITOR: string = 'pages/NormalDataEditorPage';
  static readonly NORMAL_DATA_SECTION: string = 'pages/NormalDataSectionPage';
  static readonly DEBUG: string = 'pages/DebugStatePage';

  static toVerifyCode(account: string, targetKind: VerifyTargetKind): router.RouterOptions {
    return { url: AuthRoutes.VERIFY_CODE, params: { account, targetKind } };
  }

  static toPasswordSetup(targetKind: VerifyTargetKind): router.RouterOptions {
    return { url: AuthRoutes.PASSWORD_SETUP, params: { targetKind } };
  }

  static toResetPassword(account: string): router.RouterOptions {
    return { url: AuthRoutes.RESET_PASSWORD, params: { account } };
  }

  static toProfileEdit(): router.RouterOptions {
    return { url: AuthRoutes.PROFILE_COMPLETION, params: { editMode: true } };
  }

  static toHealthDetail(cardId: string): router.RouterOptions {
    return { url: AuthRoutes.HEALTH_DETAIL, params: { cardId } };
  }

  static toNormalDataSection(section: string): router.RouterOptions {
    return { url: AuthRoutes.NORMAL_DATA_SECTION, params: { section } };
  }
}

export interface VerifyCodeParams {
  account: string;
  targetKind: VerifyTargetKind;
}

export interface PasswordSetupParams {
  targetKind: VerifyTargetKind;
}

export interface ResetPasswordParams {
  account: string;
}

export interface LegalDocumentParams {
  returnPage: string;
}

export interface ProfilePageParams {
  editMode?: boolean;
}

export interface HealthDetailParams {
  cardId: string;
}

export interface NormalDataSectionParams {
  section: string;
}
