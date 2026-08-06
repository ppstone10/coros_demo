# 持久决策记录

> 从历史 `Codex_worklog.md` 蒸馏的永久有效决策和踩坑。每次新 AI 会话必读。
> 每次对话结束后，将本轮的持久决策和坑追加到此文件。

---

## 架构决策

| 决策 | 详情 |
|------|------|
| **三端原生 UI + KMP 共享** | Android Jetpack Compose，iOS SwiftUI，HarmonyOS ArkUI；业务逻辑在 `common` KMP 模块共享。HarmonyOS 不走 KuiklyUI 共享 UI |
| **MVVM / MVI** | `LoginAction` → `LoginStore.dispatch()` → `LoginState` + `LoginEffect`。ViewModel 只做薄适配，不做业务规则。Health 模块已在 2026-07-24 对齐为相同 MVI 模式：`HealthAction` → `HealthStore.dispatch()` → `HealthState` + `HealthEffect`，`HealthFacade` 为跨语言门面 |
| **平台边界** | UI 层只做展示和交互，不拼装业务规则。规则在 `common` 的 `LoginRules`、`LoginUseCase`、`HealthRules`、`HealthDashboardUseCase`、`HealthDashboardVisuals` 中 |
| **导航架构** | Android `Navigation Compose` (NavHost)，iOS `NavigationStack` + `AuthCoordinator`，HarmonyOS `router`。导航协调器监听 `LoginEffect` 做页面跳转 |
| **HarmonyOS KMP 接入** | 独立 Gradle 项目 `harmony-kmp-bridge`，使用 KuiklyBase-Kotlin + KNOI 编译 `commonMain` 为 `libkn.so`，ArkTS 通过 KNOI provider 调用 |
| **三端 UI 组件对齐** | 每端提取公共组件到 `components/`（`AuthComponents.kt` / `AuthComponents.swift` / `AuthComponents.ets`），保持签名一致 |
| **三端同步原则** | 所有影响 UI 结构、行为或架构模式的变更必须在三端同步实施，或在 Spec/TRACE 中明确标记单平台并跟踪为债务。Spec 不得写"三端同步"却只做一端。iOS 和 HarmonyOS 的视觉拆分参照 Android `HLTH-UI-ARCH-001` 模式 |
| **共享消息本地化边界** | `common` 的认证失败消息只输出稳定 `auth_*` 语义键；Android/iOS/HarmonyOS 在展示边界使用各自原生资源解析。保留既有跨语言 `errorMessage`/`message` 字段名，未知键原样回退 |
| **健康文案本地化边界** | `common` 健康 UI model 使用 `LocalizedTextSpec(key, arguments)`，只输出稳定 `health_*` 语义键和参数；三端在原生资源边界格式化最终文案，KNOI JSON 同步传递 key/arguments |
| **法律正文资源结构** | Demo 法律正文使用原生本地化资源保存，并以空行、`## ` 标题和 `**...**` 强调组成受限轻量结构；三端解析器恢复段落样式。英文仅为 Demo 翻译，正式发布前必须法律审校 |
| **视觉 Token 边界** | 生产页面颜色使用三端语义 `AppColors`，健康页重复字号/间距使用有限 `AppTypography`/`AppSpacing`；门禁只排除 Token 定义文件和明确不发布的 HarmonyOS 调试页，一次性几何与动画参数可保留局部值 |
| **应用语言边界** | 应用语言是平台 UI 状态，不进入 KMP；三端首次统一 `zh-Hans`，支持 `zh-Hans/en` 应用内选择并由 SharedPreferences、UserDefaults、PersistentStorage/i18n 分别持久化，不能再直接依赖设备 Locale 决定默认展示 |
| **三端 Preview 数据边界** | Preview 的确定性业务场景定义在 `commonMain`，不包含平台 UI 类型或副作用；Android 直接消费共享模型，iOS 经 Kotlin/Native typed model 进入 Swift 展示适配器，HarmonyOS 经 KNOI JSON 进入 ArkTS 运行时同款 DTO 映射。Preview 宿主缺少 native service 时应安全退化。 |
| **Mock 服务器 HTTP 边界** | 数据权威源可由本仓库 `mock-server/` 提供（见 `spec/mock-server-api-spec.md`）；HTTP 请求只位于三端平台层远程数据源（HarmonyOS 走 ArkTS 侧 `ohos.net.http` 并复用既有 KNOI `restoreStoreSnapshot/restoreHealthSnapshot`、`exportStoreSnapshot/exportHealthSnapshot` 入口），`commonMain` 不放网络客户端且保持同步数据源接口不变；HTTP 状态码在平台层映射到既有 `MockError` 语义，本地持久化降级为缓存兜底。 |
| **Mock 服务器技术栈** | `mock-server/` 采用 Node.js + Express，进程内内存 + `data/mock-server-store.json` 落盘（gitignore）；密码哈希沿用 `mock:<reversed>:<len>` 约定、账号/验证码/区域种子与 `LocalMockAuthRepository` 一致；错误响应统一 `{ error: { code, message } }`，HTTP 状态码沿用 proto 错误名。契约测试用 `node --test` + 全局 fetch 启动临时端口，`setPersistEnabled(false)` 保证 hermetic 不写盘。 |
| **Android 远程数据源模式** | HTTP 客户端不引入第三方依赖（`java.net.HttpURLConnection` 单线程 executor + 超时，线程 daemon）；认证 `RemoteAuthRepository` 实现 `AuthRepository`，逐接口 HTTP + 本地 `AuthStoreDataSource` 缓存会话/验证码，`AuthJson.parseObjectArray` 直接解析响应 body（不要对 `optionalArray` 返回内容再包裹 JSON）；健康 `RemoteHealthDashboardStateDataSource` 实现 `HealthDashboardStateDataSource`，GET/PUT 整份快照并以本地数据源作缓存兜底；`MockErrorMessage.toMockError()` 复用服务端错误码 → `MockError` 映射。 |
| **iOS 远程数据源模式** | Kotlin/Native 直接调 `NSURLSession` cinterop 不可行（`NSMutableURLRequest.HTTPMethod`/`HTTPBody` 等属性名解析不稳定），iOS HTTP 必须由 Swift 实现并通过闭包注入：`iosMain` 定义 `IosHttpTransport` 函数类型与 `IosRemoteAuthRepository`/`IosRemoteHealthDashboardStateDataSource`（复用 common JSON codec），Swift `SharedLoginAdapter` 用 `URLSession` + `DispatchSemaphore` 构造 transport 并注入，符合既有 `loadJson/saveJson` 注入模式。Kotlin `object` 在 Swift 中用 `Xxx.shared` 引用。 |
| **HarmonyOS 快照同步模式** | HarmonyOS 不走 KMP 桥发 HTTP：ArkTS 用 `@ohos.net.http` 请求 `/api/sync/auth`（按 userId）与 `/api/sync/health`（整集合），拿到 JSON 后经既有 `restoreStoreSnapshot`/`restoreHealthSnapshot` 喂给 KMP，保存时用 `exportStoreSnapshot`/`exportHealthSnapshot` 取 JSON 再 PUT；启动拉取失败不阻断（沿用本地 prefs 缓存），保存后异步推送失败也保留本地。`module.json5` 需 `ohos.permission.INTERNET`。 |
| **头像跨设备内容契约** | 三端头像 `avatarUri` 统一保存 base64 `data:image/...;base64,...` 真实内容（可经 mock server 跨设备传输），展示端解码渲染；旧格式（Android 私有文件路径、iOS UserDefaults key）在展示端回退兼容。Android 用 `BitmapFactory` 解码、iOS 用 `Data(base64Encoded:)`、Harmony 用 `@ohos.multimedia.image` `ImageSource.createPixelMap`。 |
| **头像必须缩放 + 统一 JPEG** | 头像不能把原图原始字节直接 base64（相册原图可达数百 KB~MB，且 mime 与实际格式不符——PNG 魔数 `iVBORw0KGgo` 却标 `image/jpeg`）。三端统一先解码→缩放至 512px 内→JPEG 85 重编码→base64（Android `scaleToAvatar`、iOS `UIGraphicsImageRenderer`、Harmony `createImageSource`+`ImagePacker.packing`）；展示端按内容而非 mime 解码。 |
| **头像最终方案：mock server 文件存储** | 头像不应塞进 store JSON。mock server 提供 `GET/PUT/DELETE /api/avatar/:userId` 二进制文件落盘 `data/avatars/{userId}.jpg`（express.raw 处理 binary body，注销账号级联删除）；`avatarUri` 存相对路径 `/api/avatar/{userId}`，三端用各自 base URL 拼 URL 显示（Android `getBinary`+解码、iOS URLSession+`image(at:)`、Harmony `Image(baseUrl+path)`）。Harmony 不做不可验证的 image 重编码，直接上传原始字节即可。 |
| **服务器 buildUserId 与客户端一致性** | mock server 的 `buildUserId` 必须复刻 common `LocalMockAuthRepository` 的 Int32 环绕算法（`hash = Math.imul(hash,31)+code|0`），否则 JS 浮点溢出产生科学计数法（`mock-user-4.09e+35`）导致按 userId 查询/隔离失效。 |
| **快照同步 upsert 语义** | `/api/sync/auth` 提交整份 store 文档时必须遍历 `accounts` 逐条 upsert（存在更新、缺失新增），不能只取 `accounts[0]`，否则新注册账号在数组非首位时静默丢失；会话按 `currentSession.userId` 匹配且 `isValid` 才保存。 |
| **快照同步按用户合并** | 多端共用服务器时，HarmonyOS 快照同步端点（`PUT /api/sync/health`、`PUT /api/sync/auth`）必须**按 userId 合并而非整体替换**：健康快照逐条 upsert（保留其他用户），auth 只更新当前会话用户账号/会话（不遍历覆盖账号库）。客户端 `syncToServer` 只提交当前 userId 数据；`syncFromServer` 未登录跳过 auth 拉取、服务器无该用户时保留本地登录态。登录成功后需主动 `syncFromServer` 才能看到其他端写入的数据。 |
| **mock server 数据按端口隔离** | mock server 持久化文件必须按实例隔离（`data/mock-server-store-{PORT}.json`，`DATA_FILE` 可覆盖），否则同机多实例（不同端口）共享一个文件会互相覆盖；测试必须用独立测试文件名且 `setPersistEnabled(false)`，绝不触碰运行时实例数据。清理 `data/` 会删除用户运行时数据，验证时不得 `rm -rf data`。 |
| **mock server 会话按 userId 隔离 + 单设备顶号** | mock server 会话必须是 per-account 集合（`sessions`），不能是全局单例，否则多账号并存时后登录顶掉先登录（即使不同账号）、登出会清掉其他账号会话。单账号单设备用"微信顶号 + 二次确认"：非 `force` 登录遇有效异地会话返回 409 `SESSION_ACTIVE_ELSEWHERE`（带 `activeDevice`），确认后以 `force: true` 重发顶号，被顶设备后续请求返回 401 `SESSION_EXPIRED_ELSEWHERE`；被顶只在"下次请求"时被发现（mock 无推送）。设备身份由客户端持久化 `deviceId` 标识，未携带时服务端默认 `device-default`（向后兼容降级）。 |
| **mock server 数据接口必须校验会话** | 健康/头像/sync 接口若不校验会话，userId 是确定性哈希可被预测 → 越权读写。`GET/PUT /api/health/:userId`、`PUT/DELETE /api/avatar/:userId`、`GET/PUT /api/sync/*` 均需本人有效会话（设备不匹配或失效返回 401）；`GET /api/avatar/:userId` 因原生图片加载器无法携带设备标识，仅校验会话有效性。 |
| **mock server 存储拆分 + 原子落盘** | 数据按端口目录 `data/{PORT}/accounts.json`（accounts+sessions+verifyCodes）+ `data/{PORT}/health/{userId}.json`（每账号一文件，缺失=空快照）+ `data/{PORT}/avatars/`；旧单文件 `mock-server-store-{PORT}.json` 启动时一次性迁移后删除。所有写操作"临时文件 + rename"原子落盘（`atomicWrite/atomicWriteBuffer`），崩溃不产生半写文件；测试用 `setDataRoot(临时目录)+configureDataDir+setPersistEnabled(false)` 保持 hermetic。 |
| **鸿蒙快照同步模型成因** | 鸿蒙不能像 Android/iOS 一样在平台层实现逐接口 `AuthRepository`：KNOI 桥是同步调用、`ohos_arm64` 无法编译 ktor 等网络库，HTTP 只能在 ArkTS 侧（`ohos.net.http`）发起，再用 KNOI snapshot 入口灌回 KMP。因此鸿蒙天然是"快照同步"模型，必须靠服务器端按用户合并保证多端不互相覆盖。 |
| **远端会话 TTL 需注入时钟** | Android/iOS 远端 `AuthRepository` 的本地 TTL（`pauseSession`/`restoreSessionOnColdStart`）若 `nowEpochMs` 默认 `{ 0L }` 会永不失效；构造时必须注入真实时钟（Android `System.currentTimeMillis()`、iOS 经 `syncClock()`→`setCurrentTimeEpochMs`）。Harmony 快照同步时若本地会话已被 TTL 清除，不得用服务器持久会话"复活"登录态（本地为登录态权威）。 |
| **ArkUI ForEach key 与值刷新** | 仅把 `field.id` 作为 `ForEach` key 时，Choice 选中值变化（数组元素替换）不会触发 `@Builder` 重执行，界面显示旧值；非输入型行（Choice）可在 key 中带上选中值（`id:value`）强制重建刷新，TextInput 等输入型必须保持稳定 id 防止焦点丢失。 |

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
| Compose 调用 `stringResource(id, *emptyArray())` 仍会选择格式化重载，资源中的裸 `%` 会触发 `UnknownFormatConversionException` | 本地化解析器必须按参数是否为空分支：无参数调用 `Resources.getString(id)`，仅非空参数调用格式化重载；百分比单位资源保持字面量 `%` |
| Compose `LaunchedEffect` 以刷新布尔值为 key，并在 effect 内切换该值后立即执行复位动画，可能因重组取消自身协程而停在复位中间 | 刷新收尾必须由稳定生命周期协程托管，或把状态切换后的有限复位段放入 `NonCancellable`；仍需保证离开页面前的长等待可以正常取消 |
| Compose 对承载图标和文字的父 `Row` 使用 `graphicsLayer.rotationZ` 会让整组内容旋转，横排文字在拖动中变成竖排 | 父层只负责整体位移、透明度和轻微缩放；旋转反馈必须下放到图标子节点，并限制角度，文字布局始终保持水平 |
| Compose 覆盖提示即使已组合也可能因 `zIndex` 低于带不透明背景的固定 Hero 而在拖动阶段完全不可见；线性 alpha 在高密度屏幕的小幅拉动下也可能过暗 | 所有可见刷新阶段统一高于 Hero，并将提示文案映射和层级提取为可测试纯函数；拖动提示应在阈值前较早完成淡入，不能只验证松手后的刷新态 |
| 下拉提示需要在拖动、达阈值、刷新和复位全生命周期与主体严格等距；刷新态独立停靠或复位额外退出位移都会造成松手后距离断开 | 所有阶段统一以 `bodyTop - indicatorHeight - fixedGap` 计算提示位置，不使用任何阶段专属停靠插值；复位只随主体移动并按进度淡出 |
| iOS 用原生 `UIScrollView` 手势读取下拉距离后再给内容施加自定义 offset，如果保留系统 bounce，会同时产生原生橡皮筋位移和自定义位移 | 自定义下拉期间由观察器关闭该 ScrollView 的 `bounces`，仅保留原生 pan 识别和滚动；观察器销毁时恢复原值 |
| HarmonyOS API 12 的 `Refresh` 已提供状态、阈值、阻尼和 offset 回调，但可配置最大下拉距离的 `maxPullDownDistance` 从 API 20 才可用 | API 12 项目使用原生 Refresh 边界，不调用高版本 API；覆盖提示必须消费未截断的真实 `onOffsetChange`，否则极限下拉时提示会与主体失去固定间距 |
| HarmonyOS API 12 中废弃的 `RefreshOptions.offset` 不再可靠控制刷新停留位置；直接把 `.refreshOffset` 用作 80 阈值又会让主体停留参数失效 | `.refreshOffset` 专门绑定 `PULL_REFRESH_HOLD_OFFSET`，关闭原生 `pullToRefresh`；通过状态回调锁定手势结束点，并用真实 offset 独立判断 80 阈值后程序化刷新 |
| Compose 本地化层用 `createConfigurationContext` 覆盖 `LocalContext` 后，`rememberLauncherForActivityResult` 找不到 Activity owner 并在组合时崩溃 | 覆盖前读取 `LocalActivityResultRegistryOwner.current`，覆盖 Context 后在子树显式继续提供；预览等 owner 为空的宿主保持可组合。仅升级 `activity-compose` 不能修复，因为当前实现仍从 `LocalContext` 查找该 owner |
| iOS KMP 导出：`AuthMode.Register` 在 Swift 中为 `AuthMode.register_`（尾随下划线） | 适配层需使用正确的导出名 |
| HarmonyOS KNOI `@ServiceProvider` 实例模型不确定是 singleton 还是 factory | 持久化操作前需确认 service 实例一致性；`restoreStoreSnapshot` 后需同步 adapter 状态 |
| ArkUI 不能直接 Preview 带外部状态装饰器的子组件 | 含 `@Consume`、`@Link`、`@ObjectLink` 或 `@Prop` 的子组件移除直接 `@Preview`；由不含这些外部入参的父 `@Component` Preview Host 持有完整 `@State`/常量，再传给子组件。只通过 ArkTS 构建不足以发现 DevEco 设计态限制，需专项静态门禁。 |
| ArkUI Preview 会解析完整静态 import 图 | 即使页面未调用 native，只要 `Page → ViewModelProvider → Adapter → knoi/provider` 可达，Previewer 仍会在模块加载阶段因缺少 native `setup` 导出而失败，try/catch 无效。页面必须只 import 纯 ArkTS 契约；生成 service 和 KNOI delegate 仅由 `EntryAbility` 运行时组合根安装，ViewModel provider 禁止模块顶层立即实例化。 |
| 健康 Visual 叶组件需要专项 Preview | Android 每个 `*Visual.kt` 在同文件放命名 `@Preview`，通过 `HealthPreviewFixtures` 适配器取 common 数据；HarmonyOS 的 `*VisualComp.ets` 含 `@Prop`，不得直接标 `@Preview`，由不含 KNOI/native import 的纯父 `VisualPreviewCatalog*.ets` 传入完整 ArkTS DTO。DevEco 限制单个文件最多 10 个 `@Preview`，超过必须拆分；Preview DTO 的对象数组必须显式标注 `HealthChartPointData[]` 等已知接口类型。普通平台构建通过不等于设计态通过，仍需专项静态门禁和 Previewer 人工检查。 |
| `LoginFacade` 在 Android IDE 中显示 unused warning | 保留 `@Suppress("unused")`，它是给 iOS/HarmonyOS 用的跨语言导出 API |
| 会话只保留一套冷启动 TTL，冷/暖恢复必须分离 | `pauseSession()` 在后台保存截止时间；`restoreSessionOnColdStart()` 仅冷启动校验；`resumeSessionInSameProcess()` 暖恢复不判过期并清除旧截止时间。Android 不得让独立 `LaunchedEffect` 与 `ON_START` 分别触发冷/暖恢复，否则生命周期补发可能先清除 TTL；应由单一 `ON_START` 协调器保证首次冷恢复、后续暖恢复。强杀时刻不可可靠观测，TTL 从上一次进入后台计算；`SessionTtlMs = 10 * 1000` 仅用于 Demo |
| Xcode KMP framework 构建：`ENABLE_USER_SCRIPT_SANDBOXING` 必须为 NO | 否则 Run Script phase 被沙箱拦截 |
| Xcode `FRAMEWORK_SEARCH_PATHS` 需包含所有架构路径 | `iosSimulatorArm64`、`iosX64`、`iosArm64` 的 debug/release 路径 |
| HarmonyOS hvigor 插件版本必须与本机 DevEco Studio 版本匹配 | DevEco 自动调整后需同步更新 `oh-package.json5` |
| `iosArm64/debugFramework` 模拟器构建时找不到 | 非阻塞 warning；真机运行需补齐 device framework 或改用 XCFramework |
| macOS BSD `sed` 不支持 `\b` 且 zsh 不对未加引号变量按空白切分 | 批量替换先 `for f in ${(f)VAR}` 换行拆分，替换模式用纯字符串（常量名无前缀冲突时不用 `\b`），否则 sed 会静默失败 |
| ArkTS 禁止无类型对象字面量（`arkts-no-untyped-obj-literals`） | 分组常量/配置对象必须声明 `interface` 后以类型化对象赋值；直接 `static auth = {...}` 编译失败 |
| Xcode 显式 pbxproj 新增 Swift 文件 | 非文件系统同步组时须手工登记 PBXBuildFile/PBXFileReference/分组/Sources phase 四处，且文件磁盘路径必须与分组 `path` 一致，否则 "cannot find in scope" |
| SwiftUI NavigationStack 要求单一路径类型 | 域级导航拆分只移动目的地渲染（@ViewBuilder 函数归 Health 模块），`AuthRoute` 枚举保持全局 NavigationStack 容器，避免破坏 NavigationPath |
| 平台大文件拆分的跨文件可见性 | 同一包内拆分时把被其他文件引用的 `private` 收敛为 `internal`（如 `ProfileTextRow/GenderRow/displayText/parseBirthDate`），保持对外公共 API 不变即可通过构建 |
| `MockResult` 与 `MockError` 是 auth 域错误聚合 | `MockResult.Failure` 携带 `MockError`，`MockError` 编码 `AuthMessageKeys` 且引用 `HealthMessageKeys`；把 `MockResult` 单独抽到 core 会形成 core→auth/health 反向依赖。抽取前先检查 Result 类型是否耦合域错误枚举，避免编译红灯后回退 |
| Swift 跨文件 extension 访问类私有成员受限 | 按域把 Swift 适配类拆成 `Xxx+Domain.swift` 扩展时，跨文件 extension 只能访问 `internal` 及以上成员；先盘点目标方法依赖面（如 health 方法只依赖 `healthFacade` 不含 `syncClock`），再定向放开可见性 |
| KNOI 契约稳定拆分法 | 保持 `@ServiceProvider` 类与方法签名不变，把大方法体抽到同包内部委托类（`HarmonyHealthBridge`）与序列化文件（`HarmonyHealthSnapshotJson`）；拆分前后用 `provider.ets` 的 `git diff` 验证契约零变化。避免拆成两个 ServiceProvider，那会改 provider 契约并联动 ArkTS 组合根与预览门禁 |
| common 子包重命名脚本陷阱 | ① 正则需 `re.MULTILINE` 否则 `^` 只匹配首行；② 扩展函数 `fun Receiver.name()` 的符号是 `name` 而非 receiver，否则 `fun String.jsonEscaped()` 会把 `String` 误收进符号表并产生 `import ...mock.String` 污染；③ 单词匹配自动补 import 会产生误导入（`Text(text=)` 的 `text` 误当函数），需按实际调用 `name(`/`::name` 二次判定；④ 跨包同名符号（`toDomain`/`toProtoMessage`）不能单映射，跳过自动导入并按调用方手工补齐 |
| mock server 会话全局单例导致多账号互顶 | 会话按 userId 隔离为 `sessions` 集合；登出/被顶作用域化只影响本账号；否则后登录账号顶掉先登录（即使不同账号），且登出会清掉其他账号会话 |
| 鸿蒙登录是"本地校验"，本地 store 缺账号即报"账号不存在" | 鸿蒙走 `LocalMockAuthRepository` 本地校验，`syncFromServer` 必须保证本地 store 具备服务器账号：未登录时也拉取全部账号（`GET /api/sync/auth` 无 userId，MSRV-018 登录发现例外），并用 `mergeAuthStores` 按 userId 合并而非 `restoreStoreSnapshot` 整体替换——整体替换会丢弃种子账号，导致后续登录其他服务器账号失败 |
| 被顶提示依赖"回前台/写操作"懒校验 | mock 无推送，被顶设备只能下次请求时发现：Android/iOS `resumeSessionInSameProcess`（暖恢复）也要打 `GET /api/auth/session`（抽取 `checkSessionRemotely` 助手与冷启动共用）；`LoginStore` 写路径（updateProfile/deleteCurrentAccount）遇 `SessionExpiredElsewhere` 走 `applyKicked`（清会话 + `SessionExpired` effect 跳登录页）。健康读数据源是 Boolean/缓存接口，健康写被顶单独导航暂为债务 |
| 头像 GET 必须完全忽略设备匹配，只校验会话有效 | 原生图片加载器无法携带 `X-Device-Id`，且 Android `MockServerHttpClient` 会默认带 `device-default` 头——服务端头像 GET 若做设备匹配，即使"无头才宽松"也会被默认头破坏（`req.get('x-device-id') || null` 不够彻底）。正确做法：头像 GET 恒 `sessionStatus(userId, null)`（仅会话有效）；写操作（PUT/DELETE）保持严格会话+设备校验 |
| iOS 独立 URLSession 上传必须手动带头 | `ProfileImageStore.save` 不走注入的 `IosHttpTransport`，是独立 `URLSession`，必须手动 `request.setValue(IosMockServerConfig.shared.deviceId, forHTTPHeaderField: "X-Device-Id")`，否则服务端严格校验回退 `device-default` → 401 → 上传失败不写入 |
| 健康数据源被顶检测用回调传播 | `RemoteHealthDashboardStateDataSource`/`IosRemoteHealthDashboardStateDataSource` 是 Boolean/Snapshot? 接口，无法携带错误语义；用 `onSessionKicked: (() -> Unit)?` 回调把 `SESSION_EXPIRED_ELSEWHERE` 传出去，接线到 `LoginStore.onSessionKicked()`（清会话+跳登录页）。Swift 闭包捕获 self 必须在所有存储属性初始化完成之后，否则编译报 "used before being initialized" |
| 鸿蒙登录前必须先做账号发现同步 | `KnoiLoginAdapter.submit` 开头 `await syncFromServer`，否则"登录先于启动同步完成"时本地 store 缺账号仍报"账号不存在" |
| 被顶交互用"确认弹窗"而非直接跳转 | 被顶（SESSION_EXPIRED_ELSEWHERE）先弹"仅确认按钮"弹窗（`kickedDialogShown`），确认后 `KickedDialogConfirmed`→`SessionKicked` effect 静默回登录页；不要在检测时清会话/设错误文案，否则登录页重复提示或提前导航。前台每 15s `checkSessionOnForeground` 监听，弹窗显示期间暂停 |
| 被顶检测绝不能调服务器 logout | `checkSessionRemotely` 若用 `clearSession()` 会 POST logout 清掉服务器该账号会话，把**顶号方也登出**；必须只清本地缓存（`clearLocalSessionOnly()`） |
| 鸿蒙页面 `await` 异步 dispatch 后才能消费 effect | `KnoiLoginAdapter.submit` 内 `await syncFromServer` 让异步 submit 变慢，暴露 `LoginFormPage.submitLogin` 未 await dispatch 的竞态（consumeEffect 在登录完成前调用返回 null → 不跳转）；异步 dispatch 后必须 await 再读 effect |
| 鸿蒙登录提交前绝不能重建 LoginFacade | `restoreStoreSnapshot` 会 `facade = createFacade(...)` 重建，清空已输入的账号/密码/验证码/区域 → 提交后提示"请输入账号密码"并清空字段。登录/注册前的账号发现必须用不重建的轻量桥方法（`mergeAccounts`，仅 `dataSource.replaceStore`），`restoreStoreSnapshot` 只用于启动/换号全量恢复 |
| SwiftUI `.task` 会捕获 `@Environment` 快照 | `.task` 闭包创建时把 `scenePhase` 等 `@Environment` 值捕获为常量，启动瞬间若非 `.active` 则循环内判断恒 false；前台监听不要依赖闭包内捕获的 scenePhase，改由 `.onChange(of: scenePhase)` 触发即时检查 |
| 头像展示必须本地缓存优先 | 每次切页都走网络下载会占位闪烁。显示一律先读内部目录当前头像文件（组合时同步读、未命中才下载并覆盖）；上传要异步（`Dispatchers.IO`），避免阻塞主线程导致保存按钮无响应 |
| 头像本地只存"当前账号"单文件 | 内部目录只保留一份当前账号头像（Android `AvatarStore` `files/avatar_current.jpg` / iOS `ProfileImageStore` `Documents/avatar_current.jpg`）。登录/切换账号时先清除再用服务器头像覆盖（AuthSucceeded 钩子）；信息完善页选图即上传+覆盖；信息修改页选图仅本地预览、保存时才上传+覆盖+保存资料；显示一律读该文件。切账号依赖"清除旧文件→拉新头像"，拉取期间短暂占位可接受 |
| iOS 头像视图需版本号强制刷新 | 头像相对路径 `/api/avatar/{userId}` 恒定，SwiftUI 会因 `AccountAvatar` 结构体相等而跳过 body 重渲染，`ProfileImageStore.image(at:)` 不再被调用 → 换头像后不更新。用 `@Published avatarRevision`（保存成功后 `notifyAvatarSaved()` 递增）+ `AccountAvatar.id("avatar-\(revision)")` 强制重建并重读内部目录文件 |
| HarmonyOS Preview 需 getService 兜底 | 带 `@Preview` 的页面若调用 `getService()`，native service 未安装（Previewer）时不能抛错，必须返回 no-op 实现契约的 `PreviewHarmonyService`（交互退化为空操作，UI-PREVIEW-010）；Preview 健康数据用 `preview/VisualPreviewData` 构造富数据快照，否则健康页只显示空壳 |
| ArkTS 接口新增必填字段必须同步所有对象字面量 | `LoginStatePayload` 加 `confirmForceLogin`/`kickedDialogShown` 必填字段后，`parseStatePayload` catch 兜底对象字面量缺字段 → ArkTSCheck 报 "missing the following properties"；实现接口的每个对象字面量（含兜底/测试）都要补默认值 |
| `register` 用默认 device 签发会话，客户端后续用真实 `deviceId` 登录同账号会误触 409 二次确认 | 客户端 `register` 必须携带 `deviceId`，否则新账号在真实设备首次登录就被要求"挤下线" |
| mock server 契约测试共享服务器状态，测试顺序脆弱（会话残留、种子密码被改） | 行为独立用例开头 `resetStore()` 隔离；改密/重置类用例末尾恢复种子密码；`register` 显式传 `deviceId` 与后续登录设备一致 |
| 冷启动懒校验 200 分支不得用服务器会话覆盖本地缓存 | 服务端会话 `expireAtEpochMs=0` 会冲掉 `pauseSession` 设置的本地 TTL 截止时间，导致后台挂起过期判定失效；`GET /api/auth/session` 懒校验只用于检测被顶（`SESSION_EXPIRED_ELSEWHERE`→`KickedElsewhere`）与失效，200 时保留本地会话 |
| Kotlin `object` 的 `.shared` 引用仅限 Swift 互操作 | iosMain Kotlin 内直接 `IosMockServerConfig.deviceId`；`IosMockServerConfig.shared.deviceId` 会在 `:common:check` 编译报 "Unresolved reference 'shared'" |
| 二次确认（微信顶号）跨 common 的涟漪面 | `LoginResult` 加 `SessionActiveElsewhere`、`LoginRequestDto` 加 `deviceId/force`（默认值向后兼容）、`MockError` 加两个错误码、`SessionResumeResult` 加 `KickedElsewhere`、`LoginAction/LoginState/LoginEffect` 加确认相关；`LoginStore` 的 `when` 与 `HarmonyLoginJson` 的 effect 快照必须同步补分支，否则 common 或 Harmony 桥编译失败 |

