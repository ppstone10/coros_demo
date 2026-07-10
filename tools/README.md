# tools

这里存放项目自动化脚本入口。

- `build-shared.sh`：构建并测试 KMP 共享模块。
- `build-shared-xcframework.sh`：生成 iOS 使用的 `Shared.xcframework`。
- `build-shared-harmony.sh`：安装 KuiklyBase-Kotlin/KNOI 生成的 HarmonyOS shared native module，并验证 `harmonyApp`。
- `generate-contracts.sh`：预留脚本（当前无代码生成计划，数据模型以 `common` 为准）。

这些脚本应该都可以从仓库根目录安全执行。

## HarmonyOS shared native module

`build-shared-harmony.sh` 不会伪造 native module。它支持三种真实输入：

```bash
KNOI_BUILD_COMMAND='<your KNOI build command>' ./tools/build-shared-harmony.sh
KNOI_HOME=/path/to/knoi-sdk ./tools/build-shared-harmony.sh
./tools/build-shared-harmony.sh
```

脚本会调用 `harmony-kmp-bridge` 生成 `libkn.so`，并安装到 `harmonyApp/entry/src/main/libs/$HARMONY_SHARED_LOGIN_ABI/` 与 `harmonyApp/entry/libs/$HARMONY_SHARED_LOGIN_ABI/`，默认 ABI 是 `arm64-v8a`。
