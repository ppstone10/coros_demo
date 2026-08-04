package com.example.demo.common.health

/** 编辑表单跨语言 JSON 编解码：字段值编码、表单/结果快照序列化。 */
object HealthEditFormJson {
    fun encodeValues(values: Map<String, String>): String =
        values.entries.joinToString("&") { (key, value) ->
            "${key.percentEncode()}=${value.percentEncode()}"
        }

    fun decodeValues(spec: String): Map<String, String> =
        spec.split('&').filter(String::isNotBlank).associate { entry ->
            val separator = entry.indexOf('=')
            require(separator > 0) { "Invalid form value" }
            entry.substring(0, separator).percentDecode() to
                entry.substring(separator + 1).percentDecode()
        }

    fun formJson(source: EditableHealthData, section: HealthEditableSection): String =
        formJson(HealthEditableForms.form(source, section))

    fun formJson(form: HealthEditForm): String =
        buildString {
            append("{\"section\":\"").append(form.section.name)
            append("\",\"titleKey\":\"").append(form.titleKey)
            append("\",\"sourceKind\":\"").append(form.sourceKind.name)
            append("\",\"sourceMessageKey\":\"").append(form.sourceMessageKey)
            append("\",\"fields\":[")
            form.fields.forEachIndexed { index, field ->
                if (index > 0) append(',')
                append("{\"id\":\"").append(field.id)
                append("\",\"labelKey\":\"").append(field.labelKey)
                append("\",\"value\":\"").append(field.value.jsonEscape())
                append("\",\"type\":\"").append(field.type.name).append('"')
                field.minimum?.let { append(",\"minimum\":").append(it) }
                field.maximum?.let { append(",\"maximum\":").append(it) }
                append(",\"labelArguments\":[")
                field.labelArguments.forEachIndexed { argumentIndex, argument ->
                    if (argumentIndex > 0) append(',')
                    append('"').append(argument.jsonEscape()).append('"')
                }
                append(']')
                field.groupId?.let {
                    append(",\"groupId\":\"").append(it.jsonEscape()).append('"')
                }
                field.rowIndex?.let { append(",\"rowIndex\":").append(it) }
                append(",\"options\":[")
                field.options.forEachIndexed { optionIndex, option ->
                    if (optionIndex > 0) append(',')
                    append("{\"value\":\"").append(option.value)
                    append("\",\"labelKey\":\"").append(option.labelKey).append("\"}")
                }
                append("]}")
            }
            append("],\"repeatGroups\":[")
            form.repeatGroups.forEachIndexed { index, group ->
                if (index > 0) append(',')
                append("{\"id\":\"").append(group.id)
                append("\",\"addLabelKey\":\"").append(group.addLabelKey)
                append("\",\"itemLabelKey\":\"").append(group.itemLabelKey)
                append("\",\"minimumItems\":").append(group.minimumItems)
                append(",\"maximumItems\":").append(group.maximumItems)
                append('}')
            }
            append("]}")
        }

    fun applyResultJson(result: HealthEditApplyResult): String = buildString {
        append("{\"success\":").append(result.isSuccess)
        result.issue?.let { issue ->
            append(",\"issue\":{\"fieldId\":\"").append(issue.fieldId.jsonEscape())
            append("\",\"labelKey\":\"").append(issue.labelKey.jsonEscape())
            append("\",\"labelArguments\":[")
            issue.labelArguments.forEachIndexed { index, argument ->
                if (index > 0) append(',')
                append('"').append(argument.jsonEscape()).append('"')
            }
            append("],\"reason\":\"").append(issue.reason.name)
            append("\",\"reasonArguments\":[")
            issue.reasonArguments.forEachIndexed { index, argument ->
                if (index > 0) append(',')
                append('"').append(argument.jsonEscape()).append('"')
            }
            append("]}")
        }
        append('}')
    }

    private fun String.percentEncode(): String = buildString {
        this@percentEncode.encodeToByteArray().forEach { byte ->
            val value = byte.toInt() and 0xff
            if (
                value in 'a'.code..'z'.code ||
                value in 'A'.code..'Z'.code ||
                value in '0'.code..'9'.code ||
                value == '-'.code || value == '_'.code || value == '.'.code
            ) append(value.toChar())
            else append('%').append(value.toString(16).uppercase().padStart(2, '0'))
        }
    }

    private fun String.percentDecode(): String {
        val bytes = mutableListOf<Byte>()
        var index = 0
        while (index < length) {
            if (this[index] == '%' && index + 2 < length) {
                bytes += substring(index + 1, index + 3).toInt(16).toByte()
                index += 3
            } else {
                bytes += this[index].code.toByte()
                index++
            }
        }
        return bytes.toByteArray().decodeToString()
    }

    private fun String.jsonEscape(): String =
        replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n")
}
