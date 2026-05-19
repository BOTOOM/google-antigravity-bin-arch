#!/bin/bash

set -euo pipefail

# Set up temporary directory
TEMP_DIR=$(mktemp -d)

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Download and set up the repository key (Antigravity 2)
if ! curl -fsSL "https://antigravity.google/apt/antigravity.asc" -o "$TEMP_DIR/antigravity.asc"; then
    # Fallback to legacy key location
    curl -fsSL "https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg" -o "$TEMP_DIR/antigravity.asc"
fi

# Add the key to apt's trusted keys
gpg --batch --yes --dearmor -o "/usr/share/keyrings/antigravity-archive-keyring.gpg" "$TEMP_DIR/antigravity.asc"

# Create sources list (Antigravity 2 repository)
echo "deb [signed-by=/usr/share/keyrings/antigravity-archive-keyring.gpg arch=amd64] https://antigravity.google/apt stable main" | tee /etc/apt/sources.list.d/antigravity.list > /dev/null

# Update package lists for the repository
apt-get update > /dev/null 2>&1

# Get package version using candidate package names
PACKAGE_NAME=""
VERSION=""

for candidate in antigravity google-antigravity; do
    CANDIDATE_VERSION=$(apt-cache madison "$candidate" | head -n1 | awk '{ print $3 }' | cut -d'-' -f1)
    if [ -n "$CANDIDATE_VERSION" ]; then
        PACKAGE_NAME="$candidate"
        VERSION="$CANDIDATE_VERSION"
        break
    fi
done

if [ -n "$VERSION" ]; then
    # Construct DEB URL
    # We can use 'apt-get download --print-uris' to get the URL
    DEB_URL=$(apt-get download --print-uris "$PACKAGE_NAME" | awk '{print $1}' | tr -d "'")
    
    if [ -n "$DEB_URL" ]; then
        # Download the DEB file to calculate SHA256 sum
        DEB_FILE="$TEMP_DIR/${PACKAGE_NAME}_${VERSION}.deb"
        if curl --silent --output "$DEB_FILE" "$DEB_URL"; then
            # Calculate SHA256 sum
            SHA256SUM=$(sha256sum "$DEB_FILE" | awk '{print $1}')
            # Output version, SHA256 sum, and URL
            printf "%s %s %s" "$VERSION" "$SHA256SUM" "$DEB_URL"
            exit 0
        else
            echo "Failed to download DEB package from $DEB_URL" >&2
            exit 1
        fi
    else
        echo "Could not determine DEB URL for $PACKAGE_NAME" >&2
        exit 1
    fi
else
    echo "Failed to get version. Package not found?" >&2
    apt-cache search antigravity >&2
    exit 1
fi
