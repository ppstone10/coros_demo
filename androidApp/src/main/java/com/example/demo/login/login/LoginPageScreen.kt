package com.example.demo.login.login

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.view.WindowInsetsControllerCompat
import com.example.demo.common.login.AuthMode
import com.example.demo.common.login.LoginEffect
import com.example.demo.login.LoginViewModel
import com.example.demo.login.components.AuthTitleSize
import com.example.demo.login.components.AuthTitleTopPadding
import com.example.demo.login.components.CorosButtonRed
import com.example.demo.login.components.CorosMuted
import com.example.demo.login.components.CorosWhite
import com.example.demo.login.components.AuthBlackPage
import com.example.demo.login.components.AgreementRow
import com.example.demo.login.components.CorosFilledButton
import com.example.demo.login.components.ErrorText
import com.example.demo.login.components.TermsConsentSheet
import com.example.demo.login.components.TermsPromptAction
import com.example.demo.login.components.ThirdPartyArea
import com.example.demo.login.components.UnderlineInput
import com.example.demo.login.components.UnavailableFeatureDialog
import com.example.demo.login.components.findActivity
import com.example.demo.ui.theme.DemoTheme
import androidx.compose.material3.Text

@Composable
fun LoginPageScreen(
    viewModel: LoginViewModel,
    onBack: () -> Unit,
    onLoginSuccess: () -> Unit,
    onForgotPasswordClick: () -> Unit,
    onPrivacyClick: () -> Unit,
    onServiceTermsClick: () -> Unit
) {
    val state = viewModel.state
    var acceptedTerms by rememberSaveable { mutableStateOf(false) }
    var localError by rememberSaveable { mutableStateOf<String?>(null) }
    var termsPromptAction by rememberSaveable { mutableStateOf<TermsPromptAction?>(null) }
    var unavailableDialogVisible by rememberSaveable { mutableStateOf(false) }
    val view = LocalView.current

    fun submitLogin(skipTerms: Boolean = false) {
        if (!skipTerms && !acceptedTerms) {
            termsPromptAction = TermsPromptAction.Login
        } else {
            viewModel.onModeChanged(AuthMode.Login)
            viewModel.onSubmit()
        }
    }

    SideEffect {
        val activity = view.context.findActivity() ?: return@SideEffect
        WindowInsetsControllerCompat(activity.window, view).apply {
            isAppearanceLightStatusBars = false
            isAppearanceLightNavigationBars = false
        }
    }

    LaunchedEffect(viewModel.effect) {
        if (viewModel.effect is LoginEffect.ShowMessage) {
            localError = (viewModel.effect as LoginEffect.ShowMessage).message
            viewModel.onEffectConsumed()
        }
    }

    AuthBlackPage(
        onBack = onBack,
        showFeedback = true,
        onUnavailableClick = { unavailableDialogVisible = true }
    ) {
        Text(
            text = "账号登录",
            color = CorosWhite,
            fontSize = AuthTitleSize,
            fontWeight = FontWeight.Light,
            modifier = Modifier.padding(top = AuthTitleTopPadding)
        )
        Spacer(modifier = Modifier.height(45.dp))
        UnderlineInput(
            value = state.account,
            placeholder = "输入手机号或邮箱",
            keyboardType = KeyboardType.Email,
            autoFocus = true,
            onValueChange = {
                viewModel.onUsernameChanged(it)
                localError = null
            }
        )
        Spacer(modifier = Modifier.height(16.dp))
        UnderlineInput(
            value = state.password,
            placeholder = "密码",
            keyboardType = KeyboardType.Password,
            isPassword = true,
            onValueChange = {
                viewModel.onPasswordChanged(it)
                localError = null
            }
        )
        Spacer(modifier = Modifier.height(59.dp))
        AgreementRow(
            accepted = acceptedTerms,
            onToggle = { acceptedTerms = !acceptedTerms; localError = null },
            onPrivacyClick = onPrivacyClick,
            onServiceTermsClick = onServiceTermsClick
        )
        Spacer(modifier = Modifier.height(12.dp))
        CorosFilledButton(
            text = "登录",
            color = CorosButtonRed,
            enabled = viewModel.canSubmitLogin(),
            isLoading = state.isLoading,
            onClick = { submitLogin() }
        )
        ErrorText(localError ?: state.errorMessage)
        Spacer(modifier = Modifier.height(16.dp))
        Text(
            text = "忘记密码?",
            color = CorosMuted,
            fontSize = 14.sp,
            modifier = Modifier.clickable { onForgotPasswordClick() }
        )
        Spacer(modifier = Modifier.weight(1f))
        ThirdPartyArea(onUnavailableClick = { unavailableDialogVisible = true })
        Text(
            text = "V4.8.1.14",
            color = CorosMuted,
            fontSize = 16.sp,
            modifier = Modifier.fillMaxWidth().padding(top = 22.dp, bottom = 12.dp),
            textAlign = TextAlign.Center
        )
    }

    if (termsPromptAction != null) {
        TermsConsentSheet(
            onDismiss = { termsPromptAction = null },
            onPrivacyClick = onPrivacyClick,
            onServiceTermsClick = onServiceTermsClick,
            onAgree = {
                acceptedTerms = true
                termsPromptAction = null
                submitLogin(skipTerms = true)
            }
        )
    }

    if (unavailableDialogVisible) {
        UnavailableFeatureDialog(onDismiss = { unavailableDialogVisible = false })
    }
}

@Preview(showBackground = true)
@Composable
private fun LoginPageScreenPreview() {
    DemoTheme {
        LoginPageScreen(
            viewModel = LoginViewModel(),
            onBack = {},
            onLoginSuccess = {},
            onForgotPasswordClick = {},
            onPrivacyClick = {},
            onServiceTermsClick = {}
        )
    }
}
