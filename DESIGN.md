# 注册登录模块 — 设计方案

## 架构总览

KMP `common` 共享业务层 + 三端 Native UI。Android/iOS 直接使用 KMP 产物；HarmonyOS 由独立 bridge 编译同一份 `commonMain` 纯业务源码：

| 端 | 语言 | UI 框架 | KMP 集成方式 |
| --- | --- | --- | --- |
| Android | Kotlin | Jetpack Compose | 直接调用 `LoginStore` |
| iOS | Swift | SwiftUI | `Shared.framework` + `LoginFacade` |
| HarmonyOS | ArkTS | ArkUI | KNOI bridge → `HarmonyLoginService` |

## MVVM / MVI 模式

数据流方向（单向）：

```
UI (用户操作)
  → LoginAction (sealed interface)
    → LoginStore.dispatch(action)
      → LoginUseCase / RegisterUseCase
        → AuthRepository (mock 实现)
      ← 更新 LoginState
      ← 发射 LoginEffect (一次性副作用)
  → UI 根据新 State 重绘
  → Navigator 消费 Effect (导航 / Toast)
```

## 核心模型

| 模型 | 文件 | 说明 |
| --- | --- | --- |
| `LoginState` | `LoginModels.kt` | 页面状态：输入、加载、错误、当前会话 |
| `LoginAction` | `LoginModels.kt` | 用户意图：输入改变、提交、登出、会话失效 |
| `LoginEffect` | `LoginModels.kt` | 一次性效果：认证成功、登出、失效、提示 |
| `AuthSession` | `LoginModels.kt` | 领域层登录态（含 profile 信息） |
| `AuthRegion` | `LoginModels.kt` | 注册区域（CN/US） |
| `UserProfile` | `LoginModels.kt` | 用户资料（头像、昵称、生日、身高、体重、计量单位等） |
| `MockResult` / `MockError` | `LoginModels.kt` | 本地 mock 操作结果和错误场景 |
| `LoginResult` | `LoginModels.kt` | 登录/注册 UseCase 返回结果 |

## 状态流转

### 注册流程

```
输入账号 → 获取验证码 → 输入验证码 → 选择区域 → 提交
  → validateRegister() 校验
    → 校验失败 → 返回 MockError → UI 展示错误
    → 校验通过 → 创建 MockAccount + AuthSession
      → dataSource.save(账号 + currentSession) → 成功 → LoginResult.Success → LoginEffect.AuthSucceeded
      → dataSource.save() → 失败 → MockError.PersistFailed
```

### 登录流程

```
输入账号密码 → 提交
  → account 为空/格式错 → MockError.InvalidParam
  → account 不存在 → MockError.AccountNotFound
  → password 错误 → MockError.PasswordIncorrect
  → 校验通过 → saveSession() → LoginResult.Success → LoginEffect.AuthSucceeded
```

### 登出流程

```
用户点击登出 → clearSession()
  → dataSource.save(currentSession = null)
  → LoginEffect.LoggedOut → UI 跳转登录页
  → 后续 verifyBusinessAccess() → AuthRequired
```

### 会话失效流程

```
测试入口/开关 → markSessionExpired()
  → dataSource.save(isValid = false)
  → 业务数据源调用 verifyBusinessAccess() → AuthRequired
  → UI 清理会话 → 引导重新登录
```

## Protobuf 数据结构

文件：`common/src/commonMain/proto/auth_mock.proto`

当前 `.proto` 是结构契约，项目未使用 `protoc` 生成 Kotlin Message 类；`Mock*` data class 是对 Proto 的手工镜像。完整说明见 `docs/proto与domain model之间的关系.md`。

### Message 与 Domain Model 转换关系

| Proto Message | Kotlin Data Class | 转换函数 |
| --- | --- | --- |
| `MockAccount` | `MockAccount` (`LoginModels.kt:39`) | 直接字段映射 |
| `MockAuthSession` | `MockAuthSession` (`LoginModels.kt:48`) | 直接字段映射 |
| `UserProfile` | `UserProfile` (`LoginModels.kt:80`) | 直接字段映射 |
| `MockAuthRegion` | `MockAuthRegion` → `AuthRegion` | `toDomain()` / `toMockRegion()` |
| `MockErrorMessage` | `MockErrorMessage` → `MockError` | `toProtoMessage()` / `toMockError()`，错误不持久化 |
| `MockAuthStore` | `MockAuthStore` | `MockAuthStoreJson`，在 common 中按 protobuf JSON 命名规则集中写入/读取 |
| `MockAuthSession` → `AuthSession` | `AuthSession` | `toDomainOrNull()` — 空 userId/account 时返回 null |
| `AuthSession` → `MockAuthSession` | `MockAuthSession` | `toMockSession()` |

