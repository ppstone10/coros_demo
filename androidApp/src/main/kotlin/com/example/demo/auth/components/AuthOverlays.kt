package com.example.demo.auth.components

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.platform.LocalResources
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.demo.R
import com.example.demo.core.resources.AppColors
import com.example.demo.core.theme.DemoTheme

@Composable
fun ThirdPartyArea(onUnavailableClick: () -> Unit) {
    Column(modifier = Modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(modifier = Modifier.size(width = 120.dp, height = 1.dp).background(CorosLine))
            Text(text = stringResource(R.string.auth_third_party_account), color = CorosMuted, fontSize = 14.sp, modifier = Modifier.padding(horizontal = 12.dp))
            Box(modifier = Modifier.size(width = 120.dp, height = 1.dp).background(CorosLine))
        }
        Spacer(modifier = Modifier.height(24.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(54.dp)) {
            ThirdPartyCircle(text = "☘", onClick = onUnavailableClick)
            ThirdPartyCircle(text = "···", onClick = onUnavailableClick)
        }
    }
}

@Composable
fun ThirdPartyCircle(text: String, onClick: () -> Unit) {
    Box(
        modifier = Modifier.size(34.dp).clip(CircleShape).border(1.dp, AppColors.Auth.ThirdPartyBorder, CircleShape).clickable(onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        Text(text = text, color = CorosWhite, fontSize = 20.sp)
    }
}

@Composable
fun ErrorText(message: String?) {
    if (!message.isNullOrBlank()) {
        val localizedMessage = LocalResources.current.localizedAuthMessage(message).orEmpty()
        Text(text = localizedMessage, color = CorosRed, fontSize = 15.sp, modifier = Modifier.padding(top = 10.dp))
    }
}

@Composable
fun ModalScrim(
    color: Color,
    onClick: (() -> Unit)? = null
) {
    val focusManager = LocalFocusManager.current
    val keyboardController = LocalSoftwareKeyboardController.current
    LaunchedEffect(Unit) {
        focusManager.clearFocus(force = true)
        keyboardController?.hide()
    }
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(color)
            .pointerInput(onClick) {
                detectTapGestures { onClick?.invoke() }
            }
    )
}

