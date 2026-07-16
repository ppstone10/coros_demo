package com.example.demo.common.health

object MockHealthDashboardStoreJson {
    fun encode(snapshot: HealthDashboardSnapshot): String {
        return buildString {
            append('{')
            appendJsonField("userId", snapshot.userId)
            append(',')
            appendJsonField("scenario", snapshot.scenario.name)
            append(',')
            append("\"enabledCardTypes\":[")
            snapshot.enabledCardTypes.forEachIndexed { index, type ->
                if (index > 0) append(',')
                append('"')
                append(type.name)
                append('"')
            }
            append(']')
            append('}')
        }
    }

    fun decode(json: String): HealthDashboardSnapshot {
        val userId = requireString(json, "userId", "user_id")
        val scenarioName = requireString(json, "scenario")
        val scenario = runCatching { HealthMockScenario.valueOf(scenarioName) }.getOrDefault(HealthMockScenario.Normal)
        val types = parseEnabledCardTypes(json)
        return HealthDashboardSnapshot(userId, scenario, types.ifEmpty { DefaultHealthCardOrder })
    }

    // ---- encode helpers ----

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

    // ---- decode helpers ----

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

    private fun parseEnabledCardTypes(json: String): List<HealthCardType> {
        val arrayContent = optionalArray(json, "enabledCardTypes", "enabled_card_types") ?: return emptyList()
        if (arrayContent.isBlank()) return emptyList()
        val list = mutableListOf<HealthCardType>()
        var pos = 0
        while (pos < arrayContent.length) {
            pos = skipWhitespace(arrayContent, pos)
            if (pos >= arrayContent.length) break
            if (arrayContent[pos] != '"') {
                throw IllegalArgumentException("Expected string in enabledCardTypes array")
            }
            val name = readJsonString(arrayContent, pos)
            runCatching { HealthCardType.valueOf(name) }.onSuccess { list.add(it) }
            pos += name.length + 2
            pos = skipWhitespace(arrayContent, pos)
            if (pos < arrayContent.length && arrayContent[pos] == ',') pos++
        }
        return list
    }

    private fun optionalArray(json: String, vararg fieldNames: String): String? {
        val valueStart = findAnyFieldValueStart(json, *fieldNames) ?: return null
        if (valueStart >= json.length || json[valueStart] != '[') {
            throw IllegalArgumentException("Field ${fieldNames.firstOrNull().orEmpty()} is not a JSON array")
        }
        val arrayEnd = findArrayEnd(json, valueStart)
        return json.substring(valueStart + 1, arrayEnd)
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
            if (escaped) { escaped = false; continue }
            if (c == '\\') { escaped = true; continue }
            if (c == '"') { inString = !inString; continue }
            if (inString) continue
            if (c == '[') depth++
            if (c == ']') { depth--; if (depth == 0) return i }
        }
        throw IllegalArgumentException("Unterminated JSON array")
    }
}
