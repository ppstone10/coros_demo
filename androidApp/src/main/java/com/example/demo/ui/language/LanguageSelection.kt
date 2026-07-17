package com.example.demo.ui.language

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import com.example.demo.R
import com.example.demo.ui.resources.AppColors

@Composable
fun LanguageIconButton(modifier: Modifier = Modifier, tint: Color = AppColors.Core.White) {
    val controller = LocalAppLanguageController.current
    IconButton(modifier = modifier, onClick = { LanguageDialogState.open(controller) }) {
        Icon(
            painter = painterResource(R.drawable.ic_language),
            contentDescription = stringResource(R.string.language_switch),
            tint = tint,
            modifier = Modifier.size(25.dp)
        )
    }
}

private object LanguageDialogState {
    var showDialog by mutableStateOf(false)
    private lateinit var controller: AppLanguageController

    fun open(value: AppLanguageController) {
        controller = value
        showDialog = true
    }

    fun close() {
        showDialog = false
    }

    fun currentController(): AppLanguageController = controller
}

@Composable
fun AppLanguageDialogHost() {
    if (!LanguageDialogState.showDialog) return
    val controller = LanguageDialogState.currentController()
    Dialog(onDismissRequest = LanguageDialogState::close) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .background(AppColors.Account.Dialog, RoundedCornerShape(14.dp))
                .padding(vertical = 12.dp)
        ) {
            Text(
                text = stringResource(R.string.language_select_title),
                color = AppColors.Core.White,
                fontSize = 19.sp,
                modifier = Modifier.padding(horizontal = 22.dp, vertical = 12.dp)
            )
            LanguageOption(R.string.language_chinese, AppLanguage.SimplifiedChinese, controller)
            LanguageOption(R.string.language_english, AppLanguage.English, controller)
        }
    }
}

@Composable
private fun LanguageOption(labelRes: Int, language: AppLanguage, controller: AppLanguageController) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable {
                controller.select(language)
                LanguageDialogState.close()
            }
            .padding(horizontal = 14.dp, vertical = 5.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = stringResource(labelRes),
            color = AppColors.Core.White,
            fontSize = 16.sp,
            modifier = Modifier.padding(start = 8.dp)
        )
        Spacer(Modifier.weight(1f))
        RadioButton(
            selected = controller.current == language,
            onClick = {
                controller.select(language)
                LanguageDialogState.close()
            }
        )
    }
}

@Composable
fun countryDisplayName(countryCode: String): String = stringResource(
    when (countryCode.trim().uppercase()) {
        "US" -> R.string.common_united_states
        "GB", "UK" -> R.string.common_united_kingdom
        "JP" -> R.string.common_japan
        else -> R.string.common_china
    }
)
