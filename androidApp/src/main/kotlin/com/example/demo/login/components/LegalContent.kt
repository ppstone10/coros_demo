package com.example.demo.login.components

data class LegalParagraph(
    val text: String,
    val highlights: List<String> = emptyList(),
    val isHeading: Boolean = false
)

private val LegalHighlightPattern = Regex("\\*\\*(.+?)\\*\\*")

/** Parses the small Markdown subset used by the bundled Demo legal documents. */
fun parseLegalDocument(body: String): List<LegalParagraph> = body
    .split(Regex("\\n\\s*\\n"))
    .mapNotNull { raw ->
        val value = raw.trim()
        if (value.isEmpty()) return@mapNotNull null
        val isHeading = value.startsWith("## ")
        val markedText = value.removePrefix("## ")
        val highlights = LegalHighlightPattern.findAll(markedText).map { it.groupValues[1] }.toList()
        LegalParagraph(
            text = markedText.replace(LegalHighlightPattern, "$1"),
            highlights = highlights,
            isHeading = isHeading
        )
    }
