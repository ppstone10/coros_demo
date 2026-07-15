# 注册登录模块 — 需求拆解笔记

## 需求来源

- `auth-mock-spec.md`：注册登录 Mock Spec
- `app-intern-training-plan/common/README.md` 第 4 节"注册登录前置要求"

## 功能拆解

| 模块 | 说明 |
| --- | --- |
| 注册 | 输入账号、密码、验证码、区域，本地 mock 校验并保存账号及登录态 |
| 登录 | 输入已注册账号和密码，校验后保存登录态；防重复提交 |
| 登出 | 清理本地登录态，不删除账号库；业务数据源返回未登录 |
| 会话失效 | 本地 mock 开关标记会话失效；业务数据源返回未登录，UI 引导重新登录 |
| 业务数据访问 | 所有业务 mock 数据源通过 `AuthRepository.verifyBusinessAccess()` 获取有效登录态 |
| 本地状态保存 | 账号库、登录态、验证码状态在 App 重启后可恢复 |

## 已确认规则

| 规则 | 内容 |
| --- | --- |
| 注册区域 | CN（默认）、US |
| 验证码 | 默认正确码 `1234`，重发码 `4321`，有效期 60s |
| 密码规则 | 6-20 位，须包含字母和数字 |
| 账号格式 | 注册 UI 的手机号为 11 位数字，邮箱需包含 `@` 和 `.`；Repository 同时接受 5-20 位的本地 phone-like mock 账号或邮箱 |
| 登录防重复提交 | `isLoading` 为 true 时 `canSubmit` 返回 false |
| 登出行为 | `clearSession()` 清理 session，不清除 `accounts` |
| 会话失效 | `markSessionExpired()` 将 `isValid` 置 false |
| 本地持久化 | 使用 `AuthStoreDataSource` 接口 + 各平台实现；三端只读写由 KMP common 统一编解码的认证 JSON 快照 |
| 数据结构定义 | `auth_mock.proto` 是唯一字段契约；当前使用手工镜像的 Kotlin `Mock*` 模型与集中 JSON 编解码，不使用生成的 protobuf Message 类 |

## 与认证 Mock 规范的对应说明

- `common/src/commonMain/proto/auth_mock.proto` 定义账号、会话、验证码、资料和错误码 message；不含真实 token、接口或服务端数据。
- `MockAccount`、`MockAuthSession`、`MockVerifyCodeState`、`UserProfile` 分别对应同名 proto message；`MockAuthRegion` 通过 `toDomain()` / `toMockRegion()` 映射区域配置；`MockError` 通过 `toProtoMessage()` / `toMockError()` 映射本地错误场景；`AuthSession` 通过 `toDomainOrNull()` / `toMockSession()` 与 `MockAuthSession` 转换。
- `MockAuthStoreJson` 是 common 中唯一的认证 Store 快照编解码入口。字段采用 protobuf JSON 常用的 lowerCamelCase 命名：`user_id` 写为 `userId`，`current_session` 写为 `currentSession`；枚举写为 `.proto` 中的 `METRIC`、`IMPERIAL`、`MALE`、`FEMALE`。读取时兼容旧的 snake_case 快照，便于已有本地数据恢复。
- HarmonyOS bridge 不直接提供 protobuf JSON runtime，因此不在 ArkTS 层另写认证 JSON；Android、iOS、HarmonyOS 均只通过各自存储介质保存或恢复 common 输出的快照字符串。保存内容均包含账号库、当前会话、验证码、区域资料和失效状态。
- 业务 mock 不直接伪造用户状态，而是通过 `AuthRepository.verifyBusinessAccess()` 读取会话；无有效会话时返回本地 `AuthRequired`。

## 待确认问题

当前核心注册、登录、持久化、登出、失效和业务访问链路已覆盖。Proto 使用方式、手工 JSON 编解码与严格 protobuf runtime 的差异见 `docs/proto与domain model之间的关系.md`。

## 健康首页补充规则

- 首页底部固定为体能、记录、探索、我四个入口；体能为默认页，我复用当前登录后的退出和注销页面。
- 健康数据只使用本地脱敏 mock。支持正常、部分缺失、全空、异常值和读取失败场景。
- 展示顺序为风险提醒优先、今日数据优先、无数据降级；聚合规则由 KMP common 输出稳定 UI model，页面不拼接多源业务数据。

## 健康首页总览卡片 — 功能拆解

