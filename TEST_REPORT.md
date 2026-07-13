# 注册登录模块 — 测试报告

## 测试范围

KMP `common` 共享业务层的认证与业务 mock 模块，包含三个测试类：

| 测试类 | 文件 | 测试数 |
| --- | --- | --- |
| `LoginRulesTest` | `common/src/commonTest/.../LoginRulesTest.kt` | 6 |
| `LoginUseCaseTest` | `common/src/commonTest/.../LoginUseCaseTest.kt` | 28 |
| `BusinessMockDataSourceTest` | `common/src/commonTest/.../BusinessMockDataSourceTest.kt` | 4 |
| **合计** | | **38** |

## 运行命令

```bash
./gradlew :common:check
```

## 测试详情

### LoginRulesTest（6 条）

| 测试 | 验证内容 |
| --- | --- |
| `registrationRegionMapsToTheProfileCountryRegion` | 注册区域映射为资料页国家名称 |
| `phoneInputIsNormalizedAndValidatedInCommon` | 手机号输入规范化 + 有效性校验 |
| `emailValidationUsesSharedRule` | 邮箱格式校验 |
| `verifyCodeInputIsFourDigits` | 验证码输入规范化 + 完整判断 |
| `registerPasswordRuleIsShared` | 密码规则：长度 6-20、字母+数字、两次一致 |
| `loginReadinessUsesSharedRule` | 登录按钮可用判断（loading、空输入、密码长度） |

### LoginUseCaseTest（28 条）

| 测试 | 验证内容 | 异常态 |
| --- | --- | --- |
| `registerSuccessSavesSessionAndCanBeRestored` | 注册成功，session 自动保存且可恢复 | — |
| `duplicateRegisterFails` | 重复注册返回 `AccountExists` | — |
| `invalidVerifyCodeFails` | 验证码错误返回 `VerifyCodeInvalid` | — |
| `missingRegionFailsWithExplicitMessage` | 区域缺失返回 `RegionRequired` | ✅ **区域缺失** |
| `resentVerifyCodeReplacesOriginalCode` | 重发验证码替换原码 | — |
| `verifyCodeExpiresAfterTtl` | 验证码过期返回 `VerifyCodeExpired` | — |
| `loginSuccessSavesSession` | 登录成功，session 保存 | — |
| `saveProfileMarksSessionCompleteAndPersistsForNextLogin` | 保存 profile → 下次登录仍完整 | — |
| `incompleteProfileCannotBeSaved` | 不完整 profile 保存失败 | — |
| `defaultMockAccountCanLogin` | 默认预置账号可登录 | — |
| `registeredAccountCanLoginAgainFromMockStore` | 重新构造 repository 后账号仍可登录 | — |
| `incorrectPasswordFails` | 密码错误返回 `PasswordIncorrect` | — |
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
| 并发操作 | `LoginStore.dispatch` 未测试多线程场景 | 低（当前 UI 单线程） |
| 边界字符 | 含特殊字符的账号名、超长密码等未全覆盖 | 低 |
