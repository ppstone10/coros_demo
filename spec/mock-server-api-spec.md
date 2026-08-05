# Mock 服务器接口与三端 HTTP 接入 Spec

## 元数据

- Spec ID 前缀：`MSRV`
- 状态：已采纳
- 负责人：实习培训项目
- 关联需求：README.md「关键边界」；`auth-mock-spec.md`；`health-dashboard-persistence.md`
- 最后更新：2026-08-05

## 目标

- 把三端本地孤立的 mock 数据改为“单一 Mock HTTP 服务器为权威源 + 三端通过 HTTP 做增删改查”。
- 认证与健康业务动作获得真实请求 → 响应 → 状态变化的完整流程，改善业务流程不完整的问题。
- 保持 `common` 同步架构与既有业务规则不变，HTTP 请求全部下沉到三端平台层实现。
- 保留本地持久化，但降级为“缓存/兜底”，服务器数据是唯一权威。
- 三端接入同一服务器后，同一账号在任一端产生的数据变更，其他端刷新可见。

## 非目标

- 不接入真实服务器、真实账号、真实健康数据、真实凭据或真实服务端样例。
- 不实现真实接口加密、签名、鉴权、token 刷新、网络拦截逻辑。
- 不把 HTTP 客户端（ktor/okhttp/URLSession/ohos http）放入 `commonMain`；`ohos_arm64` 目标无法编译 ktor 等常规 Kotlin/Native 库。
- 不做实时推送/长连接同步；数据一致只依赖“服务器权威 + 客户端刷新拉取”。
- 不改动 `common` 的业务规则、Store、Facade 与 `MockResult`/`MockError` 的既有语义；仅在必要时扩展错误码。
- 不要求 mock 服务器具备真实数据库或高可用；使用进程内存储 + JSON 文件落盘即可。

## 边界与约束

### 架构边界

- `common/src/commonMain` 只定义数据源抽象接口（`AuthStoreDataSource`、`HealthDashboardStateDataSource`、`AuthRepository`）与 JSON 编解码契约，不出现任何网络类型。
- 每个平台各自实现“远程数据源”，实现与本地数据源相同的同步接口，内部发起 HTTP 请求。
- 平台远程数据源必须保证同步接口被调用时不在 UI 线程做阻塞网络 I/O（Android 后台线程、iOS 后台队列、HarmonyOS 由 ArkTS 侧先完成 HTTP 再同步调用桥）。

### 安全与数据边界

- mock 服务器地址是本地调试配置，允许写入 `mock-server/` 工程内与三端 debug 配置；禁止写入真实服务地址、真实 token、真实密钥、真实账号或真实用户数据。
- 种子账号与验证码沿用 `LocalMockAuthRepository` 的既有 mock 约定（`13107012029` / `2232591785@qq.com` / `123456`，验证码 `1234`/`4321`）。
- 服务器端只保存 mock 数据，不实现真实鉴权；会话 token 为 mock 值。

### 兼容性边界

- Android 模拟器访问宿主机 mock server 使用 `10.0.2.2`；iOS 模拟器使用 `localhost`；HarmonyOS 真机/模拟器使用局域网 IP 或宿主机地址，按各端 debug 配置注入。
- 本地缓存 JSON 结构与现有 `MockAuthStoreJson` / `MockHealthDashboardStoreJson` 保持一致，服务器响应 JSON 使用相同字段契约（lowerCamelCase，遵循 proto JSON 命名规则）。

### 失败边界

- 网络不可达或服务器错误时，允许回退到本地缓存展示旧数据，并提示用户；写操作失败必须返回明确错误，不得假装成功。
- 服务器返回会话失效（401 类语义）时，映射到既有 `SessionExpired` 流程，三端引导重新登录。

## 数据与状态

