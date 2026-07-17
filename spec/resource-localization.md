# 三端资源本地化基础 Spec

## 元数据

- Spec ID 前缀：`RES-LOC`
- 状态：已采纳
- 负责人：项目维护者
- 关联需求：`docs/resource-management.md`、`docs/reference/android_app_resource_management_guide.md`、`docs/reference/ios_harmonyos_app_resource_management_guide.md`
- 最后更新：2026-07-17

## 目标

- 建立简体中文默认回退与英文翻译的三端原生文字资源基础。
- 共享认证规则只输出稳定语义键，不输出最终中文错误句子。
- 三端在展示边界把共享语义键解析为平台原生本地化文字。
- 用可执行门禁检查语言目录、认证语义键和翻译完整性，避免三端静默漂移。

## 非目标

- 本轮不迁移健康首页标题、摘要、日期、单位和复数表达；这些仍需后续独立 Spec 将共享中文 UI model 改为语义变体与结构化参数。
- 本轮不迁移所有页面静态文案，只迁移共享认证校验、认证错误和提交错误的展示链路。
- 本轮不重构颜色、Typography、Spacing、深色模式和图片密度。
- 本轮不移动或删除 `login_register_resources/`、`health_dashboard_resources/` 及现有三端图片、视频、JSON。
- 本轮不引入第三方翻译平台或运行时解析共享 YAML/JSON。

## 边界与约束

- 架构边界：`common` 决定认证错误语义；Android Compose、iOS SwiftUI、HarmonyOS ArkUI 分别解析和展示本地化资源。
- 平台边界：`commonMain` 不依赖 `R`、`LocalizedStringKey`、`Resource` 或其他平台 UI/资源类型。
- 语言边界：默认回退保持现有简体中文行为；首个新增语言为英文。未知语义键保留原值，避免错误信息静默消失。
- 安全与数据边界：继续仅使用本地 mock，不新增真实服务、账号、token、密钥或用户数据。
- 兼容性边界：保留既有 `errorMessage`、`LoginEffect.ShowMessage.message` 等跨语言字段名称，本轮只把字段载荷从最终中文改为稳定语义键，避免同时破坏 KNOI JSON 结构。
- 失败边界：任一平台缺少认证语义键、英文翻译或默认回退时资源门禁失败。

## 数据与状态

| 名称 | 类型/结构 | 来源 | 生命周期 | 约束 |
|------|-----------|------|----------|------|
| 认证消息语义键 | `auth_*` 稳定字符串 | `common` | 源码生命周期 | 只表达语义，不包含语言文本 |
| Android 文案 | `strings.xml` | Android `res` | 构建期 | 默认中文完整，`values-en` 键集合一致 |
| iOS 文案 | `Localizable.xcstrings` | iOS String Catalog | 构建期 | 每个认证键含 `zh-Hans` 与 `en` |
| HarmonyOS 文案 | `string.json` | HarmonyOS `resources` | 构建期 | `base` 与 `en_US` 键集合一致 |
| 未知消息 | 原始 `String` | 动态或迁移外代码 | 单次展示 | 解析器原样返回，不变为空字符串 |

本轮不新增持久化字段，因此不修改 `.proto`、domain 持久化模型或 JSON 存储映射。

## 行为规范

### `RES-LOC-001`：共享认证层输出稳定语义键

- Given：认证校验失败、认证仓库返回 `MockError`，或 Store 发现提交字段不完整。
- When：共享层生成 `LoginRuleCheck`、`LoginResult.Failure`、`LoginState.errorMessage` 或 `LoginEffect.ShowMessage`。
- Then：消息字段为稳定 `auth_*` 语义键，不包含最终中文展示句子。
- 异常/边界：业务错误码继续保持既有值；语义键不得作为持久化认证数据写入快照。

### `RES-LOC-002`：Android 使用原生字符串资源解析认证消息

