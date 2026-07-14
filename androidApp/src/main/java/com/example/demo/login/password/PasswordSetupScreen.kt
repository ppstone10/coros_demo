package com.example.demo.login.password

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.demo.common.login.AuthMode
import com.example.demo.common.login.LoginEffect
import com.example.demo.login.LoginViewModel
import com.example.demo.login.components.AuthTitleSize
import com.example.demo.login.components.AuthTitleTopPadding
import com.example.demo.login.components.CorosButtonRed
import com.example.demo.login.components.CorosWhite
import com.example.demo.login.components.AuthBlackPage
import com.example.demo.login.components.CorosFilledButton
import com.example.demo.login.components.ErrorText
import com.example.demo.login.components.UnderlineInput
import com.example.demo.ui.theme.DemoTheme
import androidx.compose.material3.Text
import com.example.demo.common.login.toProfileCountryRegion
import com.example.demo.login.profile.OptionSheet
import com.example.demo.login.profile.ProfilePickerRow
import com.example.demo.ui.resources.AppColors
import com.example.demo.ui.resources.AppText

@Composable
fun PasswordSetupScreen(
    viewModel: LoginViewModel,
    onBack: () -> Unit,
    onRegisterSuccess: () -> Unit
) {
    val state = viewModel.state
    var password by rememberSaveable { mutableStateOf("") }
    var confirmPassword by rememberSaveable { mutableStateOf("") }
    var localError by rememberSaveable { mutableStateOf<String?>(null) }
    var showRegionSheet by rememberSaveable { mutableStateOf(false) }
    val selectedCountryRegion = state.selectedRegion.toProfileCountryRegion()

    BackHandler(onBack = onBack)

    fun register() {
        val message = viewModel.validateRegisterPassword(password, confirmPassword)
        if (message != null) {
            localError = message
        } else {
            viewModel.onModeChanged(AuthMode.Register)
            viewModel.onPasswordChanged(password)
            viewModel.onSubmit()
        }
    }

    LaunchedEffect(viewModel.effect) {
        if (viewModel.effect is LoginEffect.ShowMessage) {
            localError = (viewModel.effect as LoginEffect.ShowMessage).message
            viewModel.onEffectConsumed()
        }
    }

    AuthBlackPage(onBack = onBack, showFeedback = false) {
        Text(
            text = AppText.Auth.SetLoginPassword,
            color = CorosWhite,
            fontSize = AuthTitleSize,
            fontWeight = FontWeight.Light,
            modifier = Modifier.padding(top = AuthTitleTopPadding)
        )
        Spacer(modifier = Modifier.height(60.dp))
        UnderlineInput(
            value = password,
            placeholder = AppText.Auth.NewPasswordPlaceholder,
            keyboardType = KeyboardType.Password,
            isPassword = true,
            autoFocus = true,
            onValueChange = {
                password = viewModel.normalizePasswordInput(it)
                localError = null
            }
        )
        Spacer(modifier = Modifier.height(48.dp))
        UnderlineInput(
            value = confirmPassword,
            placeholder = AppText.Auth.ConfirmPasswordPlaceholder,
            keyboardType = KeyboardType.Password,
            isPassword = true,
            onValueChange = {
                confirmPassword = viewModel.normalizePasswordInput(it)
                localError = null
            }
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(text = AppText.Auth.PasswordRule, color = AppColors.Auth.InputText, fontSize = 14.sp)
        Spacer(modifier = Modifier.height(12.dp))
        ProfilePickerRow(
            label = AppText.Profile.CountryRegion,
            required = false,
            value = selectedCountryRegion,
            placeholder = AppText.Common.China,
            onClick = { showRegionSheet = true }
        )
        Spacer(modifier = Modifier.height(44.dp))
        CorosFilledButton(
            text = AppText.Auth.Register,
            color = CorosButtonRed,
            enabled = viewModel.canRegisterWithPassword(password, confirmPassword),
            isLoading = state.isLoading,
            onClick = { register() }
        )
        ErrorText(localError ?: state.errorMessage)
        Spacer(modifier = Modifier.weight(1f))
    }

    if (showRegionSheet) {
        OptionSheet(
            title = AppText.Profile.CountryRegion,
            options = state.regions.map { it.region to it.region.toProfileCountryRegion() },
            selected = state.selectedRegion,
            onDismiss = { showRegionSheet = false },
            onConfirm = { region ->
                viewModel.onRegionChanged(region)
                showRegionSheet = false
                localError = null
            }
        )
    }
}

@Preview(showBackground = true)
@Composable
private fun PasswordSetupScreenPreview() {
    DemoTheme {
        PasswordSetupScreen(
            viewModel = LoginViewModel(),
            onBack = {},
            onRegisterSuccess = {}
        )
    }
}
