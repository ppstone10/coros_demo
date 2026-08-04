package com.example.demo.common.auth.mock
import com.example.demo.common.auth.model.MeasurementSystem
import com.example.demo.common.auth.model.MockAccount
import com.example.demo.common.auth.model.MockAuthSession
import com.example.demo.common.auth.model.MockAuthStore
import com.example.demo.common.auth.model.MockVerifyCodeState
import com.example.demo.common.auth.model.UserGender
import com.example.demo.common.auth.model.UserProfile
import com.example.demo.common.auth.model.toProfileCountryCode

/**
 * 受 [auth_mock.proto] 约束的本地认证快照编解码器。
 *
 * 由于 HarmonyOS bridge 不直接提供 protobuf JSON runtime，三端复用本实现产生
 * protobuf JSON 命名规则兼容的快照；平台持久化层仅负责读写字符串，不得自行
 * 拼装认证模型 JSON 或复制字段规则。
 */
object MockAuthStoreJson {
    fun encode(store: MockAuthStore): String {
        return buildString {
            append('{')
            append("\"accounts\":")
            append(store.accounts.toAccountJson())
            append(',')
            append("\"currentSession\":")
            append(store.currentSession.toJson())
            append(',')
            append("\"verifyCodes\":")
            append(store.verifyCodes.toVerifyCodeJson())
            append(',')
            appendJsonBoolean("defaultAccountsInitialized", store.defaultAccountsInitialized)
            append('}')
        }
    }

    fun decode(json: String): MockAuthStore {
        return MockAuthStore(
            accounts = parseAccounts(json),
            currentSession = parseSession(json),
            verifyCodes = parseVerifyCodes(json),
            defaultAccountsInitialized = AuthJson.parseBooleanOrDefault(
                json,
                defaultValue = false,
                "defaultAccountsInitialized",
                "default_accounts_initialized"
            )
        )
    }

