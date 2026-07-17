# Android App 资源管理与维护规范

## 1. 目标

本规范用于统一 Android App 中各类资源的组织、命名、引用和维护方式，降低以下问题的发生概率：

- 资源文件散落、重复或难以查找
- 页面中大量硬编码文字、颜色和尺寸
- 深色模式、多语言和不同屏幕适配困难
- 资源替换后需要修改大量业务代码
- 多模块项目中公共资源与业务资源边界混乱
- 图标、颜色、样式在不同页面表现不一致

核心原则：

1. **资源优先交给 Android `res` 系统管理。**
2. **业务代码依赖资源的语义，而不是具体颜色、尺寸或文件版本。**
3. **颜色、字体、形状等视觉规范通过 Theme 和设计系统统一。**
4. **公共资源放公共模块，业务专属资源放对应业务模块。**
5. **不要创建仅用于重复映射 `R.string`、`R.drawable`、`R.color` 的 Kotlin 文件。**

---

## 2. 推荐的整体分层

```text
原始资源
strings / colors / drawables / fonts / dimens
                ↓
主题与设计 Token
MaterialTheme / AppTheme / styles / attrs
                ↓
公共 UI 组件
AppButton / AppIcon / AppTextField / AppDialog
                ↓
业务页面
Login / Profile / Order / Payment
```

业务页面应尽量使用主题和公共组件，而不是直接散落地引用颜色值、尺寸值和复杂 drawable。

---

## 3. 推荐目录结构

一个常见的单模块项目可以使用以下结构：

```text
app/src/main/res/
├── anim/
├── animator/
├── color/
├── drawable/
├── drawable-night/
├── drawable-nodpi/
├── font/
├── layout/
├── menu/
├── mipmap-anydpi-v26/
├── mipmap-hdpi/
├── mipmap-mdpi/
├── mipmap-xhdpi/
├── mipmap-xxhdpi/
├── mipmap-xxxhdpi/
├── navigation/
├── raw/
├── values/
│   ├── attrs.xml
│   ├── colors.xml
│   ├── dimens.xml
│   ├── integers.xml
│   ├── strings.xml
│   ├── styles.xml
│   └── themes.xml
├── values-night/
│   ├── colors.xml
│   └── themes.xml
├── values-en/
│   └── strings.xml
├── values-zh-rCN/
│   └── strings.xml
├── values-zh-rTW/
│   └── strings.xml
└── xml/
```

不需要为了“看起来分类清晰”而把所有目录都创建出来。只有项目实际需要时再增加。

---

# 4. 文字资源

## 4.1 用户可见文字放入 `strings.xml`

适用于：

- 页面标题
- 按钮文字
- 输入框提示
- Toast、Snackbar、Dialog 文案
- 错误提示
- 空状态文案
- 无障碍描述
- 通知标题和内容
- 菜单文字
- 业务状态描述

```xml
<!-- res/values/strings.xml -->
<resources>
    <string name="common_confirm">确定</string>
    <string name="common_cancel">取消</string>

    <string name="login_title">账号登录</string>
    <string name="login_submit">登录</string>
    <string name="login_password_hint">请输入密码</string>
    <string name="login_failed">登录失败，请重试</string>
</resources>
```

XML 中使用：

```xml   android:text="@string/login_submit"
```

Compose 中使用：

```kotlin
Text(text = stringResource(R.string.login_submit))
```

传统 View 中使用：

```kotlin
textView.text = context.getString(R.string.login_submit)
```

## 4.2 使用参数化字符串

不要直接拼接可能被翻译的句子。

```xml
<string name="welcome_user">欢迎，%1$s</string>
<string name="order_amount">订单金额：%1$.2f 元</string>
```

```kotlin
val text = context.getString(R.string.welcome_user, userName)
```

## 4.3 使用复数资源

```xml
<plurals name="message_count">
    <item quantity="one">%d 条消息</item>
    <item quantity="other">%d 条消息</item>
</plurals>
```

```kotlin
val text = resources.getQuantityString(
    R.plurals.message_count,
    count,
    count
)
```

## 4.4 多语言目录

