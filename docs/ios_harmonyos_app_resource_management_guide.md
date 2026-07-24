# iOS 与 HarmonyOS App 资源管理与维护规范

> 适用于 iOS/iPadOS（SwiftUI、UIKit）和 HarmonyOS（ArkUI、ArkTS）项目。

## 1. 总体原则

1. 优先使用平台原生资源系统。
2. 资源按“用途和语义”命名，不按颜色、尺寸、版本或临时状态命名。
3. 页面使用语义颜色、Typography、Spacing 和公共组件，不直接散落硬编码值。
4. 公共资源放设计系统或公共模块，业务专属资源放对应业务模块。
5. 含义不变时替换资源内容并保留名称；含义改变时新增资源。
6. 多语言、深色模式、多设备和无障碍应从项目初期考虑。
7. 不创建仅重复映射平台资源的 `AppText`、`AppImage`、`AppColor`。
8. 只有封装增加了主题、多来源、类型安全或统一行为时，才增加代码层。

推荐分层：

```text
平台原始资源
    ↓
Theme / Design Tokens
    ↓
公共 UI 组件
    ↓
业务页面
```

## 2. Android、iOS、HarmonyOS 对应关系

| 类型 | Android | iOS | HarmonyOS |
|---|---|---|---|
| 文字 | `strings.xml` | `.xcstrings` String Catalog | `element/string.json` |
| 复数 | `plurals` | String Catalog plural variation | `element/plural.json` |
| 图片 | `drawable` | `.xcassets` Asset Catalog | `media` |
| 颜色 | `colors.xml` + Theme | Named Color + Theme | `element/color.json` |
| 尺寸 | `dimens.xml` | Swift Design Tokens | `element/float.json` |
| 字体 | `font` | Bundle Font + Typography | 系统字体或 `rawfile` |
| 原始文件 | `raw` / `assets` | App Bundle | `rawfile` |
| 多语言 | `values-en` | Catalog Localization | `en_US`、`zh_CN` |
| 深色模式 | `values-night` | Asset Appearance | `dark` 限定目录 |

# 第一部分：iOS

## 3. iOS 推荐结构

```text
App/
├── Resources/
│   ├── Assets.xcassets
│   ├── Localization/
│   │   ├── Common.xcstrings
│   │   ├── Auth.xcstrings
│   │   └── Order.xcstrings
│   ├── Fonts/
│   ├── Audio/
│   ├── Video/
│   ├── JSON/
│   └── HTML/
├── DesignSystem/
│   ├── Theme/
│   └── Components/
└── Features/
    ├── Auth/
    ├── Profile/
    └── Order/
```

## 4. iOS 文字资源

用户可见文字使用 String Catalog：

```text
Localizable.xcstrings
```

适用于页面标题、按钮、提示、错误、空状态、通知、无障碍文本、参数化文本和复数。

SwiftUI：

```swift
Text("login.title")

Button("login.submit") {
    // Action
}
```

UIKit：

```swift
titleLabel.text = String(localized: "login.title")
```

推荐 Key：

```text
common.confirm
common.cancel
login.title
login.submit
login.password.placeholder
order.empty.title
order.delete.confirm
```

不推荐：

```text
title
button
message
text1
login_new
```

参数化句子不要直接拼接：

```swift
// 不推荐
let text = "欢迎，" + userName
```

应在 String Catalog 中配置完整句子和参数。数量文案使用 plural variation，让系统处理不同语言的复数规则。

小项目可以使用一个 `Localizable.xcstrings`；中大型项目可按领域拆分为 `Common`、`Auth`、`Order` 等，但不要为每个页面单独建文件。

不向用户展示的内容放代码常量：

```swift
enum AppConstants {
    static let apiVersion = "v1"
    static let databaseName = "app.sqlite"
    static let userIdKey = "user_id"
}
```

## 5. iOS 图片和图标

图片、颜色、App 图标优先放入：

```text
Assets.xcassets
```

示例：

```text
AppIcon
AccentColor
iconActionSearch
iconActionDelete
iconNavigationBack
iconStatusSuccess
illustrationOrderEmpty
avatarDefault
```

使用：

```swift
Image("iconActionSearch")
```

```swift
UIImage(named: "iconActionSearch")
```

### 类型选择

| 场景 | 推荐 |
|---|---|
| 通用系统图标 | SF Symbols |
| 单色业务图标 | SVG 或 PDF Vector Asset |
| 多色图标 | SVG、PDF 或 PNG |
| 照片、复杂插画 | HEIF、JPEG、PNG |
| 网络图片 | URL + 缓存和占位 |
| App 图标 | AppIcon Asset |

