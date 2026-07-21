package com.example.demo.common.login

/**
 * Platform-independent semantic keys for authentication messages.
 *
 * The shared layer decides which message applies. Android, iOS, and HarmonyOS
 * resolve the key through their native localization systems.
 */
object AuthMessageKeys {
    const val ErrorAuthRequired = "auth_error_auth_required"
    const val ErrorInvalidParam = "auth_error_invalid_param"
    const val ErrorAccountExists = "auth_error_account_exists"
    const val ErrorAccountNotFound = "auth_error_account_not_found"
    const val ErrorPasswordIncorrect = "auth_error_password_incorrect"
    const val ErrorNewPasswordSameAsOld = "auth_error_new_password_same_as_old"
    const val ErrorVerifyCodeInvalid = "auth_error_verify_code_invalid"
    const val ErrorVerifyCodeExpired = "auth_error_verify_code_expired"
    const val ErrorEmptyData = "auth_error_empty_data"
    const val ErrorCorruptedData = "auth_error_corrupted_data"
    const val ErrorPersistFailed = "auth_error_persist_failed"
    const val ErrorRegionRequired = "auth_error_region_required"

    const val ValidationAccountRequired = "auth_validation_account_required"
    const val ValidationPasswordRequired = "auth_validation_password_required"
    const val ValidationPasswordLength = "auth_validation_password_length"
    const val ValidationPhoneInvalid = "auth_validation_phone_invalid"
    const val ValidationEmailInvalid = "auth_validation_email_invalid"
    const val ValidationVerifyCodeRequired = "auth_validation_verify_code_required"
    const val ValidationPasswordAlphanumericOnly = "auth_validation_password_alphanumeric_only"
    const val ValidationPasswordLetterAndDigit = "auth_validation_password_letter_and_digit"
    const val ValidationPasswordMismatch = "auth_validation_password_mismatch"
    const val ValidationRegisterIncomplete = "auth_validation_register_incomplete"
    const val ValidationLoginIncomplete = "auth_validation_login_incomplete"
    const val ErrorMinimumCardsRequired = "health_error_minimum_cards_required"
}
