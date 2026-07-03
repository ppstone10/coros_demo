package com.example.demo.common.login

data class LoginRuleCheck(
    val isValid: Boolean,
    val message: String? = null
)

object LoginRules {
    const val PhoneAccountLength = 11
    const val VerifyCodeLength = 4
    const val PasswordMinLength = 6
    const val PasswordMaxLength = 20

    fun normalizePhoneInput(value: String): String {
        return value.filter { it.isDigit() }.take(PhoneAccountLength)
    }

    fun normalizeEmailInput(value: String): String {
        return value.trim()
    }

    fun normalizeVerifyCodeInput(value: String): String {
        return value.filter { it.isDigit() }.take(VerifyCodeLength)
    }

    fun normalizePasswordInput(value: String): String {
        return value.take(PasswordMaxLength)
    }

    fun isLoginReady(account: String, password: String, isLoading: Boolean): Boolean {
        return !isLoading &&
            account.trim().isNotEmpty() &&
            password.length >= PasswordMinLength
    }

    fun isPhoneAccountValid(account: String): Boolean {
        return normalizePhoneInput(account).length == PhoneAccountLength
    }

    fun isEmailAccountValid(email: String): Boolean {
        val trimmed = normalizeEmailInput(email)
        val atIndex = trimmed.indexOf("@")
        if (atIndex <= 0) return false
        val domain = trimmed.substring(atIndex + 1)
        return domain.contains(".") && domain.substringBefore(".").isNotBlank()
    }

    fun isVerifyCodeComplete(code: String): Boolean {
        return code.length == VerifyCodeLength && code.all { it.isDigit() }
    }

    fun isRegisterPasswordValid(password: String): Boolean {
        return password.length in PasswordMinLength..PasswordMaxLength &&
            password.all { it.isDigit() || it in 'A'..'Z' || it in 'a'..'z' } &&
            password.any { it.isLetter() } &&
            password.any { it.isDigit() }
    }

    fun isRegisterPasswordReady(
        password: String,
        confirmPassword: String,
        isLoading: Boolean
    ): Boolean {
        return !isLoading &&
            password.isNotEmpty() &&
            confirmPassword == password
    }

    fun validatePhoneAccount(account: String): LoginRuleCheck {
        return if (isPhoneAccountValid(account)) {
            LoginRuleCheck(isValid = true)
        } else {
            LoginRuleCheck(isValid = false, message = "请输入11位手机号")
        }
    }

    fun validateEmailAccount(email: String): LoginRuleCheck {
        return if (isEmailAccountValid(email)) {
            LoginRuleCheck(isValid = true)
        } else {
            LoginRuleCheck(isValid = false, message = "请输入有效邮箱")
        }
    }

    fun validateVerifyCode(code: String): LoginRuleCheck {
        return if (isVerifyCodeComplete(code)) {
            LoginRuleCheck(isValid = true)
        } else {
            LoginRuleCheck(isValid = false, message = "请输入验证码")
        }
    }

    fun validateRegisterPassword(password: String, confirmPassword: String): LoginRuleCheck {
        return when {
            password.length !in PasswordMinLength..PasswordMaxLength -> {
                LoginRuleCheck(isValid = false, message = "密码需要为6-20位")
            }

            !password.all { it.isDigit() || it in 'A'..'Z' || it in 'a'..'z' } -> {
                LoginRuleCheck(isValid = false, message = "密码只能包含字母和数字")
            }

            !password.any { it.isLetter() } || !password.any { it.isDigit() } -> {
                LoginRuleCheck(isValid = false, message = "密码需要包含字母和数字")
            }

            password != confirmPassword -> {
                LoginRuleCheck(isValid = false, message = "两次输入的密码不一致")
            }

            else -> LoginRuleCheck(isValid = true)
        }
    }
}
