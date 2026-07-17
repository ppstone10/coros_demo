# 持久决策记录

> 从历史 `Codex_worklog.md` 蒸馏的永久有效决策和踩坑。每次新 AI 会话必读。
> 每次对话结束后，将本轮的持久决策和坑追加到此文件。

---

## 架构决策

| 决策 | 详情 |
|------|------|
| **三端原生 UI + KMP 共享** | Android Jetpack Compose，iOS SwiftUI，HarmonyOS ArkUI；业务逻辑在 `common` KMP 模块共享。HarmonyOS 不走 KuiklyUI 共享 UI |
| **MVVM / MVI** | `LoginAction` → `LoginStore.dispatch()` → `LoginState` + `LoginEffect`。ViewModel 只做薄适配，不做业务规则 |
| **平台边界** | UI 层只做展示和交互，不拼装业务规则。规则在 `common` 的 `LoginRules`、`LoginUseCase`、`HealthDashboardUseCase` 中 |
| **导航架构** | Android `Navigation Compose` (NavHost)，iOS `NavigationStack` + `AuthCoordinator`，HarmonyOS `router`。导航协调器监听 `LoginEffect` 做页面跳转 |
| **HarmonyOS KMP 接入** | 独立 Gradle 项目 `harmony-kmp-bridge`，使用 KuiklyBase-Kotlin + KNOI 编译 `commonMain` 为 `libkn.so`，ArkTS 通过 KNOI provider 调用 |
| **三端 UI 组件对齐** | 每端提取公共组件到 `components/`（`AuthComponents.kt` / `AuthComponents.swift` / `AuthComponents.ets`），保持签名一致 |
| **共享消息本地化边界** | `common` 的认证失败消息只输出稳定 `auth_*` 语义键；Android/iOS/HarmonyOS 在展示边界使用各自原生资源解析。保留既有跨语言 `errorMessage`/`message` 字段名，未知键原样回退 |
| **健康文案本地化边界** | `common` 健康 UI model 使用 `LocalizedTextSpec(key, arguments)`，只输出稳定 `health_*` 语义键和参数；三端在原生资源边界格式化最终文案，KNOI JSON 同步传递 key/arguments |
| **法律正文资源结构** | Demo 法律正文使用原生本地化资源保存，并以空行、`## ` 标题和 `**...**` 强调组成受限轻量结构；三端解析器恢复段落样式。英文仅为 Demo 翻译，正式发布前必须法律审校 |
| **视觉 Token 边界** | 生产页面颜色使用三端语义 `AppColors`，健康页重复字号/间距使用有限 `AppTypography`/`AppSpacing`；门禁只排除 Token 定义文件和明确不发布的 HarmonyOS 调试页，一次性几何与动画参数可保留局部值 |
| **应用语言边界** | 应用语言是平台 UI 状态，不进入 KMP；三端首次统一 `zh-Hans`，支持 `zh-Hans/en` 应用内选择并由 SharedPreferences、UserDefaults、PersistentStorage/i18n 分别持久化，不能再直接依赖设备 Locale 决定默认展示 |

## 数据契约

| 决策 | 详情 |
|------|------|
| **Protobuf 作为字段契约** | `common/.../proto/*.proto` 定义数据结构；Kotlin 用手工镜像 data class，不使用 protoc 代码生成。原型见 `docs/proto与domain model之间的关系.md` |
| **JSON 编解码集中化** | `MockAuthStoreJson` 是 common 中唯一的认证快照编解码入口，遵循 protobuf JSON 命名规则（lowerCamelCase，枚举用 proto 名称）。三端只读写字符串，不各自编解码 |
| **业务数据门禁** | 所有业务 mock 数据源通过 `AuthRepository.verifyBusinessAccess()` 检查登录态，不在 UI 层直接判断。未登录返回 `MockError.AuthRequired` |
| **Mock API** | 使用 `sealed interface MockResult<T>` + `enum class MockError` 表达成功/失败，不模拟 HTTP 响应 |
| **国家与地区值契约** | `UserProfile.countryRegion` 只持久化 `CN/US/GB/JP`；旧的中英文国家名称由 `toProfileCountryCode` 在共享层归一化，三端只在展示边界解析本地化国家名称 |

## 踩坑记录

| 坑 | 解决方案 |
|----|---------|
| ArkUI `@Builder` 函数的基本类型参数是值传递一次性快照，不建立响应式绑定 | 交互组件必须用 `@Component struct` + `@Prop`（`CorosButton`、`UnderlineInput`、`ErrorText` 等已改造） |
| SwiftUI 全局本地化函数直接读取单例 Bundle 不会自动让同级页面订阅语言变化 | 提供语言切换入口的页面及同屏导航必须通过 `@EnvironmentObject` 观察并读取 `AppLanguageStore.current`，触发局部 body 重算；不要用根视图 `.id(language)` 强制重建，否则可能丢失导航或页面状态 |
| Compose 中通过 `LocalContext.current.resources.configuration` 或 `Context.getString()` 查询资源会被新版 Lint 判为 Error | Composable 配置使用 `LocalConfiguration.current`；字符串等资源使用 `LocalResources.current`，协程副作用把 Resources 纳入 key；资源消息解析器以 `Resources` 为接收者，保证语言/Configuration 变化触发重组 |
| iOS KMP 导出：`AuthMode.Register` 在 Swift 中为 `AuthMode.register_`（尾随下划线） | 适配层需使用正确的导出名 |
| HarmonyOS KNOI `@ServiceProvider` 实例模型不确定是 singleton 还是 factory | 持久化操作前需确认 service 实例一致性；`restoreStoreSnapshot` 后需同步 adapter 状态 |
| `LoginFacade` 在 Android IDE 中显示 unused warning | 保留 `@Suppress("unused")`，它是给 iOS/HarmonyOS 用的跨语言导出 API |
| 会话 TTL 仅从 App 进入后台开始倒计时，前台期间不计时 | `AuthRepository.pauseSession()` / `resumeSession()` 实现；`SessionTtlMs = 10 * 1000`（仅 demo） |
| Xcode KMP framework 构建：`ENABLE_USER_SCRIPT_SANDBOXING` 必须为 NO | 否则 Run Script phase 被沙箱拦截 |
| Xcode `FRAMEWORK_SEARCH_PATHS` 需包含所有架构路径 | `iosSimulatorArm64`、`iosX64`、`iosArm64` 的 debug/release 路径 |
| HarmonyOS hvigor 插件版本必须与本机 DevEco Studio 版本匹配 | DevEco 自动调整后需同步更新 `oh-package.json5` |
| `iosArm64/debugFramework` 模拟器构建时找不到 | 非阻塞 warning；真机运行需补齐 device framework 或改用 XCFramework |

