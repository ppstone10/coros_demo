/**
 * Pure ArkTS contract used by page and Preview module graphs.
 * EntryAbility installs the generated KNOI implementation after native setup.
 */
import { CardEntry, HealthSnapshot } from '../../health/HealthDashboardTypes';
import {
  abilityPreviewVisual,
  activityPreviewVisual,
  bodyPreviewVisual,
  heartRatePreviewVisual,
  hrvPreviewVisual,
  recoveryPreviewVisual,
  restingHeartRatePreviewVisual,
  sleepPreviewVisual,
  stressPreviewVisual,
  trainingAssessmentPreviewVisual,
  trainingLoadPreviewVisual,
  weeklyPlanPreviewVisual
} from '../../preview/VisualPreviewData';
export interface HarmonyLoginServiceContract {
  stateSnapshot(): string;
  exportStoreSnapshot(): string;
  restoreStoreSnapshot(json: string): boolean;
  mergeAccounts(json: string): boolean;
  submit(): void;
  logout(): void;
  clearSessionSilently(): void;
  pauseSession(): void;
  resumeSessionInSameProcess(): void;
  onSessionKicked(): void;
  confirmForceLogin(): void;
  cancelForceLogin(): void;
  confirmKickedDialog(): void;
  checkSessionOnForeground(): void;
  healthScenarioDescriptorsJson(): string;
  healthEditableSectionsJson(): string;
  normalHealthEditFormJson(sectionName: string): string;
  defaultNormalHealthEditFormJson(sectionName: string): string;
  mutateNormalHealthEditFormJson(sectionName: string, valuesSpec: string, groupId: string,
    operationName: string, rowIndex: number): string;
  saveNormalHealthEditForm(sectionName: string, valuesSpec: string): boolean;
  saveNormalHealthEditFormResultJson(sectionName: string, valuesSpec: string): string;
  restoreAllNormalHealthDefaults(): string;
  staleHealthForNewAccount(): void;
  consumeEffectSnapshot(): string;
  setLoginMode(): void;
  setRegisterMode(): void;
  setUsername(value: string): void;
  setPassword(value: string): void;
  setVerifyCode(value: string): void;
  setDisplayName(value: string): void;
  setRegion(value: string): void;
  validateLogin(account: string, password: string): boolean;
  validateLoginInput(account: string, password: string): string;
  requestVerifyCode(account: string): string;
  requestResentVerifyCode(account: string): string;
  verifyCode(account: string, code: string): string;
  verifyCodeRemainingSeconds(account: string): number;
  normalizePhoneInput(value: string): string;
  normalizeEmailInput(value: string): string;
  normalizeVerifyCodeInput(value: string): string;
  normalizePasswordInput(value: string): string;
  isLoginReady(account: string, password: string, isLoading: boolean): boolean;
  isPhoneAccountValid(account: string): boolean;
  isEmailAccountValid(email: string): boolean;
  isRegisterPasswordReady(password: string, confirmPassword: string, isLoading: boolean): boolean;
  isResetPasswordReady(newPassword: string, confirmPassword: string, isLoading: boolean): boolean;
  hasAccount(account: string): boolean;
  isProfileRequiredComplete(username: string, birthDate: string, heightCm: number, weightKg: number,
    gender: string, isLoading: boolean): boolean;
  validatePhoneAccount(account: string): string;
  validateEmailAccount(email: string): string;
  validateVerifyCode(code: string): string;
  validateRegisterPassword(password: string, confirmPassword: string): string;
  resetPassword(account: string, newPassword: string): string;
  changePassword(account: string, oldPassword: string, newPassword: string): string;
  submitProfile(avatarUri: string, username: string, birthDate: string, heightCm: number, weightKg: number,
    measurementSystem: string, phone: string, email: string, countryRegion: string, gender: string): void;
  deleteCurrentAccount(): string;
  profileDefaultUsername(account: string): string;
  profileDefaultPhone(account: string): string;
  profileDefaultEmail(account: string): string;
  loadHealthSnapshot(): string;
  previewHealthSnapshot(): string;
  selectHealthScene(name: string): string;
  refreshHealthSnapshot(): string;
  saveCardConfig(typeNamesCsv: string): string;
  saveHealthBodyWeight(weightKg: number): string;
  exportHealthSnapshot(): string;
  restoreHealthSnapshot(json: string): boolean;
}

let installedService: HarmonyLoginServiceContract | null = null;

export function installHarmonyService(service: HarmonyLoginServiceContract): void {
  installedService = service;
}