```text
values/strings.xml          默认语言
values-en/strings.xml       英文
values-zh-rCN/strings.xml   简体中文
values-zh-rTW/strings.xml   繁体中文
```

不同语言文件应保持相同的资源名称：

```xml
<string name="login_submit">登录</string>
```

```xml
<string name="login_submit">Log in</string>
```

## 4.5 不向用户展示的字符串

以下内容更适合 Kotlin 常量，而不是 `strings.xml`：

```kotlin
object AppConstants {
    const val API_VERSION = "v1"
    const val DATABASE_NAME = "app.db"
    const val LOG_TAG = "MyApp"
    const val EXTRA_USER_ID = "extra_user_id"
}
```

## 4.6 是否需要 `AppText`

不建议仅做一层重复映射：

```kotlin
object AppText {
    val Login = R.string.login_submit
}
```

只有文本可能来自多种来源时，才适合定义抽象类型：

```kotlin
sealed interface AppText {
    data class Resource(
        @StringRes val resId: Int,
        val args: List<Any> = emptyList()
    ) : AppText

    data class Dynamic(
        val value: String
    ) : AppText
}
```

适用场景：

- ViewModel 需要表达资源文案
- 文案可能来自本地资源或服务端
- 希望 ViewModel 不直接持有 `Context`

---

# 5. 图片与图标资源

## 5.1 图片类型与推荐格式

| 资源类型 | 推荐方式 |
|---|---|
| 单色小图标 | Vector Drawable |
| 普通业务图标 | Vector Drawable 或 WebP |
| 照片、复杂插画 | WebP、PNG |
| 可拉伸背景 | Nine-patch 或 Shape Drawable |
| 启动器图标 | `mipmap-*` 自适应图标 |
| 网络图片 | URL + 图片加载库 |
| 大型动画 | Lottie、视频或专用动画方案 |
| 简单状态动画 | Animated Vector Drawable |

## 5.2 普通图片放置位置

```text
res/drawable/
```

示例：

```text
ic_action_search.xml
ic_action_delete.xml
ic_navigation_back.xml
ic_status_success.xml
illustration_order_empty.webp
bg_dialog.xml
```

启动器图标放置在：

```text
res/mipmap-*/
```

不要把普通业务图片放入 `mipmap`。

## 5.3 图片命名规范

推荐前缀：

| 前缀 | 用途 |
|---|---|
| `ic_` | 小图标 |
| `illustration_` | 插画 |
| `bg_` | 背景 |
| `logo_` | 品牌标识 |
| `avatar_` | 默认头像 |
| `divider_` | 分隔线 |
| `shape_` | Shape Drawable |
| `placeholder_` | 占位图 |

推荐：

```text
ic_action_delete
ic_navigation_back
ic_status_warning
illustration_network_error
bg_button_primary
avatar_default
```

不推荐：

```text
icon1
icon_new
icon_final
blue_icon
small_arrow
image_2026
```

命名应表达资源含义，不应表达版本、颜色或临时状态。

## 5.4 图标颜色使用 `tint`

如果同一个图标只有颜色不同，应使用同一份资源配合 `tint`：

```kotlin
Icon(
    painter = painterResource(R.drawable.ic_action_favorite),
    contentDescription = stringResource(R.string.favorite),
    tint = if (selected) {
        MaterialTheme.colorScheme.primary
    } else {
        MaterialTheme.colorScheme.onSurfaceVariant
    }
)
```

不要为颜色差异创建多份资源：

```text
ic_favorite_black
ic_favorite_white
ic_favorite_gray
ic_favorite_blue
```

只有图形结构不同时才创建不同资源：

```text
ic_favorite_outline
ic_favorite_filled
```

## 5.5 屏幕密度资源

位图可以根据密度放置：

```text
drawable-mdpi/
drawable-hdpi/
drawable-xhdpi/
drawable-xxhdpi/
drawable-xxxhdpi/
```

不过现代项目应优先考虑：

- 图标使用 Vector Drawable
- 照片和复杂图片使用 WebP
- 不需要按密度缩放的资源放入 `drawable-nodpi`

