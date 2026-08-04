package com.example.demo.common.login

/** 自包含的 protobuf JSON 兼容字符串解析基础；由 [MockAuthStoreJson] 复用。 */
object AuthJson {
    fun requireString(json: String, vararg fieldNames: String): String {
        return optionalString(json, *fieldNames)
            ?: throw IllegalArgumentException("Missing string field ${fieldNames.firstOrNull().orEmpty()}")
    }

    fun optionalString(json: String, vararg fieldNames: String): String? {
        val valueStart = findAnyFieldValueStart(json, *fieldNames) ?: return null
        if (valueStart >= json.length || json.startsWith("null", valueStart)) return null
        if (json[valueStart] != '"') {
            throw IllegalArgumentException("Field ${fieldNames.firstOrNull().orEmpty()} is not a JSON string")
        }
        return readJsonString(json, valueStart)
    }

    fun requireRawValue(json: String, vararg fieldNames: String): String {
        return optionalRawValue(json, *fieldNames)
            ?: throw IllegalArgumentException("Missing field ${fieldNames.firstOrNull().orEmpty()}")
    }

    fun optionalRawValue(json: String, vararg fieldNames: String): String? {
        val valueStart = findAnyFieldValueStart(json, *fieldNames) ?: return null
        var end = valueStart
        while (end < json.length && json[end] != ',' && json[end] != '}') end++
        return json.substring(valueStart, end).trim()
    }

    fun parseBooleanOrDefault(
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

    fun optionalArray(json: String, vararg fieldNames: String): String? {
        val valueStart = findAnyFieldValueStart(json, *fieldNames) ?: return null
        if (valueStart >= json.length || json[valueStart] != '[') {
            throw IllegalArgumentException("Field ${fieldNames.firstOrNull().orEmpty()} is not a JSON array")
        }
        val arrayEnd = findArrayEnd(json, valueStart)
        return json.substring(valueStart + 1, arrayEnd)
    }

    fun optionalObject(json: String, vararg fieldNames: String): String? {
        val valueStart = findAnyFieldValueStart(json, *fieldNames) ?: return null
        if (valueStart >= json.length || json.startsWith("null", valueStart)) return null
        if (json[valueStart] != '{') {
            throw IllegalArgumentException("Field ${fieldNames.firstOrNull().orEmpty()} is not a JSON object")
        }
        val objectEnd = findObjectEnd(json, valueStart)
        return json.substring(valueStart, objectEnd)
    }

    fun parseObjectArray(json: String, vararg fieldNames: String): List<String> {
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

    fun jsonEscaped(value: String): String {
        return buildString {
            value.forEach { char ->
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