通用图标优先使用 SF Symbols：

```swift
Image(systemName: "magnifyingglass")
Image(systemName: "trash")
Image(systemName: "chevron.left")
```

图片按语义命名：

```text
iconActionSearch
iconNavigationBack
iconStatusWarning
illustrationNetworkError
backgroundMembershipCard
```

不要使用：

```text
icon1
searchNew
searchFinal
blueArrow
image_2026
```

仅颜色不同的图标不要复制资源，应使用模板图片和 tint：

```swift
Image("iconActionFavorite")
    .renderingMode(.template)
    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
```

只有形状不同时才创建：

```text
iconFavoriteOutline
iconFavoriteFilled
```

Asset Catalog 可管理 Light、Dark、设备和本地化变体。单色图标优先 tint，图片中尽量不要嵌入文字。

## 6. iOS 颜色

推荐在 Asset Catalog 中创建 Named Color：

```text
brandBlue600
neutral900

textPrimary
textSecondary
surfacePrimary
backgroundPrimary
borderDefault
statusSuccess
statusWarning
statusError
```

基础色表达色值，语义色表达用途。页面优先使用语义色：

```swift
Text("profile.title")
    .foregroundStyle(Color("textPrimary"))
```

Color Set 中配置 Any 和 Dark Appearance，页面始终引用相同名称：

```swift
Color("surfacePrimary")
```

能满足需求时优先使用系统语义色：

```swift
Color.primary
Color.secondary
Color.accentColor
Color(uiColor: .systemBackground)
Color(uiColor: .separator)
```

不建议仅做重复映射：

```swift
enum AppColor {
    static let textPrimary = Color("textPrimary")
}
```

只有需要多品牌 Theme、统一 SwiftUI/UIKit、皮肤切换或完整设计系统时，才建立 `AppTheme`。

## 7. iOS 尺寸与圆角

iOS 通常使用 Swift Design Tokens：

```swift
enum AppSpacing {
    static let xSmall: CGFloat = 4
    static let small: CGFloat = 8
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
}

enum AppCornerRadius {
    static let small: CGFloat = 6
    static let medium: CGFloat = 12
    static let large: CGFloat = 20
}

enum AppIconSize {
    static let small: CGFloat = 16
    static let medium: CGFloat = 20
    static let large: CGFloat = 24
}
```

使用有限等级，不要为每个页面的每个边距创建常量。

## 8. iOS 字体

优先使用系统字体：

```swift
Font.body
Font.headline
Font.title
```

UIKit：

```swift
UIFont.preferredFont(forTextStyle: .body)
```

自定义字体作为 Bundle Resource 加入 Target：

```text
Resources/Fonts/
├── BrandSans-Regular.ttf
├── BrandSans-Medium.ttf
└── BrandSans-Bold.ttf
```

使用：

```swift
Font.custom("BrandSans-Regular", size: 16, relativeTo: .body)
```

注意字体内部名称、商业授权、Dynamic Type 和包体积。页面使用语义 Typography，而不是直接写字体文件名。

## 9. iOS 原始资源和 Bundle

以下文件通常放入 App Bundle：

- JSON
- HTML
- 音频
- 视频
- 数据库模板
- 证书
- 离线内容
- Core ML 模型

读取：

```swift
guard let url = Bundle.main.url(
    forResource: "default_config",
    withExtension: "json"
) else {
    return
}

let data = try Data(contentsOf: url)
```

要求：

- 不把密钥打包进 Bundle
- 大文件评估远程下载
- 解析失败提供兜底
- 配置进行结构校验
- 文件名保持稳定语义

## 10. iOS 多 Target 和 Swift Package

App、Widget、Extension、Framework 和 Swift Package 的资源归属必须明确。

常见问题：

- 资源没有加入正确 Target Membership
- Extension 引用了主 App 独有资源
- Swift Package 错误使用 `Bundle.main`
- 多 Bundle 中存在同名资源

Swift Package 资源使用：

```swift
Bundle.module
```

示例：

```swift
Image("iconPackageFeature", bundle: .module)
```

公共设计资源放 DesignSystem Package，业务资源跟随 Feature Package，App 独有资源留在 App Target。

## 11. iOS 的 AppText、AppImage、AppColor

不建议只复制名称：