不要随意将资源放入 `drawable-nodpi`，否则系统不会根据屏幕密度缩放。

## 5.6 深色模式图片

当图片在深色模式下必须使用不同内容时，可以使用：

```text
drawable/
drawable-night/
```

两个目录中的资源保持相同名称：

```text
drawable/illustration_empty.webp
drawable-night/illustration_empty.webp
```

系统会自动选择对应版本。

仅颜色变化的单色图标，优先使用 tint，而不是单独准备夜间资源。

## 5.7 是否需要 `AppImage`

不建议仅重复映射资源 ID：

```kotlin
object AppImage {
    val Search = R.drawable.ic_action_search
}
```

当图片可能来自多种来源时，可以抽象：

```kotlin
sealed interface AppImage {
    data class Resource(@DrawableRes val resId: Int) : AppImage
    data class Remote(val url: String) : AppImage
    data class LocalFile(val path: String) : AppImage
}
```

适合头像、商品图片、服务端配置图片等场景。

---

# 6. 颜色资源

## 6.1 不要在页面中硬编码颜色

不推荐：

```kotlin
Text(
    text = "标题",
    color = Color(0xFF111827)
)
```

也不推荐页面直接大量引用具体色阶：

```kotlin
colorResource(R.color.gray_900)
```

页面应使用语义颜色：

```kotlin
MaterialTheme.colorScheme.onSurface
```

## 6.2 基础颜色与语义颜色分层

### 基础色板

```xml
<!-- res/values/colors.xml -->
<resources>
    <color name="brand_blue_600">#2563EB</color>
    <color name="brand_blue_700">#1D4ED8</color>

    <color name="neutral_50">#F9FAFB</color>
    <color name="neutral_100">#F3F4F6</color>
    <color name="neutral_600">#4B5563</color>
    <color name="neutral_900">#111827</color>

    <color name="red_600">#DC2626</color>
    <color name="green_600">#16A34A</color>
</resources>
```

### 语义颜色

语义名称表达用途：

```text
primary
onPrimary
background
surface
onSurface
textPrimary
textSecondary
divider
success
warning
error
disabled
```

## 6.3 Compose 推荐方式

```kotlin
private val LightColorScheme = lightColorScheme(
    primary = BrandBlue600,
    onPrimary = Neutral50,
    background = Neutral50,
    onBackground = Neutral900,
    surface = Color.White,
    onSurface = Neutral900,
    error = Red600
)

private val DarkColorScheme = darkColorScheme(
    primary = BrandBlue400,
    onPrimary = Neutral900,
    background = Neutral950,
    onBackground = Neutral50,
    surface = Neutral900,
    onSurface = Neutral50,
    error = Red400
)
```

页面中使用：

```kotlin
Text(
    text = stringResource(R.string.profile_title),
    color = MaterialTheme.colorScheme.onSurface
)
```

业务扩展颜色可以定义：

```kotlin
@Immutable
data class AppExtraColors(
    val success: Color,
    val warning: Color,
    val divider: Color,
    val membership: Color
)
```

## 6.4 传统 View 推荐方式

通过主题属性使用语义颜色：

```xml
<!-- attrs.xml -->
<attr name="appColorTextPrimary" format="color" />
<attr name="appColorTextSecondary" format="color" />
<attr name="appColorDivider" format="color" />
```

```xml
<!-- themes.xml -->
<style name="Theme.MyApp" parent="Theme.Material3.DayNight.NoActionBar">
    <item name="appColorTextPrimary">@color/neutral_900</item>
    <item name="appColorTextSecondary">@color/neutral_600</item>
    <item name="appColorDivider">@color/neutral_100</item>
</style>
```

```xml
<TextView
    android:textColor="?attr/appColorTextPrimary" />
```

## 6.5 状态颜色

传统 View 可在 `res/color` 中定义 ColorStateList：

```xml
<!-- res/color/button_text.xml -->
<selector xmlns:android="http://schemas.android.com/apk/res/android">
    <item
        android:state_enabled="false"
        android:color="@color/neutral_400" />

    <item
        android:state_pressed="true"
        android:color="@color/brand_blue_700" />

    <item android:color="@color/brand_blue_600" />
</selector>
```

