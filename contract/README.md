# contract

埋点事件定义与后续业务契约预留目录。

当前为空壳骨架，实际数据模型已在 `common` 中定义。

- `openapi/`：后端 API 契约预留。注册登录培训模块只使用本地 mock，不在此目录维护认证接口、HTTP 路径、响应结构或 token 字段。
- `analytics/`：埋点事件名称和载荷定义。三端统一，`common` 不参与。

状态模型（`LoginState`、`LoginAction`、`LoginEffect`）和错误码由 `common` 模块作为单一事实来源，`contract` 不再维护。
