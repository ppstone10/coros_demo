# contract

后端 API 契约与埋点事件定义。

当前为空壳骨架，实际数据模型已在 `common` 中定义。

- `openapi/`：后端 API 契约。当前为占位，接入真实后端时应由后端维护此目录。
- `analytics/`：埋点事件名称和载荷定义。三端统一，`common` 不参与。

状态模型（`LoginState`、`LoginAction`、`LoginEffect`）和错误码由 `common` 模块作为单一事实来源，`contract` 不再维护。
