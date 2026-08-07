package com.example.demo.auth.components

import android.app.Activity
import android.content.Context
import android.content.ContextWrapper
import android.graphics.Color as AndroidColor
import android.view.Gravity
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.VideoView
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.net.toUri
import com.example.demo.R
import com.example.demo.core.resources.AppImage
import com.example.demo.core.resources.AppImages
import com.example.demo.core.theme.DemoTheme
import kotlin.math.roundToInt

fun Context.findActivity(): Activity? {
    return when (this) {
        is Activity -> this
        is ContextWrapper -> baseContext.findActivity()
        else -> null
    }
}

@Composable
fun AuthBlackPage(
    onBack: () -> Unit,
    showFeedback: Boolean,
    showBack: Boolean = true,
    onUnavailableClick: () -> Unit = {},
    content: @Composable ColumnScope.() -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(CorosBlack)
            .statusBarsPadding()
            .verticalScroll(rememberScrollState())
            .heightIn(min = 812.dp)
            .padding(horizontal = 20.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth().height(52.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            if (showBack) {
                Text(
                    text = stringResource(R.string.common_back),
                    color = CorosWhite,
                    fontSize = 44.sp,
                    modifier = Modifier.clickable(onClick = onBack)
                )
            }
            Spacer(modifier = Modifier.weight(1f))
            if (showFeedback) {
                Text(
                    text = stringResource(R.string.auth_feedback),
                    color = CorosMuted,
                    fontSize = 14.sp,
                    modifier = Modifier.clickable(onClick = onUnavailableClick)
                )
            }
        }
        content()
    }
}

@Composable
fun CorosLogo(modifier: Modifier = Modifier) {
    Row(
        modifier = modifier,
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically
    ) {
        AppImage(
            asset = AppImages.Auth.Logo,
            contentDescription = stringResource(R.string.auth_logo),
            modifier = Modifier.width(260.dp).height(48.dp)
        )
    }
}

@Composable
fun HomeBackgroundVideo(modifier: Modifier = Modifier) {
    AndroidView(
        modifier = modifier,
        factory = { context ->
            FrameLayout(context).apply {
                setBackgroundColor(AndroidColor.BLACK)
                val videoView = VideoView(context)
                var videoWidth = 0
                var videoHeight = 0
                fun resizeVideo() {
                    if (width == 0 || height == 0 || videoWidth == 0 || videoHeight == 0) return
                    val scale = maxOf(width.toFloat() / videoWidth.toFloat(), height.toFloat() / videoHeight.toFloat())
                    val targetWidth = (videoWidth * scale).roundToInt()
                    val targetHeight = (videoHeight * scale).roundToInt()
                    videoView.layoutParams = FrameLayout.LayoutParams(targetWidth, targetHeight, Gravity.CENTER)
                }
                addView(videoView, FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT, Gravity.CENTER))
                addOnLayoutChangeListener { _, _, _, _, _, _, _, _, _ -> resizeVideo() }
                videoView.setOnPreparedListener { mediaPlayer ->
                    mediaPlayer.isLooping = true
                    mediaPlayer.setVolume(0f, 0f)
                    videoWidth = mediaPlayer.videoWidth
                    videoHeight = mediaPlayer.videoHeight
                    resizeVideo()
                    videoView.start()
                }
                videoView.setVideoURI("android.resource://${context.packageName}/${R.raw.home}".toUri())
                videoView.start()
            }
        },
        update = { container ->
            val videoView = container.getChildAt(0) as? VideoView
            if (videoView?.isPlaying == false) videoView.start()
        }
    )
}

@Preview(showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun CorosLogoPreview() {
    DemoTheme { Column(Modifier.padding(20.dp)) { CorosLogo() } }
}