## 测试约定

| 约定 | 详情 |
|------|------|
| **框架** | `kotlin.test`（KMP common test），JUnit 4（Android 单元测试），AndroidX Test（插桩测试） |
| **隔离** | 测试使用 `InMemoryAuthStoreDataSource`（内存），不依赖持久化 |
| **Mock 时钟** | 通过 `LocalMockAuthRepository(..., nowEpochMs = { ... })` 注入可控时钟，测试验证码过期、会话 TTL |
| **覆盖要求** | 至少覆盖：正常流程、校验错误、重复操作、空数据、损坏数据、持久化失败、未登录拦截、会话失效拦截 |
| **测试写法** | 函数名用 BDD 风格描述行为场景，如 `registerSuccessSavesSessionAndCanBeRestored` |
| **SwiftUI Preview 覆盖** | 每个包含生产 `struct ...: View` 的 Swift 文件至少有一个 `#Preview`；同文件私有叶组件可由命名 Catalog 覆盖，纯滚动/手势 `UIViewRepresentable` 无独立视觉语义时由所属页面覆盖。健康视觉数据必须从 common fixture 经 Swift adapter 获取。 |

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
| **显式本地化白名单同步** | Android `healthStringResource` 与 HarmonyOS `healthResource` 是资源目录之外的第二层显式白名单；只新增 `strings.xml/string.json` 仍会回退为“数据不可用”。common 新增 `health_edit_*` 或 `health_visual_*` 后必须同时登记三端资源、Android/HarmonyOS 解析入口和 `resource-inventory.json`，由专项门禁逐键核对 |
| **HarmonyOS Resource 不可字符串插值** | `$r`/`healthResource()` 返回 `Resource` 对象，不能放入模板字符串与字段 ID 拼接，否则会显示对象文本或空白。需要组合标签时将 `Text(Resource)` 与普通字符串拆成独立节点；输入框已有值时 placeholder 不可承担常驻标签，标签必须独立显示 |
| **健康可视化契约** | 趋势、区间、指标、睡眠阶段等绘制数据由 common 以 `HealthCardVisualData` 输出，三端按 `kind` 原生绘制；UI 不随机补点，也不把整卡烘焙成图片 |
| **2031 图形分型、圆弧与心率区间** | `visual.kind` 只表达数据族，不保证同族图形相同：恢复/能力、心率/压力、静息心率/HRV 必须继续结合稳定 `HealthCardType` 选择专用绘制器。顶部卡路里弧三端统一按 0–800、135° 起始、270° 总扫角夹紧绘制，并使用等宽等高包围盒保持正圆。心率每根柱代表一个半小时的最低–最高区间，平均值是统计字段；不得从统一基线绘制或插值伪造更多时间片 |
| **健康卡片顶层样式复用边界** | 14 张健康卡片采用 12 类顶层样式：仅跑步/骑行能力共用 Ability、心率/压力共用 Trend；体力恢复、静息心率、HRV 及其余卡片均按稳定 `HealthCardType`/卡片 ID 进入独立顶层组件。可以复用文字、路径数学等叶级 helper，但不可再用通用 Gauge/Range 顶层组件按类型切换不同卡片布局。 |
| **模拟心率时间粒度与周计划交互边界** | 模拟心率原型保留连续 5 分钟样本，由 common 每 6 点聚合为半小时 min/max/四舍五入平均值，UI 只消费聚合区间且不得按索引制造振幅；当前运行时只启用正常 1、正常 2、异常，正常 3 不进入 fixture 或场景目录。周计划七日详情属于共享数据契约；三端日期子节点消费点击并只切换卡内选中日，卡片其余区域继续进入详情，旧快照缺少七日详情时补成“当前日原计划 + 其余休息日” |
| **三端健康页复合点击与头部元数据** | 右上角手表必须以平台原生的同一互斥手势入口区分短按/长按：短按切换主标签到“我”，长按只打开调试场景，禁止叠加两个会同时命中的独立手势。卡片级元数据优先进入 `CardHeader` 右侧并保持 nullable；健康快测时间缺失时不生成 `---`。HRV/静息心率范围指针与指标带在同一绘制层，三角尖端统一朝上、底边跨过横条；不能把“主体在线上方、尖端贴线”误当成跨端方向契约。HarmonyOS 两张范围卡必须复用相同纵向边界，避免一张使用绝对 `position`、另一张使用 `margin` 后出现仅接触而未重叠 |
| **体重编辑历史边界** | 体重每次确认都按发生顺序追加到共享持久化历史，允许重复值且不得排序、去重或覆盖；旧快照缺少历史字段时以当时体重补为首条，场景刷新只在存在用户历史时保留当前体重与完整历史 |
| **Figma 动效证据边界** | 当目标节点的 motion inventory 为空时，只实现静态终态并保留应用既有交互反馈，不凭视觉稿臆造时间线；新增动效需单独定义时长、缓动与 Reduce Motion 降级 |
| **健康卡片右栏安全区** | 仪表、趋势、区间、睡眠阶段和人体图统一使用显式 130/166 宽高安全区，叶节点与父卡片双重裁剪；HarmonyOS 右栏不得同时使用 `layoutWeight` 和 `width('100%')`，否则概览图会越过圆角卡片 |
| **健康卡片高度契约** | 空态必须由 common 的显式 `HealthCardStatus.Empty` 选择，iOS/HarmonyOS 适配层不得通过主值或图表是否为空猜测；公共外壳不固定整卡高度，但有数据视觉组件必须保留与 Android 内容固有尺寸等价的类型安全高度，防止 SwiftUI/ArkUI 把圆弧、指针或多行指标压缩裁断。空态不继承该安全高度；滚动方向仍禁止以 `fillMaxSize`、无尺寸 Spacer/Blank 或 weight 吸收不确定剩余空间 |
| **跨端图表状态与容器高度** | 周计划的选中日必须同时传给日期、计划内容和柱图高亮，不能让图表继续读取快照初始索引。柱高必须以实际图表容器高度计算；例如 36 高负荷图若沿用 58 高公式必然被裁。睡眠持续时长需转成显式 x/width，`layoutPriority/layoutWeight` 不能替代时间坐标。恢复状态等 UI 自生文案也必须进入三端资源目录，缺键会直接泄漏资源名 |
| **设计字体跨端一致性** | 用户提供的应用包字体可按文件哈希确认同源后分别进入 Android font、iOS UIAppFonts、HarmonyOS rawfile；中文标题保留平台字体，COROS 字体只承担数字/单位，避免缺字 |
| **卡片编辑器草稿边界** | “恢复默认”应先只重建编辑器本地草稿，用户点击保存后再写 KMP 持久化；不能用重新加载已保存快照代替恢复，否则删减顺序会原样返回 |
| **编辑器卡片元数据** | UI 根据类型 ID 重建已删除或默认卡片时，标题和图标必须来自完整稳定映射，不能用空标题占位；保存边界仍只提交类型 ID |
| **HarmonyOS 资源参数类型** | ArkUI 复用组件中会承载静态资源或动态文本的展示参数优先声明为 `ResourceStr`；业务状态、用户输入和持久化值继续保持 `string`，避免为接入 `$r` 把领域数据资源化 |
| **格式化本地化文案** | 验证码发送提示、倒计时等共享语义使用同一资源键和类型化参数，但占位符遵循各平台语法（Android `%1$s`/`%1$d`、iOS `%@`/`%lld`、HarmonyOS `%s`/`%d`）；页面不再自行拼接最终句子 |
| **调试资源排除** | HarmonyOS `DebugStatePage.ets` 不进入正式 Demo，可在资源债务门禁中按唯一精确路径排除文案和颜色；其他生产页面不得复用该例外 |
| **跨格式图像一致性** | Android WebP 与 iOS/HarmonyOS PNG 的文件 SHA 不同不代表可见图形不同；排查时应比较尺寸和解码后的可见像素，并以语义资源目录约束 UI 映射。透明像素中未预乘的 RGB 差异不影响渲染，不应为追求原始文件哈希而无意义重编码 |
| **卡片图标以类型映射** | 卡片编辑、恢复与详情页应按稳定类型 ID 获取图标，不依赖可冲突的整数索引或 default 回退；特殊首页标题图只在该渲染场景覆盖通用图标 |
| **健康快照持久化边界** | `Normal` 场景按用户只持久化 `EditableHealthData` 最小权威源字段与卡片配置，加载时由 common 重新派生 `HealthDashboardData`；固定异常/空态场景仍可持久化完整展示快照。场景选择只更新运行期待刷新状态，只有健康首页刷新成功才覆盖有效快照，失败保留旧快照。HarmonyOS 用单一 `health_json` 保存全部用户快照集合，不再维护 `_health` 与全局 `health_card_order` 双重权威状态 |
| **可编辑正常数据边界** | 正常数据编辑结果先保存为当前 `HealthStore` 的进程内草稿，首页不显示待处理提示，也不写 JSON/Proto；只有用户回到首页执行下拉刷新才提交为按用户持久化的有效源数据。默认 fixture、整套恢复、单模块恢复和持久化必须共用 `EditableHealthData` 契约；派生阈值、表单校验、睡眠连续区间、心率 288 点与压力 48 点快捷生成均只位于 common，平台只渲染 common 表单并提交原始输入 |
| **动态健康表单集合边界** | 睡眠阶段、锻炼部位等数量可变字段由 common 的 repeat group schema、`mutate` 和 `apply` 负责新增、删除、重新编号、最小/最大数量及合法选项；跨语言只传表单 JSON 和原始值。三端不得仅在本地数组增删，否则保存时会与 common 权威字段数量分叉 |
| **编辑器常驻提示契约** | 字段提示由 common 输出 `labelKey + labelArguments`，重复项使用“第 N 天/阶段/部位”等本地化参数，三端已有值时仍显示独立标签且不暴露技术字段 ID；标题栏返回与操作区使用对称固定宽度，避免长标题挤掉保存操作 |
| **跨端枚举选择器一致性** | Compose/SwiftUI/ArkUI 的原生 Picker/Select 默认外观与弹出位置差异较大；产品要求三端同效时，平台统一渲染“字段标签 + 当前值 + 下拉指示”的单行入口，并使用同尺寸、颜色、遮罩、纵向选项、当前项勾选和取消操作的自绘覆盖层。选项与当前值仍来自 common 表单，平台不得用点击轮换代替显式选择 |
| **跨端状态图标资源复用** | 下拉尖角、当前项勾选等状态图标不得混用字体字符、平台系统符号和图片；优先复用三端资源清单中已有的同语义资产，通过平台 Template/tint 统一操作色。方向变化可由同一方向资源旋转得到，例如 `right_more` 旋转 90°作为向下尖角，避免复制近义资产 |
| **动态人体图资产边界** | 设计资源中的人体图是胸部/股四头肌固定着色成品，不能直接代表动态选择。三端先以 Template 模式中和底图颜色，再按 common `health_visual_muscle_*` 指标在同一前后视图坐标系绘制动态标记并显示名称；否则切换其他部位后仍会残留默认红色误导 |
| **编辑保存反馈时序** | 数据编辑成功提示固定约 1500ms 且 latest-wins：Android 用递增事件 ID 驱动新 `LaunchedEffect`，iOS 取消旧 Task 后重计时，HarmonyOS 使用 1500ms 原生 toast；不能排队或让旧计时器清除后发提示 |
| **健康刷新失败前台状态** | “失败时保留最后有效快照”只约束持久化，不能让页面继续冒充刷新成功；跨语言 nullable/空 JSON 会丢失原因，门面需一次性暴露稳定错误名，三端用独立损坏态隐藏旧卡片，下一次成功刷新再清除 |
| **iOS 下拉刷新边界** | 当产品要求自定义下拉视觉/阈值时，不用 Preference 推测顶部，也不叠加独立 SwiftUI `DragGesture`；只给现有 `UIScrollView.panGestureRecognizer` 增加 target，在 `.began` 以真实 `contentOffset/adjustedContentInset` 锁定整次手势资格，changed/ended 沿用同一识别器 |
| **iOS Lottie 刷新同步** | SwiftUI `LottieView.playbackMode`、随机/周期 ID 重建都不能替代实际播放验证；需要严格同步时用 `UIViewRepresentable` 持有 `LottieAnimationView`，刷新开始显式 `stop → progress 0 → play`，结束显式 `stop → progress 0` |
| **iOS UIKit 动画尺寸** | `UIViewRepresentable` 直接返回具有固有 composition 尺寸的 `LottieAnimationView` 时，外部 SwiftUI `.frame` 可能只约束包装层而允许动画溢出；返回裁剪 UIView 容器，把动画关闭 autoresizing mask 后四边约束填充，并在 SwiftUI 层再次 `.clipped()` |
| **HarmonyOS 卡片尺寸所有权** | 百分比宽度、内外边距与固定宽子图共同参与 ArkUI 测量时，由全宽 Row 扣页面 padding、卡片 Column 仅 `layoutWeight(1)` 占剩余宽度；更关键的是 Scroll/Refresh 内的数据 renderer 禁止 `height('100%')`，否则百分比高度会解析为滚动视口并让一张普通卡占满整屏 |
| **三端资料编辑页滚动边界** | 返回/标题/保存属于固定页面栏，必须位于资料滚动容器之外；头像和字段单独滚动。HarmonyOS 的短内容还需显式 `Alignment.TopStart`，避免内容不足一屏时整体垂直居中 |
| **HarmonyOS Path 与图片着色单位边界** | ArkUI `Path.commands` 的数值坐标按物理像素解释，而 `.width/.height/.margin` 等布局尺寸按 vp；把设计稿 vp 坐标直接写进 Path 会在高密度设备上缩小并向左上错位，生成命令前应以 `vp2px` 换算且不能重复换算布局值。PNG 的 `fillColor` 单独使用不会覆盖原图颜色，单色语义图标需先启用 `ImageRenderMode.Template` |
| **HarmonyOS common JSON 依赖边界** | `ohos_arm64` 无法解析官方 kotlinx-serialization JSON Native 变体；会进入 Harmony bridge 的 common JSON codec 必须保持自包含或使用明确提供 OHOS 变体的依赖，不能仅因 Android/iOS 可编译就引入普通 Kotlin/Native 库 |
| **范围图的单一数值坐标系** | HRV 等分段横条必须由 common 同时输出总范围、连续分段边界与当前值；平台按 `(segment.max-segment.min)/(range.max-range.min)` 计算宽度，并用同一范围归一化指针。不能分别硬编码像素比例和指针上下限，否则数值、色带与指针会脱节。 |
| **HarmonyOS KNOI 保存结果类型** | common 保存接口返回 Boolean 时，Harmony bridge 与生成的 provider 必须继续暴露 `boolean`，ArkTS 直接判断结果；不要转成字符串再比较 `'true'`。顶栏保存操作使用原生 `Button` 与保存中禁用状态，避免 `Text.onClick` 热区和重复提交问题。 |
| **HarmonyOS KNOI 集合参数格式** | 跨 ArkTS/KNOI 的集合参数必须在调用两端保持同一编码契约。若 bridge 参数命名为 `typeNamesCsv` 并按逗号拆分，ArkTS 只能传 `types.join(',')`；传 `JSON.stringify(types)` 会留下方括号和引号，使所有枚举 ID 解析失败并被 common 当成空列表。结构门禁应同时禁止错误编码并验证正确编码。 |
| **登录后根层与二级导航边界** | “体能、记录、探索、我”是同一根层 UI 状态，Tab 切换不进入历史栈；健康详情、卡片编辑、资料编辑必须由各端原生导航栈 Push/Pop，`common` 只提供稳定 ID、业务状态和规则，不感知平台路由。 |
| **详情返回的状态所有权** | 保留滚动位置的关键是保留同一根页面及其平台滚动状态：Android hoist `LazyListState`，iOS 复用根 View/VM，HarmonyOS 普通 Pop 不重载根 Scroll；共享 ViewModel 提升到导航图时不得在认证完成前抢先加载用户健康数据。 |
| **人体肌肉蒙版契约** | 体型管理使用与正/背人体底图同尺寸、同坐标系的透明蒙版；common 维护稳定“锻炼部位 → 区域 ID”映射（背部可展开为斜方肌、背阔肌、竖脊肌），三端只维护区域 ID 到资源的映射并以 Template/tint 同画布叠加。不得从本地化文字反推部位，也不得用坐标圆点替代实际肌肉区域。 |
| **刷新时持久数据与草稿的字段级合并** | 同一模块同时含“用户长期数据”和“可丢弃场景草稿”时，刷新只能按字段保留长期数据，不能用旧模块对象整体覆盖草稿。体型管理保留旧 `weightKg/weightHistoryKg`，但 `trainedMuscleGroups` 必须来自当前 Normal 草稿；回归测试需覆盖“已有多条历史 → 保存草稿 → 刷新前不变 → 刷新后变化 → 重建仍一致”。 |
| **Compose 长按拖拽手势的滚动泄露** | `detectDragGesturesAfterLongPress` 在长按检测完成后、拖拽循环建立前存在指针事件泄露窗口，导致 LazyColumn 滚动与拖拽竞争。应使用 `awaitLongPressOrCancellation` 手动分两阶段：长按等待（由框架消费事件）→ 确认后立即进入 `while(true)` 拖拽循环逐帧消费 `PointerInputChange`。`pointerInput` 的 key 需绑定到拖拽目标列表引用以响应列表变更。 |
| **HealthState 跨账号复用导致数据串号** | `HealthDashboardViewModel` 在 AuthNavGraph 层用 `remember(viewModel)` 唯一缓存，登出再换号登录后 HealthState 仍持有旧账号数据。修复方案：在 `LoginEffect.AuthSucceeded` 和 `LoggedOut` 时调用 `HealthStore.staleForNewAccount()` 置空 `uiState` 并设 `isRefreshing=true`，使 HealthDashboardScreen 的 `LaunchedEffect` 识别空态并延迟 640ms 后重新 `load()`，产生"空卡片→刷新→恢复数据"的视觉过渡。 |
| **账号注销的数据域边界** | 注销不能只删除认证仓库；组合根必须先按当前稳定 `userId` 调用健康数据清理，再执行认证账号删除，并让清理失败阻止注销。清理实现同时复位内存中的 UI、草稿与待消费 Effect，回归测试需证明目标用户快照删除且其他用户不受影响。 |
| **HarmonyOS API 12 清焦点入口** | ArkUI 页面需要在滚动、打开滚轮/弹层或点击非输入操作前通过 `getUIContext().getFocusController().clearFocus()` 结束编辑；`focusControl.clearFocus()` 在当前 API 12 工具链不可用。结构门禁只能防 API 回退，键盘是否收起仍需设备交互复验。 |
| **健康场景不是编辑数据类型边界** | 正常、异常、部分缺失、全空与读取失败只描述同一健康契约的数据内容或读取结果；编辑器取值不得用场景枚举过滤。应按“当前内存快照 → 当前用户持久化快照 → 默认数据”投影，异常业务值原样回填，缺失模块才映射为 0/无数据。 |
| **空数据与读取损坏必须正交建模** | 全空是成功读取到各模块为 null，数据损坏是读取失败；两者在输入控件中都可投影为 0/无数据，但必须用独立来源状态保留语义，不能仅凭投影后的数值反推，否则保存或提示会把损坏误判为普通空数据。 |
| **健康编辑审核按模块返回结构化原因** | 模块编辑保存只审核当前模块，不能让其他缺失模块造成整份草稿失败；失败结果至少包含字段 ID、本地化标签、原因和范围/数量参数。业务上的“异常”不等于结构不合法，只有数字解析、取值范围、选项、数量和字段一致性违反契约时才拒绝。 |
| **ArkUI 输入字段 key 不得包含输入值** | `ForEach` key 决定组件身份；若使用 `${field.id}_${field.value}`，每输入一个字符都会销毁并重建 `TextInput`，导致焦点跳到其他输入框。静态和重复表单字段均使用稳定 `field.id`，只有动态增删导致 ID/行结构变化时才重建。 |
| **SwiftUI 跨导航长任务不能由旧 View 抢先认领** | 认证 Effect 与 NavigationStack ResetTo 可能重叠：旧健康页仍观察到请求并先认领，随后 `onDisappear` 取消本地 Task，新页便无任务可执行。账号刷新等跨导航长任务由长期存活 ViewModel 持有 pending/refreshing/resetting 状态；View 只触发 pending 启动并展示状态，退出登录只失效数据而不在无账号时刷新。 |