    fun isRoundTripStable(json: String): Boolean {
        return try {
            val parsed = decode(json)
            decode(encode(parsed)) == parsed
        } catch (e: Exception) {
            false
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

    private fun MockAuthSession?.toJson(): String {
        if (this == null) return "null"
        return buildString {
            append('{')
            appendJsonField("userId", userId)
            append(',')
            appendJsonField("account", account)
            append(',')
            appendJsonField("displayName", displayName)
            append(',')
            appendJsonField("region", region)
            append(',')
            appendJsonBoolean("isValid", isValid)
            append(',')
            appendJsonField("issuedAtEpochMs", issuedAtEpochMs.toString())
            append(',')
            appendJsonField("expireAtEpochMs", expireAtEpochMs.toString())
            append(',')
            append("\"profile\":")
            append(profile.toJson())
            append('}')
        }
    }

    private fun List<MockVerifyCodeState>.toVerifyCodeJson(): String {
        if (isEmpty()) return "[]"
        return buildString {
            append('[')
            this@toVerifyCodeJson.forEachIndexed { index, code ->
                if (index > 0) append(',')
                append(code.toJson())
            }
            append(']')
        }
    }

    private fun MockVerifyCodeState.toJson(): String {
        return buildString {
            append('{')
            appendJsonField("account", account)
            append(',')
            appendJsonField("code", code)
            append(',')
            appendJsonLong("expireAtEpochMs", expireAtEpochMs)
            append('}')
        }
    }

    private fun UserProfile?.toJson(): String {
        if (this == null) return "null"
        return buildString {
            append('{')
            appendJsonNullableField("avatarUri", avatarUri)
            append(',')
            appendJsonField("username", username)
            append(',')
            appendJsonField("birthDate", birthDate)
            append(',')
            appendJsonNullableInt("heightCm", heightCm)
            append(',')
            appendJsonNullableDouble("weightKg", weightKg)
            append(',')
            // protobuf JSON 约定：proto 的 measurement_system / country_region
            // 使用 lowerCamelCase 字段名，枚举使用 proto 中声明的名称。
            appendJsonField("measurementSystem", measurementSystem.toProtoJsonName())
            append(',')
            appendJsonField("phone", phone)
            append(',')
            appendJsonField("email", email)
            append(',')
            appendJsonField("countryRegion", countryRegion)
            append(',')
            appendJsonNullableField("gender", gender?.toProtoJsonName())
            append('}')
        }
    }

    private fun parseAccounts(json: String): List<MockAccount> {
        return AuthJson.parseObjectArray(json, "accounts").map { parseAccount(it) }
    }

    private fun parseSession(json: String): MockAuthSession? {
        val sessionJson = AuthJson.optionalObject(json, "currentSession", "current_session") ?: return null
        return parseSessionObject(sessionJson)
    }

    private fun parseVerifyCodes(json: String): List<MockVerifyCodeState> {
        return AuthJson.parseObjectArray(json, "verifyCodes", "verify_codes").map { parseVerifyCode(it) }
    }

    private fun parseAccount(json: String): MockAccount {
        return MockAccount(
            userId = AuthJson.requireString(json, "userId", "user_id"),
            account = AuthJson.requireString(json, "account"),
            passwordHash = AuthJson.requireString(json, "passwordHash", "password_hash"),
            displayName = AuthJson.requireString(json, "displayName", "display_name"),
            region = AuthJson.requireString(json, "region"),
            profile = parseProfile(json)
        )
    }

    private fun parseSessionObject(json: String): MockAuthSession {
        return MockAuthSession(
            userId = AuthJson.requireString(json, "userId", "user_id"),
            account = AuthJson.requireString(json, "account"),
            displayName = AuthJson.requireString(json, "displayName", "display_name"),
            region = AuthJson.requireString(json, "region"),
            isValid = AuthJson.parseBooleanOrDefault(json, defaultValue = false, "isValid", "is_valid"),
            profile = parseProfile(json),
            issuedAtEpochMs = AuthJson.optionalRawValue(json, "issuedAtEpochMs", "issued_at_epoch_ms")
                ?.trim('"')?.toLongOrNull() ?: 0L,
            expireAtEpochMs = AuthJson.optionalRawValue(json, "expireAtEpochMs", "expire_at_epoch_ms")
                ?.trim('"')?.toLongOrNull() ?: 0L
        )
    }

    private fun parseVerifyCode(json: String): MockVerifyCodeState {
        return MockVerifyCodeState(
            account = AuthJson.requireString(json, "account"),
            code = AuthJson.requireString(json, "code"),
            expireAtEpochMs = AuthJson.requireRawValue(json, "expireAtEpochMs", "expire_at_epoch_ms").trim('"').toLongOrNull()
                ?: throw IllegalArgumentException("Invalid expireAtEpochMs")
        )
    }

    private fun parseProfile(json: String): UserProfile? {
        val profileJson = AuthJson.optionalObject(json, "profile") ?: return null
        val username = AuthJson.requireString(profileJson, "username")
        val birthDate = AuthJson.optionalString(profileJson, "birthDate", "birth_date").orEmpty()
        val heightStr = AuthJson.optionalRawValue(profileJson, "heightCm", "height_cm")
        val weightStr = AuthJson.optionalRawValue(profileJson, "weightKg", "weight_kg")
        val measureSys = AuthJson.optionalString(profileJson, "measurementSystem", "measurement_system").orEmpty()
        val phone = AuthJson.optionalString(profileJson, "phone").orEmpty()
        val email = AuthJson.optionalString(profileJson, "email").orEmpty()
        val countryRegion = AuthJson.optionalString(profileJson, "countryRegion", "country_region").orEmpty()
        val genderStr = AuthJson.optionalString(profileJson, "gender") ?: AuthJson.optionalRawValue(profileJson, "gender")
        val avatarUri = AuthJson.optionalString(profileJson, "avatarUri", "avatar_uri")
        if (username.isBlank()) return null
        return UserProfile(
            avatarUri = avatarUri,
            username = username,
            birthDate = birthDate,
            heightCm = heightStr?.takeUnless { it == "null" }?.toIntOrNull(),
            weightKg = weightStr?.takeUnless { it == "null" }?.toDoubleOrNull(),
            measurementSystem = measureSys.toMeasurementSystem(),
            phone = phone,
            email = email,
            countryRegion = countryRegion.toProfileCountryCode(),
            gender = genderStr
                ?.trim('"')
                ?.takeUnless { it == "null" || it.isBlank() }
                ?.toUserGender()
        )
    }

    private fun MeasurementSystem.toProtoJsonName() = when (this) {
        MeasurementSystem.Metric -> "METRIC"
        MeasurementSystem.Imperial -> "IMPERIAL"
    }

    private fun String.toMeasurementSystem() = when (this) {
        "IMPERIAL", MeasurementSystem.Imperial.name -> MeasurementSystem.Imperial
        else -> MeasurementSystem.Metric
    }

    private fun UserGender.toProtoJsonName() = when (this) {
        UserGender.Male -> "MALE"
        UserGender.Female -> "FEMALE"
    }

    private fun String.toUserGender(): UserGender? = when (trim('"')) {
        "MALE", UserGender.Male.name -> UserGender.Male
        "FEMALE", UserGender.Female.name -> UserGender.Female
        else -> null
    }

    private fun StringBuilder.appendJsonField(name: String, value: String) {
        append('"')
        append(name)
        append("\":\"")
        append(AuthJson.jsonEscaped(value))
        append('"')
    }

    private fun StringBuilder.appendJsonNullableField(name: String, value: String?) {
        append('"')
        append(name)
        append("\":")
        if (value == null) {
            append("null")
        } else {
            append('"')
            append(AuthJson.jsonEscaped(value))
            append('"')
        }
    }

    private fun StringBuilder.appendJsonBoolean(name: String, value: Boolean) {
        append('"')
        append(name)
        append("\":")
        append(value)
    }

    private fun StringBuilder.appendJsonLong(name: String, value: Long) {
        append('"')
        append(name)
        append("\":")
        append(value)
    }

    private fun StringBuilder.appendJsonNullableInt(name: String, value: Int?) {
        append('"')
        append(name)
        append("\":")
        append(value?.toString() ?: "null")
    }

    private fun StringBuilder.appendJsonNullableDouble(name: String, value: Double?) {
        append('"')
        append(name)
        append("\":")
        append(value?.toString() ?: "null")
    }
}