## 6.6 是否需要 `AppColor`

不建议仅重复映射：

```kotlin
object AppColor {
    val Primary = R.color.brand_blue_600
}
```

有价值的 `AppColors` 应表达设计系统中的语义颜色，并通过 Theme 提供，而不是单纯保存色值或资源 ID。

---

# 7. 尺寸资源

## 7.1 传统 View 项目

可在 `dimens.xml` 中定义：

```xml
<resources>
    <dimen name="spacing_xs">4dp</dimen>
    <dimen name="spacing_sm">8dp</dimen>
    <dimen name="spacing_md">16dp</dimen>
    <dimen name="spacing_lg">24dp</dimen>

    <dimen name="icon_size_sm">16dp</dimen>
    <dimen name="icon_size_md">20dp</dimen>
    <dimen name="icon_size_lg">24dp</dimen>

    <dimen name="corner_radius_sm">4dp</dimen>
    <dimen name="corner_radius_md">8dp</dimen>
    <dimen name="corner_radius_lg">16dp</dimen>
</resources>
```

## 7.2 Compose 项目

可以使用统一 Token：

```kotlin
object AppSpacing {
    val Xs = 4.dp
    val Sm = 8.dp
    val Md = 16.dp
    val Lg = 24.dp
}

object AppIconSize {
    val Sm = 16.dp
    val Md = 20.dp
    val Lg = 24.dp
}
```

这类 Kotlin Token 是合理的，因为 Compose 的尺寸并不一定需要通过 Android XML 资源管理。

## 7.3 避免过度抽象

不需要为每个页面的每个距离都创建资源：

```text
login_button_top_margin
profile_card_left_padding
order_title_bottom_space
```

优先建立有限、统一的间距等级。

---

# 8. 字体资源

字体文件通常放入：

```text
res/font/
```

示例：

```text
inter_regular.ttf
inter_medium.ttf
inter_bold.ttf
```

传统 View 可定义 font-family XML，Compose 可统一定义 Typography：

```kotlin
val AppTypography = Typography(
    titleLarge = TextStyle(
        fontFamily = AppFontFamily,
        fontWeight = FontWeight.Bold,
        fontSize = 22.sp
    ),
    bodyMedium = TextStyle(
        fontFamily = AppFontFamily,
        fontWeight = FontWeight.Normal,
        fontSize = 14.sp
    )
)
```

建议：

- 字体文件名称统一使用小写下划线
- 避免在页面中直接指定字体文件
- 字号和字重通过 Typography 语义管理
- 关注字体授权和安装包体积
- 系统字体能满足需求时，优先使用系统字体

---

# 9. Shape、背景与状态资源

## 9.1 Shape Drawable

适合：

- 圆角背景
- 边框
- 纯色或渐变背景
- 分隔线
- 简单几何图形

```xml
<!-- res/drawable/bg_card.xml -->
<shape xmlns:android="http://schemas.android.com/apk/res/android">
    <solid android:color="?attr/colorSurface" />
    <corners android:radius="12dp" />
    <stroke
        android:width="1dp"
        android:color="?attr/appColorDivider" />
</shape>
```

## 9.2 Selector

适合传统 View 的：

- 按下状态
- 选中状态
- 禁用状态
- 获取焦点状态

```xml
<!-- res/drawable/bg_button.xml -->
<selector xmlns:android="http://schemas.android.com/apk/res/android">
    <item
        android:state_enabled="false"
        android:drawable="@drawable/bg_button_disabled" />

    <item
        android:state_pressed="true"
        android:drawable="@drawable/bg_button_pressed" />

    <item android:drawable="@drawable/bg_button_default" />
</selector>
```

Compose 项目通常直接在组件代码中根据状态选择颜色和样式。

---

# 10. Theme、Style 与设计系统

## 10.1 Theme

Theme 负责应用级视觉规范，例如：

- 主色和辅助色
- 背景色和表面色
- 状态栏、导航栏
- 控件默认样式
- 深色模式
- 字体与形状

## 10.2 Style

Style 适合复用传统 View 的属性组合：

