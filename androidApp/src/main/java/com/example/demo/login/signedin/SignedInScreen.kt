package com.example.demo.login.signedin

import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.demo.login.LoginViewModel
import com.example.demo.login.components.CorosButtonRed
import com.example.demo.login.components.CorosWhite
import com.example.demo.login.components.AuthBlackPage
import com.example.demo.login.components.CorosFilledButton
import com.example.demo.login.components.CorosLogo
import com.example.demo.ui.theme.DemoTheme
import androidx.compose.material3.Text

@Composable
fun SignedInScreen(
    viewModel: LoginViewModel,
    onLogout: () -> Unit
) {
    val state = viewModel.state

    AuthBlackPage(onBack = {}, showFeedback = false) {
        CorosLogo(
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = 80.dp)
        )
        Spacer(modifier = Modifier.height(96.dp))
        Text(
            text = "欢迎使用 COROS\n${state.currentSession?.account.orEmpty()}",
            color = CorosWhite,
            fontSize = 26.sp,
            lineHeight = 36.sp,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth()
        )
        Spacer(modifier = Modifier.height(48.dp))
        CorosFilledButton(text = "退出登录", color = CorosButtonRed, onClick = {
            viewModel.onLogout()
            onLogout()
        })
    }
}

@Preview(showBackground = true)
@Composable
private fun SignedInScreenPreview() {
    DemoTheme {
        SignedInScreen(
            viewModel = LoginViewModel(),
            onLogout = {}
        )
    }
}
