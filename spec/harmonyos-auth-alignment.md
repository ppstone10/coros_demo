# 鸿蒙端认证与数据接入对齐 Android/iOS Spec

## 元数据

- Spec ID 前缀：`HARM`
- 状态：已采纳
- 负责人：实习培训项目
- 关联需求：`mock-server-api-spec.md`（MSRV-008/016/018/019）；`auth-mock-spec.md`；`health-dashboard-persistence.md`
- 最后更新：2026-08-07

## 目标

- 把鸿蒙端（HarmonyOS）从"本地校验 + 整文档快照同步"模型收敛为与 Android/iOS 一致的**服务器校验 + 设备标识 + 逐接口 + 会话懒校验**模型。
- 鸿蒙端参与"微信模式顶号 + 二次确认"（MSRV-016）：鸿蒙登录可顶掉其他设备会话，其他设备登录也能把鸿蒙挤下线并弹出被顶确认。
- 鸿蒙端健康数据与 Android/iOS 互通：同一账号任一端写入，鸿蒙刷新/回前台可见；鸿蒙写入他端可见（MSRV-010）。
- **不修改 Android/iOS 端正常功能**：`androidApp/`、`iosApp/` 与 `common` 业务代码零改动；允许对 `common` 做纯增量（带默认值）但本轮不引入。

## 非目标

- 不引入 KNOI 桥同步 HTTP：受 `ohos_arm64` 无 kotlinx-serialization JSON Native 变体、KNOI 桥同步调用限制，HTTP 仍只在 ArkTS 侧 `ohos.net.http`（LEARNINGS #40/#96）。
- 不做实时推送/长连接同步；一致性仍靠"服务器权威 + 客户端刷新拉取"（MSRV-010）。
- 不改变 `mock-server/src/*` 行为；服务器已有能力全部复用。
- 不重写鸿蒙健康视觉组件或 KNOI 契约外的新通道。

## 边界与约束

### 架构边界

- 登录/注册/会话/资料等认证动作由 ArkTS 侧先向服务器发起 HTTP（镜像 Android `RemoteAuthRepository`），再把服务器结果经 KNOI 桥新增的 **staging 槽位**喂给既有 `LoginStore` 状态机，最终状态/effect 仍由 KMP 产出。
- `common` 的 `LoginStore`/`LoginFacade`/`AuthRepository` 接口语义不变；桥新增 `HarmonyRemoteAuthRepository`（ohosArm64Main Kotlin）实现 `AuthRepository`，对 `login`/`register`/`resumeSessionInSameProcess`/`restoreSessionOnColdStart` 在消费 staging 槽位后短路，其余委托本地仓库。
- 设备标识 `deviceId` 不进 common：与 Android/iOS 一致，设备匹配由"每个请求的 `X-Device-Id`/body deviceId vs 服务器会话 deviceId"完成；鸿蒙用持久化的 `HarmonyDeviceId`（`harmony-<UUID>`）。
- 健康数据读写统一 `GET/PUT /api/health/:userId`（MSRV-004）；`/api/sync/*` 仅保留为冷启动兜底与未登录账号发现（MSRV-018 例外）。

### 失败边界

- 网络不可达：登录/写操作展示错误，不本地伪装成功；会话懒校验网络失败沿用本地会话，不误登出。
- 服务器会话失效（`AUTH_REQUIRED`）或已被顶（`SESSION_EXPIRED_ELSEWHERE`）：分别映射既有 `SessionExpired`/`SessionKicked` 流程。
- 本地验证码/密码校验降级为兜底，仅在服务器不可达时使用；服务器结果优先。

## 数据与状态

| 名称 | 来源 | 说明 |
|------|------|------|
| `deviceId` | 鸿蒙 preferences（`harmony-<UUID>`） | 每个请求发送；同一账号同一设备重复登录不触发顶号冲突 |
| 服务器会话 | `POST /api/auth/login` | 服务器签发，含 deviceId/deviceName；本地缓存仅作离线兜底 |
| 二次确认 | `LoginState.confirmForceLogin` + `forceLoginActiveDevice` | 409 时由 KMP 状态机置真，ArkUI 渲染"挤下线"弹窗 |
| 被顶弹窗 | `LoginState.kickedDialogShown` | 服务器懒校验命中 `SESSION_EXPIRED_ELSEWHERE` 时置真 |
| 健康快照 | `GET/PUT /api/health/:userId` | 按 userId 整文档；本地 prefs 缓存兜底 |

## 行为规范

### `HARM-001`：鸿蒙全请求携带设备标识

