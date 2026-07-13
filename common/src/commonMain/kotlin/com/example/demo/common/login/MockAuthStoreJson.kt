package com.example.demo.common.login

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
            defaultAccountsInitialized = parseBooleanOrDefault(
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
            appendJsonField("countryRegion", countryRegion)
            append(',')
            appendJsonNullableField("gender", gender?.toProtoJsonName())
            append('}')
        }
    }

    private fun parseAccounts(json: String): List<MockAccount> {
        return parseObjectArray(json, "accounts").map { parseAccount(it) }
    }

    private fun parseSession(json: String): MockAuthSession? {
        val sessionJson = optionalObject(json, "currentSession", "current_session") ?: return null
        return parseSessionObject(sessionJson)
    }

    private fun parseVerifyCodes(json: String): List<MockVerifyCodeState> {
        return parseObjectArray(json, "verifyCodes", "verify_codes").map { parseVerifyCode(it) }
    }

    private fun parseObjectArray(json: String, vararg fieldNames: String): List<String> {
        val arrayContent = optionalArray(json, *fieldNames) ?: return emptyList()
        if (arrayContent.isBlank()) return emptyList()
        val list = mutableListOf<String>()
        var pos = 0
        while (pos < arrayContent.length) {
            pos = skipWhitespace(arrayContent, pos)
            if (pos >= arrayContent.length) break
            if (arrayContent[pos] != '{') {
                throw IllegalArgumentException("Expected object in array")
            }
            val objEnd = findObjectEnd(arrayContent, pos)
            list.add(arrayContent.substring(pos, objEnd))
            pos = skipWhitespace(arrayContent, objEnd)
            if (pos < arrayContent.length && arrayContent[pos] == ',') pos++
        }
        return list
    }

    private fun parseAccount(json: String): MockAccount {
        return MockAccount(
            userId = requireString(json, "userId", "user_id"),
            account = requireString(json, "account"),
            passwordHash = requireString(json, "passwordHash", "password_hash"),
            displayName = requireString(json, "displayName", "display_name"),
            region = requireString(json, "region"),
            profile = parseProfile(json)
        )
    }

    private fun parseSessionObject(json: String): MockAuthSession {
        return MockAuthSession(
            userId = requireString(json, "userId", "user_id"),
            account = requireString(json, "account"),
            displayName = requireString(json, "displayName", "display_name"),
            region = requireString(json, "region"),
            isValid = parseBooleanOrDefault(json, defaultValue = false, "isValid", "is_valid"),
            profile = parseProfile(json),
            issuedAtEpochMs = optionalRawValue(json, "issuedAtEpochMs", "issued_at_epoch_ms")
                ?.trim('"')?.toLongOrNull() ?: 0L,
            expireAtEpochMs = optionalRawValue(json, "expireAtEpochMs", "expire_at_epoch_ms")
                ?.trim('"')?.toLongOrNull() ?: 0L
        )
    }

    private fun parseVerifyCode(json: String): MockVerifyCodeState {
        return MockVerifyCodeState(
            account = requireString(json, "account"),
            code = requireString(json, "code"),
            expireAtEpochMs = requireRawValue(json, "expireAtEpochMs", "expire_at_epoch_ms").trim('"').toLongOrNull()
                ?: throw IllegalArgumentException("Invalid expireAtEpochMs")
        )
    }

    private fun parseProfile(json: String): UserProfile? {
        val profileJson = optionalObject(json, "profile") ?: return null
        val username = requireString(profileJson, "username")
        val birthDate = optionalString(profileJson, "birthDate", "birth_date").orEmpty()
        val heightStr = optionalRawValue(profileJson, "heightCm", "height_cm")
        val weightStr = optionalRawValue(profileJson, "weightKg", "weight_kg")
        val measureSys = optionalString(profileJson, "measurementSystem", "measurement_system").orEmpty()
        val phone = optionalString(profileJson, "phone").orEmpty()
        val countryRegion = optionalString(profileJson, "countryRegion", "country_region").orEmpty()
        val genderStr = optionalString(profileJson, "gender") ?: optionalRawValue(profileJson, "gender")
        val avatarUri = optionalString(profileJson, "avatarUri", "avatar_uri")
        if (username.isBlank()) return null
        return UserProfile(
            avatarUri = avatarUri,
            username = username,
            birthDate = birthDate,
            heightCm = heightStr?.takeUnless { it == "null" }?.toIntOrNull(),
            weightKg = weightStr?.takeUnless { it == "null" }?.toDoubleOrNull(),
            measurementSystem = measureSys.toMeasurementSystem(),
            phone = phone,
            countryRegion = countryRegion.ifBlank { "中国" },
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
        append(value.jsonEscaped())
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
            append(value.jsonEscaped())
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

    private fun requireString(json: String, vararg fieldNames: String): String {
        return optionalString(json, *fieldNames)
            ?: throw IllegalArgumentException("Missing string field ${fieldNames.firstOrNull().orEmpty()}")
    }

    private fun optionalString(json: String, vararg fieldNames: String): String? {
        val valueStart = findAnyFieldValueStart(json, *fieldNames) ?: return null
        if (valueStart >= json.length || json.startsWith("null", valueStart)) return null
        if (json[valueStart] != '"') {
            throw IllegalArgumentException("Field ${fieldNames.firstOrNull().orEmpty()} is not a JSON string")
        }
        return readJsonString(json, valueStart)
    }

    private fun readJsonString(json: String, quoteStart: Int): String {
        val sb = StringBuilder()
        var i = quoteStart + 1
        while (i < json.length) {
            val c = json[i]
            if (c == '\\') {
                i++
                if (i >= json.length) throw IllegalArgumentException("Invalid JSON escape")
                when (val escaped = json[i]) {
                    '\\' -> sb.append('\\')
                    '"' -> sb.append('"')
                    'n' -> sb.append('\n')
                    'r' -> sb.append('\r')
                    't' -> sb.append('\t')
                    'u' -> {
                        if (i + 4 >= json.length) throw IllegalArgumentException("Invalid unicode escape")
                        val hex = json.substring(i + 1, i + 5)
                        sb.append(hex.toInt(16).toChar())
                        i += 4
                    }
                    else -> {
                        sb.append('\\')
                        sb.append(escaped)
                    }
                }
            } else if (c == '"') {
                return sb.toString()
            } else {
                sb.append(c)
            }
            i++
        }
        throw IllegalArgumentException("Unterminated JSON string")
    }

    private fun requireRawValue(json: String, vararg fieldNames: String): String {
        return optionalRawValue(json, *fieldNames)
            ?: throw IllegalArgumentException("Missing field ${fieldNames.firstOrNull().orEmpty()}")
    }

    private fun optionalRawValue(json: String, vararg fieldNames: String): String? {
        val valueStart = findAnyFieldValueStart(json, *fieldNames) ?: return null
        var end = valueStart
        while (end < json.length && json[end] != ',' && json[end] != '}') end++
        return json.substring(valueStart, end).trim()
    }

    private fun parseBooleanOrDefault(
        json: String,
        defaultValue: Boolean,
        vararg fieldNames: String
    ): Boolean {
        return when (optionalRawValue(json, *fieldNames)) {
            null -> defaultValue
            "true" -> true
            "false" -> false
            else -> throw IllegalArgumentException("Invalid boolean field ${fieldNames.firstOrNull().orEmpty()}")
        }
    }

    private fun optionalArray(json: String, vararg fieldNames: String): String? {
        val valueStart = findAnyFieldValueStart(json, *fieldNames) ?: return null
        if (valueStart >= json.length || json[valueStart] != '[') {
            throw IllegalArgumentException("Field ${fieldNames.firstOrNull().orEmpty()} is not a JSON array")
        }
        val arrayEnd = findArrayEnd(json, valueStart)
        return json.substring(valueStart + 1, arrayEnd)
    }

    private fun optionalObject(json: String, vararg fieldNames: String): String? {
        val valueStart = findAnyFieldValueStart(json, *fieldNames) ?: return null
        if (valueStart >= json.length || json.startsWith("null", valueStart)) return null
        if (json[valueStart] != '{') {
            throw IllegalArgumentException("Field ${fieldNames.firstOrNull().orEmpty()} is not a JSON object")
        }
        val objectEnd = findObjectEnd(json, valueStart)
        return json.substring(valueStart, objectEnd)
    }

    private fun findAnyFieldValueStart(json: String, vararg fieldNames: String): Int? {
        for (fieldName in fieldNames) {
            val pattern = "\"$fieldName\":"
            val start = json.indexOf(pattern)
            if (start >= 0) return skipWhitespace(json, start + pattern.length)
        }
        return null
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
            if (escaped) {
                escaped = false
                continue
            }
            if (c == '\\') {
                escaped = true
                continue
            }
            if (c == '"') {
                inString = !inString
                continue
            }
            if (inString) continue
            if (c == '[') depth++
            if (c == ']') {
                depth--
                if (depth == 0) return i
            }
        }
        throw IllegalArgumentException("Unterminated JSON array")
    }

    private fun findObjectEnd(json: String, start: Int): Int {
        var depth = 0
        var inString = false
        var escaped = false
        for (i in start until json.length) {
            val c = json[i]
            if (escaped) {
                escaped = false
                continue
            }
            if (c == '\\') {
                escaped = true
                continue
            }
            if (c == '"') {
                inString = !inString
                continue
            }
            if (inString) continue
            if (c == '{') depth++
            if (c == '}') {
                depth--
                if (depth == 0) return i + 1
            }
        }
        throw IllegalArgumentException("Unterminated JSON object")
    }
}

class JsonAuthStoreDataSource(
    private val loadJson: () -> String?,
    private val saveJson: (String) -> Boolean
) : AuthStoreDataSource {
    override fun load(): MockAuthStore {
        val raw = loadJson()?.takeIf { it.isNotBlank() } ?: return MockAuthStore()
        return runCatching { MockAuthStoreJson.decode(raw) }.getOrDefault(MockAuthStore())
    }

    override fun save(store: MockAuthStore): Boolean {
        return saveJson(MockAuthStoreJson.encode(store))
    }
}
