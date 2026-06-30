#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "Contract generation is not wired yet."
echo "Input contracts live in ./contract and should generate Kotlin, Swift and ArkTS DTOs later."
