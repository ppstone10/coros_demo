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
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.demo.R
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
import com.example.demo.common.login.toProfileCountryCode
import com.example.demo.login.profile.OptionSheet
import com.example.demo.login.profile.ProfilePickerRow
import com.example.demo.ui.resources.AppColors
import com.example.demo.ui.language.countryDisplayName

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
    val selectedCountryRegion = countryDisplayName(state.selectedRegion.toProfileCountryCode())

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
            text = stringResource(R.string.auth_set_login_password),
            color = CorosWhite,
            fontSize = AuthTitleSize,
            fontWeight = FontWeight.Light,
            modifier = Modifier.padding(top = AuthTitleTopPadding)
        )
        Spacer(modifier = Modifier.height(60.dp))
        UnderlineInput(
            value = password,
            placeholder = stringResource(R.string.auth_new_password_placeholder),
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
            placeholder = stringResource(R.string.auth_confirm_password_placeholder),
            keyboardType = KeyboardType.Password,
            isPassword = true,
            onValueChange = {
                confirmPassword = viewModel.normalizePasswordInput(it)
                localError = null
            }
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(text = stringResource(R.string.auth_password_rule), color = AppColors.Auth.InputText, fontSize = 14.sp)
        Spacer(modifier = Modifier.height(12.dp))
        ProfilePickerRow(
            label = stringResource(R.string.profile_country_region),
            required = false,
            value = selectedCountryRegion,
            placeholder = stringResource(R.string.common_china),
            onClick = { showRegionSheet = true }
        )
        Spacer(modifier = Modifier.height(44.dp))
        CorosFilledButton(
            text = stringResource(R.string.auth_register),
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
            title = stringResource(R.string.profile_country_region),
            options = state.regions.map { it.region to countryDisplayName(it.region) },
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
