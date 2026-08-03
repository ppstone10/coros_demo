import { HarmonyLoginService } from '../knoi/provider';
import { HarmonyLoginServiceContract } from './HarmonyServiceProvider';

/** Runtime-only nominal adapter between generated KNOI type and the pure page contract. */
export class KnoiHarmonyServiceAdapter implements HarmonyLoginServiceContract {
  private service: HarmonyLoginService;

  constructor(service: HarmonyLoginService) { this.service = service; }

  stateSnapshot(): string { return this.service.stateSnapshot(); }
  exportStoreSnapshot(): string { return this.service.exportStoreSnapshot(); }
  restoreStoreSnapshot(json: string): boolean { return this.service.restoreStoreSnapshot(json); }
  submit(): void { this.service.submit(); }
  logout(): void { this.service.logout(); }
  clearSessionSilently(): void { this.service.clearSessionSilently(); }
  pauseSession(): void { this.service.pauseSession(); }
  resumeSessionInSameProcess(): void { this.service.resumeSessionInSameProcess(); }
  healthScenarioDescriptorsJson(): string { return this.service.healthScenarioDescriptorsJson(); }
  healthEditableSectionsJson(): string { return this.service.healthEditableSectionsJson(); }
  normalHealthEditFormJson(sectionName: string): string { return this.service.normalHealthEditFormJson(sectionName); }
  defaultNormalHealthEditFormJson(sectionName: string): string {
    return this.service.defaultNormalHealthEditFormJson(sectionName);
  }
  mutateNormalHealthEditFormJson(sectionName: string, valuesSpec: string, groupId: string,
    operationName: string, rowIndex: number): string {
    return this.service.mutateNormalHealthEditFormJson(sectionName, valuesSpec, groupId, operationName, rowIndex);
  }
  saveNormalHealthEditForm(sectionName: string, valuesSpec: string): boolean {
    return this.service.saveNormalHealthEditForm(sectionName, valuesSpec);
  }
  saveNormalHealthEditFormResultJson(sectionName: string, valuesSpec: string): string {
    return this.service.saveNormalHealthEditFormResultJson(sectionName, valuesSpec);
  }
  restoreAllNormalHealthDefaults(): string { return this.service.restoreAllNormalHealthDefaults(); }
  staleHealthForNewAccount(): void { this.service.staleHealthForNewAccount(); }
  consumeEffectSnapshot(): string { return this.service.consumeEffectSnapshot(); }
  setLoginMode(): void { this.service.setLoginMode(); }
  setRegisterMode(): void { this.service.setRegisterMode(); }
  setUsername(value: string): void { this.service.setUsername(value); }
  setPassword(value: string): void { this.service.setPassword(value); }
  setVerifyCode(value: string): void { this.service.setVerifyCode(value); }
  setDisplayName(value: string): void { this.service.setDisplayName(value); }
  setRegion(value: string): void { this.service.setRegion(value); }
  validateLogin(account: string, password: string): boolean { return this.service.validateLogin(account, password); }
  validateLoginInput(account: string, password: string): string {
    return this.service.validateLoginInput(account, password);
  }
  requestVerifyCode(account: string): string { return this.service.requestVerifyCode(account); }
  requestResentVerifyCode(account: string): string { return this.service.requestResentVerifyCode(account); }
  verifyCode(account: string, code: string): string { return this.service.verifyCode(account, code); }
  verifyCodeRemainingSeconds(account: string): number { return this.service.verifyCodeRemainingSeconds(account); }
  normalizePhoneInput(value: string): string { return this.service.normalizePhoneInput(value); }
  normalizeEmailInput(value: string): string { return this.service.normalizeEmailInput(value); }
  normalizeVerifyCodeInput(value: string): string { return this.service.normalizeVerifyCodeInput(value); }
  normalizePasswordInput(value: string): string { return this.service.normalizePasswordInput(value); }
  isLoginReady(account: string, password: string, isLoading: boolean): boolean {
    return this.service.isLoginReady(account, password, isLoading);
  }
  isPhoneAccountValid(account: string): boolean { return this.service.isPhoneAccountValid(account); }
  isEmailAccountValid(email: string): boolean { return this.service.isEmailAccountValid(email); }
  isRegisterPasswordReady(password: string, confirmPassword: string, isLoading: boolean): boolean {
    return this.service.isRegisterPasswordReady(password, confirmPassword, isLoading);
  }
  isResetPasswordReady(newPassword: string, confirmPassword: string, isLoading: boolean): boolean {
    return this.service.isResetPasswordReady(newPassword, confirmPassword, isLoading);
  }
  hasAccount(account: string): boolean { return this.service.hasAccount(account); }
  isProfileRequiredComplete(username: string, birthDate: string, heightCm: number, weightKg: number,
    gender: string, isLoading: boolean): boolean {
    return this.service.isProfileRequiredComplete(username, birthDate, heightCm, weightKg, gender, isLoading);
  }
  validatePhoneAccount(account: string): string { return this.service.validatePhoneAccount(account); }
  validateEmailAccount(email: string): string { return this.service.validateEmailAccount(email); }
  validateVerifyCode(code: string): string { return this.service.validateVerifyCode(code); }
  validateRegisterPassword(password: string, confirmPassword: string): string {
    return this.service.validateRegisterPassword(password, confirmPassword);
  }
  resetPassword(account: string, newPassword: string): string { return this.service.resetPassword(account, newPassword); }
  changePassword(account: string, oldPassword: string, newPassword: string): string {
    return this.service.changePassword(account, oldPassword, newPassword);
  }
  submitProfile(avatarUri: string, username: string, birthDate: string, heightCm: number, weightKg: number,
    measurementSystem: string, phone: string, email: string, countryRegion: string, gender: string): void {
    this.service.submitProfile(avatarUri, username, birthDate, heightCm, weightKg, measurementSystem,
      phone, email, countryRegion, gender);
  }
  deleteCurrentAccount(): string { return this.service.deleteCurrentAccount(); }
  profileDefaultUsername(account: string): string { return this.service.profileDefaultUsername(account); }
  profileDefaultPhone(account: string): string { return this.service.profileDefaultPhone(account); }
  profileDefaultEmail(account: string): string { return this.service.profileDefaultEmail(account); }
  loadHealthSnapshot(): string { return this.service.loadHealthSnapshot(); }
  previewHealthSnapshot(): string { return this.service.previewHealthSnapshot(); }
  selectHealthScene(name: string): string { return this.service.selectHealthScene(name); }
  refreshHealthSnapshot(): string { return this.service.refreshHealthSnapshot(); }
  saveCardConfig(typeNamesCsv: string): string { return this.service.saveCardConfig(typeNamesCsv); }
  saveHealthBodyWeight(weightKg: number): string { return this.service.saveHealthBodyWeight(weightKg); }
  exportHealthSnapshot(): string { return this.service.exportHealthSnapshot(); }
  restoreHealthSnapshot(json: string): boolean { return this.service.restoreHealthSnapshot(json); }
}
