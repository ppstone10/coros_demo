# harmonyApp

这是登录示例的 HarmonyOS 原生 ArkTS + ArkUI 应用壳。

当前阶段：

- UI 使用 ArkTS + ArkUI 原生实现，不采用 KuiklyUI 共享 UI。
- 登录页面通过 `LoginViewModel` -> `LoginLogicAdapter` 调用业务逻辑。
- `KnoiLoginAdapter` 通过 KuiklyBase-Kotlin + KNOI 调用 `harmony-kmp-bridge` 中的 `HarmonyLoginService`；该 service 复用 `common/src/commonMain` 的 `LoginFacade`、验证码、注册、登录和登出逻辑。
- native 运行期使用内存 Store；`StorePersister.ets` 将 bridge 导出的认证 JSON 快照保存到 `@ohos.data.preferences`，并在应用启动时恢复。
- `EntryAbility` 显式执行 `setup('libkn.so', false)` 和 `init()`；Harmony 登录业务不再走 `import libshared_login_bridge.so`。
- KNOI 工具链、native module 产物和兼容约束以 `harmony-kmp-bridge/README.md` 为准。没有 `libkn.so` 时，鸿蒙端不应被视为已完成可运行构建。

## shared native module

KNOI 生成的 native module 需要命名为 `libkn.so`。源码目录按用户约定保留一份，同时 Hvigor 实际打包目录也需要一份：

```text
entry/src/main/libs/arm64-v8a/libkn.so
entry/libs/arm64-v8a/libkn.so
```

`entry/hvigorfile.ts` 会在 `assembleApp`、`assembleHap` 等构建命令执行前检查该文件；缺失时构建直接失败，避免运行期才发现鸿蒙端没有切到 shared。

推荐通过仓库脚本安装 KNOI 产物并验证：

```bash
../harmony-kmp-bridge/gradlew -p ../harmony-kmp-bridge ohosArm64Binaries
```

如果你的 KNOI 工具链提供 CLI 或 Gradle 命令，可以改用：

```bash
../tools/build-shared-harmony.sh
```

如果 DevEco Studio 内置工具未加入系统 PATH，可以临时这样运行：

```bash
env NODE_HOME=/Applications/DevEco-Studio.app/Contents/tools/node \
  DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk \
  PATH=/Applications/DevEco-Studio.app/Contents/tools/node/bin:/Applications/DevEco-Studio.app/Contents/tools/ohpm/bin:/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin:$PATH \
  /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw assembleApp --no-daemon
```

## 在 DevEco Studio 中打开

直接打开这个目录：

```text
harmonyApp
```

不要把仓库根目录作为 DevEco 工程打开。仓库根目录是 Android/KMP 的 Gradle 工作区，`harmonyApp` 才是 HarmonyOS ArkTS 工程。

跨端边界见 `docs/architecture.md`，构建和 ArkUI 状态约定见 `docs/development-workflow.md`。