| 模块 | 说明 |
| --- | --- |
| Mock 数据源 | DailySummary（日摘要）、SleepSummary（睡眠摘要）、TrainingLoad（训练负荷）、Recovery（恢复状态）四种本地 mock 数据源，支持按场景切换数据内容 |
| 卡片类型 | 睡眠卡、今日运动卡、训练负荷卡、恢复状态卡、空态引导卡五种 |
| 卡片排序引擎 | 读取各数据源状态后，按有风险提醒优先、今日有数据优先、无数据降级的规则输出有序卡片列表 |
| UI Model 层 | 每张卡片统一输出 title（标题）、summary（摘要）、status（状态）、action（操作入口），Native UI 直接消费渲染 |
| Mock 场景切换 | 提供场景选择能力，支持正常、部分缺失、全空、异常值和读取失败五种场景 |
| 数据聚合层 | KMP common 层聚合多源 mock 数据，按规则输出稳定 DashboardUiState，Native UI 不直接拼接多源业务数据 |
| 未登录拦截 | 业务 mock 数据源通过 AuthRepository 读取当前登录态，未登录时返回 AuthRequired 错误 |

## 健康首页总览卡片 — 已确认规则

| 规则 | 内容 |
| --- | --- |
| 数据源类型 | 必须包含 DailySummary、SleepSummary、TrainingLoad、Recovery 四种 mock 数据源 |
| 卡片类型 | 必须实现睡眠、今日运动、训练负荷、恢复状态、空态引导五种卡片 |
| UI Model 结构 | 每张卡片必须输出 title、summary、status、action |
| 排序优先级 | 有风险提醒 > 今日有数据 > 无数据降级；优先级规则须可解释、可测试 |
| Mock 场景 | 必须支持正常（全量）、部分缺失（单种缺失）、全空（所有缺失）、异常值（如恢复分数异常）、读取失败五种 |
| 聚合规则位置 | 数据和排序聚合在 KMP common 层完成，输出稳定 UI model；Native UI 不拼接多源数据 |
| 验收标准 | 正常 / 空数据 / 部分数据 / 异常数据均可展示且不崩溃；卡片展示优先级可解释；业务规则层输出稳定 UI model |
| 测试覆盖 | 至少 12 条单元测试，必须覆盖全量数据、睡眠缺失、今日运动缺失、恢复状态异常、卡片排序 |
| 完成档位 — 基础 | 注册登录门禁通过 + 健康总览卡片可运行 + 业务 mock 数据源能验证未登录拦截 |
| 完成档位 — 标准 | 完成卡片聚合、排序、空态、错误态和本项目测试要求 |
| 完成档位 — 挑战 | 支持卡片配置、局部刷新、趋势摘要和可复用 dashboard state |

## 健康首页总览卡片 — 与 Mock 规范的对应说明

- `common/src/commonMain/proto/health_dashboard_mock.proto` 定义 DailySummaryMock、SleepSummaryMock、TrainingLoadMock、RecoveryMock、HealthDashboardMock 和 HealthDashboardSnapshotMock message；不含真实服务端字段或协议。
- Domain 模型 `DailySummary`、`SleepSummary`、`TrainingLoad`、`Recovery` 分别对应同名 proto message，通过 `toDomain()` / `toMock()` 双向映射。
- `HealthCardType`、`HealthCardStatus`、`HealthCardAction` 等枚举定义卡片分类和交互类型，不在 proto 中定义，属于 domain 层常量。
- `HealthDashboardSnapshotMock` 用于持久化保存用户场景选择和卡片配置，与 `HealthDashboardSnapshot` domain 模型对应。
- Proto 定义的数据字段均为 `optional`，天然支持缺失场景；domain 层通过 nullable 字段向下传递空状态。

## 健康首页总览卡片 — 待确认问题

- 风险提醒的具体触发标准：哪些数据条件（如恢复分数低于阈值、训练负荷过高）标记为 Risk 状态？
- 空态引导卡片的展示策略：当所有卡片无数据时只显示空态引导卡片，还是同时展示空态的各类卡片骨架？
- 卡片配置功能是否属于本次标准档范围，还是仅作为挑战档目标？
- 趋势摘要的展现形式和时间跨度（7 天 / 30 天）需确认产品方向。
- Mock 场景切换的 UI 入口位置：开发者菜单 / 设置页 / 首页长按？