### 命名规则

- Proto 使用 `snake_case` 字段名。
- Kotlin 使用 `camelCase` 字段名。
- 本地 JSON 由 common 中的 `MockAuthStoreJson` 集中编解码：字段使用 `camelCase`、枚举使用 proto 枚举名称；读取时兼容既有 `snake_case` 与 Kotlin 枚举名称快照。HarmonyOS 平台层只保存和恢复认证 Store 快照，不复制认证字段规则。

## 持久化方案

### 接口层

```kotlin
interface AuthStoreDataSource {
    fun load(): MockAuthStore
    fun save(store: MockAuthStore): Boolean
}
```

### 各平台实现

| 平台 | 实现类 | 存储方式 |
| --- | --- | --- |
| 测试/通用 | `InMemoryAuthStoreDataSource` | 内存 Map |
| Android | `AndroidAuthStoreDataSource` | SharedPreferences（protobuf JSON） |
| iOS | `JsonAuthStoreDataSource` | `UserDefaults` 保存认证 JSON |
| HarmonyOS | `MemoryAuthStoreDataSource` + `StorePersister` | ArkTS Preferences 保存 bridge 导出的认证 JSON |

### 存储内容

- 账号列表（含 profile）
- 当前会话
- 验证码状态
- `defaultAccountsInitialized` 标记
- 会话签发/失效时间与 `isValid` 失效状态

## 账号态依赖规则

- 所有业务 mock 数据源必须通过 `AuthRepository.verifyBusinessAccess()` 获取当前登录态。
- `verifyBusinessAccess()` 返回 `MockResult.Success(AuthSession)` 或 `MockResult.Failure(AuthRequired)`。
- UI 层收到 `AuthRequired` 后清理会话并导航到登录页。
- `LocalBusinessMockDataSource` 提供示例业务摘要，按当前 `userId` 生成本地 mock 数据。

## iOS 集成

- `iosApp/Login/SharedLoginAdapter.swift` 包装 KMP `LoginFacade`。
- `LoginFacade` 通过 `LoginStore` 处理 action 和 side effect。
- `SharedLoginAdapter` 向 `JsonAuthStoreDataSource` 注入 `UserDefaults` 的字符串读写回调。
- iOS 需先运行 `tools/build-shared-xcframework.sh` 生成 `Shared.framework`。

## HarmonyOS 集成

- `harmony-kmp-bridge` 独立 Gradle 项目使用 KuiklyBase-Kotlin + KNOI 生成 `libkn.so`。
- `HarmonyLoginService` 封装 `LoginFacade` 供 ArkTS 调用。
- `harmonyApp` 通过 `KnoiLoginAdapter.ets` → `HarmonyLoginService` 完成登录操作。
- native 运行期使用 `MemoryAuthStoreDataSource`；`StorePersister` 将 bridge 导出的 Store 快照保存到 ArkTS Preferences，并在启动时恢复。

## 健康首页

- `common/health` 提供脱敏健康模型和 `health_dashboard_mock.proto` 字段契约。
- `HealthDashboardUseCase` 收敛多源 mock 数据为稳定的 `DashboardUiState` 与 `HealthCardUiModel`，Native UI 不拼接聚合规则。
- 固定排序为：风险 > 今日恢复、睡眠、运动 > 训练趋势 > 单模块空态；全量缺失时显示首页级引导。
- Android 登录成功后进入四 Tab：体能（健康首页）、记录（占位）、探索（占位）、我（复用当前账号页）。
- 健康首页状态独立持久化：`HealthDashboardSnapshot` 使用认证 `userId` 分区，当前保存 mock 场景；Android 通过独立 SharedPreferences 存储。登出仅阻断访问，账号注销可在后续接入时清除该用户分区。
- `HealthDashboardSnapshot.enabledCardTypes` 同时保存用户启用的卡片及顺序。编辑页支持加减卡片、最少三项约束和长按拖动换序，保存后首页按该配置输出；卡片点击进入对应的占位详情页。