```swift
enum AppText {
    static let loginTitle = "login.title"
}

enum AppImage {
    static let search = "iconActionSearch"
}
```

有价值的抽象包括：

```swift
enum AppText {
    case localized(LocalizedStringKey)
    case dynamic(String)
}
```

```swift
enum AppImage {
    case asset(String)
    case system(String)
    case remote(URL)
    case data(Data)
}
```

判断标准：

> 封装是否增加了多来源、主题、类型安全或统一行为？没有则不需要。

# 第二部分：HarmonyOS

## 12. HarmonyOS 推荐结构

```text
entry/src/main/
├── ets/
│   ├── pages/
│   ├── features/
│   └── designsystem/
└── resources/
    ├── base/
    │   ├── element/
    │   │   ├── string.json
    │   │   ├── plural.json
    │   │   ├── color.json
    │   │   └── float.json
    │   ├── media/
    │   └── profile/
    ├── dark/
    │   └── element/color.json
    ├── en_US/
    │   └── element/
    ├── zh_CN/
    │   └── element/
    └── rawfile/
```

核心访问方式：

```text
$r('app.type.name')
$rawfile('fileName')
```

## 13. HarmonyOS 文字

用户可见文字放入：

```text
entry/src/main/resources/base/element/string.json
```

示例：

```json
{
  "string": [
    {
      "name": "common_confirm",
      "value": "确定"
    },
    {
      "name": "login_title",
      "value": "账号登录"
    },
    {
      "name": "login_submit",
      "value": "登录"
    }
  ]
}
```

使用：

```typescript
Text($r('app.string.login_title'))
Button($r('app.string.login_submit'))
```

推荐命名：

```text
common_confirm
login_title
login_password_placeholder
order_empty_title
order_delete_confirm
```

数量文案放入 `plural.json`，不要只在代码中判断单复数。

多语言：

```text
resources/base/element/string.json
resources/zh_CN/element/string.json
resources/zh_TW/element/string.json
resources/en_US/element/string.json
```

各语言文件保持相同资源名称，只修改值。`base` 提供完整回退资源。

## 14. HarmonyOS 图片和图标

图片和图标通常放在：

```text
entry/src/main/resources/base/media/
```

示例：

```text
ic_action_search.svg
ic_action_delete.svg
ic_navigation_back.svg
ic_status_success.svg
illustration_order_empty.webp
avatar_default.png
```

使用：

```typescript
Image($r('app.media.ic_action_search'))
```

推荐：

| 场景 | 格式 |
|---|---|
| 单色图标 | SVG |
| 业务图标 | SVG 或 WebP |
| 照片、复杂插画 | WebP、JPEG、PNG |
| 网络图片 | URL + 缓存、占位和失败处理 |

命名：

```text
ic_action_search
ic_navigation_back
ic_status_warning
illustration_network_error
avatar_default
bg_membership_card
```

不要使用 `icon1`、`new_search`、`final_icon`、`blue_arrow`。

仅颜色不同不复制图标，应通过组件颜色能力处理：

```typescript
Image($r('app.media.ic_action_delete'))
  .fillColor($r('app.color.status_error'))
```

只有图形结构不同时才创建不同资源。

## 15. HarmonyOS 颜色

颜色放入：

```text
entry/src/main/resources/base/element/color.json
```

示例：

```json
{
  "color": [
    {
      "name": "brand_primary",
      "value": "#0A59F7"
    },
    {
      "name": "text_primary",
      "value": "#181818"
    },
    {
      "name": "status_error",
      "value": "#D94838"
    }
  ]
}
```

使用：

```typescript
Text($r('app.string.login_title'))
  .fontColor($r('app.color.text_primary'))
```

基础色：

```text
brand_blue_600
neutral_900
red_600
```

语义色：

```text
color_primary
background_primary
surface_primary
text_primary
text_secondary
border_default
status_success
status_warning
status_error
```

页面优先使用语义色，不直接散落 `#RRGGBB`。

深色模式：

```text
resources/base/element/color.json
resources/dark/element/color.json
```

两个文件保持相同资源名称，不同色值。页面只引用：

```typescript
$r('app.color.text_primary')
```

## 16. HarmonyOS 尺寸

常用尺寸放入：

```text
entry/src/main/resources/base/element/float.json
```

推荐：

```text
spacing_xs
spacing_sm
spacing_md
spacing_lg

icon_size_sm
icon_size_md
icon_size_lg

radius_sm
radius_md
radius_lg
```

使用：

```typescript
.padding($r('app.float.spacing_md'))
```