| 名称 | 类型/结构 | 来源 | 生命周期 | 约束 |
|------|-----------|------|----------|------|
| 账号库 | `MockAuthStore.accounts` | mock server | 服务器进程内 + JSON 落盘 | 按 `userId` 唯一；JSON 遵循 `auth_mock.proto` 契约 |
| 会话 | `AuthSession`（mock token） | mock server 登录/注册签发 | 服务器持有 + 客户端本地缓存 TTL | 客户端冷启动懒校验，不强制每次启动打网络 |
| 验证码 | `MockVerifyCodeState` | mock server 生成 | 服务器短时持有，60s TTL | 沿用固定验证码 `1234`/`4321` |
| 健康快照 | `HealthDashboardSnapshot` | mock server（按 `userId`） | 服务器持有 + 客户端本地缓存 | JSON 遵循 `health_dashboard_mock.proto` 契约 |
| base URL | 字符串 | 各端 debug 配置 | 进程内注入 | 平台层注入，不写入 `commonMain` |
| 错误码 | `MockError` / HTTP 状态码 | mock server + 客户端映射 | 每次请求 | HTTP 状态码映射到既有 `MockError` 语义 |

### 接口清单

认证域逐业务接口（对应 `LocalMockAuthRepository` 的方法）：

| 方法 | 路径 | 作用 | 对应既有逻辑 |
|---|---|---|---|
| POST | `/api/auth/regions` | 获取注册区域 | `availableRegions()` |
| POST | `/api/auth/verify-code` | 发送验证码（服务器生成/存储） | `requestVerifyCode()` |
| POST | `/api/auth/verify-code/check` | 校验验证码（注册前 UX 预检查） | `verifyCode()` |
| GET | `/api/auth/account?account=` | 判断账号是否已存在（UX 预检查） | `hasAccount()` |
| POST | `/api/auth/register` | 注册 | `register()` |
| POST | `/api/auth/login` | 登录，签发会话 | `login()` |
| GET | `/api/auth/session` | 冷启动懒校验会话 | `restoreSessionOnColdStart()` |
| POST | `/api/auth/logout` | 登出 | `clearSession()` |
| PUT | `/api/auth/profile` | 更新资料 | `saveProfile()` |
| POST | `/api/auth/password/change` | 修改密码 | `changePassword()` |
| POST | `/api/auth/password/reset` | 重置密码 | `resetPassword()` |
| DELETE | `/api/auth/account` | 注销（级联删除健康数据） | `deleteCurrentAccount()` |

健康域整文档接口：

| 方法 | 路径 | 作用 | 对应既有逻辑 |
|---|---|---|---|
| GET | `/api/health/{userId}` | 拉取健康快照 | `HealthDashboardStateDataSource.load` |
| PUT | `/api/health/{userId}` | 提交健康快照 | `HealthDashboardStateDataSource.save` |
| GET | `/api/health/{userId}/scenario` | 场景选择（服务器种子） | `HealthDashboardStore.selectScenario` |

HarmonyOS 快照同步接口（MSRV-008：ArkTS 侧经 `ohos.net.http` 读写整份文档，经 KNOI snapshot 入口同步给 KMP）：

| 方法 | 路径 | 作用 | 说明 |
|---|---|---|---|
| GET | `/api/sync/auth` | 拉取权威认证 store 文档 | 返回 `{ "store": <MockAuthStore JSON> }` |
| PUT | `/api/sync/auth` | 提交认证 store 文档 | 请求体为 `MockAuthStore JSON` |
| GET | `/api/sync/health` | 拉取权威健康快照集合 | 返回 `{ "snapshots": [ <HealthDashboardSnapshot> ... ] }` |
| PUT | `/api/sync/health` | 提交健康快照集合 | 请求体为 `{ "snapshots": [...] }` |

## 行为规范

### `MSRV-001`：Mock 服务器是唯一权威数据源

- Given：mock 服务器已启动，并拥有种子账号与健康场景
- When：三端任一客户端发起认证或健康读写请求
- Then：服务器返回当前权威数据，客户端以服务器响应为准
- 异常/边界：服务器不可达时客户端回退本地缓存；写操作失败时展示错误并保留本地状态

