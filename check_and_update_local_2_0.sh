#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

export PKG_NAME="google-antigravity-2-0-bin"
export PKGBUILD_PATH="package-2.0/PKGBUILD"
export ANTIGRAVITY_CHANNEL="2.0"
export PRODUCT_DISPLAY_NAME="Antigravity 2.0"

exec "$SCRIPT_DIR/check_and_update_local.sh" "$@"
