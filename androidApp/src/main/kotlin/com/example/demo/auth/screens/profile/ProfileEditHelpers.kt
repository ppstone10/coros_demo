package com.example.demo.auth.screens.profile

import android.content.Context
import android.graphics.Bitmap
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource
import com.example.demo.R
import com.example.demo.common.login.MeasurementSystem
import java.io.File
import java.io.FileOutputStream
@Composable
internal fun MeasurementSystem.displayText(): String {
    return when (this) {
        MeasurementSystem.Metric -> stringResource(R.string.profile_unit_metric)
        MeasurementSystem.Imperial -> stringResource(R.string.profile_unit_imperial)
    }
}

@Composable
internal fun localizedCountryOptions(): List<Pair<String, String>> = listOf(
    "CN" to stringResource(R.string.common_china),
    "US" to stringResource(R.string.common_united_states),
    "GB" to stringResource(R.string.common_united_kingdom),
    "JP" to stringResource(R.string.common_japan)
)

internal fun parseBirthDate(value: String): Triple<Int, Int, Int> {
    val numbers = Regex("\\d+").findAll(value).map { it.value.toIntOrNull() ?: 0 }.toList()
    return Triple(
        numbers.getOrNull(0)?.takeIf { it in 1950..2026 } ?: 2002,
        numbers.getOrNull(1)?.takeIf { it in 1..12 } ?: 11,
        numbers.getOrNull(2)?.takeIf { it in 1..31 } ?: 17
    )
}

internal fun saveAvatarBitmap(context: Context, bitmap: Bitmap): String {
    val directory = File(context.filesDir, "profile_avatars").also { it.mkdirs() }
    val file = File(directory, "avatar_${System.currentTimeMillis()}.jpg")
    FileOutputStream(file).use { output ->
        bitmap.compress(Bitmap.CompressFormat.JPEG, 92, output)
    }
    return Uri.fromFile(file).toString()
}

internal fun copyAvatarToPrivateFile(context: Context, uri: Uri): String {
    val directory = File(context.filesDir, "profile_avatars").also { it.mkdirs() }
    val file = File(directory, "avatar_${System.currentTimeMillis()}.jpg")
    context.contentResolver.openInputStream(uri)?.use { input ->
        FileOutputStream(file).use { output -> input.copyTo(output) }
    }
    return Uri.fromFile(file).toString()
}
