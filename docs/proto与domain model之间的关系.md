# Proto 与 Domain Model 之间的关系

## 结论

当前项目采用的是 **Proto-first 的受约束手工映射架构**：

```text
auth_mock.proto（数据结构契约）
  → Kotlin Mock 存储模型（手工镜像）
  → MockAuthStoreJson（统一 JSON 快照编解码）
  → 本地键值存储

Kotlin Mock 存储模型
  ↕ 集中转换函数
KMP Domain Model
  → AuthRepository / LoginStore
  → 三端原生 UI
```

项目当前 **没有** 配置 `protoc` 生成 Kotlin protobuf Message 类。`.proto` 是认证数据的唯一 Schema；`MockAuthStore`、`MockAuthSession` 等 Kotlin data class 按该 Schema 手工镜像。

## 1. 什么是 protobuf 结构

Protobuf（Protocol Buffers）用 `.proto` 文件定义跨语言数据结构，包含：

- `message` 名称；
- 字段名称和类型；
- 字段编号；
- 枚举值。

例如：

```proto
message MockAuthSession {
  string user_id = 1;
  string account = 2;
  string display_name = 3;
  string region = 4;
  bool is_valid = 5;
}
```

其中 `1` 至 `5` 是字段编号。未来演进时可以增加新的字段编号，但不应改变既有编号的语义。

本项目的契约文件是 `common/src/commonMain/proto/auth_mock.proto`，定义了账号、Session、验证码、区域、资料和错误场景。

## 2. Proto、JSON 与本地持久化的职责

三者不能混为一谈：

| 层次 | 当前项目中的职责 |
| --- | --- |
| `.proto` | 定义哪些认证数据存在、字段名、字段类型和字段语义 |
| Kotlin `Mock*` 模型 | 在 KMP common 内存中承载与 Proto 对应的存储数据 |
| `MockAuthStoreJson` | 将完整认证 Store 编码为 JSON 字符串，或从 JSON 恢复 Store |
| 平台存储 API | 保存或读取 JSON 字符串 |

因此，JSON 的直接用途是本地持久化；Proto 的用途是约束这份持久化数据和其对应 Kotlin 对象的结构。

```text
MockAuthStore
  → MockAuthStoreJson.encode()
  → JSON 字符串
  → Android SharedPreferences / iOS UserDefaults / Harmony Preferences
```

应用重启后则反向恢复：

```text
JSON 字符串
  → MockAuthStoreJson.decode()
  → MockAuthStore
  → resumeSession()
  → 重新推导入口页、资料页或已登录页
```

如果项目接入了兼容三端的 protobuf runtime，protobuf Message 既可以序列化为二进制，也可以按 protobuf JSON 规则序列化为 JSON；当前项目为了兼容 iOS 和 HarmonyOS 的现有调用链，使用 common 中的统一手工编解码器。

## 3. Proto Message 与 Kotlin 存储模型的对应

`.proto` 中的 Message 与 Kotlin 的 `Mock*` 模型一一对应：

| Proto Message | Kotlin 模型 | 说明 |
| --- | --- | --- |
| `MockAuthStore` | `MockAuthStore` | 本地认证持久化根对象 |
| `MockAccount` | `MockAccount` | 本地 mock 账号记录 |
| `MockAuthSession` | `MockAuthSession` | 可持久化的当前 Session |
| `MockVerifyCodeState` | `MockVerifyCodeState` | 验证码及其过期时间 |
| `MockAuthRegion` | `MockAuthRegion` | 本地区域配置 |
| `UserProfile` | `UserProfile` | 用户资料 |
| `MockErrorMessage` | `MockErrorMessage` | 可追溯的错误消息结构 |

字段按 protobuf JSON 的常用命名规则从 `snake_case` 转为 `camelCase`：

| Proto 字段 | Kotlin / JSON 字段 |
| --- | --- |
| `user_id` | `userId` |
| `password_hash` | `passwordHash` |
| `display_name` | `displayName` |
| `current_session` | `currentSession` |
| `verify_codes` | `verifyCodes` |

例如 Proto 的 `MockAuthStore`：

```proto
message MockAuthStore {
  repeated MockAccount accounts = 1;
  optional MockAuthSession current_session = 2;
  repeated MockVerifyCodeState verify_codes = 3;
  bool default_accounts_initialized = 4;
}
```

对应 Kotlin：

```kotlin
data class MockAuthStore(
    val accounts: List<MockAccount> = emptyList(),
    val currentSession: MockAuthSession? = null,
    val verifyCodes: List<MockVerifyCodeState> = emptyList(),
    val defaultAccountsInitialized: Boolean = false
)
```

## 4. 什么是 Domain Model

Domain Model（领域模型）是为业务逻辑服务的模型，而不是单纯为了持久化或序列化存在的模型。

项目中的主要 Domain Model 包括：

- `AuthSession`：当前业务登录态；
- `AuthRegion`：注册页使用的区域；
- `MockError`、`MockResult`：本地认证结果和错误；
- `LoginState`、`LoginAction`、`LoginEffect`：共享状态机模型。

其中：

| 模型 | 职责 | 是否直接持久化 |
| --- | --- | --- |
| `MockAuthSession` | 贴近 Proto、存入 `MockAuthStore` | 是 |
| `AuthSession` | 表达当前用户的业务登录态 | 否，转换后使用 |
| `LoginState` | 页面持续状态 | 否 |
| `LoginEffect` | 登录成功、登出、失效等一次性事件 | 否 |

