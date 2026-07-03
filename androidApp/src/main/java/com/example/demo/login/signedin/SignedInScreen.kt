package com.example.demo.login.signedin

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.Composable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.Alignment
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
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
import com.example.demo.login.components.ErrorText
import com.example.demo.ui.theme.DemoTheme
import androidx.compose.material3.Text
import androidx.compose.foundation.layout.Spacer
import androidx.compose.runtime.saveable.rememberSaveable

@Composable
fun SignedInScreen(
    viewModel: LoginViewModel,
    onBack: () -> Unit,
    onLogout: () -> Unit,
    onAccountDeleted: () -> Unit
) {
    val state = viewModel.state
    val username = state.currentSession?.resolvedDisplayName.orEmpty()
    var showDeleteDialog by rememberSaveable { mutableStateOf(false) }
    var localError by rememberSaveable { mutableStateOf<String?>(null) }

    Box {
        AuthBlackPage(onBack = onBack, showFeedback = false, showBack = false) {
            CorosLogo(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 80.dp)
            )
            Spacer(modifier = Modifier.height(96.dp))
            Text(
                text = "欢迎使用 COROS\n$username",
                color = CorosWhite,
                fontSize = 26.sp,
                lineHeight = 36.sp,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(modifier = Modifier.height(48.dp))
            CorosFilledButton(
                text = "退出登录",
                color = CorosButtonRed,
                onClick = {
                    viewModel.onLogout()
                    onLogout()
                }
            )
            Spacer(modifier = Modifier.height(16.dp))
            CorosFilledButton(
                text = "注销账户",
                color = Color(0xFF2A2A2E),
                onClick = { showDeleteDialog = true }
            )
            ErrorText(localError)
        }

        if (showDeleteDialog) {
            DeleteAccountDialog(
                onCancel = { showDeleteDialog = false },
                onConfirm = {
                    val message = viewModel.deleteCurrentAccountMessage()
                    if (message == null) {
                        showDeleteDialog = false
                        onAccountDeleted()
                    } else {
                        localError = message
                        showDeleteDialog = false
                    }
                }
            )
        }
    }
}

@Composable
private fun DeleteAccountDialog(
    onCancel: () -> Unit,
    onConfirm: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = 0.62f))
            .clickable(onClick = onCancel),
        contentAlignment = Alignment.Center
    ) {
        Column(
            modifier = Modifier
                .padding(horizontal = 42.dp)
                .clip(RoundedCornerShape(12.dp))
                .background(Color(0xFF202023))
                .clickable(onClick = {})
                .padding(horizontal = 24.dp, vertical = 22.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = "是否确认注销账号",
                color = CorosWhite,
                fontSize = 18.sp,
                textAlign = TextAlign.Center
            )
            Spacer(modifier = Modifier.height(24.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(14.dp)
            ) {
                DialogActionButton(
                    text = "取消",
                    color = Color(0xFF343438),
                    textColor = CorosWhite,
                    modifier = Modifier.weight(1f),
                    onClick = onCancel
                )
                DialogActionButton(
                    text = "确认",
                    color = CorosButtonRed,
                    textColor = CorosWhite,
                    modifier = Modifier.weight(1f),
                    onClick = onConfirm
                )
            }
        }
    }
}

@Composable
private fun DialogActionButton(
    text: String,
    color: Color,
    textColor: Color,
    modifier: Modifier = Modifier,
    onClick: () -> Unit
) {
    Box(
        modifier = modifier
            .height(44.dp)
            .clip(RoundedCornerShape(8.dp))
            .background(color)
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        Text(text = text, color = textColor, fontSize = 16.sp)
    }
}

@Preview(showBackground = true)
@Composable
private fun SignedInScreenPreview() {
    DemoTheme {
        SignedInScreen(
            viewModel = LoginViewModel(),
            onBack = {},
            onLogout = {},
            onAccountDeleted = {}
        )
    }
}
