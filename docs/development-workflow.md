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

用 DevEco Studio 打开 `harmonyApp`，当前不走 Gradle 主线。

## 修改共享逻辑

1. 先改 `common/src/commonMain`。
2. 补 `common/src/commonTest`。
3. Android 通过 `LoginStore` 或 `LoginFacade` 调用。
4. iOS 通过 `SharedLoginAdapter` 调用。
5. HarmonyOS 在 ArkTS 中同步模型和流程。
6. 若涉及协议字段，先更新 `contract`。

## 修改平台 UI

- Android UI 只改 `androidApp`。
- iOS UI 只改 `iosApp`。
- HarmonyOS UI 只改 `harmonyApp`。
- 不把 UI 类型、平台生命周期、SDK 对象放入 `commonMain`。

## 实验规则

HarmonyOS KMP 相关实验只能放在 `experimental/harmony-kmp`，并记录到 `docs/harmonyos-kmp-experiment.md`。实验目录不加入根 Gradle 主线，不影响 Android/iOS 交付。