只管理重复使用的设计 Token，不要为每个页面每个距离创建资源。

## 17. HarmonyOS profile 与 rawfile

`profile` 适合平台或功能使用的结构化配置：

```text
resources/base/profile/
```

`rawfile` 适合保持原始格式的文件：

```text
resources/rawfile/
├── config/
├── audio/
├── video/
├── html/
├── fonts/
└── models/
```

使用：

```typescript
$rawfile('default_config.json')
```

适合 JSON、HTML、音视频、字体、3D 模型和离线数据。部分场景通过 `ResourceManager` 读取。

要求：

- 不存放密钥
- 大文件评估远程下载
- JSON 做类型和结构校验
- 加载失败提供兜底
- 可结构化的文字、颜色和尺寸不要放入 rawfile

## 18. HarmonyOS 字体

优先使用系统字体。自定义字体仅用于品牌或特殊展示，并注意：

- 字体授权
- 字符覆盖范围
- 包体积
- 只打包实际使用的字重
- 普通正文优先系统字体
- 建立语义 Typography
- 不在页面散落字体文件名

## 19. HarmonyOS 资源限定词

资源系统可以根据配置选择资源，例如：

- 语言和地区
- 深色、浅色模式
- 屏幕密度
- 屏幕方向
- 设备类型

原则：

- `base` 提供回退资源
- 不同目录中的同名资源保持相同语义
- 不在 UI 代码中重复实现匹配逻辑
- 只有真实差异时才增加限定目录
- 优先响应式布局，资源限定作为补充
- 避免过多组合目录导致维护爆炸

## 20. HarmonyOS ResourceManager

组件能直接接受 `Resource` 时，优先直接传递：

```typescript
Text($r('app.string.login_title'))
Image($r('app.media.ic_action_search'))
```

以下场景可使用 `ResourceManager`：

- 获取实际字符串
- 格式化资源
- 获取复数资源
- 读取 rawfile
- 获取指定 Configuration 的资源
- 非 UI 层需要解析资源

业务层不要直接依赖颜色、图片资源 ID；业务层返回状态，UI 层映射资源。

## 21. HarmonyOS 多模块

公共设计系统模块放：

- 公共图标
- 语义颜色
- Theme
- Typography
- Spacing
- 公共组件资源

业务模块放：

- 业务专属字符串
- 业务插画
- 业务状态图标
- 业务配置和音视频

判断：

> 删除这个业务模块后，其他模块是否还需要该资源？

需要则放公共模块，不需要则放业务模块。

## 22. HarmonyOS 的 AppText、AppImage、AppColor

不建议：

```typescript
export class AppText {
  static LoginTitle = $r('app.string.login_title')
}
```

有价值的多来源抽象：

```typescript
export type AppText =
  | { type: 'resource', value: Resource }
  | { type: 'dynamic', value: string }
```

```typescript
export type AppImage =
  | { type: 'resource', value: Resource }
  | { type: 'remote', value: string }
  | { type: 'rawfile', value: Resource }
```

只有封装增加主题、多来源、加载、缓存、失败、占位或无障碍行为时才使用。

# 第三部分：跨平台维护

## 23. 跨平台语义映射

| 语义 | iOS | HarmonyOS |
|---|---|---|
| 登录标题 | `login.title` | `login_title` |
| 搜索图标 | `iconActionSearch` | `ic_action_search` |
| 主要文字色 | `textPrimary` | `text_primary` |
| 中等间距 | `AppSpacing.medium` | `spacing_md` |
| 网络错误插画 | `illustrationNetworkError` | `illustration_network_error` |

设计侧可维护统一 Token：

```text
color.text.primary
color.surface.primary
color.status.error
spacing.xs
spacing.sm
spacing.md
spacing.lg
icon.size.sm
icon.size.md
radius.sm
radius.md
```

各平台再转换为自身命名格式。

## 24. 更新规则

### 含义不变

例如搜索图标只修改线条：

```text
保持资源名称
直接替换内容
```

### 含义变化

例如会员拆分为普通会员和高级会员：

```text
memberStandard / memberPremium
membership_standard / membership_premium
```

应新增资源，不要改变旧资源语义。

### 禁止版本命名

```text
new
old
final
final2
copy
temp
v2
2026
```

版本历史交给 Git。

## 25. 服务端动态资源

服务端可能下发图片 URL、文案、颜色和运营配置。

建议：