- Given：鸿蒙任一端发起任意 mock server HTTP 请求
- When：请求发出
- Then：请求头携带 `X-Device-Id: <harmony-<UUID>>`；登录/注册 body 同时带 `deviceId`（与 Android `MockServerHttpClient`/`RemoteAuthRepository` 对齐）
- 异常/边界：设备标识来自 `HarmonyDeviceId`（preferences 持久化，首次生成并落盘）

### `HARM-002`：鸿蒙登录走服务器并支持二次确认

- Given：用户提交登录（登录模式）
- When：`KnoiLoginAdapter.submit` 进入登录分支
- Then：先 `POST /api/auth/login {account,password,deviceId,force:false}`（不本地先验）
- 分支：
  - 200 → 服务器会话经 `stageServerLoginResult` 入 staging，再 `submit()` 走 KMP 状态机成功
  - 409 `SESSION_ACTIVE_ELSEWHERE` → `stageForceLogin(activeDevice)` 入 staging，再 `submit()` → 状态机产出 `confirmForceLogin=true` + `ShowForceLoginDialog`
  - 其余错误 → `stageServerError(code,message)` 入 staging，再 `submit()` → 状态机产出错误提示
- 用户确认挤下线：先 `POST /api/auth/login` `force:true` 顶号，成功后 `stageServerLoginResult` + `confirmForceLogin()`；取消则 `clearStaged()` + `cancelForceLogin()`
- 异常/边界：网络失败展示错误，不本地登录成功

### `HARM-003`：鸿蒙注册走服务器

- Given：用户提交注册（注册模式）
- When：`KnoiLoginAdapter.submit` 进入注册分支
- Then：先 `POST /api/auth/register`（含 `deviceId`）；成功后 `stageServerLoginResult(会话)` 入 staging，再 `submit()` → `HarmonyRemoteAuthRepository.register` 短路为成功并本地落账号/会话
- 异常/边界：服务器返回错误（`ACCOUNT_EXISTS`/`VERIFY_CODE_INVALID` 等）经 staging 短路为对应错误提示；验证码请求也先发服务器

### `HARM-004`：鸿蒙会话懒校验三态对齐 MSRV-019

- Given：冷启动恢复或回前台，且本地存在会话
- When：触发 `GET /api/auth/session?userId=&deviceId=`
- Then：
  - 200 有效 → 保持本地会话
  - 401 `AUTH_REQUIRED` → `stageSessionExpired` 后走本地恢复 → `SessionExpired` 流程
  - 401 `SESSION_EXPIRED_ELSEWHERE` → `onSessionKicked()` → `kickedDialogShown=true` → 确认后清会话回登录页
  - 网络失败 → 沿用本地会话（不登出）
- 异常/边界：`SignedInPage` 3s 前台 timer 与 `EntryAbility.onForeground` 均接入；被顶处理幂等防重入

### `HARM-005`：鸿蒙登出/资料/改密/重置/注销走服务器

- Given：用户登出、保存资料、修改密码、重置密码或注销账号
- When：触发对应动作
- Then：
  - 登出先 `POST /api/auth/logout {userId}` 再本地清会话；
  - 保存资料在 KMP `submitProfile` 本地提交后**尽力异步** `PUT /api/auth/profile`（同步接口签名约束下不与 UI 交互阻塞）；
  - 修改密码/重置密码**尽力异步** `POST /api/auth/password/change|reset`（本地与服务器同算法，正常路径结果一致）；
  - 注销先捕获 userId 再**尽力异步** `DELETE /api/auth/account` 后本地删除
- 异常/边界：登出服务器失败仍本地登出；服务器写失败保留本地状态并记录日志，不做虚假成功

### `HARM-006`：鸿蒙健康数据按 userId 整文档读写

- Given：用户已登录
- When：健康首页刷新、回前台或编辑保存
- Then：GET/PUT `/api/health/:userId`（携带 `X-Device-Id`），替换原先失效的 `/api/sync/health` 无参拉取；失败回退本地 prefs 缓存
- 异常/边界：401 `SESSION_EXPIRED_ELSEWHERE` 时触发被顶处理，不弹窗循环

### `HARM-007`：消除"每次同步失败弹被顶"循环

- Given：`syncFromServer`/`syncToServer` 网络或鉴权失败
- When：请求返回非 2xx
- Then：静默降级本地缓存，**不得**在同步失败路径触发被顶弹窗；被顶只由显式会话懒校验或健康读写 401 触发，且**同一被顶事件幂等只通知一次**（`kickNotified` 守卫），健康同步成功后续复位
- 异常/边界：写失败保留本地状态，下次同步补偿；`handleSessionKicked` 不持久化（避免 persist → syncToServer → 401 → 通知 → 再 persist 的级联循环）

