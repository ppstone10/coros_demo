# contract

这里仅保存三端共用的埋点事件契约：

- `analytics/events.json`：机器可读的事件名称与载荷字段。
- `analytics/events.md`：事件用途和字段说明。

认证与健康数据字段、状态模型和错误场景由 `common/src/commonMain/proto/` 与 common 模型作为单一事实来源。本项目不接入真实服务，因此不维护 OpenAPI、HTTP 路径、请求/响应或 token 契约。
