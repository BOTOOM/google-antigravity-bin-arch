#!/bin/bash

set -euo pipefail

CHANNEL="${1:-${ANTIGRAVITY_CHANNEL:-ide}}"
DOWNLOAD_PAGE="https://antigravity.google/download"
CURL_RETRY_OPTS=(--retry 5 --retry-delay 5 --retry-connrefused --connect-timeout 15)

if curl --help all 2>/dev/null | grep -q -- '--retry-all-errors'; then
    CURL_RETRY_OPTS+=(--retry-all-errors)
fi

TEMP_DIR=$(mktemp -d)
cleanup() { rm -rf "$TEMP_DIR"; }
trap cleanup EXIT

configure_channel() {
    case "$CHANNEL" in
        ide)
            PRODUCT_DISPLAY_NAME="Antigravity IDE"
            DOWNLOAD_URL_PATTERN='https://edgedl\.me\.gvt1\.com/edgedl/release2/j0qc3/antigravity/stable/[0-9]+\.[0-9]+\.[0-9]+-[0-9]+/linux-x64/Antigravity%20IDE\.tar\.gz'
            ;;
        2.0|2|hub|app)
            PRODUCT_DISPLAY_NAME="Antigravity 2.0"
            DOWNLOAD_URL_PATTERN='https://storage\.googleapis\.com/antigravity-public/antigravity-hub/[0-9]+\.[0-9]+\.[0-9]+-[0-9]+/linux-x64/Antigravity\.tar\.gz'
            ;;
        *)
            echo "Unsupported Antigravity channel: $CHANNEL" >&2
            exit 1
            ;;
    esac
}

extract_version() {
    printf '%s' "$1" | grep -oP '/(?:stable/)?\K[0-9]+\.[0-9]+\.[0-9]+(?=-[0-9]+/linux-x64/)'
}

configure_channel

DOWNLOAD_URL=$(
    curl -fsSL --compressed "${CURL_RETRY_OPTS[@]}" "$DOWNLOAD_PAGE" \
        | grep -oP "$DOWNLOAD_URL_PATTERN" \
        | sort -u \
        | while IFS= read -r url; do
            version=$(extract_version "$url")
            printf '%s\t%s\n' "$version" "$url"
        done \
        | sort -t $'\t' -k1,1V \
        | tail -n1 \
        | cut -f2- \
        || true
)

if [ -z "$DOWNLOAD_URL" ]; then
    echo "Failed to find the ${PRODUCT_DISPLAY_NAME} Linux x64 download URL" >&2
    exit 1
fi

VERSION=$(extract_version "$DOWNLOAD_URL" || true)
if [ -z "$VERSION" ]; then
    echo "Failed to parse ${PRODUCT_DISPLAY_NAME} version from download URL" >&2
    exit 1
fi

ARCHIVE_FILE="$TEMP_DIR/antigravity-${CHANNEL//[^a-zA-Z0-9]/-}-${VERSION}.tar.gz"
echo "Downloading ${PRODUCT_DISPLAY_NAME} from $DOWNLOAD_URL ..." >&2
if ! curl -fsSL "${CURL_RETRY_OPTS[@]}" --output "$ARCHIVE_FILE" "$DOWNLOAD_URL"; then
    echo "Failed to download archive from $DOWNLOAD_URL" >&2
    exit 1
fi

SHA256SUM=$(sha256sum "$ARCHIVE_FILE" | awk '{print $1}')

printf "%s %s %s" "$VERSION" "$SHA256SUM" "$DOWNLOAD_URL"
