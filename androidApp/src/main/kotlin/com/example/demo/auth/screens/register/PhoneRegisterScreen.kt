package com.example.demo.auth.screens.register

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
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.view.WindowInsetsControllerCompat
import com.example.demo.auth.viewmodel.LoginViewModel
import com.example.demo.auth.components.AuthTitleSize
import com.example.demo.auth.components.AuthTitleTopPadding
import com.example.demo.auth.components.CorosButtonRed
import com.example.demo.auth.components.CorosRed
import com.example.demo.auth.components.RegisterActionTopSpacing
import com.example.demo.auth.components.RegisterAgreementTopSpacing
import com.example.demo.auth.components.CorosWhite
import com.example.demo.auth.components.AuthBlackPage
import com.example.demo.auth.components.AgreementRow
import com.example.demo.auth.components.CorosFilledButton
import com.example.demo.auth.components.ErrorText
import com.example.demo.auth.components.PhoneInput
import com.example.demo.auth.components.TermsConsentSheet
import com.example.demo.auth.components.TermsPromptAction
import com.example.demo.auth.components.UnavailableFeatureDialog
import com.example.demo.auth.components.findActivity
import androidx.compose.ui.res.stringResource
import com.example.demo.R
import com.example.demo.common.auth.model.AuthMessageKeys
import com.example.demo.core.theme.DemoTheme
import androidx.compose.material3.Text
import com.example.demo.common.auth.model.LoginEffect

@Composable
fun PhoneRegisterScreen(
    viewModel: LoginViewModel,
    onBack: () -> Unit,
    onSendCode: (account: String) -> Unit,
    onEmailRegister: () -> Unit,
    onPrivacyClick: () -> Unit,
    onServiceTermsClick: () -> Unit
) {
    val state = viewModel.state
    var acceptedTerms by rememberSaveable { mutableStateOf(false) }
    var localError by rememberSaveable { mutableStateOf<String?>(null) }
    var termsPromptAction by rememberSaveable { mutableStateOf<TermsPromptAction?>(null) }
    var unavailableDialogVisible by rememberSaveable { mutableStateOf(false) }
    val view = LocalView.current

    fun requestPhoneVerifyCode(skipTerms: Boolean = false) {
        val validationMessage = viewModel.validatePhoneAccount(state.account)
        when {
            validationMessage != null -> localError = validationMessage
            viewModel.hasAccount(state.account) -> localError = AuthMessageKeys.ErrorAccountExists
            !skipTerms && !acceptedTerms -> termsPromptAction = TermsPromptAction.PhoneCode
            else -> {
                val message = viewModel.requestVerifyCodeMessage(state.account)
                if (message == null) {
                    onSendCode(state.account)
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
            text = stringResource(R.string.auth_phone_register),
            color = CorosWhite,
            fontSize = AuthTitleSize,
            fontWeight = FontWeight.Light,
            modifier = Modifier.padding(top = AuthTitleTopPadding)
        )
        Spacer(modifier = Modifier.height(60.dp))
        PhoneInput(
            value = state.account,
            autoFocus = true,
            onValueChange = {
                viewModel.onUsernameChanged(viewModel.normalizePhoneInput(it))
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
            text = stringResource(R.string.auth_send_code),
            color = CorosButtonRed,
            enabled = viewModel.canRequestPhoneCode(),
            isLoading = state.isLoading,
            onClick = { requestPhoneVerifyCode() }
        )
        ErrorText(localError ?: state.errorMessage)
        Text(
            text = stringResource(R.string.auth_email_register),
            color = CorosRed,
            fontSize = 18.sp,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth().padding(top = 26.dp).clickable { onEmailRegister() }
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
                requestPhoneVerifyCode(skipTerms = true)
            }
        )
    }

    if (unavailableDialogVisible) {
        UnavailableFeatureDialog(onDismiss = { unavailableDialogVisible = false })
    }
}

@Preview(showBackground = true)
@Composable
private fun PhoneRegisterScreenPreview() {
    DemoTheme {
        PhoneRegisterScreen(
            viewModel = LoginViewModel(),
            onBack = {},
            onSendCode = {},
            onEmailRegister = {},
            onPrivacyClick = {},
            onServiceTermsClick = {}
        )
    }
}
