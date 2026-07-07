#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HARMONY_DIR="$ROOT_DIR/harmonyApp"
BRIDGE_DIR="$ROOT_DIR/harmony-kmp-bridge"
NATIVE_LIB_NAME="libkn.so"
DEFAULT_ABI="${HARMONY_SHARED_LOGIN_ABI:-arm64-v8a}"
SOURCE_LIB_DIR="$HARMONY_DIR/entry/src/main/libs/$DEFAULT_ABI"
PACKAGED_LIB_DIR="$HARMONY_DIR/entry/libs/$DEFAULT_ABI"
SOURCE_SO="$SOURCE_LIB_DIR/$NATIVE_LIB_NAME"
PACKAGED_SO="$PACKAGED_LIB_DIR/$NATIVE_LIB_NAME"
GENERATED_PROVIDER="$HARMONY_DIR/entry/src/main/ets/knoi/provider.ets"

DEVECO_HOME="${DEVECO_HOME:-/Applications/DevEco-Studio.app/Contents}"
DEVECO_NODE_HOME="${NODE_HOME:-$DEVECO_HOME/tools/node}"
DEVECO_SDK_HOME="${DEVECO_SDK_HOME:-$DEVECO_HOME/sdk}"
HVIGORW="${HVIGORW:-$DEVECO_HOME/tools/hvigor/bin/hvigorw}"

build_knoi_bridge() {
  echo "Building KuiklyBase-Kotlin/KNOI bridge..."
  (cd "$BRIDGE_DIR" && ./gradlew ohosArm64Binaries)
}

verify_knoi_outputs() {
  local missing=0
  for output in "$SOURCE_SO" "$PACKAGED_SO" "$GENERATED_PROVIDER"; do
    if [[ ! -f "$output" ]]; then
      echo "Missing generated output: $output" >&2
      missing=1
    fi
  done

  if [[ "$missing" -ne 0 ]]; then
    cat >&2 <<EOF
Run failed before producing the expected KNOI POC outputs.

Expected:
  $SOURCE_SO
  $PACKAGED_SO
  $GENERATED_PROVIDER
EOF
    exit 1
  fi

  echo "Verified KNOI outputs:"
  echo "  $SOURCE_SO"
  echo "  $PACKAGED_SO"
  echo "  $GENERATED_PROVIDER"
}

verify_harmony_build() {
  echo "Running HarmonyOS assembleApp..."
  (
    cd "$HARMONY_DIR"
    env NODE_HOME="$DEVECO_NODE_HOME" \
      DEVECO_SDK_HOME="$DEVECO_SDK_HOME" \
      PATH="$DEVECO_NODE_HOME/bin:$DEVECO_HOME/tools/ohpm/bin:$DEVECO_HOME/tools/hvigor/bin:$PATH" \
      "$HVIGORW" assembleApp --no-daemon
  )
}

cd "$ROOT_DIR"
./gradlew :common:check
build_knoi_bridge
verify_knoi_outputs
verify_harmony_build
