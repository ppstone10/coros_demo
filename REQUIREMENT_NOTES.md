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
