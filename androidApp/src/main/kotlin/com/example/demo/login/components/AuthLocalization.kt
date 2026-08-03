package com.example.demo.login.components

import android.content.res.Resources
import androidx.annotation.StringRes
import com.example.demo.R
import com.example.demo.common.login.AuthMessageKeys

@StringRes
private fun authMessageResourceId(key: String): Int? = when (key) {
    AuthMessageKeys.ErrorAuthRequired -> R.string.auth_error_auth_required
    AuthMessageKeys.ErrorInvalidParam -> R.string.auth_error_invalid_param
    AuthMessageKeys.ErrorAccountExists -> R.string.auth_error_account_exists
    AuthMessageKeys.ErrorAccountNotFound -> R.string.auth_error_account_not_found
    AuthMessageKeys.ErrorPasswordIncorrect -> R.string.auth_error_password_incorrect
    AuthMessageKeys.ErrorNewPasswordSameAsOld -> R.string.auth_error_new_password_same_as_old
    AuthMessageKeys.ErrorVerifyCodeInvalid -> R.string.auth_error_verify_code_invalid
    AuthMessageKeys.ErrorVerifyCodeExpired -> R.string.auth_error_verify_code_expired
    AuthMessageKeys.ErrorEmptyData -> R.string.auth_error_empty_data
    AuthMessageKeys.ErrorCorruptedData -> R.string.auth_error_corrupted_data
    AuthMessageKeys.ErrorPersistFailed -> R.string.auth_error_persist_failed
    AuthMessageKeys.ErrorRegionRequired -> R.string.auth_error_region_required
    AuthMessageKeys.ValidationAccountRequired -> R.string.auth_validation_account_required
    AuthMessageKeys.ValidationPasswordRequired -> R.string.auth_validation_password_required
    AuthMessageKeys.ValidationPasswordLength -> R.string.auth_validation_password_length
    AuthMessageKeys.ValidationPhoneInvalid -> R.string.auth_validation_phone_invalid
    AuthMessageKeys.ValidationEmailInvalid -> R.string.auth_validation_email_invalid
    AuthMessageKeys.ValidationVerifyCodeRequired -> R.string.auth_validation_verify_code_required
    AuthMessageKeys.ValidationPasswordAlphanumericOnly -> R.string.auth_validation_password_alphanumeric_only
    AuthMessageKeys.ValidationPasswordLetterAndDigit -> R.string.auth_validation_password_letter_and_digit
    AuthMessageKeys.ValidationPasswordMismatch -> R.string.auth_validation_password_mismatch
    AuthMessageKeys.ValidationRegisterIncomplete -> R.string.auth_validation_register_incomplete
    AuthMessageKeys.ValidationLoginIncomplete -> R.string.auth_validation_login_incomplete
    else -> null
}

fun Resources.localizedAuthMessage(message: String?): String? {
    if (message.isNullOrBlank()) return message
    val resourceId = authMessageResourceId(message) ?: return message
    return getString(resourceId)
}