/**
 * Preview 安全的 no-op 服务（UI-PREVIEW-010）：native service 未安装（DevEco Previewer）时
 * 返回本实例，页面可正常组合/渲染，交互回调退化为空操作，不再抛"service unavailable"。
 */
class PreviewHarmonyService implements HarmonyLoginServiceContract {
  stateSnapshot(): string {
    return '{"mode":"Login","username":"","password":"","verifyCode":"","displayName":"","selectedRegion":"CN",' +
      '"currentSession":null,"isLoading":false,"isLoggedIn":false,"errorMessage":"",' +
      '"confirmForceLogin":false,"kickedDialogShown":false}';
  }
  exportStoreSnapshot(): string {
    return '{"accounts":[],"currentSession":null,"verifyCodes":[],"defaultAccountsInitialized":false}';
  }
  restoreStoreSnapshot(_json: string): boolean { return true; }
  mergeAccounts(_json: string): boolean { return true; }
  submit(): void { }
  logout(): void { }
  clearSessionSilently(): void { }
  pauseSession(): void { }
  resumeSessionInSameProcess(): void { }
  onSessionKicked(): void { }
  confirmForceLogin(): void { }
  cancelForceLogin(): void { }
  confirmKickedDialog(): void { }
  checkSessionOnForeground(): void { }
  healthScenarioDescriptorsJson(): string {
    return '[{"scenario":"Normal","displayNameKey":"health_scenario_normal"},' +
      '{"scenario":"Abnormal","displayNameKey":"health_scenario_abnormal"}]';
  }
  healthEditableSectionsJson(): string { return '[]'; }
  normalHealthEditFormJson(_sectionName: string): string { return '{}'; }
  defaultNormalHealthEditFormJson(_sectionName: string): string { return '{}'; }
  mutateNormalHealthEditFormJson(_sectionName: string, _valuesSpec: string, _groupId: string,
    _operationName: string, _rowIndex: number): string { return '{}'; }
  saveNormalHealthEditForm(_sectionName: string, _valuesSpec: string): boolean { return true; }
  saveNormalHealthEditFormResultJson(_sectionName: string, _valuesSpec: string): string { return '{}'; }
  restoreAllNormalHealthDefaults(): string { return 'true'; }
  staleHealthForNewAccount(): void { }
  consumeEffectSnapshot(): string { return '{"type":"None"}'; }
  setLoginMode(): void { }
  setRegisterMode(): void { }
  setUsername(_value: string): void { }
  setPassword(_value: string): void { }
  setVerifyCode(_value: string): void { }
  setDisplayName(_value: string): void { }
  setRegion(_value: string): void { }
  validateLogin(_account: string, _password: string): boolean { return false; }
  validateLoginInput(_account: string, _password: string): string { return ''; }
  requestVerifyCode(_account: string): string { return ''; }
  requestResentVerifyCode(_account: string): string { return ''; }
  verifyCode(_account: string, _code: string): string { return ''; }
  verifyCodeRemainingSeconds(_account: string): number { return 0; }
  normalizePhoneInput(value: string): string { return value; }
  normalizeEmailInput(value: string): string { return value; }
  normalizeVerifyCodeInput(value: string): string { return value; }
  normalizePasswordInput(value: string): string { return value; }
  isLoginReady(_account: string, _password: string, _isLoading: boolean): boolean { return false; }
  isPhoneAccountValid(_account: string): boolean { return false; }
  isEmailAccountValid(_email: string): boolean { return false; }
  isRegisterPasswordReady(_password: string, _confirmPassword: string, _isLoading: boolean): boolean { return false; }
  isResetPasswordReady(_newPassword: string, _confirmPassword: string, _isLoading: boolean): boolean { return false; }
  hasAccount(_account: string): boolean { return false; }
  isProfileRequiredComplete(_username: string, _birthDate: string, _heightCm: number, _weightKg: number,
    _gender: string, _isLoading: boolean): boolean { return false; }
  validatePhoneAccount(_account: string): string { return ''; }
  validateEmailAccount(_email: string): string { return ''; }
  validateVerifyCode(_code: string): string { return ''; }
  validateRegisterPassword(_password: string, _confirmPassword: string): string { return ''; }
  resetPassword(_account: string, _newPassword: string): string { return ''; }
  changePassword(_account: string, _oldPassword: string, _newPassword: string): string { return ''; }
  submitProfile(_avatarUri: string, _username: string, _birthDate: string, _heightCm: number, _weightKg: number,
    _measurementSystem: string, _phone: string, _email: string, _countryRegion: string, _gender: string): void { }
  deleteCurrentAccount(): string { return ''; }
  profileDefaultUsername(_account: string): string { return 'COROS User'; }
  profileDefaultPhone(_account: string): string { return _account; }
  profileDefaultEmail(_account: string): string { return _account; }
  loadHealthSnapshot(): string { return buildPreviewHealthSnapshotJson(); }
  previewHealthSnapshot(): string { return buildPreviewHealthSnapshotJson(); }
  selectHealthScene(_name: string): string { return 'true'; }
  refreshHealthSnapshot(): string { return buildPreviewHealthSnapshotJson(); }
  saveCardConfig(_typeNamesCsv: string): string { return '{}'; }
  saveHealthBodyWeight(_weightKg: number): string { return '{}'; }
  exportHealthSnapshot(): string { return '{}'; }
  restoreHealthSnapshot(_json: string): boolean { return true; }
}

