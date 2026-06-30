# contract

这里存放 Android、iOS、HarmonyOS 共用的接口和产品契约。

目录说明：

- `openapi/`：后端 API 契约。
- `schema/`：用于对齐 DTO 和状态模型的 JSON Schema。
- `errors/`：稳定的错误码登记表。
- `analytics/`：埋点事件名称和载荷约定。

后续代码生成工具应以本目录为输入，生成 Kotlin、Swift、ArkTS 模型，同时不改变运行时架构。
