#!/bin/bash
set -eo pipefail

# --- Configuration ---
readonly DOCKER_IMAGE_NAME="antigravity-version-checker"
: "${ANTIGRAVITY_CHANNEL:=ide}"
: "${PKGBUILD_PATH:=package/PKGBUILD}"
: "${PRODUCT_DISPLAY_NAME:=Antigravity IDE}"

# --- Helper Functions ---
log() {
    echo "[INFO] $(date +'%T') - $1"
}

error_exit() {
    echo "[ERROR] $(date +'%T') - $1" >&2
    exit 1
}

check_command() {
    command -v "$1" >/dev/null 2>&1 || error_exit "Required command '$1' not found. Please install it."
}

# --- Main Script ---
check_command "docker"
check_command "perl"
check_command "sed"

# 1. Build the Docker image to ensure it's up-to-date
log "Building Docker image '$DOCKER_IMAGE_NAME' to ensure it's up-to-date..."
if ! docker build -t "$DOCKER_IMAGE_NAME" . ; then
    error_exit "Failed to build Docker image. Check Dockerfile and build output."
fi
log "Docker image build process complete."

# 2. Get current version from PKGBUILD
if [ ! -f "$PKGBUILD_PATH" ]; then
    # If PKGBUILD doesn't exist, create a dummy one or fail?
    # Let's assume it might not exist yet and we are bootstrapping, but the user asked for a similar project structure.
    # If I am running this for the first time, I might want to just output the version so I can create the PKGBUILD.
    # But the script logic expects PKGBUILD.
    # I will create a dummy PKGBUILD later if needed, but for now let's stick to the logic.
    error_exit "PKGBUILD not found at '$PKGBUILD_PATH'."
fi

CURRENT_VERSION=$(grep -m1 '^pkgver=' "$PKGBUILD_PATH" | cut -d'=' -f2)
if [ -z "$CURRENT_VERSION" ]; then
    error_exit "Could not read current pkgver from '$PKGBUILD_PATH'."
fi
log "Current $PRODUCT_DISPLAY_NAME version in PKGBUILD is: $CURRENT_VERSION"

# 3. Run Docker container to get the latest version and SHA256 sum
log "Running version check container..."
CHECK_OUTPUT=$(docker run --rm "$DOCKER_IMAGE_NAME" "$ANTIGRAVITY_CHANNEL")

if [ -z "$CHECK_OUTPUT" ]; then
    error_exit "Failed to get version from Docker container. The command returned no output."
fi

LATEST_VERSION=$(echo "$CHECK_OUTPUT" | awk '{print $1}')
LATEST_SHA256=$(echo "$CHECK_OUTPUT" | awk '{print $2}')
LATEST_URL=$(echo "$CHECK_OUTPUT" | awk '{print $3}')

if [ -z "$LATEST_VERSION" ] || [ -z "$LATEST_SHA256" ] || [ -z "$LATEST_URL" ]; then
    error_exit "Could not parse version, SHA256 or URL from container output: '$CHECK_OUTPUT'"
fi
log "Latest available $PRODUCT_DISPLAY_NAME version is: $LATEST_VERSION"

# 4. Compare versions and update if necessary
if [ "$CURRENT_VERSION" == "$LATEST_VERSION" ]; then
    log "$PRODUCT_DISPLAY_NAME is already up-to-date. No changes needed."
    exit 0
fi

log "New $PRODUCT_DISPLAY_NAME version available. Updating PKGBUILD from $CURRENT_VERSION to $LATEST_VERSION..."

# Update pkgver
sed -i "s/^pkgver=.*/pkgver=$LATEST_VERSION/" "$PKGBUILD_PATH"

# Update pkgrel to 1
sed -i "s/^pkgrel=.*/pkgrel=1/" "$PKGBUILD_PATH"

# Update source URL (only first line of source array)
perl -i -pe 'BEGIN{$u=shift} if (!$done && s{source=\("[^"]*"}{source=("$u"}) { $done=1 }' "$LATEST_URL" "$PKGBUILD_PATH"

# Update sha256sum (only first checksum)
perl -i -pe 'BEGIN{$s=shift} if (!$done && s/'"'"'[a-f0-9]{64}'"'"'/'"'"'$s'"'"'/) { $done=1 }' "$LATEST_SHA256" "$PKGBUILD_PATH"

log "PKGBUILD updated successfully!"
log "New $PRODUCT_DISPLAY_NAME version: $LATEST_VERSION"
log "New SHA256: $LATEST_SHA256"
log "New URL: $LATEST_URL"


log "You can now commit the changes and build the new package."
