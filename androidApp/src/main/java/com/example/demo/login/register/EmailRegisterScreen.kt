package com.example.demo.login.register

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
import com.example.demo.login.LoginViewModel
import com.example.demo.login.components.AuthTitleSize
import com.example.demo.login.components.AuthTitleTopPadding
import com.example.demo.login.components.CorosButtonRed
import com.example.demo.login.components.CorosRed
import com.example.demo.login.components.CorosWhite
import com.example.demo.login.components.RegisterActionTopSpacing
import com.example.demo.login.components.RegisterAgreementTopSpacing
import com.example.demo.login.components.AuthBlackPage
import com.example.demo.login.components.AgreementRow
import com.example.demo.login.components.CorosFilledButton
import com.example.demo.login.components.ErrorText
import com.example.demo.login.components.TermsConsentSheet
import com.example.demo.login.components.TermsPromptAction
import com.example.demo.login.components.UnderlineInput
import com.example.demo.login.components.UnavailableFeatureDialog
import com.example.demo.login.components.findActivity
import com.example.demo.ui.theme.DemoTheme
import androidx.compose.material3.Text

@Composable
fun EmailRegisterScreen(
    viewModel: LoginViewModel,
    onBack: () -> Unit,
    onSendCode: (email: String) -> Unit,
    onPhoneRegister: () -> Unit,
    onPrivacyClick: () -> Unit,
    onServiceTermsClick: () -> Unit
) {
    val state = viewModel.state
    var acceptedTerms by rememberSaveable { mutableStateOf(false) }
    var emailInput by rememberSaveable { mutableStateOf("") }
    var localError by rememberSaveable { mutableStateOf<String?>(null) }
    var termsPromptAction by rememberSaveable { mutableStateOf<TermsPromptAction?>(null) }
    var unavailableDialogVisible by rememberSaveable { mutableStateOf(false) }
    val view = LocalView.current

    fun requestEmailVerifyCode(skipTerms: Boolean = false) {
        val email = viewModel.normalizeEmailInput(emailInput)
        val validationMessage = viewModel.validateEmailAccount(email)
        when {
            validationMessage != null -> localError = validationMessage
            !skipTerms && !acceptedTerms -> termsPromptAction = TermsPromptAction.EmailCode
            else -> {
                val message = viewModel.requestVerifyCodeMessage(email)
                if (message == null) {
                    onSendCode(email)
                } else {
                    localError = message
                }
            }
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
        when (viewModel.effect) {
            is com.example.demo.common.login.LoginEffect.ShowMessage -> {
                localError = (viewModel.effect as? com.example.demo.common.login.LoginEffect.ShowMessage)?.message
                viewModel.onEffectConsumed()
            }
            else -> viewModel.onEffectConsumed()
        }
    }

    AuthBlackPage(
        onBack = onBack,
        showFeedback = true,
        onUnavailableClick = { unavailableDialogVisible = true }
    ) {
        Text(
            text = "邮箱注册",
            color = CorosWhite,
            fontSize = AuthTitleSize,
            fontWeight = FontWeight.Light,
            modifier = Modifier.padding(top = AuthTitleTopPadding)
        )
        Spacer(modifier = Modifier.height(60.dp))
        UnderlineInput(
            value = emailInput,
            placeholder = "请输入邮箱",
            keyboardType = KeyboardType.Email,
            autoFocus = true,
            onValueChange = {
                emailInput = viewModel.normalizeEmailInput(it)
                localError = null
            }
        )
        Spacer(modifier = Modifier.height(RegisterAgreementTopSpacing))
        AgreementRow(
            accepted = acceptedTerms,
            onToggle = { acceptedTerms = !acceptedTerms; localError = null },
            onPrivacyClick = onPrivacyClick,
            onServiceTermsClick = onServiceTermsClick
        )
        Spacer(modifier = Modifier.height(RegisterActionTopSpacing))
        CorosFilledButton(
            text = "发送验证码",
            color = CorosButtonRed,
            enabled = viewModel.canRequestEmailCode(emailInput),
            onClick = { requestEmailVerifyCode() }
        )
        ErrorText(localError ?: state.errorMessage)
        Text(
            text = "手机号注册",
            color = CorosRed,
            fontSize = 18.sp,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth().padding(top = 26.dp).clickable { onPhoneRegister() }
        )
        Spacer(modifier = Modifier.weight(1f))
    }

    if (termsPromptAction != null) {
        TermsConsentSheet(
            onDismiss = { termsPromptAction = null },
            onPrivacyClick = onPrivacyClick,
            onServiceTermsClick = onServiceTermsClick,
            onAgree = {
                acceptedTerms = true
                termsPromptAction = null
                requestEmailVerifyCode(skipTerms = true)
            }
        )
    }

    if (unavailableDialogVisible) {
        UnavailableFeatureDialog(onDismiss = { unavailableDialogVisible = false })
    }
}

@Preview(showBackground = true)
@Composable
private fun EmailRegisterScreenPreview() {
    DemoTheme {
        EmailRegisterScreen(
            viewModel = LoginViewModel(),
            onBack = {},
            onSendCode = {},
            onPhoneRegister = {},
            onPrivacyClick = {},
            onServiceTermsClick = {}
        )
    }
}
