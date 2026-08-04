import i18n from '@ohos.i18n';

export const APP_LANGUAGE_CHINESE: string = 'zh-Hans';
export const APP_LANGUAGE_ENGLISH: string = 'en';

PersistentStorage.persistProp<string>('app_language', APP_LANGUAGE_CHINESE);
PersistentStorage.persistProp<number>('app_language_version', 0);

export function currentAppLanguage(): string {
  const stored: string | undefined = AppStorage.get<string>('app_language');
  return stored === APP_LANGUAGE_ENGLISH ? APP_LANGUAGE_ENGLISH : APP_LANGUAGE_CHINESE;
}

export function initializeAppLanguage(): void {
  i18n.System.setAppPreferredLanguage(currentAppLanguage());
}

export function selectAppLanguage(language: string): void {
  const normalized: string = language === APP_LANGUAGE_ENGLISH ? APP_LANGUAGE_ENGLISH : APP_LANGUAGE_CHINESE;
  i18n.System.setAppPreferredLanguage(normalized);
  AppStorage.setOrCreate<string>('app_language', normalized);
  const version: number = AppStorage.get<number>('app_language_version') ?? 0;
  AppStorage.setOrCreate<number>('app_language_version', version + 1);
}
