# 注册登录 Mock Spec

## 1. 模块定位

注册登录是所有实习培训方案的基础模块。每个实习项目都必须先完成该模块，再实现自己的业务功能。

注册登录模块只允许使用本地 mock 账号数据和本地状态保存，不接入任何真实服务器、测试服务器、内测服务器或外部认证服务。

注册登录模块负责：

- 注册本地 mock 账号。
- 登录本地 mock 账号。
- 保存登录态。
- 为后续业务 mock 数据源提供当前登录状态。
- 处理未登录、登出、会话失效等基础状态。

## 2. 安全边界

- 不写真实 base url、真实 path、真实请求头、真实请求参数、真实响应结构或真实错误码映射。
- 不实现真实接口加密、签名、鉴权、token 刷新或网络拦截逻辑。
- 不提交真实账号、真实密码、真实 token、真实用户数据、真实密钥或真实服务端返回样例。
- 所有账号、验证码、会话、错误态都必须由本地 mock 数据源生成。
- 本地 mock 认证数据结构必须使用 Protocol Buffers 定义，至少包含账号、会话、验证码状态和错误场景 message。KMP 共享业务层可以把 protobuf message 转换为 domain model。
- 登录态和业务数据状态必须能在本地保存和恢复，便于验收演示。

## 3. Protobuf 结构定义

认证模块至少提供 `auth_mock.proto` 或等价命名文件，字段名可以按实现调整，但不得包含真实 token 字段。示例结构：

```proto
syntax = "proto3";

package training.auth;

message MockAccount {
  string user_id = 1;
  string account = 2;
  string password_hash = 3;
  string display_name = 4;
  string region = 5;
}

message MockAuthSession {
  string user_id = 1;
  string account = 2;
  string display_name = 3;
  string region = 4;
  bool is_valid = 5;
}

message MockVerifyCodeState {
  string account = 1;
  string code = 2;
  int64 expire_at_epoch_ms = 3;
}

message MockAuthStore {
  repeated MockAccount accounts = 1;
  MockAuthSession current_session = 2;
  repeated MockVerifyCodeState verify_codes = 3;
}
```

## 4. 本地会话模型

登录或注册成功后，App 必须保存本地登录态。KMP domain model 可以从 protobuf message 转换而来，例如：

```kotlin
data class AuthSession(
    val userId: String,
    val account: String,
    val displayName: String?,
    val region: String,
    val isValid: Boolean,
)
```

推荐统一封装：

```kotlin
interface AuthRepository {
    fun currentSession(): AuthSession?
    fun requireSession(): AuthSession
    fun saveSession(session: AuthSession)
    fun clearSession()
    fun markSessionExpired()
}
```

后续业务 mock 数据源必须从 `AuthRepository` 获取当前登录态，不能在业务页面里硬编码用户状态。

## 5. 本地 mock 结果

共享业务层可以使用 sealed class、Result、Either 或等价结构表达成功和失败，不要求模拟 HTTP 响应。

示例：

```kotlin
sealed interface MockResult<out T> {
    data class Success<T>(val data: T) : MockResult<T>
    data class Failure(val error: MockError) : MockResult<Nothing>
}

enum class MockError {
    AuthRequired,
    InvalidParam,
    AccountExists,
    AccountNotFound,
    PasswordIncorrect,
    VerifyCodeInvalid,
    EmptyData,
    CorruptedData,
    PersistFailed,
}
```

## 6. 注册区域

注册区域由本地 mock 配置提供，不调用接口。至少提供：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `region` | String | 区域，如 `CN` |
| `displayName` | String | 展示名称，如 `China` |
| `isDefault` | Boolean | 是否默认区域 |

验收重点：

- 默认区域可展示。
- 区域选择后能保存到注册表单状态。
- 区域缺失时有明确错误提示。

## 7. 验证码

验证码由本地 mock 规则生成，不调用接口。建议规则：

- 默认正确验证码为 `123456`。
- 验证码为空、长度错误、验证码错误都要展示明确错误态。
- 可模拟验证码过期。

## 8. 注册

注册输入至少包含：

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `account` | String | 是 | 手机号或邮箱格式的 mock 账号 |
| `password` | String | 是 | 本地 mock 密码 |
| `verifyCode` | String | 是 | 本地 mock 验证码 |
| `region` | String | 是 | 本地 mock 区域 |
| `displayName` | String? | 否 | 展示昵称 |

注册规则：

- 账号为空、格式错误、密码为空、密码过短、验证码错误时返回明确错误。
- 已存在账号不能重复注册。
- 注册成功后写入本地账号库，并调用 `AuthRepository.saveSession(...)`。
- 注册成功后的账号和登录态必须可本地恢复。

## 9. 登录

登录输入至少包含：

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `account` | String | 是 | 已注册的 mock 账号 |
| `password` | String | 是 | 本地 mock 密码 |

登录规则：

- 账号不存在时返回账号不存在。
- 密码错误时返回密码错误。
- 登录中状态需要防重复提交。
- 登录成功后调用 `AuthRepository.saveSession(...)`。
- App 重启或页面重建后仍可恢复登录态。

