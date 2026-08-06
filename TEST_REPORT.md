# 注册登录模块 — 测试报告

## Android 会话启动竞态修复（2026-07-27）

- 新增 `SessionLifecycleCoordinatorTest` 2 条，覆盖首次 `ON_START` 冷恢复、后续 `ON_START` 暖恢复，以及协调器重建后重新执行冷恢复。
- 红灯阶段测试因缺少 `SessionLifecycleCoordinator` 编译失败；实现串行协调器并移除独立冷启动 `LaunchedEffect` 后转绿。
- `./gradlew :androidApp:testDebugUnitTest`、`:common:check`、`:androidApp:assembleDebug` 均通过。

## 会话与健康契约收口（2026-07-27）

- 新增会话冷启动/暖恢复测试 3 条，覆盖暖恢复不失效、清除旧截止时间和冷启动超时清理。
- 新增健康契约测试 3 条，覆盖场景/错误双向映射、Proto enum 名称写入、旧场景字符串迁移和核心卡片空态引导。
- `./gradlew :common:check`、Android assemble、iOS simulator build、HarmonyOS KNOI bridge + `assembleApp` 均通过。

## 健康首页（2026-07-14）

- 命令：`./gradlew :common:testAndroidHostTest :androidApp:compileDebugKotlin`
- 结果：通过。
- 覆盖：正常、部分缺失、全空、异常与读取失败场景，完整健康领域快照往返、旧快照迁移、模块数据优先、场景选择与刷新提交分离、配置更新不丢数据、账户删除清理、20 用户集合容量与隔离，以及结构化本地化、5 分钟心率聚合、半小时心率区间、七日计划和健康快测可选测量时间契约，共 39 条健康聚合、资源契约与持久化测试。
- UI 验证：Android Debug Kotlin 编译通过；登录成功后的默认页面为四 Tab 主容器，体能展示健康首页，我复用现有退出登录/注销账户页。

## 测试范围

KMP `common` 共享业务层的认证与业务 mock 模块，以及 Android 本地存储集成测试：

| 测试类 | 文件 | 测试数 |
| --- | --- | --- |
| `LoginRulesTest` | `common/src/commonTest/.../LoginRulesTest.kt` | 8 |
| `LoginUseCaseTest` | `common/src/commonTest/.../LoginUseCaseTest.kt` | 41 |
| `BusinessMockDataSourceTest` | `common/src/commonTest/.../BusinessMockDataSourceTest.kt` | 4 |
| `HealthDashboardUseCaseTest` | `common/src/commonTest/.../HealthDashboardUseCaseTest.kt` | 47 |
| `EditableHealthDataTest` | `common/src/commonTest/.../EditableHealthDataTest.kt` | 16 |
| `HealthPreviewFixturesTest` | `common/src/commonTest/.../HealthPreviewFixturesTest.kt` | 1 |
| `HealthStoreTest` | `common/src/commonTest/.../HealthStoreTest.kt` | 11 |
| **业务需求映射小计** | | **117** |
| **common 全部合计（含 HealthStore）** | | **128** |
| `SessionLifecycleCoordinatorTest` | `androidApp/src/test/.../SessionLifecycleCoordinatorTest.kt` | 2 |
| `AndroidAuthStoreDataSourceTest` | `androidApp/src/androidTest/.../AndroidAuthStoreDataSourceTest.kt` | 1 |

共享业务测试合计：**117 条**；另有 `HealthStoreTest` 11 条架构测试，common 当前共 **128 条**。Android JVM 单元测试当前共 **9 条**，其中本轮会话生命周期调度测试 2 条。计数由源码中的 `@Test` 动态核对。

## 运行命令

```bash
./gradlew :common:check
```

## 测试详情

### LoginRulesTest（8 条）