`AuthSession` 包含 `resolvedDisplayName`、`isProfileComplete` 等计算属性，它们由已有字段推导，不需要写入 Proto 或本地快照。

## 5. 当前项目中的转换关系

### Session 转换

核心转换函数位于 `LoginModels.kt`：

```kotlin
fun MockAuthSession.toDomainOrNull(): AuthSession?
fun AuthSession.toMockSession(): MockAuthSession
```

恢复时：

```text
JSON
  → MockAuthStore
  → MockAuthSession
  → toDomainOrNull()
  → AuthSession
  → LoginStore / UI
```

保存时：

```text
注册或登录成功
  → AuthSession
  → toMockSession()
  → MockAuthStore.currentSession
  → JSON 持久化
```

`toDomainOrNull()` 不只是复制字段；如果 `userId` 或 `account` 为空，会返回 `null`，避免损坏的本地 Session 被当作有效登录态。

### 区域转换

```kotlin
fun MockAuthRegion.toDomain(): AuthRegion
fun AuthRegion.toMockRegion(): MockAuthRegion
```

`MockAuthRegion` 贴近 Proto 配置，`AuthRegion` 则用于注册页和业务逻辑。

### 错误转换

```kotlin
fun MockError.toProtoMessage(): MockErrorMessage
fun MockErrorMessage.toMockError(): MockError?
```

这使 `AccountExists`、`PasswordIncorrect`、`AuthRequired` 等本地错误可追溯到 `MockErrorCode`，但不模拟 HTTP 错误响应。

### 不需要额外转换的模型

`MockAuthStore`、`MockAccount`、`MockVerifyCodeState` 主要是仓库和持久化内部模型。注册和登录会从账号记录构建 `AuthSession`，但它们没有单独的 Domain Model 转换函数。

## 6. AuthRepository 如何使用这些模型

`LocalMockAuthRepository` 每次操作都以完整 `MockAuthStore` 为单位：

```text
dataSource.load()
  → 读取 MockAuthStore
  → 执行注册、登录、验证码、登出或失效规则
  → 构造新的 MockAuthStore
  → dataSource.save(nextStore)
```

例如注册成功：

```text
RegisterRequestDto
  → 校验账号、密码、验证码、区域
  → 创建 MockAccount
  → 创建 AuthSession
  → AuthSession.toMockSession()
  → 写入 accounts + currentSession
  → 持久化 MockAuthStore
```

这样，账号库、Session 和验证码不会分别散落在页面中，而是集中由仓库管理。

## 7. 什么是字段漂移风险

字段漂移是指 Proto、Kotlin 模型、转换函数和 JSON 编解码器没有同步更新，导致它们不再表达同一份数据结构。

例如未来在 Proto 增加：

```proto
string device_id = 9;
```

当前项目还必须手工同步：

1. `MockAuthSession` 是否新增 `deviceId`；
2. `AuthSession` 是否需要该业务字段；
3. `toDomainOrNull()` / `toMockSession()` 是否映射；
4. `MockAuthStoreJson.encode()` / `decode()` 是否处理；
5. 测试是否覆盖保存与恢复。

若只改 Proto，不改 JSON，字段保存后会丢失；若只改 Kotlin，不改 Proto，该字段就不再可追溯到契约。

当前有一个仅影响严格规范一致性的细节：Proto 中验证码过期时间是 `int64`，但 JSON 编码中该字段写成数字；Session 的两个 `int64` 时间字段则写成字符串。当前功能和恢复逻辑正常，但严格 protobuf JSON 约定通常将 `int64` 写成字符串。后续可统一编码形式，减少规则差异。

## 8. 如果使用 protoc 生成 Message，架构会怎样

若三端都有兼容的 protobuf runtime，`protoc` 会生成 Message 类，替代手工 `Mock*` 存储模型：

```text
auth_mock.proto
  → protoc 生成 MockAuthStore / MockAuthSession 等 Message
  ↕ Mapper
AuthSession / AuthRegion / MockError 等 Domain Model
  → AuthRepository / LoginStore
```

此时常见函数会是：

```text
GeneratedMockAuthSession.toDomain()
AuthSession.toProto()
```

这里的 `toProto()` 是将 Domain Model 转为“生成的 protobuf Message”；当前项目中的对应函数是 `AuthSession.toMockSession()`，目标是手工镜像的存储模型。

使用生成 Message 的优点是 Proto 字段变更后生成模型会自动更新，字段漂移风险更低；但 Google protobuf Kotlin 的常见生成与 runtime 链路并不天然适配当前 iOS Kotlin/Native 和 Harmony KNOI bridge，因此当前项目选择手工镜像和 common 统一编解码。

## 9. 可用于讲解的总结

> 本项目以 `auth_mock.proto` 作为本地认证数据的唯一结构契约。由于当前三端，特别是 iOS 与 HarmonyOS bridge 的 protobuf runtime 接入成本和兼容性限制，项目没有直接使用生成的 protobuf Message，而是在 KMP common 中用 `MockAuthStore`、`MockAccount`、`MockAuthSession` 等对象一一镜像 Proto 结构。`MockAuthStoreJson` 统一将这些存储模型保存为 JSON 快照；`AuthSession`、`AuthRegion`、`MockError` 等 Domain Model 则承载业务语义。二者通过集中 Mapper 转换，因此三端 UI 和平台存储不需要重复实现认证数据结构和认证规则。