### `HARM-008`：KNOI staging 槽位生命周期

- Given：`HarmonyRemoteAuthRepository` 持有 staging 槽位
- When：`login`/`register`/`resumeSessionInSameProcess`/`restoreSessionOnColdStart` 被调用
- Then：只消费一次对应槽位；消费后立即清空；`cancelForceLogin`/`clearStaged` 显式清空；槽位不影响其他方法
- 异常/边界：staging 空时完全委托本地仓库（行为与现状一致）

### `HARM-009`：被顶后不可用服务器持久会话"复活"登录态

- Given：本地会话已被 TTL 清除或已登出
- When：后续同步/懒校验命中服务器有效会话
- Then：本地保持登出态，不自动恢复（本地为登录态兜底权威，LEARNINGS #41）

### `HARM-010`：被顶/二次确认弹窗样式与导航

- Given：被顶弹窗（`KickedDialog`）或二次确认弹窗（`ForceLoginDialog`）展示
- When：弹窗展示或用户操作
- Then：
  - 弹窗为**居中紧凑卡片**（固定宽度如 300vp），不占满全屏、背景为半透明遮罩；
  - 被顶弹窗确认后：清会话并消费 `SessionKicked` effect 触发跳转登录页（不得停留在首页）；
  - 新成功登录**清除残留被顶弹窗状态**（`LoginStore` 成功分支复位 `kickedDialogShown`），避免登录成功后首页仍弹"已在其他设备登录"
- 异常/边界：`kickNotified` 幂等守卫保证同一被顶事件只弹一次；确认导航与前台 3s timer 不重入

## 测试要求

| Spec ID | 自动化测试/人工验收 | 预期结果 |
|---------|---------------------|----------|
| `HARM-001` | `tools/check-harmony-auth-alignment.sh` 结构门禁；`mock-server` 契约测试带 deviceId 用例 | 鸿蒙请求必带设备标识 |
| `HARM-002` | 结构门禁；mock-server 契约测试（409→force 顶号→被顶 401）；鸿蒙构建 + 设备人工验收 | 登录 200/409/错误三分支正确；二次确认 UI 可操作 |
| `HARM-003` | 结构门禁；契约测试注册含 deviceId；构建 | 注册走服务器并本地落账号 |
| `HARM-004` | 结构门禁；契约测试 session 三态；构建 | 冷启动/回前台三态正确，被顶弹窗一次 |
| `HARM-005` | 结构门禁；构建 | 登出/资料写服务器 |
| `HARM-006` | 结构门禁；契约测试 `/api/health/:userId`；三端交叉人工验收 | 鸿蒙健康数据与他端互通 |
| `HARM-007` | 结构门禁（禁止同步路径弹窗） | 无弹窗循环/闪退 |
| `HARM-008` | 结构门禁 + 代码审查 | staging 槽位只消费一次 |
| `HARM-009` | 代码审查 + 人工验收 | 不复活登录态 |

## 验收标准

- [ ] 鸿蒙任意请求携带 `X-Device-Id`；同设备重复登录不触发 409，异设备登录触发二次确认。
- [ ] 鸿蒙登录/注册/登出/资料/会话懒校验全部走服务器，状态机行为与 Android/iOS 一致。
- [ ] 鸿蒙健康数据按 userId 与 Android/iOS 互通；被顶不再弹窗循环、不再闪退。
- [ ] `androidApp`/`iosApp`/`common` 业务代码零改动；`./gradlew :common:check` 全绿。
- [ ] `./tools/build-shared-harmony.sh` + `hvigorw assembleApp` 构建通过；`provider.ets` diff 仅含新增 staging 方法。
- [ ] `./tools/check-sdd.sh` 通过；TRACE 无未说明的 `⏳`；Worklog 记录真实时间与验证。
- [ ] 设备交互（顶号、被顶弹窗、二次确认）因无在线鸿蒙设备按 ⚠️ 债务跟踪，真机验收后转 ✅。

## 待人工确认

- 无在线鸿蒙设备：`HARM-002/004/006` 的设备交互验证需真机/模拟器人工验收（按单平台债务跟踪，TRACE 标注）。
- 服务器"未登录账号发现"接口（`GET /api/sync/auth` 不带 userId 返回含 passwordHash 全部账号）仅 mock 用途，保留（MSRV-018 例外）。