### `MSRV-002`：HTTP 请求只位于三端平台层

- Given：`commonMain` 中的接口与业务逻辑
- When：需要发起 HTTP 请求
- Then：请求只在 Android/iOS/HarmonyOS 的远程数据源实现中发起，`commonMain` 不出现网络类型或 HTTP 客户端
- 异常/边界：`ohos_arm64` 目标不引入 ktor/普通 Kotlin/Native 网络库；HarmonyOS 的 HTTP 在 ArkTS 侧使用 `ohos.net.http`

### `MSRV-003`：认证按业务逐接口请求

- Given：用户执行注册、登录、验证码、改密、重置密码、改资料或注销
- When：客户端调用 `AuthRepository` 对应方法
- Then：平台远程数据源发起对应 HTTP 请求，把服务器响应映射为 `MockResult<T>` 返回
- 异常/边界：账号不存在、密码错误、验证码错误、账号已存在、注册区域缺失等场景由服务器返回，客户端映射到既有 `MockError`

### `MSRV-004`：健康快照按 `userId` 整文档读写

- Given：用户已登录
- When：健康首页刷新或编辑保存提交
- Then：客户端 GET/PUT `/api/health/{userId}` 整份快照 JSON，服务器按 `userId` 隔离存储
- 异常/边界：读失败（`ReadFailure`）映射到既有 `MockError.CorruptedData`，保留最后有效快照

### `MSRV-005`：HTTP 状态码映射到既有错误语义

- Given：服务器返回任意 HTTP 响应
- When：客户端远程数据源解析响应
- Then：非 2xx 状态码映射到 `MockError` 语义（如 `AuthRequired`、`AccountNotFound`、`PersistFailed`），网络不可达映射为新增的网络错误
- 异常/边界：`MockError` 需补充网络类枚举时，同步三端错误文案键与资源

### `MSRV-006`：会话由服务器签发，客户端冷启动惰性校验

- Given：登录/注册成功后服务器签发会话
- When：App 冷启动恢复会话
- Then：客户端先按本地缓存 TTL 判断，仅在必要时调用 `GET /api/auth/session` 校验；校验失败映射到既有 `SessionExpired` 流程
- 异常/边界：离线冷启动时允许以本地缓存会话进入，后续写操作失败再提示

### `MSRV-007`：三端 base URL 为平台注入配置

- Given：三端各自的 debug/运行环境
- When：构造远程数据源
- Then：base URL 从平台配置注入（Android `10.0.2.2`、iOS `localhost`、HarmonyOS 局域网地址），不写入 `commonMain`
- 异常/边界：未配置或非法地址时明确报错，不静默使用默认地址

### `MSRV-007-PORT`：mock server 数据按端口隔离

- Given：同一台机器可能同时运行多个 mock server 实例（不同端口）
- When：实例启动
- Then：每个端口实例使用独立持久化文件 `data/mock-server-store-{PORT}.json`（可用 `DATA_FILE` 覆盖），互不覆盖其他实例数据
- 异常/边界：未指定 PORT 时默认 3000；测试与运行时实例使用不同数据文件，绝不互相污染

### `MSRV-008`：HarmonyOS 通过 ArkTS 侧 HTTP 复用 KNOI 快照入口

- Given：HarmonyOS 需要与服务器通信
- When：发起认证或健康读写
- Then：ArkTS 使用 `ohos.net.http` 完成请求，把返回 JSON 通过既有 `restoreStoreSnapshot` / `restoreHealthSnapshot` 入口同步给 KMP，导出时用 `exportStoreSnapshot` / `exportHealthSnapshot` 取 JSON 再 PUT
- 异常/边界：KNOI 桥契约为零变化；不在 bridge 内实现网络请求

### `MSRV-008-SYNC`：快照同步按用户合并，不整体覆盖其他端数据

