package com.example.demo.home

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import com.example.demo.R
import com.example.demo.ui.resources.AppColors
import com.example.demo.ui.theme.DemoTheme

@Composable
fun ExplorePlaceholderScreen() {
    Box(
        modifier = Modifier.fillMaxSize().background(AppColors.Core.Black),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = stringResource(R.string.nav_unavailable, stringResource(R.string.nav_explore)),
            color = AppColors.Navigation.Placeholder,
            textAlign = TextAlign.Center
        )
    }
}

@Preview(showBackground = true)
@Composable
private fun ExplorePlaceholderScreenPreview() {
    DemoTheme {
        ExplorePlaceholderScreen()
    }
}