@Composable
fun TermsConsentSheet(onDismiss: () -> Unit, onPrivacyClick: () -> Unit, onServiceTermsClick: () -> Unit, onAgree: () -> Unit) {
    BackHandler(onBack = onDismiss)
    Box(modifier = Modifier.fillMaxSize()) {
        ModalScrim(color = AppColors.Core.Black.copy(alpha = 0.78f))
        Column(
            modifier = Modifier.align(Alignment.BottomCenter).fillMaxWidth()
                .clip(RoundedCornerShape(topStart = 12.dp, topEnd = 12.dp))
                .background(AppColors.Auth.Sheet).padding(horizontal = 22.dp, vertical = 18.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(text = "×", color = CorosWhite, fontSize = 34.sp, modifier = Modifier.align(Alignment.End).clickable(onClick = onDismiss))
            Spacer(modifier = Modifier.height(12.dp))
            Text(text = stringResource(R.string.auth_read_terms), color = CorosWhite, fontSize = 18.sp, textAlign = TextAlign.Center)
            Row(modifier = Modifier.padding(top = 8.dp), horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically) {
                Text(text = stringResource(R.string.auth_privacy_policy_link), color = CorosRed, fontSize = 18.sp, modifier = Modifier.clickable(onClick = onPrivacyClick))
                Text(text = stringResource(R.string.auth_terms_joiner), color = CorosWhite, fontSize = 18.sp)
                Text(text = stringResource(R.string.auth_service_terms_link), color = CorosRed, fontSize = 18.sp, modifier = Modifier.clickable(onClick = onServiceTermsClick))
            }
            Spacer(modifier = Modifier.height(42.dp))
            CorosFilledButton(text = stringResource(R.string.auth_agree_and_continue), color = CorosRed, onClick = onAgree)
        }
    }
}

@Composable
fun UnavailableFeatureDialog(onDismiss: () -> Unit) {
    Box(modifier = Modifier.fillMaxSize().background(AppColors.Core.Black.copy(alpha = 0.62f)).clickable(onClick = onDismiss), contentAlignment = Alignment.Center) {
        Column(
            modifier = Modifier.padding(horizontal = 42.dp).clip(RoundedCornerShape(12.dp))
                .background(AppColors.Auth.Dialog).padding(horizontal = 28.dp, vertical = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(text = stringResource(R.string.auth_unavailable), color = CorosWhite, fontSize = 16.sp, textAlign = TextAlign.Center)
            Spacer(modifier = Modifier.height(20.dp))
            Text(text = stringResource(R.string.auth_got_it), color = CorosRed, fontSize = 16.sp, modifier = Modifier.clickable(onClick = onDismiss))
        }
    }
}

@Composable
fun BlockingLoadingOverlay() {
    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        ModalScrim(color = AppColors.Core.Black.copy(alpha = 0.72f))
        Box(modifier = Modifier.size(96.dp).clip(RoundedCornerShape(8.dp)).background(AppColors.Auth.Loading), contentAlignment = Alignment.Center) {
            CircularProgressIndicator(modifier = Modifier.size(36.dp), color = AppColors.Auth.InputText, strokeWidth = 4.dp)
        }
    }
}

@Composable
fun LegalDocumentPage(title: String, paragraphs: List<LegalParagraph>, onBack: () -> Unit) {
    val scrollState = rememberScrollState()
    Column(modifier = Modifier.fillMaxSize().background(CorosBlack).statusBarsPadding().padding(horizontal = 20.dp)) {
        Box(modifier = Modifier.fillMaxWidth().height(52.dp), contentAlignment = Alignment.Center) {
            Text(text = stringResource(R.string.common_back), color = CorosWhite, fontSize = 44.sp, modifier = Modifier.align(Alignment.CenterStart).clickable(onClick = onBack))
            Text(text = title, color = CorosWhite, fontSize = 18.sp, fontWeight = FontWeight.Bold, textAlign = TextAlign.Center)
        }
        Column(modifier = Modifier.fillMaxSize().weight(1f).verticalScroll(scrollState).padding(top = 16.dp, bottom = 32.dp)) {
            paragraphs.forEachIndexed { index, paragraph ->
                LegalParagraphText(paragraph = paragraph)
                if (index != paragraphs.lastIndex) Spacer(modifier = Modifier.height(if (paragraph.isHeading) 8.dp else 12.dp))
            }
        }
    }
}

@Composable
fun LegalParagraphText(paragraph: LegalParagraph) {
    Text(
        text = buildLegalText(paragraph.text, paragraph.highlights),
        color = if (paragraph.isHeading) CorosWhite else AppColors.Auth.LegalText,
        fontSize = if (paragraph.isHeading) 19.sp else 18.sp,
        lineHeight = if (paragraph.isHeading) 28.sp else 30.sp,
        fontWeight = if (paragraph.isHeading) FontWeight.Bold else FontWeight.Normal
    )
}

@Preview(showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun ErrorTextPreview() {
    DemoTheme {
        Column(Modifier.padding(20.dp)) {
            ErrorText(message = "This is an error message")
            ErrorText(message = null)
        }
    }
}

@Preview(showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun BlockingLoadingOverlayPreview() {
    DemoTheme {
        Box(Modifier.size(200.dp)) { BlockingLoadingOverlay() }
    }
}

@Preview(showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun ThirdPartyAreaPreview() {
    DemoTheme {
        Column(Modifier.padding(20.dp)) { ThirdPartyArea(onUnavailableClick = {}) }
    }
}

@Preview(showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun TermsConsentSheetPreview() {
    DemoTheme { TermsConsentSheet(onDismiss = {}, onPrivacyClick = {}, onServiceTermsClick = {}, onAgree = {}) }
}
