package com.example.demo.auth.screens.profile

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.demo.R
import com.example.demo.auth.components.CorosLine
import com.example.demo.auth.components.CorosWhite
import com.example.demo.auth.components.ModalScrim
import com.example.demo.core.resources.AppColors
@Composable
internal fun AvatarActionSheet(
    onDismiss: () -> Unit,
    onAlbum: () -> Unit,
    onCamera: () -> Unit
) {
    BackHandler(onBack = onDismiss)
    Box(modifier = Modifier.fillMaxSize()) {
        ModalScrim(
            color = AppColors.Core.Black.copy(alpha = 0.42f),
            onClick = onDismiss
        )
        Column(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .fillMaxWidth()
                .clip(RoundedCornerShape(topStart = 10.dp, topEnd = 10.dp))
                .background(AppColors.Profile.ActionSheet)
                .navigationBarsPadding()
        ) {
            SheetAction(text = stringResource(R.string.profile_take_photo), onClick = onCamera)
            Box(modifier = Modifier.fillMaxWidth().height(1.dp).background(CorosLine))
            SheetAction(text = stringResource(R.string.profile_album), onClick = onAlbum)
            Box(modifier = Modifier.fillMaxWidth().height(8.dp).background(AppColors.Profile.ActionSheetDivider))
            SheetAction(text = stringResource(R.string.common_cancel), onClick = onDismiss)
        }
    }
}

@Composable
private fun SheetAction(text: String, onClick: () -> Unit) {
    Box(
        modifier = Modifier.fillMaxWidth().height(64.dp).clickable(onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        Text(text = text, color = CorosWhite, fontSize = 20.sp)
    }
}
