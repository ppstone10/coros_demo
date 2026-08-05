# Mock 服务器（mock-server）

Demo 项目三端共享的 Mock HTTP 服务器。契约见 `spec/mock-server-api-spec.md`。

## 技术栈

- Node.js（>= 18）+ Express 4
- 数据：进程内内存 + `data/mock-server-store.json` 落盘（已 gitignore）

## 启动

```bash
npm install
npm start        # 默认 http://0.0.0.0:3000，可用 PORT/HOST 环境变量覆盖
```

数据按端口隔离：每个端口实例使用独立持久化文件 `data/mock-server-store-{PORT}.json`，多实例互不覆盖。可用 `DATA_FILE` 环境变量指定文件名。

## 测试

```bash
npm test         # 契约测试（node:test + fetch，MSRV-001/003/004/012）
```

## 接口总览

### 认证域

| 方法 | 路径 | 作用 |
|---|---|---|
| POST | `/api/auth/regions` | 注册区域列表（CN 默认 / US） |
| POST | `/api/auth/verify-code` | 发送验证码（固定 `1234`，重发 `4321`，TTL 60s） |
| POST | `/api/auth/register` | 注册并签发会话 |
| POST | `/api/auth/login` | 登录并签发会话 |
| GET | `/api/auth/session?userId=` | 会话懒校验 |
| POST | `/api/auth/logout` | 登出 |
| PUT | `/api/auth/profile` | 更新资料 |
| POST | `/api/auth/password/change` | 修改密码 |
| POST | `/api/auth/password/reset` | 重置密码 |
| DELETE | `/api/auth/account` | 注销（级联删除健康数据） |

### 健康域

| 方法 | 路径 | 作用 |
|---|---|---|
| GET | `/api/health/:userId` | 拉取健康快照 |
| PUT | `/api/health/:userId` | 提交健康快照 |
| GET | `/api/health/:userId/scenario` | 场景选择 |
| GET | `/api/sync/auth?userId=` | 拉取认证 store 快照（HarmonyOS，MSRV-008） |
| PUT | `/api/sync/auth` | 提交认证 store 快照（HarmonyOS，MSRV-008） |
| GET | `/api/sync/health` | 拉取健康快照集合（HarmonyOS，MSRV-008） |
| PUT | `/api/sync/health` | 提交健康快照集合（HarmonyOS，MSRV-008） |
| PUT | `/api/avatar/:userId` | 上传头像图片二进制（缩放后 JPEG），落盘 `data/avatars/{userId}.jpg`（MSRV-015） |
| GET | `/api/avatar/:userId` | 拉取头像图片二进制 |
| DELETE | `/api/avatar/:userId` | 删除头像文件（注销账号级联） |

## 种子账号

- `13107012029` / `123456`（userId：`mock-user-default`）
- `2232591785@qq.com` / `123456`（userId：`mock-user-default-email`）

## 错误约定

统一响应体：`{ "error": { "code": "<CODE>", "message": "<文案>" } }`。

HTTP 状态码与代码映射（`MSRV-005`）：

| HTTP | CODE |
|---|---|
| 400 | `INVALID_PARAM` / `VERIFY_CODE_INVALID` / `VERIFY_CODE_EXPIRED` / `REGION_REQUIRED` / `NEW_PASSWORD_SAME_AS_OLD` |
| 401 | `AUTH_REQUIRED` / `PASSWORD_INCORRECT` |
| 404 | `ACCOUNT_NOT_FOUND` / `EMPTY_DATA` |
| 409 | `ACCOUNT_EXISTS` |
| 500 | `CORRUPTED_DATA` / `PERSIST_FAILED` |

## 三端 base URL

- Android 模拟器访问宿主机：`http://10.0.2.2:3000`
- iOS 模拟器：`http://localhost:3000`
- HarmonyOS 真机/模拟器：宿主局域网 IP `http://<host-ip>:3000`
