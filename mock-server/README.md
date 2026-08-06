# Mock 服务器（mock-server）

Demo 项目三端共享的 Mock HTTP 服务器。契约见 `spec/mock-server-api-spec.md`。

## 技术栈

- Node.js（>= 18）+ Express 4
- 数据：进程内内存（权威）+ 按端口目录拆分文件落盘（已 gitignore），见下"数据布局"

## 启动

```bash
npm install
npm start        # 默认 http://0.0.0.0:3000，可用 PORT/HOST 环境变量覆盖
```

## 数据布局（MSRV-020/021）

按端口目录隔离，每个实例独立：

```text
data/{PORT}/accounts.json          # accounts + sessions(per-account 集合) + verifyCodes + 种子标记
data/{PORT}/health/{userId}.json   # 每账号一个健康快照文件（缺失=空快照）
data/{PORT}/avatars/{userId}.jpg   # 头像二进制文件
```

- 写操作统一"临时文件 + rename"原子落盘（`MSRV-021`），进程崩溃不产生半写文件。
- 启动时若检测到旧版单文件 `data/mock-server-store-{PORT}.json`，会**一次性迁移**到新布局后删除旧文件。
- 可用 `DATA_DIR` 环境变量覆盖数据根目录（默认 `mock-server/data/`）。

## 测试

```bash
npm test         # 契约测试（node:test + fetch，43 条）与 store 层测试（布局/迁移/原子写）
```

## 单设备登录与多账号并存（MSRV-016/017）

- 同一账号同时只允许一台设备在线；不同账号可在多设备并存。
- 登录/注册 body 携带 `deviceId`（建议同时带 `deviceName` 供提示文案）。
- 非 `force` 登录遇有效异地会话：返回 409 `SESSION_ACTIVE_ELSEWHERE`（含 `activeDevice`），客户端弹二次确认。
- 用户确认后以 `force: true` 重发登录：服务端顶掉旧会话，被顶设备后续请求返回 401 `SESSION_EXPIRED_ELSEWHERE`。
- 未携带 `deviceId` 的旧客户端统一视为 `device-default`（向后兼容）。

## 接口总览

### 认证域

| 方法 | 路径 | 作用 |
|---|---|---|
| POST | `/api/auth/regions` | 注册区域列表（CN 默认 / US） |
| POST | `/api/auth/verify-code` | 发送验证码（固定 `1234`，重发 `4321`，TTL 60s） |
| POST | `/api/auth/register` | 注册并签发会话（body 含 `deviceId`/`deviceName`） |
| POST | `/api/auth/login` | 登录并签发会话；`deviceId`+`force` 实现单设备顶号 |
| GET | `/api/auth/session?userId=&deviceId=` | 会话懒校验（被顶返回 `SESSION_EXPIRED_ELSEWHERE`） |
| POST | `/api/auth/logout` | 登出（按 `userId`+`deviceId` 作用域化，只清本账号） |
| PUT | `/api/auth/profile` | 更新资料 |
| POST | `/api/auth/password/change` | 修改密码 |
| POST | `/api/auth/password/reset` | 重置密码 |
| DELETE | `/api/auth/account` | 注销（级联删除健康数据与头像） |

### 健康域

| 方法 | 路径 | 作用 |
|---|---|---|
| GET | `/api/health/:userId` | 拉取健康快照 |
| PUT | `/api/health/:userId` | 提交健康快照 |
| GET | `/api/health/:userId/scenario` | 场景选择 |
| GET | `/api/sync/auth?userId=` | 拉取认证 store 快照（HarmonyOS，MSRV-008） |
| PUT | `/api/sync/auth` | 提交认证 store 快照（HarmonyOS，MSRV-008） |
| GET | `/api/sync/health?userId=` | 拉取健康快照集合（HarmonyOS，MSRV-008） |
| PUT | `/api/sync/health?userId=` | 提交健康快照集合（HarmonyOS，MSRV-008） |
| PUT | `/api/avatar/:userId` | 上传头像图片二进制（缩放后 JPEG） |
| GET | `/api/avatar/:userId` | 拉取头像图片二进制 |
| DELETE | `/api/avatar/:userId` | 删除头像文件（注销账号级联） |

> 健康/头像/sync 接口需要持有该 userId 的**有效会话**（`MSRV-018`，可通过 `X-Device-Id` 请求头携带设备标识）；头像 GET 因原生图片加载器无法携带设备头，仅校验会话有效性。

## 种子账号

- `13107012029` / `123456`（userId：`mock-user-default`）
- `2232591785@qq.com` / `123456`（userId：`mock-user-default-email`）

## 错误约定

统一响应体：`{ "error": { "code": "<CODE>", "message": "<文案>" } }`。

HTTP 状态码与代码映射（`MSRV-005`）：

| HTTP | CODE |
|---|---|
| 400 | `INVALID_PARAM` / `VERIFY_CODE_INVALID` / `VERIFY_CODE_EXPIRED` / `REGION_REQUIRED` / `NEW_PASSWORD_SAME_AS_OLD` |
| 401 | `AUTH_REQUIRED` / `PASSWORD_INCORRECT` / `SESSION_EXPIRED_ELSEWHERE` |
| 404 | `ACCOUNT_NOT_FOUND` / `EMPTY_DATA` |
| 409 | `ACCOUNT_EXISTS` / `SESSION_ACTIVE_ELSEWHERE` |
| 500 | `CORRUPTED_DATA` / `PERSIST_FAILED` |

## 三端 base URL

- Android 模拟器访问宿主机：`http://10.0.2.2:3000`
- iOS 模拟器：`http://localhost:3000`
- HarmonyOS 真机/模拟器：**宿主机局域网 IP** `http://<host-ip>:3000`（不能使用 `10.0.2.2`）；运行前把 `harmonyApp/entry/src/main/ets/core/bridge/MockServerSync.ets` 中的 `MOCK_SERVER_BASE_URL` 改为本机局域网 IP（如 `192.168.x.x`），并确保 mock server 以 `HOST=0.0.0.0`（默认）监听。
