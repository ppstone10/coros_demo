# 注册登录模块 — 设计方案

## 架构总览

KMP `common` 共享业务层 + 三端 Native UI：

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
| `LoginState` | `LoginModels.kt:131` | 页面状态：输入、加载、错误、当前会话 |
| `LoginAction` | `LoginModels.kt:156` | 用户意图：输入改变、提交、登出、会话失效 |
| `LoginEffect` | `LoginModels.kt:171` | 一次性效果：导航到首页、Toast 消息、登出 |
| `AuthSession` | `LoginModels.kt:16` | 领域层登录态（含 profile 信息） |
| `AuthRegion` | `LoginModels.kt:33` | 注册区域（CN/US） |
| `UserProfile` | `LoginModels.kt:80` | 用户资料（头像、昵称、生日、身高、体重、计量单位等） |
| `MockResult` | `LoginModels.kt:99` | 本地 mock 操作结果（Success/Failure） |
| `MockError` | `LoginModels.kt:104` | 预定义错误码（11 种） |
| `LoginResult` | `LoginModels.kt:180` | UseCase 返回结果 |
| `RegisterRequestDto` | `LoginModels.kt:8` | 注册输入 DTO |
| `LoginRequestDto` | `LoginModels.kt:3` | 登录输入 DTO |

## 状态流转

### 注册流程

```
输入账号 → 获取验证码 → 输入验证码 → 选择区域 → 提交
  → validateRegister() 校验
    → 校验失败 → 返回 MockError → UI 展示错误
    → 校验通过 → 创建 MockAccount + AuthSession
      → dataSource.save() → 成功 → LoginResult.Success → LoginEffect.AuthSucceeded
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

### Message 与 Domain Model 转换关系

| Proto Message | Kotlin Data Class | 转换函数 |
| --- | --- | --- |
| `MockAccount` | `MockAccount` (`LoginModels.kt:39`) | 直接字段映射 |
| `MockAuthSession` | `MockAuthSession` (`LoginModels.kt:48`) | 直接字段映射 |
| `UserProfile` | `UserProfile` (`LoginModels.kt:80`) | 直接字段映射 |
| `MockAuthSession` → `AuthSession` | `AuthSession` (`LoginModels.kt:16`) | `toDomainOrNull()` (`LoginModels.kt:185`) — 空 userId/account 时返回 null |
| `AuthSession` → `MockAuthSession` | `MockAuthSession` | `toMockSession()` (`LoginModels.kt:197`) |

### 命名规则

- Proto 使用 `snake_case` 字段名。
- Kotlin 使用 `camelCase` 字段名。
- JSON 持久化兼容两种命名（`camelCase` 优先，`snake_case` 作为 fallback，见 `MockAuthStoreJson.kt`）。

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
| Android | `AndroidAuthStoreDataSource` | SharedPreferences (JSON) |
| iOS | `JsonAuthStoreDataSource` | 文件系统 (JSON) |
| HarmonyOS | `MemoryAuthStoreDataSource` + `StorePersister` | 文件系统 (JSON) |

### 存储内容

- 账号列表（含 profile）
- 当前会话
- 验证码状态
- `defaultAccountsInitialized` 标记

## 账号态依赖规则

- 所有业务 mock 数据源必须通过 `AuthRepository.verifyBusinessAccess()` 获取当前登录态。
- `verifyBusinessAccess()` 返回 `MockResult.Success(AuthSession)` 或 `MockResult.Failure(AuthRequired)`。
- UI 层收到 `AuthRequired` 后清理会话并导航到登录页。

## iOS 集成

- `iosApp/Login/SharedLoginAdapter.swift` 包装 KMP `LoginFacade`。
- `LoginFacade` 通过 `LoginStore` 处理 action 和 side effect。
- 持久化通过 `JsonAuthStoreDataSource`（文件读写）。
- iOS 需先运行 `tools/build-shared-xcframework.sh` 生成 `Shared.framework`。

## HarmonyOS 集成

- `harmony-kmp-bridge` 独立 Gradle 项目使用 KuiklyBase-Kotlin + KNOI 生成 `libkn.so`。
- `HarmonyLoginService` 封装 `LoginFacade` 供 ArkTS 调用。
- `harmonyApp` 通过 `KnoiLoginAdapter.ets` → `HarmonyLoginService` 完成登录操作。
- 持久化通过 `MemoryAuthStoreDataSource` + `StorePersister`（文件 JSON）。
