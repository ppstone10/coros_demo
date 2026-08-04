import router from '@ohos.router';
import { VerifyTargetKind } from '../components/AuthComponents';

interface AuthRouteGroup {
  ENTRANCE: string;
  LOGIN: string;
  PHONE_REGISTER: string;
  EMAIL_REGISTER: string;
  VERIFY_CODE: string;
  PASSWORD_SETUP: string;
  FORGOT_PASSWORD: string;
  RESET_PASSWORD: string;
  PROFILE_COMPLETION: string;
  PRIVACY_POLICY: string;
  SERVICE_TERMS: string;
}

interface HomeRouteGroup {
  SIGNED_IN: string;
}

interface HealthRouteGroup {
  DETAIL: string;
  EDITOR: string;
  NORMAL_DATA_EDITOR: string;
  NORMAL_DATA_SECTION: string;
}

interface DebugRouteGroup {
  DEBUG: string;
}

/**
 * 全局路由 URL 注册表（与 main_pages.json 一一对应）。
 * 常量按域分组：auth（账号流程）、home（主壳）、health（健康二级页）、debug（调试）。
 * URL 字符串与 main_pages.json 保持同步，不得擅自改动路径。
 */
export class AuthRoutes {
  static auth: AuthRouteGroup = {
    ENTRANCE: 'pages/EntrancePage',
    LOGIN: 'pages/LoginFormPage',
    PHONE_REGISTER: 'pages/PhoneRegisterPage',
    EMAIL_REGISTER: 'pages/EmailRegisterPage',
    VERIFY_CODE: 'pages/VerifyCodePage',
    PASSWORD_SETUP: 'pages/PasswordSetupPage',
    FORGOT_PASSWORD: 'pages/ForgotPasswordPage',
    RESET_PASSWORD: 'pages/ResetPasswordPage',
    PROFILE_COMPLETION: 'pages/ProfileCompletionPage',
    PRIVACY_POLICY: 'pages/PrivacyPolicyPage',
    SERVICE_TERMS: 'pages/ServiceTermsPage'
  };

  static home: HomeRouteGroup = {
    SIGNED_IN: 'pages/SignedInPage'
  };

  static health: HealthRouteGroup = {
    DETAIL: 'pages/HealthDetailPage',
    EDITOR: 'pages/HealthCardEditorPage',
    NORMAL_DATA_EDITOR: 'pages/NormalDataEditorPage',
    NORMAL_DATA_SECTION: 'pages/NormalDataSectionPage'
  };

  static debug: DebugRouteGroup = {
    DEBUG: 'pages/DebugStatePage'
  };

  static toVerifyCode(account: string, targetKind: VerifyTargetKind): router.RouterOptions {
    return { url: AuthRoutes.auth.VERIFY_CODE, params: { account, targetKind } };
  }

  static toPasswordSetup(targetKind: VerifyTargetKind): router.RouterOptions {
    return { url: AuthRoutes.auth.PASSWORD_SETUP, params: { targetKind } };
  }

  static toResetPassword(account: string): router.RouterOptions {
    return { url: AuthRoutes.auth.RESET_PASSWORD, params: { account } };
  }

  static toProfileEdit(): router.RouterOptions {
    return { url: AuthRoutes.auth.PROFILE_COMPLETION, params: { editMode: true } };
  }

  static toHealthDetail(cardId: string): router.RouterOptions {
    return { url: AuthRoutes.health.DETAIL, params: { cardId } };
  }

  static toNormalDataSection(section: string): router.RouterOptions {
    return { url: AuthRoutes.health.NORMAL_DATA_SECTION, params: { section } };
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