| 测试 | 验证内容 |
| --- | --- |
| `registrationRegionAndLegacyNamesNormalizeToCountryCodes` | 注册区域、旧中英文国家名称归一为稳定国家代码，并支持注册区域回退 |
| `mockErrorMapsToTheProtoErrorMessage` | 本地错误场景映射到 Proto 错误 message 语义 |
| `phoneInputIsNormalizedAndValidatedInCommon` | 手机号输入规范化 + 有效性校验 |
| `emailValidationUsesSharedRule` | 邮箱格式校验 |
| `verifyCodeInputIsFourDigits` | 验证码输入规范化 + 完整判断 |
| `registerPasswordRuleIsShared` | 密码规则：长度 6-20、字母+数字、两次一致 |
| `loginReadinessUsesSharedRule` | 登录按钮可用判断（loading、空输入、密码长度） |
| `validationFailuresExposeStableLocalizationKeys` | 共享认证校验失败只输出稳定的 `auth_*` 本地化语义键 |

### LoginUseCaseTest（41 条）

| 测试 | 验证内容 | 异常态 |
| --- | --- | --- |
| `registerSuccessSavesSessionAndCanBeRestored` | 注册成功，session 自动保存且可恢复 | — |
| `duplicateRegisterFails` | 重复注册返回 `AccountExists` | — |
| `invalidVerifyCodeFails` | 验证码错误返回 `VerifyCodeInvalid` | — |
| `missingRegionFailsWithExplicitMessage` | 区域缺失返回 `RegionRequired` | ✅ **区域缺失** |
| `resentVerifyCodeReplacesOriginalCode` | 重发验证码替换原码 | — |
| `verifyCodeExpiresAfterTtl` | 验证码过期返回 `VerifyCodeExpired` | — |
| `sessionExpiresAfterBackgroundTtlAndIsRemovedFromPersistence` | 后台 TTL 到期后清理 Session | — |
| `warmResumeKeepsSessionActiveAfterBackgroundTtlAndClearsDeadline` | 同进程暖恢复保持登录并清除旧截止时间 | — |
| `warmResumePreventsStaleDeadlineFromExpiringNextColdStart` | 暖恢复后的后续冷启动不受旧截止时间影响 | — |
| `coldStartRestoreExpiresSessionAfterPersistedDeadline` | 冷启动超过持久化截止时间后清理 Session | — |
| `verifyCodeRemainingSecondsUsesTheSameClockAsExpiration` | 倒计时与过期判断使用同一时间源 | — |
| `loginSuccessSavesSession` | 登录成功，session 保存 | — |
| `businessAccessSucceedsAfterLogin` | 登录后业务访问可读取当前 Session | — |
| `saveProfileMarksSessionCompleteAndPersistsForNextLogin` | 保存 profile → 下次登录仍完整 | — |
| `editingProfilePersistsWithoutProducingNavigationEffect` | 编辑已有 profile 可持久化且不重复触发首次资料导航 | — |
| `incompleteProfileCannotBeSaved` | 不完整 profile 保存失败 | — |
| `defaultMockAccountCanLogin` | 默认预置账号可登录 | — |
| `registeredAccountCanLoginAgainFromMockStore` | 重新构造 repository 后账号仍可登录 | — |
| `loginWithNonExistentAccountFails` | 登录未注册账号返回 `AccountNotFound` | — |
| `incorrectPasswordFails` | 密码错误返回 `PasswordIncorrect` | — |
| `profileDefaultsUseAccountTypeAndCorosUserName` | 首次资料默认用户名为 `COROS user`，并按账号类型只预填手机号或邮箱 | — |
| `changePasswordRequiresCorrectOldPassword` | 修改密码需旧密码正确 | — |
| `changedPasswordReplacesOldPassword` | 修改密码后旧密码失效 | — |
| `resetPasswordDoesNotRequireOldPassword` | 重置密码不要求旧密码 | — |
| `deleteCurrentAccountRemovesAccountAndSession` | 删除账号移除本地数据 | — |
| `businessAccessRequiresLogin` | 未登录访问业务数据返回 `AuthRequired` | ✅ **未登录** |
| `businessAccessFailsAfterLogout` | 登出后访问业务数据返回 `AuthRequired` | — |
| `businessAccessFailsAfterSessionExpired` | 会话失效后访问业务数据返回 `AuthRequired` | — |
| `localSessionCanBeRestoredAfterLogin` | 重新构造 repository 后 session 可恢复 | — |
| `mockStoreJsonPreservesProfileDisplayNameAndSession` | protobuf JSON 映射的序列化/反序列化 round-trip | — |
| `mockStoreJsonReadsLegacyAndroidSnakeCaseSnapshot` | 兼容旧版 Android snake_case JSON | — |
| `emptyStoreWithInitializedFlagReturnsNullSession` | 空数据 store 返回 null session | ✅ **空数据** |
| `corruptedSessionWithBlankUserIdReturnsNull` | 损坏 session（blank userId）返回 null | ✅ **错误数据** |
| `persistFailedOnRegisterReturnsError` | 持久化失败返回 `PersistFailed` | ✅ **持久化失败** |