## 10. 登出

登出规则：

- 清理本地登录态。
- 不删除本地账号库。
- 登出后访问任何依赖登录态的业务 mock 数据源，都必须返回未登录错误。
- UI 应引导用户重新登录。

## 11. 会话失效

会话失效由本地 mock 开关或测试入口触发，不依赖服务端。

### AUTH-SESSION-001：单一冷启动 TTL

- 前台运行期间不计算会话 TTL。
- App 进入后台时只持久化一个冷启动恢复截止时间，不增加第二套“后台 TTL”或“退出 TTL”。
- 同一进程仍存活并从后台回到前台属于暖恢复，不因后台停留时长失效。
- App 进程被回收或用户清除后台后，下一次冷启动根据上一次进入后台时持久化的截止时间判断会话是否失效。
- 移动平台无法可靠获得强制终止发生的准确时刻，因此 TTL 从“上一次进入后台”开始计算，不声明从“用户清除 App”动作发生时开始计算。

### AUTH-SESSION-002：冷启动与暖恢复分离

- 冷启动恢复必须调用可校验持久化截止时间的接口；超过 TTL 时清除会话并产生 `SessionExpired` 效果。
- 同进程暖恢复必须调用不判定过期的接口；该接口将会话恢复为前台活跃状态并清除旧截止时间。
- Android、iOS、HarmonyOS 必须分别把冷启动恢复和前台暖恢复接入对应生命周期，不得用同一个恢复动作混淆两种语义。
- 暖恢复后继续使用并在前台终止进程时，下次立即冷启动不得被旧的后台截止时间误判为过期。

### AUTH-SESSION-003：Android 首次启动串行恢复

- Android 不得通过彼此独立的 Compose `LaunchedEffect` 和 `Lifecycle.Event.ON_START` 同时触发冷恢复与暖恢复，避免暖恢复抢先清除持久化 TTL。
- 每个新建的登录生命周期协调器第一次收到 `ON_START` 时必须只执行冷启动恢复；同一协调器后续收到 `ON_START` 时才执行同进程暖恢复。
- 从最近任务清除 App 后，即使 Android 进程仍被系统缓存，只要 Activity 与登录生命周期协调器重新创建，首次 `ON_START` 仍按冷启动恢复处理。
- 冷启动恢复产生的 `SessionExpired` 不得被同一次启动过程中的暖恢复覆盖或提前消费。

验收重点：

- 可手动或通过测试用例将当前会话标记为失效。
- 业务 mock 数据源检测到失效会话后返回未登录错误。
- 页面收到未登录错误后清理会话并引导重新登录。
- 冷启动超过 TTL 后清理会话；未超过 TTL 时恢复会话。
- 同进程暖恢复不因后台停留超过 Demo TTL 而清理会话。
- Android 首次 `ON_START` 执行冷恢复，第二次及以后 `ON_START` 才执行暖恢复。

## 12. 本地状态保存

认证模块至少保存：

- 本地 mock 账号库。
- 当前登录态。
- 账号区域和展示昵称等基础资料。
- 会话失效状态。

可以使用 JSON 文件、SQLite、DataStore、UserDefaults、KeyValue 存储或等价本地方案。不得使用真实服务器同步。
无论使用哪种持久化方案，状态结构必须能追溯到 protobuf message 定义；如果使用 JSON，也应使用 protobuf JSON 映射，而不是手写无约束 JSON。

**iOS 头像图片持久化**：`UserProfile.avatarUri`（protobuf `avatar_uri`）在 iOS 上存储为 `UserDefaults` 中的一个 UserDefaults key（前缀 `profile_avatar_data_`），头像图片二进制数据直接存入 `UserDefaults`。头像图片的持久化机制必须与账号/健康卡片数据一致（统一使用 `UserDefaults`），不得单独使用文件系统路径，否则 App 重建后文件可能丢失而 URI 依然存在，导致加载失败回退为首字母占位。

## 13. 验收标准

- 注册新账号，注册成功后自动保存 `AuthSession`。
- 使用账号密码登录，登录成功后后续业务 mock 数据源能读到当前登录态。
- 密码错误、验证码错误、账号不存在时展示明确错误态。
- 登出后清理本地登录态，再访问业务 mock 数据源返回未登录错误。
- 会话失效后，页面能清理会话并引导重新登录。
- 本地账号库和登录态可保存和恢复。
- 提供认证模块 `.proto` 文件，并能说明 protobuf message 与 KMP domain model 的转换关系。
- 认证模块单元测试通过，且无真实账号、真实 token、真实接口、真实密钥或真实服务端响应结构落库。

## 14. 单元测试要求

至少覆盖：

- 注册成功。
- 重复注册失败。
- 验证码错误。
- 登录成功。
- 密码错误。
- 未登录访问业务 mock 数据源。
- 登出后访问业务 mock 数据源。
- 会话失效后访问业务 mock 数据源。
- 本地登录态保存和恢复。
