package com.example.demo.auth.components

import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.OffsetMapping
import androidx.compose.ui.text.input.TransformedText
import androidx.compose.ui.text.input.VisualTransformation
import com.example.demo.R
import com.example.demo.auth.viewmodel.LoginViewModel
import com.example.demo.common.auth.model.VerifyTarget

@Composable
fun rememberLoginViewModel(): LoginViewModel {
    val context = LocalContext.current.applicationContext
    return remember(context) { LoginViewModel.createRemote(context) }
}

@Composable
fun verifyCodeMessage(account: String, targetKind: VerifyTarget): String {
    return if (targetKind == VerifyTarget.Email) {
        stringResource(R.string.auth_verification_sent_email, account)
    } else {
        stringResource(R.string.auth_verification_sent_phone, account)
    }
}

fun buildLegalText(text: String, highlights: List<String>): AnnotatedString = buildAnnotatedString {
    val validHighlights = highlights.filter(String::isNotBlank)
    var cursor = 0
    while (cursor < text.length) {
        val nextMatch = validHighlights
            .asSequence()
            .mapNotNull { phrase ->
                val start = text.indexOf(phrase, startIndex = cursor)
                if (start >= 0) start to phrase else null
            }
            .sortedWith(compareBy<Pair<Int, String>> { it.first }.thenByDescending { it.second.length })
            .firstOrNull()
        if (nextMatch == null) {
            append(text.substring(cursor))
            cursor = text.length
        } else {
            val (start, phrase) = nextMatch
            if (start > cursor) append(text.substring(cursor, start))
            pushStyle(SpanStyle(color = CorosWhite, fontWeight = FontWeight.Bold))
            append(phrase)
            pop()
            cursor = start + phrase.length
        }
    }
}

fun latestChangedIndex(previous: String, current: String): Int? {
    if (current.isEmpty()) return null
    if (previous == current) return null
    if (current.length < previous.length) return null
    val sharedLength = minOf(previous.length, current.length)
    val firstChanged = (0 until sharedLength).firstOrNull { previous[it] != current[it] }
    if (firstChanged != null) return firstChanged.coerceAtMost(current.lastIndex)
    return if (current.length > previous.length) previous.length.coerceAtMost(current.lastIndex) else current.lastIndex
}

class LatestVisiblePasswordTransformation(private val visibleIndex: Int?) : VisualTransformation {
    override fun filter(text: AnnotatedString): TransformedText {
        val source = text.text
        if (source.isEmpty()) return TransformedText(AnnotatedString(""), OffsetMapping.Identity)
        val indexToReveal = visibleIndex?.takeIf { it in source.indices }
        val masked = buildString(source.length) {
            source.forEachIndexed { index, char ->
                append(if (index == indexToReveal) char else '•')
            }
        }
        return TransformedText(AnnotatedString(masked), OffsetMapping.Identity)
    }
}

// Use com.example.demo.common.auth.model.VerifyTarget instead of local enum
enum class TermsPromptAction { Login, PhoneCode, EmailCode }
