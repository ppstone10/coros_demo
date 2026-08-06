package com.example.demo.auth.screens.profile

import android.graphics.Bitmap
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.Dp
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * 头像显示组件：本地缓存优先 + 后台补下载。
 * - 组合时先用本地缓存同步赋值（`resolveAvatarCached`），命中即即时显示，无占位闪烁；
 * - 缓存未命中（首次）在 Dispatchers.IO 下载并写缓存；
 * - key 由 `avatarUri + revision` 组成：上传新图后递增 revision，强制重新加载。
 */
@Composable
internal fun AvatarImage(
    avatarUri: String?,
    size: Dp,
    modifier: Modifier = Modifier,
    placeholder: @Composable (() -> Unit)? = null
) {
    val context = LocalContext.current
    var bitmap by remember(avatarUri) { mutableStateOf(resolveAvatarCached(avatarUri, context)) }

    LaunchedEffect(avatarUri) {
        if (bitmap == null && !avatarUri.isNullOrBlank()) {
            bitmap = withContext(Dispatchers.IO) {
                resolveAvatarBitmap(avatarUri, context)
            }
        }
    }

    Box(
        modifier = modifier
            .size(size)
            .clip(CircleShape)
            .background(androidx.compose.ui.graphics.Color.Transparent),
        contentAlignment = Alignment.Center
    ) {
        if (bitmap != null) {
            Image(
                bitmap = bitmap!!.asImageBitmap(),
                contentDescription = null,
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Crop
            )
        } else {
            placeholder?.invoke()
        }
    }
}

/**
 * 头像在编辑页使用：带 revision，上传成功后递增 revision 触发重载。
 * 用法：在持有 avatarUri 的可组合内 `var avatarRevision by remember { mutableStateOf(0) }`，
 * 上传成功后将 avatarRevision++，并传入本组件。
 * [overrideBitmap] 用于"选图后未保存"的本地预览（信息修改界面），非空时优先展示。
 */
@Composable
internal fun AvatarImageWithRevision(
    avatarUri: String?,
    revision: Int,
    size: Dp,
    modifier: Modifier = Modifier,
    placeholder: @Composable (() -> Unit)? = null,
    overrideBitmap: Bitmap? = null
) {
    val key = "$avatarUri#$revision"
    val context = LocalContext.current
    var bitmap by remember(key) { mutableStateOf(overrideBitmap ?: resolveAvatarCached(avatarUri, context)) }

    LaunchedEffect(key) {
        if (overrideBitmap == null && bitmap == null && !avatarUri.isNullOrBlank()) {
            bitmap = withContext(Dispatchers.IO) {
                resolveAvatarBitmap(avatarUri, context)
            }
        }
    }

    val display = overrideBitmap ?: bitmap
    Box(
        modifier = modifier
            .size(size)
            .clip(CircleShape)
            .background(androidx.compose.ui.graphics.Color.Transparent),
        contentAlignment = Alignment.Center
    ) {
        if (display != null) {
            Image(
                bitmap = display.asImageBitmap(),
                contentDescription = null,
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Crop
            )
        } else {
            placeholder?.invoke()
        }
    }
}
