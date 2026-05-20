#!/bin/bash

set -euo pipefail

DOWNLOAD_PAGE="https://antigravity.google/download"
CDN_BASE="https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable"

TEMP_DIR=$(mktemp -d)
cleanup() { rm -rf "$TEMP_DIR"; }
trap cleanup EXIT

# Step 1: Find the JS bundle name from the download page
JS_FILE=$(curl -fsSL --compressed "$DOWNLOAD_PAGE" | grep -oP 'main-[A-Z0-9]+\.js' | head -1)
if [ -z "$JS_FILE" ]; then
    echo "Failed to find JS bundle on download page" >&2
    exit 1
fi

# Step 2: Extract the latest Linux x64 tar.gz download URL from the JS
DOWNLOAD_URL=$(curl -fsSL --compressed "https://antigravity.google/$JS_FILE" | \
    grep -oP 'https://edgedl\.me\.gvt1\.com/edgedl/release2/j0qc3/antigravity/stable/[^"'\''"\x60]+linux-x64/[^"'\''"\x60]+\.tar\.gz' | head -1)

if [ -z "$DOWNLOAD_URL" ]; then
    echo "Failed to extract download URL from JS bundle" >&2
    exit 1
fi

# Step 3: Extract version from URL (format: .../stable/VERSION-EXECID/...)
VERSION=$(echo "$DOWNLOAD_URL" | grep -oP '/stable/\K[^-]+')
if [ -z "$VERSION" ]; then
    echo "Failed to parse version from URL: $DOWNLOAD_URL" >&2
    exit 1
fi

# Step 4: Download the tar.gz and compute SHA256
ARCHIVE_FILE="$TEMP_DIR/antigravity-${VERSION}.tar.gz"
echo "Downloading $DOWNLOAD_URL ..." >&2
if ! curl -fsSL --output "$ARCHIVE_FILE" "$DOWNLOAD_URL"; then
    echo "Failed to download archive from $DOWNLOAD_URL" >&2
    exit 1
fi

SHA256SUM=$(sha256sum "$ARCHIVE_FILE" | awk '{print $1}')

# Output: version sha256sum url
printf "%s %s %s" "$VERSION" "$SHA256SUM" "$DOWNLOAD_URL"