## Spec 文件索引

- `spec/auth-mock-spec.md` — 认证模块规格（14 章）
- `spec/health-dashboard-cards.md` — 健康卡片规格
- `spec/health-dashboard-visual-cards.md` — Figma 2031 健康可视化数据与三端原生绘制规格
- `spec/common-training-requirements.md` — 公共培训要求
- `spec/TRACE.md` — 规格到代码的完整追溯映射
- `spec/sdd-workflow.md` — SDD 开发闭环、状态和完成门禁
- `spec/documentation-governance.md` — 项目文档、辅助目录和历史归档治理规则
- `spec/resource-localization.md` — 三端认证资源本地化基础、语义键边界和一致性门禁
- `spec/resource-maintainability.md` — 全模块资源清单、跨端一致性和分批债务收敛规范
- `spec/app-language-switching.md` — 应用内中英文切换、平台持久化与国家代码化规范
- `spec/android-profile-activity-result.md` — Android 本地化 Context 与资料头像 Activity Result 宿主兼容性规范
- `spec/profile-edit-layout.md` — 三端个人资料编辑页固定标题栏与滚动内容边界规范
- `spec/health-editable-normal-data.md` — 正常健康 Mock 的最小源数据、进程内草稿、刷新提交与三端编辑导航规范
- `spec/cross-platform-ui-previews.md` — 三端生产页面 Preview、共享 fixture 与跨语言展示适配规范
