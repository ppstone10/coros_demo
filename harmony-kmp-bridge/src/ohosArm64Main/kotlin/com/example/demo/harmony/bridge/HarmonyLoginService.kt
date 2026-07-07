package com.example.demo.harmony.bridge

import com.example.demo.common.login.AuthMode
import com.example.demo.common.login.AuthSession
import com.example.demo.common.login.AuthStoreDataSource
import com.example.demo.common.login.LocalMockAuthRepository
import com.example.demo.common.login.LoginEffect
import com.example.demo.common.login.LoginFacade
import com.example.demo.common.login.LoginState
import com.example.demo.common.login.LoginStore
import com.example.demo.common.login.MockAccount
import com.example.demo.common.login.MockAuthSession
import com.example.demo.common.login.MockAuthStore
import com.example.demo.common.login.MockVerifyCodeState
import com.example.demo.common.login.UserProfile
import com.tencent.tmm.knoi.annotation.ServiceProvider

@ServiceProvider
open class HarmonyLoginService {
    private var dataSource: AuthStoreDataSource = object : AuthStoreDataSource {
        private var store: MockAuthStore = MockAuthStore()
        override fun load(): MockAuthStore = store
        override fun save(s: MockAuthStore): Boolean { store = s; return true }
    }
    private var facade: LoginFacade = LoginFacade(LoginStore.create(LocalMockAuthRepository(dataSource)))

    fun stateSnapshot(): String {
        return facade.state.toJson()
    }

    fun exportStoreSnapshot(): String {
        return generateStoreSnapshot()
    }

    fun restoreStoreSnapshot(json: String): Boolean {
        if (json.isBlank()) return false
        return try {
            val store = parseMockAuthStore(json)
            val newDataSource = object : AuthStoreDataSource {
                private var s: MockAuthStore = store
                override fun load(): MockAuthStore = s
                override fun save(updated: MockAuthStore): Boolean { s = updated; return true }
            }
            dataSource = newDataSource
            facade = LoginFacade(LoginStore.create(LocalMockAuthRepository(dataSource)))
            true
        } catch (e: Exception) {
            false
        }
    }

    fun setLoginMode() {
        facade.setLoginMode()
    }

    fun setRegisterMode() {
        facade.setRegisterMode()
    }

    fun setUsername(value: String) {
        facade.setUsername(value)
    }

    fun setPassword(value: String) {
        facade.setPassword(value)
    }

    fun setVerifyCode(value: String) {
        facade.setVerifyCode(value)
    }

    fun setDisplayName(value: String) {
        facade.setDisplayName(value)
    }

    fun setRegion(value: String) {
        facade.setRegion(value)
    }

    fun submit() {
        facade.submit()
    }

    fun logout() {
        facade.logout()
    }

    fun clearSessionSilently() {
        facade.clearSessionSilently()
    }

    fun consumeEffectSnapshot(): String {
        return facade.consumeEffect().toJson()
    }

    fun validateLogin(account: String, password: String): Boolean {
        return facade.isLoginReady(account, password, isLoading = false)
    }

    fun validateLoginInput(account: String, password: String): String {
        val normalizedAccount = account.trim()
        return when {
            normalizedAccount.isBlank() -> "请输入账号"
            password.isBlank() -> "请输入密码"
            password.length < 6 -> "密码需要为6-20位"
            else -> ""
        }
    }

    fun requestVerifyCode(account: String): String {
        return facade.requestVerifyCode(account).orEmpty()
    }

    fun requestResentVerifyCode(account: String): String {
        return facade.requestResentVerifyCode(account).orEmpty()
    }

    fun verifyCode(account: String, code: String): String {
        return facade.verifyCode(account, code).orEmpty()
    }

    fun normalizePhoneInput(value: String): String {
        return facade.normalizePhoneInput(value)
    }

    fun normalizeEmailInput(value: String): String {
        return facade.normalizeEmailInput(value)
    }

    fun normalizeVerifyCodeInput(value: String): String {
        return facade.normalizeVerifyCodeInput(value)
    }

    fun normalizePasswordInput(value: String): String {
        return facade.normalizePasswordInput(value)
    }

    fun isLoginReady(account: String, password: String, isLoading: Boolean): Boolean {
        return facade.isLoginReady(account, password, isLoading)
    }

    fun isPhoneAccountValid(account: String): Boolean {
        return facade.isPhoneAccountValid(account)
    }

    fun isEmailAccountValid(email: String): Boolean {
        return facade.isEmailAccountValid(email)
    }

