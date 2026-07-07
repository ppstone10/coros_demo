# Harmony KMP Bridge

This is an isolated KuiklyBase-Kotlin + KNOI bridge build for HarmonyOS.

- It compiles the shared login business sources from `../common/src/commonMain/kotlin`.
- Harmony UI stays native ArkTS/ArkUI; login business goes through `HarmonyLoginService` and `LoginFacade`.
- It uses KuiklyBase Kotlin `2.0.21-KBA-003`.
- It builds `ohosArm64` as a shared library with `baseName = "kn"`, producing `libkn.so`.
- KNOI generates ArkTS API files into `build/ts-api`, then copies them to `harmonyApp/entry/src/main/ets/knoi`.

Run:

```bash
./gradlew ohosArm64Binaries
```

Expected copied outputs:

```text
harmonyApp/entry/src/main/libs/arm64-v8a/libkn.so
harmonyApp/entry/libs/arm64-v8a/libkn.so
harmonyApp/entry/src/main/ets/knoi/provider.ets
```
