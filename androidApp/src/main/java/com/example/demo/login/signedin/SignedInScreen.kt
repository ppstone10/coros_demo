package com.example.demo.login.signedin

import android.widget.ImageView
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.rememberScrollState
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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.net.toUri
import com.example.demo.common.login.toProfileCountryRegion
import com.example.demo.login.LoginViewModel
import com.example.demo.login.components.CorosButtonRed
import com.example.demo.login.components.CorosWhite
import com.example.demo.login.components.ErrorText
import com.example.demo.login.profile.PersonalProfileEditScreen
import com.example.demo.ui.resources.AppColors
import com.example.demo.ui.resources.AppText
import com.example.demo.ui.theme.DemoTheme

private val ProfileCardColor = AppColors.Account.Card
private val ProfileMuted = AppColors.Account.Muted

@Composable
fun SignedInScreen(
    viewModel: LoginViewModel,
    onBack: () -> Unit,
    onLogout: () -> Unit,
    onAccountDeleted: () -> Unit,
    onFullscreenChange: (Boolean) -> Unit = {}
) {
    val state = viewModel.state
    val session = state.currentSession
    val profile = session?.profile
    val username = session?.resolvedDisplayName?.takeIf { it.isNotBlank() } ?: AppText.Account.DefaultUser
    var showDeleteDialog by rememberSaveable { mutableStateOf(false) }
    var localError by rememberSaveable { mutableStateOf<String?>(null) }
    var editingProfile by rememberSaveable { mutableStateOf(false) }

    if (editingProfile) {
        PersonalProfileEditScreen(
            viewModel = viewModel,
            onBack = {
                editingProfile = false
                onFullscreenChange(false)
            },
            onSaved = {
                editingProfile = false
                onFullscreenChange(false)
            }
        )
        return
    }

    Box(Modifier.fillMaxSize().background(AppColors.Core.Black)) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .statusBarsPadding()
                .padding(horizontal = 18.dp)
        ) {
            Text(
                text = AppText.Account.My,
                color = CorosWhite,
                fontSize = 26.sp,
                fontWeight = FontWeight.SemiBold,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 18.dp, bottom = 18.dp)
            )
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(10.dp))
                    .background(ProfileCardColor)
                    .clickable {
                        editingProfile = true
                        onFullscreenChange(true)
                    }
                    .padding(horizontal = 18.dp, vertical = 18.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                ProfileSummaryAvatar(
                    avatarUri = profile?.avatarUri,
                    username = username
                )
                Spacer(Modifier.width(14.dp))
                Column(Modifier.weight(1f)) {
                    Text(username, color = CorosWhite, fontSize = 19.sp)
                    Spacer(Modifier.height(5.dp))
                    Text(
                        text = session?.account.orEmpty(),
                        color = ProfileMuted,
                        fontSize = 12.sp,
                        maxLines = 1
                    )
                }
                Text(
                    text = if (session?.isProfileComplete == true) AppText.Account.Complete else AppText.Account.Incomplete,
                    color = if (session?.isProfileComplete == true) {
                        AppColors.Account.Complete
                    } else {
                        AppColors.Account.Incomplete
                    },
                    fontSize = 11.sp,
                    modifier = Modifier.clickable {
                        editingProfile = true
                        onFullscreenChange(true)
                    }
                )
            }

            ProfileSectionTitle(AppText.Account.PersonalInfo)
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(10.dp))
                    .background(ProfileCardColor)
            ) {
                ProfileValueRow(AppText.Profile.Username, username)
                ProfileValueRow(AppText.Profile.BirthDate, profile?.birthDate.orEmpty().ifBlank { AppText.Common.NotSet })
                ProfileValueRow(AppText.Profile.Height, profile?.heightCm?.let { "$it cm" } ?: AppText.Common.NotSet)
                ProfileValueRow(AppText.Profile.Weight, profile?.weightKg?.let { "$it kg" } ?: AppText.Common.NotSet)
                ProfileValueRow(
                    AppText.Profile.CountryRegion,
                    profile?.countryRegion?.takeIf { it.isNotBlank() }
                        ?: session?.region?.toProfileCountryRegion().orEmpty()
                )
            }

            ProfileSectionTitle(AppText.Account.AccountSection)
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(10.dp))
                    .background(ProfileCardColor)
            ) {
                ProfileValueRow(AppText.Account.LoginAccount, session?.account.orEmpty())
                ProfileActionRow(AppText.Account.Logout, CorosWhite) {
                    viewModel.onLogout()
                    onLogout()
                }
                ProfileActionRow(AppText.Account.DeleteAccount, AppColors.Account.Destructive) {
                    showDeleteDialog = true
                }
            }

            Spacer(Modifier.height(18.dp))
            ErrorText(localError)
            Spacer(Modifier.height(30.dp))
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
private fun ProfileSummaryAvatar(avatarUri: String?, username: String) {
    Box(
        modifier = Modifier
            .size(58.dp)
            .clip(CircleShape)
            .background(AppColors.Account.AvatarFallback),
        contentAlignment = Alignment.Center
    ) {
        if (avatarUri.isNullOrBlank()) {
            Text(
                text = username.take(1).uppercase(),
                color = CorosWhite,
                fontSize = 23.sp,
                fontWeight = FontWeight.Medium
            )
        } else {
            val context = LocalContext.current
            AndroidView(
                modifier = Modifier.fillMaxSize(),
                factory = {
                    ImageView(context).apply {
                        scaleType = ImageView.ScaleType.CENTER_CROP
                    }
                },
                update = { imageView -> imageView.setImageURI(avatarUri.toUri()) }
            )
        }
    }
}

@Composable
private fun ProfileSectionTitle(title: String) {
    Text(
        text = title,
        color = ProfileMuted,
        fontSize = 13.sp,
        modifier = Modifier.padding(top = 24.dp, bottom = 10.dp, start = 4.dp)
    )
}

@Composable
private fun ProfileValueRow(label: String, value: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(52.dp)
            .padding(horizontal = 16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(label, color = CorosWhite, fontSize = 14.sp)
        Spacer(Modifier.weight(1f))
        Text(value.ifBlank { AppText.Common.NotSet }, color = ProfileMuted, fontSize = 13.sp)
    }
    Box(
        Modifier
            .padding(start = 16.dp)
            .fillMaxWidth()
            .height(1.dp)
            .background(AppColors.Account.Divider)
    )
}

@Composable
private fun ProfileActionRow(text: String, textColor: Color, onClick: () -> Unit) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(52.dp)
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp),
        contentAlignment = Alignment.CenterStart
    ) {
        Text(text, color = textColor, fontSize = 14.sp)
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
            .background(AppColors.Core.Black.copy(alpha = 0.62f))
            .clickable(onClick = onCancel),
        contentAlignment = Alignment.Center
    ) {
        Column(
            modifier = Modifier
                .padding(horizontal = 42.dp)
                .clip(RoundedCornerShape(12.dp))
                .background(AppColors.Account.Dialog)
                .clickable(onClick = {})
                .padding(horizontal = 24.dp, vertical = 22.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = AppText.Account.DeleteConfirmation,
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
                    text = AppText.Common.Cancel,
                    color = AppColors.Account.DialogSecondary,
                    textColor = CorosWhite,
                    modifier = Modifier.weight(1f),
                    onClick = onCancel
                )
                DialogActionButton(
                    text = AppText.Common.Confirm,
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