    fun isRegisterPasswordReady(password: String, confirmPassword: String, isLoading: Boolean): Boolean {
        return facade.isRegisterPasswordReady(password, confirmPassword, isLoading)
    }

    fun isResetPasswordReady(newPassword: String, confirmPassword: String, isLoading: Boolean): Boolean {
        return facade.isResetPasswordReady(newPassword, confirmPassword, isLoading)
    }

    fun hasAccount(account: String): Boolean {
        return facade.hasAccount(account)
    }

    fun isProfileRequiredComplete(
        username: String,
        birthDate: String,
        heightCm: Int,
        weightKg: Double,
        gender: String,
        isLoading: Boolean
    ): Boolean {
        return facade.isProfileRequiredComplete(username, birthDate, heightCm, weightKg, gender, isLoading)
    }

    fun validatePhoneAccount(account: String): String {
        return facade.validatePhoneAccount(account).orEmpty()
    }

    fun validateEmailAccount(email: String): String {
        return facade.validateEmailAccount(email).orEmpty()
    }

    fun validateVerifyCode(code: String): String {
        return facade.validateVerifyCode(code).orEmpty()
    }

    fun validateRegisterPassword(password: String, confirmPassword: String): String {
        return facade.validateRegisterPassword(password, confirmPassword).orEmpty()
    }

    fun resetPassword(account: String, newPassword: String): String {
        return facade.resetPassword(account, newPassword).orEmpty()
    }

    fun changePassword(account: String, oldPassword: String, newPassword: String): String {
        return facade.changePassword(account, oldPassword, newPassword).orEmpty()
    }

    fun submitProfile(
        avatarUri: String,
        username: String,
        birthDate: String,
        heightCm: Int,
        weightKg: Double,
        measurementSystem: String,
        phone: String,
        countryRegion: String,
        gender: String
    ) {
        facade.submitProfile(
            avatarUri = avatarUri.takeIf { it.isNotBlank() },
            username = username,
            birthDate = birthDate,
            heightCm = heightCm,
            weightKg = weightKg,
            measurementSystem = measurementSystem,
            phone = phone,
            countryRegion = countryRegion,
            gender = gender
        )
    }

    fun deleteCurrentAccount(): String {
        return facade.deleteCurrentAccount().orEmpty()
    }

    private fun LoginState.toJson(): String {
        return buildString {
            append('{')
            appendJsonField("mode", mode.name)
            append(',')
            appendJsonField("username", username)
            append(',')
            appendJsonField("password", password)
            append(',')
            appendJsonField("verifyCode", verifyCode)
            append(',')
            appendJsonField("displayName", displayName)
            append(',')
            appendJsonField("selectedRegion", selectedRegion)
            append(',')
            append("\"currentSession\":")
            append(currentSession.toJson())
            append(',')
            append("\"isLoading\":")
            append(isLoading)
            append(',')
            append("\"isLoggedIn\":")
            append(isLoggedIn)
            append(',')
            appendJsonField("errorMessage", errorMessage.orEmpty())
            append('}')
        }
    }

    private fun LoginEffect?.toJson(): String {
        return when (this) {
            null -> """{"type":"None"}"""
            is LoginEffect.AuthSucceeded -> buildString {
                append('{')
                appendJsonField("type", "AuthSucceeded")
                append(',')
                appendJsonField("mode", mode.name)
                append(',')
                append("\"session\":")
                append(session.toJson())
                append('}')
            }

            is LoginEffect.ProfileSaved -> buildString {
                append('{')
                appendJsonField("type", "ProfileSaved")
                append(',')
                append("\"session\":")
                append(session.toJson())
                append('}')
            }

            LoginEffect.LoggedOut -> """{"type":"LoggedOut"}"""
            LoginEffect.SessionExpired -> """{"type":"SessionExpired","message":"登录已过期"}"""
            is LoginEffect.ShowMessage -> buildString {
                append('{')
                appendJsonField("type", "ShowMessage")
                append(',')
                appendJsonField("message", message)
                append('}')
            }

            is LoginEffect.NavigateHome -> buildString {
                append('{')
                appendJsonField("type", "NavigateHome")
                append(',')
                appendJsonField("message", user.displayName)
                append('}')
            }
        }
    }

    private fun AuthSession?.toJson(): String {
        if (this == null) return "null"
        return buildString {
            append('{')
            appendJsonField("account", account)
            append(',')
            appendJsonField("displayName", resolvedDisplayName)
            append(',')
            appendJsonField("region", region)
            append(',')
            append("\"isValid\":")
            append(isValid)
            append(',')
            append("\"isProfileComplete\":")
            append(isProfileComplete)
            append('}')
        }
    }

