# 开发工作流

## 日常开发

Android/iOS 共享逻辑：

```bash
./gradlew :common:check
```

Android 应用：

```bash
./gradlew :androidApp:assembleDebug
```

iOS 框架：

```bash
./tools/build-shared-xcframework.sh
```

HarmonyOS：

用 DevEco Studio 打开 `harmonyApp`，当前不走 Gradle 主线。ArkUI 页面保持原生实现；KNOI bridge 通过独立 `harmony-kmp-bridge` 生成 `libkn.so` 和 `entry/src/main/ets/knoi/provider.ets`，ArkTS 侧通过生成的 `getHarmonyLoginService()` 调用 Kotlin `HarmonyLoginService`，再复用 `common/src/commonMain` 的 `LoginFacade`。命令行验证时可临时设置 DevEco 内置工具环境变量：

```bash
env NODE_HOME=/Applications/DevEco-Studio.app/Contents/tools/node \
  DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk \
  PATH=/Applications/DevEco-Studio.app/Contents/tools/node/bin:/Applications/DevEco-Studio.app/Contents/tools/ohpm/bin:/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin:$PATH \
  /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw assembleApp --no-daemon
```

## 修改共享逻辑

1. 先改 `common/src/commonMain`。
2. 补 `common/src/commonTest`。
3. Android 通过 `LoginStore` 或 `LoginFacade` 调用。
4. iOS 通过 `SharedLoginAdapter` 调用。
5. HarmonyOS 优先扩展 `harmony-kmp-bridge` 中的 KNOI service；登录、注册、验证码和登出逻辑已接入 `common/src/commonMain`，新增业务应继续放回 shared，再由 ArkTS 做原生 UI 映射。
6. 若涉及协议字段，先更新 `contract`。

## 修改平台 UI

- Android UI 只改 `androidApp`。
- iOS UI 只改 `iosApp`。
- HarmonyOS UI 只改 `harmonyApp`。
- 不把 UI 类型、平台生命周期、SDK 对象放入 `commonMain`。

## 实验规则

HarmonyOS KMP/KNOI 工具链相关实验只能放在 `experimental/harmony-kmp`，并记录到 `docs/harmonyos-kmp-experiment.md`。实验目录不加入根 Gradle 主线，不影响 Android/iOS 交付。不要引入 KuiklyUI 共享 UI 路线。