- Given：Compose UI 收到共享认证语义键。
- When：认证错误组件或 Toast/Snackbar 展示消息。
- Then：通过 Android `R.string` 和当前 Locale 得到中文或英文，不在页面复制语义键到中文的字典。
- 异常/边界：未知键原样显示；`strings.xml` 默认目录提供完整回退。

### `RES-LOC-003`：iOS 使用 String Catalog 解析认证消息

- Given：SwiftUI 收到共享认证语义键。
- When：认证错误组件或消息提示展示内容。
- Then：通过 `Localizable.xcstrings` 按当前 Locale 解析 `zh-Hans` 或 `en`。
- 异常/边界：未知键原样显示；不为每个页面单独创建 Catalog。

### `RES-LOC-004`：HarmonyOS 使用限定词字符串资源解析认证消息

- Given：ArkUI 收到共享认证语义键。
- When：认证错误组件或 Toast 展示内容。
- Then：通过 `base/element/string.json` 或 `en_US/element/string.json` 解析资源。
- 异常/边界：`base` 提供完整中文回退，未知键原样显示。

### `RES-LOC-005`：资源一致性门禁

- Given：三端认证本地化资源或共享认证语义键发生变更。
- When：运行 `./tools/check-resources.sh`。
- Then：检查共享认证代码不再包含目标中文错误句子、23 个共享认证消息语义键三端完整、三端全部 `auth_*` 默认与英文资源集合一致。
- 异常/边界：认证页面静态资源允许复用 `auth_*` 前缀，但不要求在 `AuthMessageKeys` 或错误解析器中建立无意义映射；其三端存在性同时由 `resource-inventory.json` 管理。缺失翻译、重复键、遗漏平台入口或重新引入目标硬编码时命令非零退出。

### `RES-LOC-006`：设计源和运行资源边界保持不变

- Given：本地化迁移完成。
- When：检查设计源、平台图片、视频和 JSON。
- Then：既有文件位置和内容不因本轮文字迁移发生变化。
- 异常/边界：资源源目录仍由文档治理门禁保护。

## 测试要求

| Spec ID | 自动化测试/人工验收 | 预期结果 |
|---------|---------------------|----------|
| `RES-LOC-001` | `LoginRulesTest.validationFailuresExposeStableLocalizationKeys`、既有认证测试 | 共享失败结果返回稳定键，认证行为不回归 |
| `RES-LOC-002` | `./tools/check-resources.sh`、`./gradlew :androidApp:assembleDebug` | Android 默认/英文键完整且应用可构建 |
| `RES-LOC-003` | `./tools/check-resources.sh`、iOS simulator `xcodebuild` | String Catalog 含两种语言且应用可构建 |
| `RES-LOC-004` | `./tools/check-resources.sh`、HarmonyOS `hvigorw assembleApp` | base/en_US 键完整且应用可构建 |
| `RES-LOC-005` | 首次在实现前运行门禁红灯；实现后再次运行 | 缺失资源时失败，资源齐全时通过 |
| `RES-LOC-006` | `./tools/check-docs.sh`、`git diff --name-only` 人工核对 | 设计源和二进制资源无迁移或删除 |

应用内语言状态与切换行为已进入后续 `spec/app-language-switching.md`；长英文溢出仍需在三端运行环境人工查看，不把未执行的视觉检查记为通过。

## 验收标准

- [x] 所有规范 ID 已在 `spec/TRACE.md` 建立映射。
- [x] 资源门禁在实现前出现红灯、实现后通过。
- [x] 共享认证目标代码不再输出最终中文错误句子。
- [x] Android、iOS、HarmonyOS 都有默认中文和英文认证资源。
- [x] 相关 common 测试和可执行的平台构建通过；未执行项如实记录。
- [x] 未修改设计源和既有图片、视频、JSON。
- [x] TRACE、`Codex_worklog.md` 和必要的 `LEARNINGS.md` 已更新。

## 待人工确认

- 后续是否增加繁体中文，以及产品最终默认回退语言是否继续使用简体中文。
- 后续健康摘要迁移采用领域专用内容变体，还是统一 `messageKey + typed args` 契约。
