package com.example.demo.login.legal

import androidx.compose.runtime.Composable
import androidx.compose.ui.tooling.preview.Preview
import com.example.demo.login.components.LegalDocumentPage
import com.example.demo.login.components.LegalParagraph
import com.example.demo.login.components.PrivacyPolicyParagraphs
import com.example.demo.login.components.ServiceTermsParagraphs
import com.example.demo.ui.theme.DemoTheme

@Composable
fun PrivacyPolicyScreen(onBack: () -> Unit) {
    LegalDocumentPage(
        title = "隐私政策",
        paragraphs = PrivacyPolicyParagraphs,
        onBack = onBack
    )
}

@Composable
fun ServiceTermsScreen(onBack: () -> Unit) {
    LegalDocumentPage(
        title = "服务条款",
        paragraphs = ServiceTermsParagraphs,
        onBack = onBack
    )
}

@Preview(showBackground = true)
@Composable
private fun PrivacyPolicyScreenPreview() {
    DemoTheme {
        PrivacyPolicyScreen(onBack = {})
    }
}

@Preview(showBackground = true)
@Composable
private fun ServiceTermsScreenPreview() {
    DemoTheme {
        ServiceTermsScreen(onBack = {})
    }
}
