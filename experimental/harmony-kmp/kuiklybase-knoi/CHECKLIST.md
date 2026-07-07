# KuiklyBase-Kotlin/KNOI shared native checklist

检查日期：2026-07-06

## 当前结论

当前工程已通过独立 `harmony-kmp-bridge` 生成真实 KuiklyBase-Kotlin/KNOI HarmonyOS native module：

```text
harmonyApp/entry/src/main/libs/arm64-v8a/libkn.so
harmonyApp/entry/libs/arm64-v8a/libkn.so
harmonyApp/entry/src/main/ets/knoi/provider.ets
```

HAP 已确认包含 `libs/arm64-v8a/libkn.so`、`libknoi.so`、`libc++_shared.so`。

## 逐项检查

| 项 | 检查项 | 当前结果 |
| --- | --- | --- |
| 1 | `setup()` / import 名称是否是 `libkn.so` | `EntryAbility` 执行 `setup('libkn.so', false)` + `init()`；不再 import `libshared_login_bridge.so`。 |
| 2 | `entry/src/main/libs/arm64-v8a/` 下是否有同名 `.so` | 已存在 `libkn.so`。 |
| 3 | Gradle `sharedLib` `baseName` 是否和 `.so` 名一致 | `harmony-kmp-bridge` 配置 `binaries.sharedLib { baseName = "kn" }`。 |
| 4 | 是否执行了 `ohosArm64Binaries` 或对应构建任务 | 已执行 `./gradlew ohosArm64Binaries`，构建成功。 |
| 5 | 是否把 release/debug 对应产物复制进鸿蒙工程 | debug `libkn.so` 已复制到源码约定目录和 Hvigor 打包目录。 |
| 6 | 是否使用普通 JetBrains Kotlin 而不是 KuiklyBase-Kotlin 构建鸿蒙 `.so` | 使用 KuiklyBase Kotlin `2.0.21-KBA-003`，不使用根工程 JetBrains Kotlin `2.2.10`。 |
| 7 | 是否有多个 Kotlin module 都配置了 `sharedLib` | 只有独立 `harmony-kmp-bridge` 配置 `sharedLib`。 |
| 8 | 是否有依赖 `.so` 没有一起打包 | HAP 内包含 `libkn.so`、`libknoi.so`、`libc++_shared.so`。 |
| 9 | 是否先 import 了带 NAPI 的被动依赖 `.so` | 通过 `@kuiklybase/knoi` 导入 `libknoi.so`，`libkn.so` 由 `setup()` 加载。 |
| 10 | 是否在真机 arm64 环境跑，而不是 ABI 不匹配 | 当前 HAP 仅验证 arm64 打包；真机运行需使用 arm64 设备。 |

## 下一步

标准验证命令：

```bash
./tools/build-shared-harmony.sh
```

脚本会运行 `:common:check`、`harmony-kmp-bridge` 的 `ohosArm64Binaries`，并运行 DevEco/Hvigor `assembleApp` 验证。