- Given：Android/iOS 已在服务器写入某用户健康快照与账号，HarmonyOS 随后做快照同步
- When：`PUT /api/sync/health` 提交健康快照集合、`PUT /api/sync/auth` 提交 store 文档
- Then：健康快照**逐条按 userId upsert**（只更新/新增传入的用户，保留服务器上其他用户快照，不 replaceAll）；认证 store 只更新 `currentSession.userId` 对应的账号与会话，不遍历覆盖账号库中其他用户
- When：HarmonyOS 冷启动未登录（本地无 userId）执行 `syncFromServer`
- Then：跳过认证 store 拉取（不向服务器发空 userId 查询，也不用空 store 覆盖本地），健康快照仍可全量拉取合并
- 异常/边界：`accounts` 为空或账号缺 `userId` 返回 `INVALID_PARAM`；健康快照缺 `userId` 的条目忽略

### `MSRV-009`：本地持久化降级为缓存兜底

- Given：客户端已有本地缓存
- When：启动、进入页面或刷新
- Then：先展示本地缓存，再于后台发起 GET 刷新；服务器数据到达后覆盖缓存与展示
- 异常/边界：写操作只在服务器确认成功后更新本地缓存；服务器不可达时展示旧缓存并提示

### `MSRV-010`：三端数据一致靠服务器权威 + 刷新拉取

- Given：同一账号在三端登录
- When：A 端修改数据成功后
- Then：B/C 端执行刷新或重新进入页面时通过 GET 拿到 A 端写入的新数据
- 异常/边界：不做实时推送；数据一致性以“最近一次成功 GET”为准

### `MSRV-011`：服务器不可达或写失败时展示明确错误

- Given：网络中断、超时或服务器返回错误
- When：客户端执行认证或健康操作
- Then：展示与既有错误一致的语义提示，读操作回退缓存，写操作不假装成功
- 异常/边界：错误提示键与文案遵循三端资源门禁

### `MSRV-012`：种子数据与场景模板由服务器提供

- Given：mock 服务器首次启动或重置
- When：服务器初始化
- Then：载入 `LocalMockAuthRepository` 既有种子账号与 5 个健康场景模板，客户端不再本地生成场景数据
- 异常/边界：服务器种子缺失时返回明确错误，不允许客户端伪造权威数据

### `MSRV-013`：服务器不包含任何真实凭据或敏感信息

- Given：mock 服务器代码与落盘数据
- When：代码审查与门禁检查
- Then：不出现真实 base url、真实 token、真实密钥、真实账号或真实用户数据
- 异常/边界：仅允许本项目 demo 种子账号与 mock 值

### `MSRV-014`：`/api/sync/auth` 遍历全部账号 upsert，会话按 userId 匹配

- Given：HarmonyOS 推送整份 store 快照（accounts 数组可包含多个账号）
- When：`PUT /api/sync/auth` 接收快照
- Then：逐账号 upsert（存在更新、缺失新增），会话仅在与该 userId 匹配且 `isValid` 时保存
- 异常/边界：`accounts` 为空或账号缺 `userId` 时返回 `INVALID_PARAM`；`buildUserId` 与 common `LocalMockAuthRepository` 完全一致（Int32 环绕），避免科学计数法导致查询失效

### `MSRV-015`：头像以真实图片文件存储于 mock server，avatarUri 存相对路径

- Given：用户选择或拍摄头像
- When：任一端保存头像
- Then：客户端把图像字节（缩放 + JPEG）`PUT /api/avatar/{userId}` 到 mock server，服务器以二进制文件落盘 `data/avatars/{userId}.jpg`；`UserProfile.avatarUri` 存**相对路径** `/api/avatar/{userId}`，随 store 同步；各端展示时用自身 base URL + 相对路径拉取图片
- 异常/边界：`GET /api/avatar/{userId}` 文件不存在返回 404；注销账号时级联删除头像文件；非 `/api/avatar/` 前缀的旧值（data URI / 本地路径 / UserDefaults key）在展示端回退兼容，不强制迁移

