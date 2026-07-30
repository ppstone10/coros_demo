# 健康仪表盘维护性提升 Spec

## 元数据

- Spec ID 前缀：`HLTH-MAINT`
- 状态：草案
- 关联需求：解决健康主页模块业务规则漂移、模型重复、导航逻辑三端冗余
- 最后更新：2026-07-30

## 目标

- 将健康主页「最少卡片数(≥3)」业务验证从三端 UI 层收归 common
- 将场景名/场景展示键列表从三端各自维护收归 common 静态常量
- 消除 iOS 端 `HealthCard`/`defaultHealthCards` 重复模型定义
- 将 HarmonyOS `SignedInPage.ets` 按职责拆分为独立文件
- 将登录后导航分支规则（`isProfileComplete`）从三端各写一套收归 `LoginEffect`

## 非目标

- 不改变 UI 层卡片展示、拖拽排序、刷新等交互行为
- 不改变 common 层健康业务规则（状态判定、排序优先级）
- 不引入 DI 框架或新增第三方依赖
- 不重写 HarmonyOS 的 JSON 桥接或 KNOI 通信机制
- 不改动 iOS/HarmonyOS 的图片图标映射逻辑（`iconFor`/`healthIcon` 等平台特有映射保留）
- 不更改 Android 端的数据模型使用方式（已使用 common 类型）

## 边界与约束

- 架构边界：common 层增加业务验证和常量，不引入平台类型
- 安全与数据边界：无敏感数据变更
- 兼容性边界：修改 `LoginEffect.AuthSucceeded` 需确保三端旧版导航逻辑被新路由字段替代
- 失败边界：最少卡片数验证失败时由 common 返回 `MockResult.Failure`，UI 端展示对应错误文案

## 数据与状态

| 名称 | 类型/结构 | 来源 | 生命周期 | 约束 |
|------|-----------|------|----------|------|
| `PostLoginRoute` | `enum`：`SignedIn` / `ProfileCompletion` | common `LoginModels.kt` | 随 LoginEffect 消费而释放 | 新增，不破坏既有字段 |
| `HealthScenarios.names` | `List<String>` | common `HealthDashboardModels.kt` | 静态常量 | 与 `HealthMockScenario.entries` 同步 |
| `HealthScenarios.displayKeys` | `List<String>` | common `HealthDashboardModels.kt` | 静态常量 | 与 `HealthMockScenario` 枚举顺序一致 |
| `LoginEffect.AuthSucceeded.nextRoute` | `PostLoginRoute` | common `LoginModels.kt` | 随 effect 携带 | 新增字段，iOS/HarmonyOS JSON 桥接需同步 |

## 行为规范

### `HLTH-MAINT-001`：最少卡片数验证在 common 层统一执行

- Given：用户在编辑卡片列表时，尝试取消最后第 3 张卡片
- When：调用 `HealthDashboardStore.saveCardConfiguration(List<HealthCardType>)`
- Then：返回 `MockResult.Failure(MockError.MinimumCardsRequired)`，不更新配置
- 异常/边界：`types` 为 `emptyList()` 时同样返回失败；`types.size >= 3` 时正常保存

### `HLTH-MAINT-002`：`LoginFacade` 暴露卡片保存错误消息

- Given：`HLTH-MAINT-001` 失败
- When：iOS/HarmonyOS 通过 `LoginFacade` 调用卡片保存
- Then：`LoginFacade.saveHealthCardConfiguration` 返回错误消息字符串（非 null）
- 异常/边界：成功时返回 `null`，与 facade 其他方法模式一致

### `HLTH-MAINT-003`：场景名和展示键由 common 提供

- Given：任何需要展示场景列表的场景
- When：三端 UI 需要获取所有场景名称或展示键
- Then：从 common 的 `HealthScenarios` 对象读取，不在 UI 层硬编码
- 异常/边界：`HealthScenarios.names` 与 `HealthMockScenario.entries` 一一对应

### `HLTH-MAINT-004`：iOS 移除 `HealthCard` 和 `defaultHealthCards`

- Given：iOS 健康仪表盘数据来自 common 的 `PersistedDashboard`
- When：`HealthDashboardViewModel.load()` 获取数据
- Then：直接从 `pd.uiState.cards` 映射到平台展示列表，不再依赖本地 `HealthCard` 结构体和 `defaultHealthCards`
- 异常/边界：图片图标映射保留本地 `iconFor()` 函数（平台特有）

### `HLTH-MAINT-005`：HarmonyOS `SignedInPage.ets` 按职责拆分

- Given：`SignedInPage.ets` 当前 991 行单一文件
- When：完成本次重构后
- Then：文件拆分为 `pages/SignedInPage.ets`（容器）、`health/HealthDashboardTypes.ets`、`health/HealthDashboardView.ets`、`health/HealthCardEditor.ets`、`account/AccountOverview.ets`
- 异常/边界：拆分仅移动代码，不改变 UI 布局、交互和状态管理逻辑

