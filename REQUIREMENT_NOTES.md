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
| 业务数据访问 | 所有业务 mock 数据源从 `AuthRepository.currentSession()` 获取登录态 |
| 本地状态保存 | 账号库、登录态、验证码状态在 App 重启后可恢复 |

## 已确认规则

| 规则 | 内容 |
| --- | --- |
| 注册区域 | CN（默认）、US |
| 验证码 | 默认正确码 `1234`，重发码 `4321`，有效期 60s |
| 密码规则 | 6-20 位，须包含字母和数字 |
| 账号格式 | 手机号（5-20 位纯数字或 `+-`）或邮箱（含 `@` 和 `.`） |
| 登录防重复提交 | `isLoading` 为 true 时 `canSubmit` 返回 false |
| 登出行为 | `clearSession()` 清理 session，不清除 `accounts` |
| 会话失效 | `markSessionExpired()` 将 `isValid` 置 false |
| 本地持久化 | 使用 `AuthStoreDataSource` 接口 + 各平台实现（Android SharedPrefs / iOS JSON / HarmonyOS StorePersister） |
| 数据结构定义 | `auth_mock.proto` 定义 mock 数据字段结构，KMP 使用手动映射 `toDomainOrNull()`/`toMockSession()` |

## 待确认问题

无。当前实现已覆盖 spec 全部要求。