    private fun StringBuilder.appendJsonField(name: String, value: String) {
        append('"')
        append(name)
        append("\":\"")
        append(value.jsonEscaped())
        append('"')
    }

    private fun String.jsonEscaped(): String {
        return buildString {
            this@jsonEscaped.forEach { char ->
                when (char) {
                    '\\' -> append("\\\\")
                    '"' -> append("\\\"")
                    '\n' -> append("\\n")
                    '\r' -> append("\\r")
                    '\t' -> append("\\t")
                    else -> append(char)
                }
            }
        }
    }

    private fun generateStoreSnapshot(): String {
        val accounts = dataSource.load().accounts
        return buildString {
            append('{')
            append("\"accounts\":")
            append(accounts.toAccountJson())
            append(',')
            append("\"currentSession\":null")
            append(',')
            append("\"verifyCodes\":[]")
            append(',')
            append("\"defaultAccountsInitialized\":true")
            append('}')
        }
    }

    private fun List<MockAccount>.toAccountJson(): String {
        if (isEmpty()) return "[]"
        return buildString {
            append('[')
            this@toAccountJson.forEachIndexed { index, account ->
                if (index > 0) append(',')
                append(account.toJson())
            }
            append(']')
        }
    }

    private fun MockAccount.toJson(): String {
        return buildString {
            append('{')
            appendJsonField("userId", userId)
            append(',')
            appendJsonField("account", account)
            append(',')
            appendJsonField("passwordHash", passwordHash)
            append(',')
            appendJsonField("displayName", displayName)
            append(',')
            appendJsonField("region", region)
            append(',')
            append("\"profile\":")
            append(profile.toJson())
            append('}')
        }
    }

    private fun UserProfile?.toJson(): String {
        if (this == null) return "null"
        return buildString {
            append('{')
            appendJsonField("username", username)
            append(',')
            appendJsonField("birthDate", birthDate)
            append(',')
            append("\"heightCm\":")
            append(heightCm?.toString() ?: "null")
            append(',')
            append("\"weightKg\":")
            append(weightKg?.toString() ?: "null")
            append(',')
            appendJsonField("measurementSystem", measurementSystem.name)
            append(',')
            appendJsonField("phone", phone)
            append(',')
            appendJsonField("countryRegion", countryRegion)
            append(',')
            appendJsonField("gender", gender?.name ?: "null")
            append(',')
            append("\"avatarUri\":")
            append(avatarUri?.let { "\"$it\"" } ?: "null")
            append('}')
        }
    }
}

private fun parseMockAuthStore(json: String): MockAuthStore {
    val accounts = parseAccounts(json)
    val session = parseSession(json)
    val verifyCodes = parseVerifyCodes(json)
    val defaultInit = json.contains("\"defaultAccountsInitialized\":true")
    return MockAuthStore(accounts, session, verifyCodes, defaultInit)
}

private fun parseAccounts(json: String): List<MockAccount> {
    val list = mutableListOf<MockAccount>()
    val start = json.indexOf("\"accounts\":[")
    if (start < 0) return list
    val arrayEnd = findArrayEnd(json, start + 12)
    val arrayContent = json.substring(start + 12, arrayEnd)
    if (arrayContent.isBlank()) return list
    var pos = 0
    while (pos < arrayContent.length) {
        pos = skipWhitespace(arrayContent, pos)
        if (pos >= arrayContent.length || arrayContent[pos] != '{') break
        val objEnd = findObjectEnd(arrayContent, pos)
        val accountJson = arrayContent.substring(pos, objEnd)
        list.add(parseAccount(accountJson))
        pos = objEnd
        pos = skipWhitespace(arrayContent, pos)
        if (pos < arrayContent.length && arrayContent[pos] == ',') pos++
    }
    return list
}

private fun parseSession(json: String): MockAuthSession? {
    val start = json.indexOf("\"currentSession\":{")
    if (start < 0) return null
    val objEnd = findObjectEnd(json, start + 19)
    return parseSessionObject(json.substring(start + 18, objEnd))
}

private fun parseVerifyCodes(json: String): List<MockVerifyCodeState> {
    return emptyList()
}

private fun parseAccount(json: String): MockAccount {
    return MockAccount(
        userId = extractString(json, "userId"),
        account = extractString(json, "account"),
        passwordHash = extractString(json, "passwordHash"),
        displayName = extractString(json, "displayName"),
        region = extractString(json, "region"),
        profile = parseProfile(json)
    )
}

