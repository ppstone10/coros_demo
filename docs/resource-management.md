# 三端资源管理

本文只描述当前项目实际采用的资源位置和维护流程。通用 Android、iOS、HarmonyOS 资源教程不在仓库重复保存。

## 资源分层

| 层级 | 目录 | 用途 |
|------|------|------|
| 设计/导入源 | `login_register_resources/` | 登录、注册页面的原始候选资源与来源说明 |
| 设计/导入源 | `health_dashboard_resources/` | 健康首页、卡片、状态、Tab 与 Lottie 的原始候选资源和映射 |
| Android 运行资源 | `androidApp/src/main/res/` | Android 实际打包资源 |
| iOS 运行资源 | `iosApp/iosApp/Assets.xcassets/`、`iosApp/iosApp/Resources/` | iOS Asset Catalog 与视频/Lottie 等 Bundle 资源 |
| HarmonyOS 运行资源 | `harmonyApp/entry/src/main/resources/` | `element`、`media`、`profile` 与 `rawfile` 资源 |

设计源目录用于追溯和重新导入，不参与应用构建；平台运行资源才是各端最终事实。不要因为资源已经复制到三端就删除设计源。

## 当前访问入口

- Android：文案位于 `res/values/strings.xml`；图片位于 `drawable*`；视频与 Lottie JSON 位于 `res/raw`。`AppText.kt`、`AppImages.kt`、`AppColors.kt` 只承载项目已有的语义分组，不新增纯粹重复 `R` 映射的包装。
- iOS：图片使用 `Assets.xcassets`；`home.mp4`、`watch_status.json` 和 `AppResources.swift` 位于 `Resources/`。Swift 页面通过语义名称访问资源。
- HarmonyOS：文案和颜色位于 `resources/base/element`，图片位于 `resources/base/media`，视频和 Lottie JSON 位于 `resources/rawfile`；ArkTS 统一入口为 `entry/src/main/ets/resources/AppResources.ets`。

## 命名与一致性

1. 同一语义尽量在三端使用相同基础名称，例如 `icon_calendar`、`watch_status`。
2. 文件名使用小写 snake_case，不添加 `new`、`final`、`v2` 等临时版本后缀。
3. 含义不变的视觉替换沿用名称；含义变化时创建新的语义名称并更新调用方。
4. 页面只依赖平台运行资源，不直接读取两个设计源目录。
5. 设计源中的 Android XML 只能作为视觉/状态参考，不能直接复制到 iOS 或 HarmonyOS。

## 导入流程

1. 在资源映射中确认来源、语义和使用页面。
2. 按各平台要求复制并转换格式；保留合理尺寸，避免把无用密度变体全部打包。
3. 更新平台资源入口和调用点，确保三端语义一致。
4. 对图片、视频、JSON 做存在性和格式检查。
5. 运行受影响平台构建，并人工查看正常、选中、禁用、空态和深色背景等相关状态。

## 当前源资源说明

- `health_dashboard_resources/RESOURCE_MAPPING.md` 是健康首页基础资源索引。
- `health_dashboard_resources/figma_home_progress/RESOURCE_MAPPING.md` 保存完整 Figma 画板到候选资源的映射，虽然与基础索引存在部分文件重合，但承担更细的设计追溯职责，因此保留。
- `login_register_resources/README.md` 记录登录/注册候选资源的原始相对路径。

## 评审清单

- 资源是否已进入正确的平台运行目录，而不是从设计源运行时读取。
- 三端同一语义是否使用一致名称和视觉含义。
- 用户可见文案是否进入平台本地化资源或当前统一语义入口。
- 图片是否包含不必要的重复密度、透明边缘或过大分辨率。
- Lottie JSON、视频和图片是否在实际构建产物中可读取。
- 删除资源前是否确认全部代码引用、平台变体和设计追溯价值。

