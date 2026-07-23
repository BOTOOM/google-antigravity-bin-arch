#!/bin/bash

set -euo pipefail

DOWNLOAD_PAGE="https://antigravity.google/download"

TEMP_DIR=$(mktemp -d)
cleanup() { rm -rf "$TEMP_DIR"; }
trap cleanup EXIT

# Step 1: Find the JS bundle URL from the download page.
# Match any script src attribute containing "main" and ending in ".js",
# handling both relative (/path/main-*.js) and absolute (https://…/main-*.js) URLs.
JS_FILE=$(
    curl -fsSL --compressed "$DOWNLOAD_PAGE" \
        | grep -oP '(?<=src=")[^"]*main[^"]*\.js' \
        | head -1 \
        || true
)
if [ -z "$JS_FILE" ]; then
    echo "Failed to find JS bundle on download page" >&2
    exit 1
fi

# Normalize to an absolute URL: if the path is relative, prepend the base origin.
if [[ "$JS_FILE" != http* ]]; then
    JS_FILE="https://antigravity.google/${JS_FILE#/}"
fi

# Step 2: Extract the latest Antigravity IDE Linux x64 tar.gz download URL from the JS.
# The download page currently mixes multiple product channels, so only track concrete
# Antigravity IDE artifacts and choose the highest semantic version found.
DOWNLOAD_URL=$(
    curl -fsSL --compressed "$JS_FILE" \
        | grep -oP 'https://edgedl\.me\.gvt1\.com/edgedl/release2/j0qc3/antigravity/stable/[0-9]+\.[0-9]+\.[0-9]+-[0-9]+/linux-x64/Antigravity%20IDE\.tar\.gz' \
        | awk '
            {
                version = $0
                sub(/^.*\/stable\//, "", version)
                sub(/-[0-9]+\/linux-x64\/Antigravity%20IDE\.tar\.gz$/, "", version)
                print version "\t" $0
            }
        ' \
        | sort -t $'\t' -k1,1V \
        | tail -n1 \
        | cut -f2- \
        || true
)

if [ -z "$DOWNLOAD_URL" ]; then
    echo "Failed to extract Antigravity IDE download URL from JS bundle" >&2
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