```xml
<style name="Widget.MyApp.PrimaryButton">
    <item name="android:minHeight">48dp</item>
    <item name="android:textAllCaps">false</item>
    <item name="android:textAppearance">@style/TextAppearance.MyApp.Button</item>
</style>
```

## 10.3 公共 UI 组件

推荐封装：

```text
AppButton
AppIcon
AppTextField
AppToolbar
AppDialog
AppCard
AppLoading
AppEmptyState
```

组件负责统一：

- 颜色
- 间距
- 字体
- 圆角
- 状态
- 无障碍
- 深色模式表现

不建议只封装一个资源 ID 清单而不提供实际 UI 行为。

---

# 11. 布局资源

传统 View 项目的布局放入：

```text
res/layout/
```

命名建议：

```text
activity_main.xml
fragment_login.xml
dialog_confirm.xml
item_order.xml
view_empty_state.xml
include_toolbar.xml
```

Compose 项目通常不使用 XML layout，但可能仍会使用部分 XML 资源，例如启动页、Widget、通知 RemoteViews 等。

避免把业务逻辑写进资源命名中，例如：

```text
layout1.xml
new_page.xml
final_order_item.xml
```

---

# 12. Menu 资源

菜单资源放入：

```text
res/menu/
```

示例：

```text
menu_main.xml
menu_profile.xml
menu_order_actions.xml
```

菜单中的标题应引用字符串资源：

```xml
<item
    android:id="@+id/action_search"
    android:icon="@drawable/ic_action_search"
    android:title="@string/search" />
```

---

# 13. Navigation 资源

使用 Navigation Component 时，导航图放入：

```text
res/navigation/
```

示例：

```text
nav_main.xml
nav_auth.xml
nav_order.xml
```

大型项目可按业务流程拆分导航图，避免所有页面堆在一个文件中。

---

# 14. 动画资源

## 14.1 `res/anim`

适合 View Animation 和部分过渡：

```text
fade_in.xml
fade_out.xml
slide_in_right.xml
slide_out_left.xml
```

## 14.2 `res/animator`

适合属性动画：

```text
scale_up.xml
button_press.xml
```

## 14.3 动画命名

名称应表达效果和方向：

```text
fade_in
slide_in_bottom
scale_out
```

避免：

```text
animation1
new_anim
test_move
```

---

# 15. Raw 资源

`res/raw` 可放置：

- 音频
- 视频
- JSON 模板
- 证书
- 不能被 Android 其他资源目录处理的原始文件

示例：

```text
notification_sound.mp3
default_config.json
terms_template.html
```

使用：

```kotlin
resources.openRawResource(R.raw.default_config)
```

注意：

- 不要把敏感密钥放入 `raw`
- 大型文件会增加 APK/AAB 体积
- 可远程下发的文件不一定要打包进 App
- 需要保持原文件名和目录结构时，可考虑 `assets`

---

# 16. Assets 与 Raw 的区别

## `res/raw`

优点：

- 有 `R.raw.xxx` 编译期引用
- 资源名称可被检查
- 使用方式统一

限制：

- 目录不能自由嵌套
- 文件名受 Android 资源命名规则限制

## `assets`

优点：

- 可以保留目录结构
- 文件名限制较少
- 适合 HTML、模型、数据库模板等复杂文件结构

使用：

```kotlin
context.assets.open("config/default.json")
```

选择原则：

```text
需要 R 引用和简单文件管理 → res/raw
需要目录结构或原始文件名 → assets
```

---

# 17. XML 配置资源

`res/xml` 常用于：

- FileProvider 路径
- Network Security Config
- 数据备份规则
- Preference 配置
- App Widget 配置
- 快捷方式配置
- 其他 Android Framework XML 配置

示例：

```text
file_paths.xml
network_security_config.xml
backup_rules.xml
shortcuts.xml
```

---

# 18. 资源限定符与设备适配

Android 支持通过目录限定符自动选择资源。

常见限定符：

