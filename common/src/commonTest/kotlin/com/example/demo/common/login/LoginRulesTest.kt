package com.example.demo.common.login

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class LoginRulesTest {
    @Test
    fun phoneInputIsNormalizedAndValidatedInCommon() {
        val normalized = LoginRules.normalizePhoneInput("13a10701202999")

        assertEquals("13107012029", normalized)
        assertTrue(LoginRules.isPhoneAccountValid(normalized))
        assertFalse(LoginRules.validatePhoneAccount("123").isValid)
    }

    @Test
    fun emailValidationUsesSharedRule() {
        assertTrue(LoginRules.isEmailAccountValid(" user@example.com "))
        assertFalse(LoginRules.isEmailAccountValid("user@example"))
        assertEquals("请输入有效邮箱", LoginRules.validateEmailAccount("bad-email").message)
    }

    @Test
    fun verifyCodeInputIsFourDigits() {
        assertEquals("1234", LoginRules.normalizeVerifyCodeInput("12a345"))
        assertTrue(LoginRules.isVerifyCodeComplete("1234"))
        assertFalse(LoginRules.isVerifyCodeComplete("123"))
    }

    @Test
    fun registerPasswordRuleIsShared() {
        assertEquals("abcd1234abcd1234abcd", LoginRules.normalizePasswordInput("abcd1234abcd1234abcd!"))
        assertTrue(LoginRules.isRegisterPasswordReady("abc123", "abc123", isLoading = false))
        assertEquals("密码需要为6-20位", LoginRules.validateRegisterPassword("a1", "a1").message)
        assertEquals("密码需要包含字母和数字", LoginRules.validateRegisterPassword("abcdef", "abcdef").message)
        assertEquals("两次输入的密码不一致", LoginRules.validateRegisterPassword("abc123", "abc124").message)
    }

    @Test
    fun loginReadinessUsesSharedRule() {
        assertTrue(LoginRules.isLoginReady("13107012029", "123456", isLoading = false))
        assertFalse(LoginRules.isLoginReady("13107012029", "12345", isLoading = false))
        assertFalse(LoginRules.isLoginReady("13107012029", "123456", isLoading = true))
        assertEquals("请输入账号", LoginRules.validateLoginInput("", "123456").message)
        assertEquals("请输入密码", LoginRules.validateLoginInput("13107012029", "").message)
        assertEquals("密码需要为6-20位", LoginRules.validateLoginInput("13107012029", "12345").message)
        assertTrue(LoginRules.validateLoginInput("13107012029", "123456").isValid)
    }
}