private fun parseSessionObject(json: String): MockAuthSession {
    return MockAuthSession(
        userId = extractString(json, "userId"),
        account = extractString(json, "account"),
        displayName = extractString(json, "displayName"),
        region = extractString(json, "region"),
        isValid = json.contains("\"isValid\":true"),
        profile = parseProfile(json)
    )
}

private fun parseProfile(json: String): UserProfile? {
    val start = json.indexOf("\"profile\":{")
    if (start < 0) return null
    val objEnd = findObjectEnd(json, start + 11)
    val profileJson = json.substring(start + 10, objEnd)
    val username = extractString(profileJson, "username")
    val birthDate = extractString(profileJson, "birthDate")
    val heightStr = extractRawValue(profileJson, "heightCm")
    val weightStr = extractRawValue(profileJson, "weightKg")
    val measureSys = extractString(profileJson, "measurementSystem")
    val phone = extractString(profileJson, "phone")
    val countryRegion = extractString(profileJson, "countryRegion")
    val genderStr = extractRawValue(profileJson, "gender")
    val avatarUri = extractStringOrNull(profileJson, "avatarUri")
    if (username.isBlank()) return null
    return UserProfile(
        username = username,
        birthDate = birthDate,
        heightCm = heightStr.toIntOrNull(),
        weightKg = weightStr.toDoubleOrNull(),
        measurementSystem = try {
            com.example.demo.common.login.MeasurementSystem.valueOf(measureSys)
        } catch (e: Exception) {
            com.example.demo.common.login.MeasurementSystem.Metric
        },
        phone = phone,
        countryRegion = countryRegion.ifBlank { "中国" },
        gender = if (genderStr == "null" || genderStr.isBlank()) null else try {
            com.example.demo.common.login.UserGender.valueOf(genderStr)
        } catch (e: Exception) {
            null
        },
        avatarUri = avatarUri
    )
}

private fun extractString(json: String, fieldName: String): String {
    val pattern = "\"$fieldName\":\""
    val start = json.indexOf(pattern)
    if (start < 0) return ""
    val valueStart = start + pattern.length
    val sb = StringBuilder()
    var i = valueStart
    while (i < json.length) {
        val c = json[i]
        if (c == '\\') {
            i++
            if (i < json.length) {
                when (json[i]) {
                    '\\' -> sb.append('\\')
                    '"' -> sb.append('"')
                    'n' -> sb.append('\n')
                    'r' -> sb.append('\r')
                    't' -> sb.append('\t')
                    else -> { sb.append('\\'); sb.append(json[i]) }
                }
            }
        } else if (c == '"') {
            break
        } else {
            sb.append(c)
        }
        i++
    }
    return sb.toString()
}

private fun extractStringOrNull(json: String, fieldName: String): String? {
    val pattern = "\"$fieldName\":"
    val start = json.indexOf(pattern)
    if (start < 0) return null
    val afterField = start + pattern.length
    val rest = json.substring(afterField).trimStart()
    if (rest.startsWith("null")) return null
    val str = extractString(json, fieldName)
    return str.ifBlank { null }
}

private fun extractRawValue(json: String, fieldName: String): String {
    val pattern = "\"$fieldName\":"
    val start = json.indexOf(pattern)
    if (start < 0) return ""
    val valueStart = start + pattern.length
    var end = valueStart
    while (end < json.length && json[end] != ',' && json[end] != '}') end++
    return json.substring(valueStart, end).trim()
}

private fun skipWhitespace(str: String, pos: Int): Int {
    var p = pos
    while (p < str.length && str[p].isWhitespace()) p++
    return p
}

private fun findArrayEnd(json: String, start: Int): Int {
    var depth = 0
    var inString = false
    var escaped = false
    for (i in start until json.length) {
        val c = json[i]
        if (escaped) { escaped = false; continue }
        if (c == '\\') { escaped = true; continue }
        if (c == '"') { inString = !inString; continue }
        if (inString) continue
        if (c == '[') depth++
        if (c == ']') { if (depth == 0) return i; depth-- }
    }
    return json.length
}

private fun findObjectEnd(json: String, start: Int): Int {
    var depth = 0
    var inString = false
    var escaped = false
    for (i in start until json.length) {
        val c = json[i]
        if (escaped) { escaped = false; continue }
        if (c == '\\') { escaped = true; continue }
        if (c == '"') { inString = !inString; continue }
        if (inString) continue
        if (c == '{') depth++
        if (c == '}') { if (depth == 0) return i + 1; depth-- }
    }
    return json.length
}
