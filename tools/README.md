# tools

这里存放项目自动化脚本入口。

- `build-shared.sh`：构建并测试 KMP 共享模块。
- `build-shared-xcframework.sh`：生成 iOS 使用的 `Shared.xcframework`。
- `generate-contracts.sh`：预留脚本，后续用于从 `contract` 生成 Kotlin、Swift、ArkTS DTO。

这些脚本应该都可以从仓库根目录安全执行。