| 目录 | 用途 |
|---|---|
| `values-night` | 深色模式 |
| `values-en` | 英文 |
| `values-zh-rCN` | 简体中文 |
| `layout-land` | 横屏布局 |
| `drawable-hdpi` | hdpi 图片 |
| `values-sw600dp` | 大屏设备 |
| `drawable-v24` | Android API 24+ |
| `mipmap-anydpi-v26` | API 26+ 自适应图标 |

原则：

- 优先使用响应式布局，而不是为每个屏幕创建独立布局
- 只有确实需要时才增加限定符目录
- 默认目录必须包含可回退资源
- 同名资源在不同限定符目录中保持相同语义

---

# 19. 多模块项目的资源管理

推荐结构：

```text
app/
core/
├── designsystem/
├── common-ui/
└── common/
feature/
├── login/
├── profile/
├── order/
└── payment/
```

## 19.1 公共设计系统模块

`core:designsystem` 可放：

- 公共图标
- 基础色板
- Theme
- Typography
- Shapes
- Spacing
- 公共 UI 组件

## 19.2 业务模块

业务模块只保存自己的专属资源：

```text
feature:order
├── illustration_order_empty
├── ic_order_refund
└── order_strings.xml
```

判断资源归属的方法：

> 删除这个业务模块后，其他模块是否仍然需要该资源？

- 仍然需要：放公共模块
- 不再需要：放业务模块

## 19.3 避免资源名称冲突

多模块项目中建议增加模块语义：

```text
order_empty_title
order_refund_confirm
profile_edit_title
payment_failed_message
```

---

# 20. 业务状态与资源解耦

不建议 ViewModel 直接返回具体 UI 资源：

```kotlin
data class OrderUiState(
    @ColorRes val statusColor: Int,
    @DrawableRes val statusIcon: Int
)
```

推荐返回业务状态：

```kotlin
data class OrderUiState(
    val status: OrderStatus
)

enum class OrderStatus {
    Pending,
    Paid,
    Failed
}
```

由 UI 层映射：

```kotlin
@Composable
fun OrderStatusView(status: OrderStatus) {
    val icon = when (status) {
        OrderStatus.Pending -> R.drawable.ic_status_pending
        OrderStatus.Paid -> R.drawable.ic_status_success
        OrderStatus.Failed -> R.drawable.ic_status_error
    }

    val color = when (status) {
        OrderStatus.Pending -> AppTheme.colors.warning
        OrderStatus.Paid -> AppTheme.colors.success
        OrderStatus.Failed -> MaterialTheme.colorScheme.error
    }

    Icon(
        painter = painterResource(icon),
        contentDescription = null,
        tint = color
    )
}
```

这样更换视觉方案时，不需要修改业务层。

---

# 21. 资源更新与替换规则

## 21.1 含义不变，仅视觉调整

例如搜索图标更换风格：

```text
保持名称：ic_action_search
直接替换资源内容
```

业务代码不需要修改。

## 21.2 含义发生变化

例如一个会员图标拆成普通会员和高级会员：

```text
ic_membership_standard
ic_membership_premium
```

应新增资源，不要直接覆盖旧资源并改变其语义。

## 21.3 不使用版本后缀

不推荐：

```text
ic_search_new
ic_search_v2
ic_search_final
ic_search_final_final
```

版本历史交给 Git 管理。

---

# 22. 资源命名统一规范

## 22.1 通用要求

- 只使用小写字母、数字和下划线
- 不使用中文、空格和短横线
- 名称表达语义
- 不包含 `new`、`final`、`temp` 等临时词
- 不把颜色和尺寸写入名称，除非它们确实代表不同资源语义

## 22.2 推荐模板

```text
字符串：<模块>_<场景>_<含义>
颜色：<色系>_<色阶> 或语义名称
图标：ic_<类别>_<含义>
插画：illustration_<场景>
背景：bg_<组件或场景>
布局：<类型>_<场景>
菜单：menu_<场景>
动画：<效果>_<方向>
```

示例：

```text
login_submit
order_delete_confirm
profile_edit_title

brand_blue_600
neutral_900

ic_action_share
ic_navigation_back
ic_status_error

illustration_order_empty
bg_dialog
item_order
menu_profile
slide_in_right
```

---

# 23. 不推荐的做法