### BusinessMockDataSourceTest（4 条）

| 测试 | 验证内容 |
| --- | --- |
| `loggedInUserCanReadBusinessMockData` | 已登录后读取业务摘要成功，并使用当前用户资料 |
| `anonymousUserCannotReadBusinessMockData` | 未登录读取业务摘要返回 `AuthRequired` |
| `loggedOutUserCannotReadBusinessMockData` | 登出后读取业务摘要返回 `AuthRequired` |
| `expiredSessionCannotReadBusinessMockData` | 会话失效后读取业务摘要返回 `AuthRequired` |

### HealthDashboardUseCaseTest（47 条）

覆盖 14 类卡片目录、稳定优先级、正常/部分缺失/全空/异常/读取失败场景、类型化场景与错误契约、Proto enum 快照写入、旧字符串场景迁移、核心 Empty 引导、完整领域快照与多用户集合 JSON 往返、旧配置及旧心率单值样本迁移、体重有序重复历史往返及旧快照迁移、288 个 5 分钟模拟采样聚合为 48 个半小时最低/最高/平均心率区间、七日计划结构、健康快测可选测量时间、账户删除清理、模块数据优先、场景选择不立即提交、刷新成功提交及失败回滚、健康 UI model 的语义键/参数契约，以及卡片选择与顺序持久化。具体测试名以 `common/src/commonTest/kotlin/com/example/demo/common/health/HealthDashboardUseCaseTest.kt` 为准。

### EditableHealthDataTest（16 条）

覆盖正常场景最小权威源字段往返与展示数据重建、进程内草稿和刷新提交分离、单模块及整套默认恢复、共享表单 schema 与原始输入校验、288/48 点心率和压力快捷序列生成、周计划派生、睡眠阶段连续性与结束时间计算，以及睡眠阶段/锻炼部位动态增删、共享部位选项约束、体型编辑只修改锻炼部位并保留体重历史、体型图示部位语义输出和已有体重历史下的草稿肌群刷新合并；另覆盖异常场景内存/持久化数据回填、全空与数据损坏的同投影异语义、部分缺失场景单模块保存，以及字段级结构化审核原因。

### HealthStoreTest（11 条）

覆盖 Health MVI Action、State、Effect、认证拦截和卡片配置校验。

### AndroidAuthStoreDataSourceTest（1 条）

| 测试 | 验证内容 |
| --- | --- |
| `loginSessionIsPersistedAndRestoredByNewDataSourceInstance` | 使用真实 `SharedPreferences` 保存登录态；新建数据源后仍能恢复 Session 并访问业务 mock |

## 异常态覆盖

| 异常类别 | 覆盖状态 | 对应测试 |
| --- | --- | --- |
| 未登录 | ✅ 已覆盖 | `businessAccessRequiresLogin` |
| 空数据 | ✅ 已覆盖 | `emptyStoreWithInitializedFlagReturnsNullSession` |
| 错误数据 | ✅ 已覆盖 | `corruptedSessionWithBlankUserIdReturnsNull` |
| 持久化失败 | ✅ 已覆盖 | `persistFailedOnRegisterReturnsError` |

## 未覆盖风险

| 风险 | 说明 | 优先级 |
| --- | --- | --- |
| Native UI 层自动化测试 | 当前未做 Android/iOS/HarmonyOS 的 UI 自动化测试 | 低（可手动验收） |
| iOS/HarmonyOS 存储集成测试 | common 测试覆盖共享规则；尚未在 iOS/Harmony 真机或模拟器上自动验证恢复链路 | 中 |
| 并发操作 | `LoginStore.dispatch` 未测试多线程场景 | 低（当前 UI 单线程） |
| 边界字符 | 含特殊字符的账号名、超长密码等未全覆盖 | 低 |
