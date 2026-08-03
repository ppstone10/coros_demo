package com.example.demo.login.entrance

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.demo.login.LoginViewModel
import com.example.demo.login.components.CorosRed
import com.example.demo.login.components.CorosFilledButton
import com.example.demo.login.components.CorosLogo
import com.example.demo.login.components.HomeBackgroundVideo
import com.example.demo.ui.resources.AppColors
import com.example.demo.ui.language.LanguageIconButton
import androidx.compose.ui.res.stringResource
import com.example.demo.R
import com.example.demo.ui.theme.DemoTheme

@Composable
fun EntranceScreen(
    viewModel: LoginViewModel,
    onRegisterClick: () -> Unit,
    onLoginClick: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(AppColors.Auth.EntranceBackground)
    ) {
        HomeBackgroundVideo(modifier = Modifier.fillMaxSize())
        CorosLogo(
            modifier = Modifier
                .align(Alignment.TopCenter)
                .padding(top = 62.dp)
        )
        LanguageIconButton(
            modifier = Modifier
                .align(Alignment.TopEnd)
                .statusBarsPadding()
                .padding(top = 10.dp, end = 12.dp)
        )
        Column(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(horizontal = 20.dp)
                .padding(bottom = 60.dp),
            verticalArrangement = Arrangement.spacedBy(20.dp)
        ) {
            CorosFilledButton(
                text = stringResource(R.string.auth_register),
                color = CorosRed,
                buttonHeight = 48.dp,
                textSize = 18.sp,
                onClick = onRegisterClick
            )
            CorosFilledButton(
                text = stringResource(R.string.auth_login),
                color = AppColors.Core.White.copy(alpha = 0.26f),
                buttonHeight = 48.dp,
                textSize = 18.sp,
                onClick = onLoginClick
            )
        }
    }
}

@Preview(showBackground = true)
@Composable
private fun EntranceScreenPreview() {
    DemoTheme {
        EntranceScreen(
            viewModel = LoginViewModel(),
            onRegisterClick = {},
            onLoginClick = {}
        )
    }
}