## 23.1 创建重复映射文件

```kotlin
object AppText {
    val Login = R.string.login
}

object AppImage {
    val Search = R.drawable.ic_search
}

object AppColor {
    val Primary = R.color.primary
}
```

问题：

- 增加无意义跳转
- Android Studio 已能重构和检查资源
- 容易出现映射遗漏
- 不能替代 Theme、多语言和资源限定符

## 23.2 页面硬编码

```kotlin
Text(
    text = "登录",
    color = Color(0xFF333333),
    modifier = Modifier.padding(13.dp)
)
```

应改为：

```kotlin
Text(
    text = stringResource(R.string.login_submit),
    color = MaterialTheme.colorScheme.onSurface,
    modifier = Modifier.padding(AppSpacing.Md)
)
```

## 23.3 为颜色变化复制图标

不推荐：

```text
ic_delete_red
ic_delete_gray
ic_delete_white
```

推荐：

```text
ic_action_delete + tint
```

## 23.4 所有资源都放到 `app` 模块

大型项目应按公共设计系统和业务模块划分资源归属。

## 23.5 资源名称体现临时版本

不推荐：

```text
logo_new
bg_home_final
icon_test2
```

---

# 24. 推荐的统一组件

资源管理最终应落实到组件层。

例如：

```kotlin
@Composable
fun AppIcon(
    @DrawableRes resId: Int,
    contentDescription: String?,
    modifier: Modifier = Modifier,
    tint: Color = LocalContentColor.current
) {
    Icon(
        painter = painterResource(resId),
        contentDescription = contentDescription,
        modifier = modifier,
        tint = tint
    )
}
```

```kotlin
@Composable
fun AppPrimaryButton(
    text: String,
    onClick: () -> Unit,
    enabled: Boolean = true
) {
    Button(
        onClick = onClick,
        enabled = enabled
    ) {
        Text(text = text)
    }
}
```

统一组件比单纯建立 `AppImage`、`AppColor`、`AppText` 清单更有价值，因为组件可以统一：

- 样式
- 尺寸
- 状态
- 可访问性
- 主题
- 交互行为

---

# 25. 无障碍资源要求

图标、图片和控件需要考虑无障碍描述。

Compose：

```kotlin
Icon(
    painter = painterResource(R.drawable.ic_action_delete),
    contentDescription = stringResource(R.string.delete)
)
```

纯装饰图片可设置：

```kotlin
contentDescription = null
```

要求：

- 可点击图标应有明确描述
- 不要使用文件名作为无障碍文本
- 无障碍文本同样放入 `strings.xml`
- 不仅通过颜色表达状态
- 检查文字与背景的对比度

---

# 26. 服务端动态资源

服务端可能下发：

- 图片 URL
- 动态文案
- 活动颜色
- 运营配置
- JSON 布局配置

建议：

- 网络图片由图片加载库处理缓存和占位图
- 动态文案与本地系统文案区分
- 服务端颜色必须进行格式校验并提供默认值
- 不允许服务端颜色绕过设计规范影响核心控件
- 关键系统错误文案保留本地兜底
- 服务端资源加载失败时使用本地占位资源

示例：

```kotlin
val displayColor = runCatching {
    Color(android.graphics.Color.parseColor(serverColor))
}.getOrDefault(MaterialTheme.colorScheme.primary)
```

---

# 27. 资源体积管理

建议定期检查：

- 未使用图片
- 重复图片
- 体积过大的 PNG
- 可转换为 WebP 的图片
- 路径过于复杂的 Vector Drawable
- 无用字体字重
- 重复的 Lottie 文件
- 打包进 App 但可远程加载的大型素材

可采用：

- Android Studio Resource Manager
- Lint
- APK Analyzer
- Gradle 资源压缩
- CI 自定义检查脚本

发布版本可启用资源压缩，但需要充分测试动态资源引用场景。

---

# 28. Git 与评审规范

资源文件应与代码一起进入版本控制。

资源变更的代码评审应检查：

