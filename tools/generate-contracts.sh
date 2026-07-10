#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "Contract generation is deferred."
echo "Data models are now defined in :common directly. contract/ holds only API contract (openapi/) and analytics events."