const previewService: HarmonyLoginServiceContract = new PreviewHarmonyService();

/** 预览用富数据健康快照（UI-PREVIEW-009：展示有数据状态，供布局调整）。 */
function buildPreviewHealthSnapshotJson(): string {
  const cards: CardEntry[] = [
    { type: 'TodayActivity', titleKey: 'health_card_today_activity_title', summaryKey: 'health_summary_activity_empty', summaryArgs: [], status: 'Available', isRisk: false, visual: activityPreviewVisual() },
    { type: 'WeeklyPlan', titleKey: 'health_card_weekly_plan_title', summaryKey: 'health_summary_weekly_empty', summaryArgs: [], status: 'Available', isRisk: false, visual: weeklyPlanPreviewVisual() },
    { type: 'TrainingLoad', titleKey: 'health_card_training_load_title', summaryKey: 'health_summary_training_load_empty', summaryArgs: [], status: 'Available', isRisk: false, visual: trainingLoadPreviewVisual() },
    { type: 'TrainingAssessment', titleKey: 'health_card_training_assessment_title', summaryKey: 'health_summary_training_assessment_empty', summaryArgs: [], status: 'Available', isRisk: false, visual: trainingAssessmentPreviewVisual() },
    { type: 'Recovery', titleKey: 'health_card_recovery_title', summaryKey: 'health_summary_recovery_empty', summaryArgs: [], status: 'Available', isRisk: false, visual: recoveryPreviewVisual() },
    { type: 'RunningAbility', titleKey: 'health_card_running_ability_title', summaryKey: 'health_summary_running_empty', summaryArgs: [], status: 'Available', isRisk: false, visual: abilityPreviewVisual() },
    { type: 'HeartRate', titleKey: 'health_card_heart_rate_title', summaryKey: 'health_summary_heart_rate_empty', summaryArgs: [], status: 'Available', isRisk: false, visual: heartRatePreviewVisual() },
    { type: 'Stress', titleKey: 'health_card_stress_title', summaryKey: 'health_summary_stress_empty', summaryArgs: [], status: 'Available', isRisk: false, visual: stressPreviewVisual() },
    { type: 'Sleep', titleKey: 'health_card_sleep_title', summaryKey: 'health_summary_sleep_empty', summaryArgs: [], status: 'Available', isRisk: false, visual: sleepPreviewVisual() },
    { type: 'HrvAssessment', titleKey: 'health_card_hrv_assessment_title', summaryKey: 'health_summary_hrv_empty', summaryArgs: [], status: 'Available', isRisk: false, visual: hrvPreviewVisual() },
    { type: 'RestingHeartRate', titleKey: 'health_card_resting_heart_rate_title', summaryKey: 'health_summary_resting_hr_empty', summaryArgs: [], status: 'Available', isRisk: false, visual: restingHeartRatePreviewVisual() },
    { type: 'BodyManagement', titleKey: 'health_card_body_management_title', summaryKey: 'health_summary_body_empty', summaryArgs: [], status: 'Available', isRisk: false, visual: bodyPreviewVisual() }
  ];
  const snapshot: HealthSnapshot = {
    scenario: 'Normal',
    dateLabelKey: 'health_demo_date',
    steps: 8769,
    calories: 769,
    activeMinutes: 69,
    cards: cards,
    enabledTypes: 'ALL'
  };
  return JSON.stringify(snapshot);
}

export function getService(): HarmonyLoginServiceContract {
  if (installedService === null) {
    return previewService;
  }
  return installedService;
}
