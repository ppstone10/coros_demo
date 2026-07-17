package com.example.demo.common.login

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class LoginRulesTest {

    @Test
    fun mockErrorMapsToTheProtoErrorMessage() {
        val message = MockError.RegionRequired.toProtoMessage()
        assertEquals("REGION_REQUIRED", message.code)
        assertEquals(MockError.RegionRequired, message.toMockError())
    }
    @Test
    fun registrationRegionAndLegacyNamesNormalizeToCountryCodes() {
        assertEquals("CN", "CN".toProfileCountryCode())
        assertEquals("US", "us".toProfileCountryCode())
        assertEquals("CN", "中国".toProfileCountryCode())
        assertEquals("US", "United States".toProfileCountryCode())
        assertEquals("GB", "英国".toProfileCountryCode())
        assertEquals("JP", "Japan".toProfileCountryCode())
        assertEquals("CN", "unknown".toProfileCountryCode())
        assertEquals("US", "".toProfileCountryCode(fallback = "US"))
    }

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
        assertEquals(AuthMessageKeys.ValidationEmailInvalid, LoginRules.validateEmailAccount("bad-email").message)
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
        assertEquals(AuthMessageKeys.ValidationPasswordLength, LoginRules.validateRegisterPassword("a1", "a1").message)
        assertEquals(AuthMessageKeys.ValidationPasswordLetterAndDigit, LoginRules.validateRegisterPassword("abcdef", "abcdef").message)
        assertEquals(AuthMessageKeys.ValidationPasswordMismatch, LoginRules.validateRegisterPassword("abc123", "abc124").message)
    }

    @Test
    fun loginReadinessUsesSharedRule() {
        assertTrue(LoginRules.isLoginReady("13107012029", "123456", isLoading = false))
        assertFalse(LoginRules.isLoginReady("13107012029", "12345", isLoading = false))
        assertFalse(LoginRules.isLoginReady("13107012029", "123456", isLoading = true))
        assertEquals(AuthMessageKeys.ValidationAccountRequired, LoginRules.validateLoginInput("", "123456").message)
        assertEquals(AuthMessageKeys.ValidationPasswordRequired, LoginRules.validateLoginInput("13107012029", "").message)
        assertEquals(AuthMessageKeys.ValidationPasswordLength, LoginRules.validateLoginInput("13107012029", "12345").message)
        assertTrue(LoginRules.validateLoginInput("13107012029", "123456").isValid)
    }

    @Test
    fun validationFailuresExposeStableLocalizationKeys() {
        val keys = listOf(
            LoginRules.validatePhoneAccount("123").message,
            LoginRules.validateEmailAccount("bad-email").message,
            LoginRules.validateVerifyCode("12").message,
            LoginRules.validateRegisterPassword("a1", "a1").message,
            LoginRules.validateRegisterPassword("abcdef", "abcdef").message,
            LoginRules.validateRegisterPassword("abc123", "abc124").message
        )

        assertTrue(keys.all { it?.startsWith("auth_") == true })
    }
}