1. 核心文案保留本地兜底。
2. 网络图片统一缓存、占位和失败处理。
3. 服务端颜色校验格式并提供默认值。
4. 动态资源不能绕过核心设计规范。
5. 文件大小、类型和内容都要校验。
6. 业务层表达状态，UI 层决定图片与颜色。

## 26. 业务状态与资源解耦

不推荐：

```text
订单状态 = 图片资源 + 颜色资源
```

推荐：

```text
订单状态 = Pending / Paid / Failed
```

UI 映射：

```text
Pending → 等待图标 + warning
Paid    → 成功图标 + success
Failed  → 错误图标 + error
```

这样视觉调整不会影响业务逻辑，iOS 和 HarmonyOS 也可以有不同表现。

## 27. Resource Gallery

建议在 Debug 版本建立资源预览页，展示：

- 所有图标
- 基础色和语义色
- Light / Dark
- Typography
- Spacing 和 Radius
- 按钮、输入框、Dialog
- 空状态和错误状态
- 多语言长文本
- 大字号和无障碍

资源更新后检查裁切、文字溢出、深色模式、对比度、字体缺字和状态表现。

## 28. CI 检查

建议自动检查：

- 硬编码用户文案
- 硬编码颜色
- 不规范名称
- 缺失翻译
- 重复和未使用资源
- 过大图片
- 无用字体
- 图片中包含文字
- 深色模式缺失
- 错误模块归属
- `new`、`final`、`temp` 等临时命名

## 29. 代码评审清单

- [ ] 名称是否表达语义
- [ ] 是否已有相同资源
- [ ] 是否位于正确模块
- [ ] 是否支持深色模式
- [ ] 是否需要多语言
- [ ] 是否有无障碍描述
- [ ] 是否增加明显包体
- [ ] 是否有失败兜底
- [ ] 是否保持旧资源语义
- [ ] 是否更新资源预览页
- [ ] 图标是否可以使用系统图标
- [ ] 是否仅因颜色不同而复制图片
- [ ] Light / Dark 是否都已验证
- [ ] 文本是否测试长文案和大字号

## 30. 最终推荐

### iOS

```text
文字 → String Catalog
图片、颜色、AppIcon → Asset Catalog
通用图标 → SF Symbols
尺寸、字体、圆角 → Design Tokens / AppTheme
JSON、音视频、字体、HTML → Bundle
模块资源 → 跟随 Target 或 Swift Package
统一性 → Design System Components
```

### HarmonyOS

```text
文字 → element/string.json
复数 → element/plural.json
颜色 → element/color.json
尺寸 → element/float.json
图片 → media
配置 → profile
原始文件 → rawfile
多语言和深色模式 → 限定词目录
访问 → $r(...) / $rawfile(...)
统一性 → Design System Components
```

## 31. 关于 AppText、AppImage、AppColor 的结论

不建议仅做：

```text
平台资源
    ↓
AppText / AppImage / AppColor
    ↓
页面
```

推荐：

```text
平台资源
    ↓
Theme / Design Tokens / 多来源资源类型
    ↓
公共 UI 组件
    ↓
业务页面
```

判断标准：

> 封装是否增加了实际能力，而不是只换了资源访问名称？

## 32. 官方参考资料

### Apple

- [Asset management](https://developer.apple.com/documentation/xcode/asset-management)
- [Managing assets with asset catalogs](https://developer.apple.com/documentation/xcode/managing-assets-with-asset-catalogs)
- [Adding images to your Xcode project](https://developer.apple.com/documentation/xcode/adding-images-to-your-xcode-project)
- [Localizing and varying text with a string catalog](https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog)
- [Supporting multiple languages in your app](https://developer.apple.com/documentation/xcode/supporting-multiple-languages-in-your-app)
- [Bundling resources with a Swift package](https://developer.apple.com/documentation/xcode/bundling-resources-with-a-swift-package)
- [Configuring your app icon](https://developer.apple.com/documentation/xcode/configuring-your-app-icon)

### Huawei HarmonyOS

- [资源分类与访问](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/resource-categories-and-access)
- [ResourceManager](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-resource-manager)
- [应用深浅色适配](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ui-dark-light-color-adaptation)
- [Image 组件](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-basic-components-image)

---

**一句话总结：iOS 使用 String Catalog、Asset Catalog 和 Bundle 管资源；HarmonyOS 使用 `element`、`media`、`profile`、`rawfile` 和限定词目录管资源；两端都应通过 Theme、Design Tokens 和公共组件提升一致性，而不是简单重复包装资源。**