### `HLTH-MAINT-006`：登录后导航规则由 `LoginEffect` 携带

- Given：用户登录成功
- When：`LoginStore.submit()` 完成认证
- Then：`LoginEffect.AuthSucceeded` 携带 `nextRoute: PostLoginRoute`，值由 common 根据 `isProfileComplete` 计算
- Then：三端 UI 根据 `effect.nextRoute` 决定导航目标，不再自行判断 `isProfileComplete`
- 异常/边界：`PostLoginRoute` 只有 `SignedIn` 和 `ProfileCompletion` 两个值；`AuthSucceeded` 保留既有 `session` 字段

### `HLTH-MAINT-007`：HarmonyOS 编辑卡片保存参数保持 CSV 契约

- Given：HarmonyOS 编辑卡片页已有不少于 3 个有效 `HealthCardType` ID
- When：用户点击“保存”，页面把编辑结果交给 `HealthDashboardViewModel`，再调用 KNOI `saveCardConfig(typeNamesCsv)`
- Then：ViewModel 必须使用 `types.join(',')` 生成 CSV；不得对数组执行 `JSON.stringify` 后再交给按逗号拆分的 bridge
- And：标题栏保存入口使用原生 `Button` 提供稳定点击热区，而不是仅给 `Text` 附加点击事件
- And：保存成功后更新健康卡片版本、持久化快照并返回健康首页；保存失败时停留编辑页，不得把失败结果当成成功返回
- 异常/边界：空列表或少于 3 项仍由 common 的最少卡片规则拒绝；参数转换不得在平台端修改卡片 ID

## 测试要求

| Spec ID | 自动化测试/人工验收 | 预期结果 |
|---------|---------------------|----------|
| `HLTH-MAINT-001` | `HealthDashboardUseCaseTest.cardSaveRejectsMinimumConfig` | 传入 `size < 3` 的卡片列表返回 `MockResult.Failure`，>=3 返回 `Success` |
| `HLTH-MAINT-001` | `HealthDashboardUseCaseTest.cardSaveAcceptsSufficientConfig` | 传入 3 张以上卡片返回 `MockResult.Success` |
| `HLTH-MAINT-003` | `HealthDashboardUseCaseTest.healthScenariosMatchMockEntries` | `HealthScenarios.names` 与 `HealthMockScenario.entries.map { it.name }` 完全一致 |
| `HLTH-MAINT-006` | `LoginUseCaseTest.loginSuccessCarriesNextRoute` | `LoginEffect.AuthSucceeded.nextRoute` 在资料完整时 = `SignedIn`，不完整时 = `ProfileCompletion` |
| `HLTH-MAINT-004` | 人工验收：iOS 构建通过 + 健康仪表盘展示数据与修改前一致 | `xcodebuild` 构建成功，卡片列表、内容、图标与之前无差异 |
| `HLTH-MAINT-005` | 人工验收：HarmonyOS 构建通过 + 页面交互无差异 | `hvigorw assembleHap --no-daemon` 构建成功，仪表盘、编辑器和账户页交互正常 |
| `HLTH-MAINT-002` | 人工验收：三端尝试减少卡片到少于 3 张 | Android 显示 common 返回的错误文案；iOS 显示 facade 返回的错误消息；HarmonyOS 显示 JSON 中的错误字段 |
| `HLTH-MAINT-007` | `tools/check-health-card-editor-regressions.sh` + HarmonyOS 构建/设备点击 | ViewModel 发送纯 CSV 且不再发送 JSON 数组；保存后返回并由首页读取新顺序 |

## 验收标准

- [ ] 所有规范 ID 已在 `spec/TRACE.md` 建立映射
- [ ] `HLTH-MAINT-001` 测试在实现前运行显示红灯，实现后通过
- [ ] `HLTH-MAINT-003` 测试通过
- [ ] `HLTH-MAINT-006` 测试通过
- [ ] Android `./gradlew :common:check` 通过
- [ ] iOS `xcodebuild` 构建通过
- [ ] HarmonyOS `hvigorw assembleHap` 构建通过
- [ ] 三端卡片编辑器中减少卡片至 <3 张时均显示错误提示
- [ ] 登录后导航行为与修改前一致
- [x] HarmonyOS 编辑卡片保存使用原生按钮并保持 CSV bridge 契约
- [x] TRACE、`Codex_worklog.md` 和必要的 `LEARNINGS.md` 已更新

## 待人工确认

- `MockError.MinimumCardsRequired` 的错误消息 key 需要确定文案
- HarmonyOS JSON 桥接中 `LoginEffect` 的 `nextRoute` 字段名需与 ArkTS 解析侧对齐