## 测试约定

| 约定 | 详情 |
|------|------|
| **框架** | `kotlin.test`（KMP common test），JUnit 4（Android 单元测试），AndroidX Test（插桩测试） |
| **隔离** | 测试使用 `InMemoryAuthStoreDataSource`（内存），不依赖持久化 |
| **Mock 时钟** | 通过 `LocalMockAuthRepository(..., nowEpochMs = { ... })` 注入可控时钟，测试验证码过期、会话 TTL |
| **覆盖要求** | 至少覆盖：正常流程、校验错误、重复操作、空数据、损坏数据、持久化失败、未登录拦截、会话失效拦截 |
| **测试写法** | 函数名用 BDD 风格描述行为场景，如 `registerSuccessSavesSessionAndCanBeRestored` |

## SDD 治理约定

| 约定 | 详情 |
|------|------|
| **入口分工** | `AGENTS.md` 是 AI 自动入口，`spec/sdd-workflow.md` 是完整权威规范，`spec/SESSION_START.md` 只是无法自动加载入口时的便携摘要 |
| **稳定追溯** | 新规范使用稳定 ID；开发前 TRACE 预留 `⏳`，完成后补测试、实现和实际验证证据，只有证据完整才标记 `✅` |
| **测试先行** | 行为实现前先写测试并确认红灯；无法自动化时必须记录可重复的人工验收方法和原因 |
| **记录分层** | `Codex_worklog.md` 每轮以 `# YYYY-MM-DD HH:mm — 内容概要` 记录实际写入时间和可检索摘要，再写固定四段；本文件只保存跨会话仍有效的决策、坑和可复用方法，不复制流水账 |
| **框架门禁** | 每轮结束运行 `./tools/check-sdd.sh`；该命令只校验 SDD 文档框架，不能替代业务测试或平台构建 |
| **文档分层** | `docs/` 根目录保存当前权威说明，`docs/reference/` 保存完整长期参考，`docs/archive/` 保存阶段计划与实验历史，平台细节写入对应实现目录 README；内容重复不等于没有保留价值 |
| **清理边界** | 删除文档前必须逐章节确认唯一内容已有落点；有知识价值但非当前入口的内容优先移动到 reference/archive，不用摘要替代完整原文 |
| **历史不可变** | `docs/worklog/` 只允许新增归档，既有完整日志不得修改、覆盖或删除；文档清理运行 `./tools/check-docs.sh` 校验 |
| **资源一致性门禁** | 新增或修改认证语义键时同步三端默认中文与英文资源、三端解析入口，并运行 `./tools/check-resources.sh`；健康摘要等结构化文案需另立 Spec，不扩展共享中文硬编码 |
| **全资源清单与债务棘轮** | `tools/resource-inventory.json` 是共享图片、Raw、共享文字键和硬编码债务上限的机器事实；`./tools/check-resource-maintainability.sh` 只允许文案/颜色债务下降，平台专属 AppIcon/启动资源不为目录对称跨端复制 |
| **跨端文案对齐口径** | 三端共享文字键要求语义和键名一致，但允许默认中文沿用平台既有措辞（例如账户页“我的”/“我”）；迁移资源不顺带改变产品文案，统一措辞应另行评审 |
| **HarmonyOS 资源参数类型** | ArkUI 复用组件中会承载静态资源或动态文本的展示参数优先声明为 `ResourceStr`；业务状态、用户输入和持久化值继续保持 `string`，避免为接入 `$r` 把领域数据资源化 |
| **格式化本地化文案** | 验证码发送提示、倒计时等共享语义使用同一资源键和类型化参数，但占位符遵循各平台语法（Android `%1$s`/`%1$d`、iOS `%@`/`%lld`、HarmonyOS `%s`/`%d`）；页面不再自行拼接最终句子 |
| **调试资源排除** | HarmonyOS `DebugStatePage.ets` 不进入正式 Demo，可在资源债务门禁中按唯一精确路径排除文案和颜色；其他生产页面不得复用该例外 |

## Spec 文件索引

- `spec/auth-mock-spec.md` — 认证模块规格（14 章）
- `spec/health-dashboard-cards.md` — 健康卡片规格
- `spec/common-training-requirements.md` — 公共培训要求
- `spec/TRACE.md` — 规格到代码的完整追溯映射
- `spec/sdd-workflow.md` — SDD 开发闭环、状态和完成门禁
- `spec/documentation-governance.md` — 项目文档、辅助目录和历史归档治理规则
- `spec/resource-localization.md` — 三端认证资源本地化基础、语义键边界和一致性门禁
- `spec/resource-maintainability.md` — 全模块资源清单、跨端一致性和分批债务收敛规范
- `spec/app-language-switching.md` — 应用内中英文切换、平台持久化与国家代码化规范