- 名称是否符合规范
- 是否已有相同或近似资源
- 是否误删正在使用的资源
- 图标 ViewBox 是否正确
- Vector 是否包含硬编码颜色
- 图片尺寸和体积是否合理
- 是否支持深色模式
- 是否补充无障碍描述
- 是否影响多语言
- 是否放入正确模块
- 是否需要更新资源预览页

---

# 29. CI 自动检查建议

可以在持续集成中检查：

- 硬编码字符串
- 硬编码颜色
- 不规范资源名称
- 重复资源
- 未使用资源
- 缺失翻译
- 过大图片
- SVG 或 Vector 中的固定颜色
- `new`、`final`、`temp` 等资源名
- 公共模块错误依赖业务模块资源

示例禁止模式：

```text
.*_new.*
.*_final.*
.*_temp.*
.*_copy.*
```

---

# 30. 资源预览页

建议在 Debug 版本提供 Design System 或 Resource Gallery 页面，展示：

- 所有图标
- 基础色板
- 语义颜色
- 字体层级
- 间距 Token
- 按钮状态
- 输入框状态
- 卡片
- Dialog
- 空状态
- Loading
- 浅色与深色模式

资源更新后可以快速确认：

- 图标是否裁切
- 视觉尺寸是否一致
- 深色模式是否正确
- 颜色对比度是否合理
- 禁用和按下状态是否正常
- 是否出现重复资源

---

# 31. 推荐实践总结

## 文字

```text
用户可见文案 → strings.xml
程序内部常量 → Kotlin constants
动态服务端文案 → 普通 String
资源文案与动态文案统一表达 → AppText sealed interface
```

## 图片

```text
普通图标 → Vector Drawable
复杂图片 → WebP / PNG
启动器图标 → mipmap
网络图片 → URL + 图片加载库
只有颜色不同 → 同一图标 + tint
多来源图片 → AppImage sealed interface
```

## 颜色

```text
基础色值 → colors.xml 或 Compose Color 常量
页面颜色 → MaterialTheme / AppTheme 语义颜色
状态颜色 → ColorStateList 或组件状态
不要在页面硬编码色值
```

## 尺寸

```text
传统 View → dimens.xml
Compose → AppSpacing / AppIconSize 等设计 Token
```

## 样式

```text
全局视觉规范 → Theme
传统 View 属性复用 → Style
Compose → MaterialTheme + 公共组件
```

---

# 32. 推荐项目结构示例

```text
core/designsystem/
├── src/main/java/
│   ├── theme/
│   │   ├── Color.kt
│   │   ├── Theme.kt
│   │   ├── Type.kt
│   │   ├── Shape.kt
│   │   └── Spacing.kt
│   └── component/
│       ├── AppButton.kt
│       ├── AppIcon.kt
│       ├── AppTextField.kt
│       └── AppDialog.kt
│
└── src/main/res/
    ├── drawable/
    │   ├── ic_navigation_back.xml
    │   ├── ic_action_close.xml
    │   └── ic_status_error.xml
    ├── values/
    │   ├── colors.xml
    │   ├── strings.xml
    │   └── themes.xml
    └── values-night/
        └── themes.xml

feature/order/
└── src/main/res/
    ├── drawable/
    │   ├── illustration_order_empty.webp
    │   └── ic_order_refund.xml
    └── values/
        └── strings.xml
```

---

# 33. 最终原则

1. **不要用 `AppText`、`AppImage`、`AppColor` 简单重复映射 `R` 资源。**
2. **文字交给 `strings.xml`，图片交给 `drawable/mipmap`，基础颜色交给色板。**
3. **页面通过 Theme 和语义 Token 使用颜色，不直接依赖具体色值。**
4. **统一性通过公共 UI 组件实现，而不是通过资源 ID 清单实现。**
5. **只有资源来源存在多态时，才使用 `AppText`、`AppImage` 等封装类型。**
6. **资源按语义命名，版本由 Git 管理。**
7. **公共资源和业务资源按模块归属管理。**
8. **资源更新尽量保持语义名称和调用接口稳定。**
9. **多语言、深色模式、屏幕密度和无障碍应从项目初期纳入设计。**
10. **通过资源预览页、Lint、CI 和代码评审保证长期质量。**
