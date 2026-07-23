#!/bin/bash

set -euo pipefail

CHANNEL="${1:-${ANTIGRAVITY_CHANNEL:-ide}}"

TEMP_DIR=$(mktemp -d)
cleanup() { rm -rf "$TEMP_DIR"; }
trap cleanup EXIT

configure_channel() {
    case "$CHANNEL" in
        ide)
            PRODUCT_DISPLAY_NAME="Antigravity IDE"
            RELEASES_URL="https://antigravity-ide-auto-updater-974169037036.us-central1.run.app/releases"
            DOWNLOAD_BASE_URL="https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable"
            ARCHIVE_NAME="Antigravity%20IDE.tar.gz"
            ;;
        2.0|2|hub|app)
            PRODUCT_DISPLAY_NAME="Antigravity 2.0"
            RELEASES_URL="https://antigravity-auto-updater-974169037036.us-central1.run.app/releases"
            DOWNLOAD_BASE_URL="https://storage.googleapis.com/antigravity-public/antigravity-hub"
            ARCHIVE_NAME="Antigravity.tar.gz"
            ;;
        *)
            echo "Unsupported Antigravity channel: $CHANNEL" >&2
            exit 1
            ;;
    esac
}

extract_manifest_field() {
    local manifest="$1"
    local field_name="$2"

    printf '%s' "$manifest" | grep -oPm1 "\"${field_name}\"\\s*:\\s*\"\\K[^\"]+"
}

configure_channel

MANIFEST=$(curl -fsSL --compressed "$RELEASES_URL")
VERSION=$(extract_manifest_field "$MANIFEST" "version" || true)
EXECUTION_ID=$(extract_manifest_field "$MANIFEST" "execution_id" || true)

if [ -z "$VERSION" ] || [ -z "$EXECUTION_ID" ]; then
    echo "Failed to extract ${PRODUCT_DISPLAY_NAME} release metadata" >&2
    exit 1
fi

DOWNLOAD_URL="${DOWNLOAD_BASE_URL}/${VERSION}-${EXECUTION_ID}/linux-x64/${ARCHIVE_NAME}"

ARCHIVE_FILE="$TEMP_DIR/antigravity-${CHANNEL//[^a-zA-Z0-9]/-}-${VERSION}.tar.gz"
echo "Downloading ${PRODUCT_DISPLAY_NAME} from $DOWNLOAD_URL ..." >&2
if ! curl -fsSL --output "$ARCHIVE_FILE" "$DOWNLOAD_URL"; then
    echo "Failed to download archive from $DOWNLOAD_URL" >&2
    exit 1
fi

SHA256SUM=$(sha256sum "$ARCHIVE_FILE" | awk '{print $1}')

printf "%s %s %s" "$VERSION" "$SHA256SUM" "$DOWNLOAD_URL"
