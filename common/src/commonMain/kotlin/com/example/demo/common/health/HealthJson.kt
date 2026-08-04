package com.example.demo.common.health

/** 自包含 JSON 解析/构建基础设施；不依赖 kotlinx-serialization（KNOI OHOS 兼容约束，见 LEARNINGS）。 */
sealed interface JsonValue {
    fun render(): String
}

class JsonObject(
    private val values: Map<String, JsonValue>
) : JsonValue {
    operator fun get(name: String): JsonValue? = values[name]
    override fun render(): String = values.entries.joinToString(prefix = "{", postfix = "}") { (key, value) ->
        "\"${key.jsonEscaped()}\":${value.render()}"
    }
    override fun toString(): String = render()
}

class JsonArray(
    private val values: List<JsonValue>
) : JsonValue, List<JsonValue> by values {
    override fun render(): String = values.joinToString(prefix = "[", postfix = "]") { it.render() }
    override fun toString(): String = render()
}

class JsonPrimitive private constructor(
    val content: String,
    private val quoted: Boolean
) : JsonValue {
    constructor(value: String) : this(value, true)
    constructor(value: Int) : this(value.toString(), false)
    constructor(value: Long) : this(value.toString(), false)
    constructor(value: Double) : this(value.toString(), false)
    constructor(value: Boolean) : this(value.toString(), false)

    val contentOrNull: String? get() = content
    val intOrNull: Int? get() = content.toIntOrNull()
    val longOrNull: Long? get() = content.toLongOrNull()
    val doubleOrNull: Double? get() = content.toDoubleOrNull()
    val booleanOrNull: Boolean? get() = when (content) { "true" -> true; "false" -> false; else -> null }

    override fun render(): String = if (quoted) "\"${content.jsonEscaped()}\"" else content
    override fun toString(): String = render()

    companion object {
        fun raw(value: String) = JsonPrimitive(value, false)
    }
}

object JsonNull : JsonValue {
    override fun render(): String = "null"
    override fun toString(): String = render()
}

class JsonObjectBuilder {
    private val values = linkedMapOf<String, JsonValue>()
    fun put(name: String, value: JsonValue) { values[name] = value }
    fun put(name: String, value: String) = put(name, JsonPrimitive(value))
    fun put(name: String, value: Int) = put(name, JsonPrimitive(value))
    fun put(name: String, value: Long) = put(name, JsonPrimitive(value))
    fun put(name: String, value: Double) = put(name, JsonPrimitive(value))
    fun put(name: String, value: Boolean) = put(name, JsonPrimitive(value))
    fun build() = JsonObject(values)
}

class JsonArrayBuilder {
    private val values = mutableListOf<JsonValue>()
    fun add(value: JsonValue) { values += value }
    fun build() = JsonArray(values)
}

fun buildJsonObject(block: JsonObjectBuilder.() -> Unit): JsonObject = JsonObjectBuilder().apply(block).build()
fun buildJsonArray(block: JsonArrayBuilder.() -> Unit): JsonArray = JsonArrayBuilder().apply(block).build()

fun parseJson(json: String): JsonValue = HealthJsonParser(json).parse()

class HealthJsonParser(private val source: String) {
    private var position = 0

    fun parse(): JsonValue {
        skipWhitespace()
        val value = parseValue()
        skipWhitespace()
        require(position == source.length) { "Unexpected trailing JSON content" }
        return value
    }

    private fun parseValue(): JsonValue {
        skipWhitespace()
        require(position < source.length) { "Unexpected end of JSON" }
        return when (source[position]) {
            '{' -> parseObject()
            '[' -> parseArray()
            '"' -> JsonPrimitive(parseString())
            't' -> parseKeyword("true", JsonPrimitive.raw("true"))
            'f' -> parseKeyword("false", JsonPrimitive.raw("false"))
            'n' -> parseKeyword("null", JsonNull)
            else -> parseNumber()
        }
    }

    private fun parseObject(): JsonObject {
        expect('{')
        skipWhitespace()
        val values = linkedMapOf<String, JsonValue>()
        if (consume('}')) return JsonObject(values)
        while (true) {
            skipWhitespace()
            require(position < source.length && source[position] == '"') { "Expected JSON object key" }
            val key = parseString()
            skipWhitespace()
            expect(':')
            values[key] = parseValue()
            skipWhitespace()
            if (consume('}')) return JsonObject(values)
            expect(',')
        }
    }

    private fun parseArray(): JsonArray {
        expect('[')
        skipWhitespace()
        val values = mutableListOf<JsonValue>()
        if (consume(']')) return JsonArray(values)
        while (true) {
            values += parseValue()
            skipWhitespace()
            if (consume(']')) return JsonArray(values)
            expect(',')
        }
    }

    private fun parseString(): String {
        expect('"')
        val result = StringBuilder()
        while (position < source.length) {
            when (val char = source[position++]) {
                '"' -> return result.toString()
                '\\' -> {
                    require(position < source.length) { "Invalid JSON escape" }
                    when (val escaped = source[position++]) {
                        '"', '\\', '/' -> result.append(escaped)
                        'b' -> result.append('\b')
                        'f' -> result.append('\u000C')
                        'n' -> result.append('\n')
                        'r' -> result.append('\r')
                        't' -> result.append('\t')
                        'u' -> {
                            require(position + 4 <= source.length) { "Invalid unicode escape" }
                            result.append(source.substring(position, position + 4).toInt(16).toChar())
                            position += 4
                        }
                        else -> error("Unsupported JSON escape $escaped")
                    }
                }
                else -> result.append(char)
            }
        }
        error("Unterminated JSON string")
    }

    private fun parseNumber(): JsonPrimitive {
        val start = position
        while (position < source.length && source[position] !in charArrayOf(',', '}', ']', ' ', '\n', '\r', '\t')) position++
        val raw = source.substring(start, position)
        require(raw.toDoubleOrNull() != null) { "Invalid JSON value $raw" }
        return JsonPrimitive.raw(raw)
    }

    private fun parseKeyword(keyword: String, value: JsonValue): JsonValue {
        require(source.startsWith(keyword, position)) { "Invalid JSON keyword" }
        position += keyword.length
        return value
    }

    private fun consume(expected: Char): Boolean {
        if (position < source.length && source[position] == expected) {
            position++
            return true
        }
        return false
    }

    private fun expect(expected: Char) {
        require(consume(expected)) { "Expected '$expected' at $position" }
    }

    private fun skipWhitespace() {
        while (position < source.length && source[position].isWhitespace()) position++
    }
}

fun String.jsonEscaped(): String = buildString {
    this@jsonEscaped.forEach { char ->
        when (char) {
            '\\' -> append("\\\\")
            '"' -> append("\\\"")
            '\b' -> append("\\b")
            '\u000C' -> append("\\f")
            '\n' -> append("\\n")
            '\r' -> append("\\r")
            '\t' -> append("\\t")
            else -> append(char)
        }
    }
}
