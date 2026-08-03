package com.example.demo.login.password

import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.example.demo.login.LoginViewModel
import com.example.demo.login.components.AuthBlackPage
import com.example.demo.login.components.AuthTitleSize
import com.example.demo.login.components.AuthTitleTopPadding
import com.example.demo.login.components.CorosButtonRed
import com.example.demo.login.components.CorosFilledButton
import com.example.demo.login.components.CorosWhite
import com.example.demo.login.components.ErrorText
import com.example.demo.login.components.UnderlineInput
import androidx.compose.ui.res.stringResource
import com.example.demo.R
import com.example.demo.common.login.AuthMessageKeys
import com.example.demo.ui.theme.DemoTheme

@Composable
fun ForgotPasswordScreen(
    viewModel: LoginViewModel,
    onBack: () -> Unit,
    onAccountVerified: (String) -> Unit
) {
    var account by rememberSaveable { mutableStateOf("") }
    var localError by rememberSaveable { mutableStateOf<String?>(null) }

    fun verifyAccount() {
        val rawAccount = account.trim()
        val isEmail = rawAccount.contains("@")
        val normalizedAccount = if (isEmail) {
            viewModel.normalizeEmailInput(rawAccount)
        } else {
            rawAccount
        }
        val validationMessage = if (isEmail) {
            viewModel.validateEmailAccount(normalizedAccount)
        } else if (rawAccount != viewModel.normalizePhoneInput(rawAccount)) {
            AuthMessageKeys.ValidationPhoneInvalid
        } else {
            viewModel.validatePhoneAccount(normalizedAccount)
        }
        when {
            validationMessage != null -> localError = validationMessage
            !viewModel.hasAccount(normalizedAccount) -> localError = AuthMessageKeys.ErrorAccountNotFound
            else -> onAccountVerified(normalizedAccount)
        }
    }

    AuthBlackPage(onBack = onBack, showFeedback = false) {
        Text(
            text = stringResource(R.string.auth_find_password),
            color = CorosWhite,
            fontSize = AuthTitleSize,
            fontWeight = FontWeight.Light,
            modifier = Modifier.padding(top = AuthTitleTopPadding)
        )
        Spacer(modifier = Modifier.height(60.dp))
        UnderlineInput(
            value = account,
            placeholder = stringResource(R.string.auth_account_placeholder),
            keyboardType = KeyboardType.Email,
            autoFocus = true,
            onValueChange = {
                account = it.trim()
                localError = null
            }
        )
        Spacer(modifier = Modifier.height(72.dp))
        CorosFilledButton(
            text = stringResource(R.string.auth_next_step),
            color = CorosButtonRed,
            enabled = account.isNotBlank(),
            onClick = { verifyAccount() }
        )
        ErrorText(localError)
        Spacer(modifier = Modifier.weight(1f))
    }
}

@Preview(showBackground = true)
@Composable
private fun ForgotPasswordScreenPreview() {
    DemoTheme {
        ForgotPasswordScreen(
            viewModel = LoginViewModel(),
            onBack = {},
            onAccountVerified = {}
        )
    }
}
