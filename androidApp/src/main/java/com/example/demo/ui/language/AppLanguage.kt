package com.example.demo.ui.language

import android.content.Context
import android.content.res.Configuration
import androidx.activity.compose.LocalActivityResultRegistryOwner
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalResources
import java.util.Locale
import androidx.core.content.edit

enum class AppLanguage(val tag: String) {
    SimplifiedChinese("zh-Hans"),
    English("en");

    companion object {
        fun fromStoredTag(tag: String?): AppLanguage = entries.firstOrNull { it.tag == tag }
            ?: SimplifiedChinese
    }
}

data class AppLanguageController(
    val current: AppLanguage,
    val select: (AppLanguage) -> Unit
)

val LocalAppLanguageController = staticCompositionLocalOf<AppLanguageController> {
    AppLanguageController(current = AppLanguage.SimplifiedChinese, select = {})
}

private const val PreferencesName = "app_language_preferences"
private const val LanguageKey = "app_language"

@Composable
fun ProvideAppLanguage(content: @Composable () -> Unit) {
    val baseContext = LocalContext.current
    val baseConfiguration = LocalConfiguration.current
    val activityResultRegistryOwner = LocalActivityResultRegistryOwner.current

    var language by remember {
        mutableStateOf(
            AppLanguage.fromStoredTag(
                baseContext.getSharedPreferences(PreferencesName, Context.MODE_PRIVATE)
                    .getString(LanguageKey, null)
            )
        )
    }
    val localizedContext = remember(baseContext, baseConfiguration, language) {
        val configuration = Configuration(baseConfiguration).apply {
            setLocale(Locale.forLanguageTag(language.tag))
        }
        baseContext.createConfigurationContext(configuration)
    }
    val controller = remember(language) {
        AppLanguageController(current = language, select = { language = it })
    }

    LaunchedEffect(language) {
        baseContext.getSharedPreferences(PreferencesName, Context.MODE_PRIVATE)
            .edit {
                putString(LanguageKey, language.tag)
            }
    }

    CompositionLocalProvider(
        LocalContext provides localizedContext,
        LocalConfiguration provides localizedContext.resources.configuration,
        LocalResources provides localizedContext.resources,
        LocalAppLanguageController provides controller
    ) {
        if (activityResultRegistryOwner != null) {
            CompositionLocalProvider(
                LocalActivityResultRegistryOwner provides activityResultRegistryOwner,
                content = content
            )
        } else {
            content()
        }
    }
}
