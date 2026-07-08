/***
*    !!!  GEN CODE DO NOT EDIT  !!!
***/
import { getService } from "@kuiklybase/knoi"

export interface HarmonyLoginService {
            
   stateSnapshot(): string;

   exportStoreSnapshot(): string;

   restoreStoreSnapshot(json: string): boolean;

   validateStoreSnapshotRoundTrip(json: string): boolean;

   validateCurrentStoreSnapshotRoundTrip(): boolean;

   setLoginMode(): void;

   setRegisterMode(): void;

   setUsername(value: string): void;

   setPassword(value: string): void;

   setVerifyCode(value: string): void;

   setDisplayName(value: string): void;

   setRegion(value: string): void;

   submit(): void;

   logout(): void;

   clearSessionSilently(): void;

   consumeEffectSnapshot(): string;

   validateLogin(account: string, password: string): boolean;

   validateLoginInput(account: string, password: string): string;

   requestVerifyCode(account: string): string;

   requestResentVerifyCode(account: string): string;

   verifyCode(account: string, code: string): string;

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

   isProfileRequiredComplete(username: string, birthDate: string, heightCm: number, weightKg: number, gender: string, isLoading: boolean): boolean;

   validatePhoneAccount(account: string): string;

   validateEmailAccount(email: string): string;

   validateVerifyCode(code: string): string;

   validateRegisterPassword(password: string, confirmPassword: string): string;

   resetPassword(account: string, newPassword: string): string;

   changePassword(account: string, oldPassword: string, newPassword: string): string;

   submitProfile(avatarUri: string, username: string, birthDate: string, heightCm: number, weightKg: number, measurementSystem: string, phone: string, countryRegion: string, gender: string): void;

   deleteCurrentAccount(): string;

}

export function getHarmonyLoginService(): HarmonyLoginService {
   return getService<HarmonyLoginService>("HarmonyLoginService")
}