mock server 头像接口：

| 方法 | 路径 | 作用 |
|---|---|---|
| PUT | `/api/avatar/:userId` | 上传头像图片二进制（缩放后 JPEG），落盘 `data/avatars/{userId}.jpg` |
| GET | `/api/avatar/:userId` | 拉取头像图片二进制 |
| DELETE | `/api/avatar/:userId` | 删除头像文件（注销账号级联） |

## 测试要求

| Spec ID | 自动化测试/人工验收 | 预期结果 |
|---------|---------------------|----------|
| `MSRV-001` | mock server 契约测试（Node test 或 shell 脚本） | 登录/健康 GET 返回服务器权威数据 |
| `MSRV-002` | 三端构建 + 结构门禁 | `commonMain` 无网络类型，三端远程数据源就位 |
| `MSRV-003` | 认证逐接口契约测试（注册/登录/验证码/改密/重置/资料/注销） | 每接口成功与错误路径返回预期 |
| `MSRV-004` | 健康快照 GET/PUT 契约测试 + 多用户隔离测试 | 按 `userId` 读写隔离正确 |
| `MSRV-005` | 错误映射测试 | HTTP 状态码 → `MockError` 映射正确 |
| `MSRV-006` | 会话签发与懒校验测试 | 登录签发、冷启动懒校验、失效映射正确 |
| `MSRV-007` | 三端 base URL 注入验证 | 各端使用各自配置地址 |
| `MSRV-008` | HarmonyOS 构建 + KNOI 契约 diff | provider.ets 无契约变化，HTTP 在 ArkTS 侧 |
| `MSRV-009` | 缓存回退测试 + 三端运行验收 | 断网展示旧缓存，恢复后刷新 |
| `MSRV-010` | 三端交叉验收 | A 端改数据，B/C 端刷新可见 |
| `MSRV-011` | 错误提示测试 | 网络/写失败时提示语义正确 |
| `MSRV-012` | 服务器种子测试 | 种子账号与场景可重置恢复 |
| `MSRV-013` | 代码审查 + 门禁扫描 | 无真实凭据落库 |

实现顺序建议：先实现 mock server 与契约测试（MSRV-001/003/004/012）→ 三端远程数据源（MSRV-002/007/008）→ 缓存与会话（MSRV-005/006/009）→ 联调验收（MSRV-010/011/013）。每步按 SDD 流程：先写测试红灯，再实现转绿，更新 TRACE。

## 验收标准

- [ ] `mock-server/` 工程可独立启动，契约测试通过。
- [ ] 三端通过 HTTP 完成认证增删改查，服务器为唯一权威源。
- [ ] 健康数据按 `userId` 整文档读写，三端同一账号数据互通。
- [ ] `commonMain` 无网络依赖，既有 common 测试不受影响。
- [ ] 本地缓存降级为兜底，断网可展示旧数据并提示。
- [ ] 会话失效/网络错误映射到既有语义与三端文案。
- [ ] KNOI 桥契约无变化，HarmonyOS 走 ArkTS 侧 HTTP。
- [ ] 无真实凭据/地址/token 落库。
- [ ] `spec/TRACE.md` 完成 MSRV 映射并记录真实验证证据。
- [ ] `Codex_worklog.md` 记录本轮真实时间与四段事实。

## 待人工确认

- mock server 技术栈最终选择（建议 Node.js + Express；如需 Python/Java 请负责人确认）。
- 会话校验粒度：冷启动是否每次打 `GET /api/auth/session`，还是仅本地 TTL + 写操作时校验。
- HarmonyOS 开发环境无在线设备，最终三端联调需在设备/模拟器人工验收。
- 服务器落盘目录（`.gitignore` 内 mock 数据文件）与重置方式需在实现轮明确。
