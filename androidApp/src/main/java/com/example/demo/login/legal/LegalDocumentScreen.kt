package com.example.demo.login.legal

import androidx.compose.runtime.Composable
import androidx.compose.ui.tooling.preview.Preview
import com.example.demo.login.components.LegalDocumentPage
import com.example.demo.login.components.parseLegalDocument
import androidx.compose.ui.res.stringResource
import com.example.demo.R
import com.example.demo.ui.theme.DemoTheme

@Composable
fun PrivacyPolicyScreen(onBack: () -> Unit) {
    LegalDocumentPage(
        title = stringResource(R.string.auth_privacy_policy),
        paragraphs = parseLegalDocument(stringResource(R.string.legal_privacy_body)),
        onBack = onBack
    )
}

@Composable
fun ServiceTermsScreen(onBack: () -> Unit) {
    LegalDocumentPage(
        title = stringResource(R.string.auth_service_terms),
        paragraphs = parseLegalDocument(stringResource(R.string.legal_service_terms_body)),
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
