#!/bin/bash
set -eo pipefail

# Configuration
: "${PKG_NAME:=google-antigravity-bin}"
: "${PKGBUILD_PATH:=package/PKGBUILD}"
: "${ANTIGRAVITY_CHANNEL:=ide}"
: "${PRODUCT_DISPLAY_NAME:=Antigravity IDE}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[INFO] $(date +'%T') - $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARN] $(date +'%T') - $1${NC}"
}

success() {
    echo -e "${GREEN}[SUCCESS] $(date +'%T') - $1${NC}"
}

# 1. Run update.sh to check for upstream updates and update PKGBUILD if needed
log "Checking for upstream ${PRODUCT_DISPLAY_NAME} updates..."
ANTIGRAVITY_CHANNEL="$ANTIGRAVITY_CHANNEL" \
PKGBUILD_PATH="$PKGBUILD_PATH" \
PRODUCT_DISPLAY_NAME="$PRODUCT_DISPLAY_NAME" \
./update.sh

# 2. Check Installed Version vs PKGBUILD Version
if [ ! -f "$PKGBUILD_PATH" ]; then
    echo "Error: $PKGBUILD_PATH not found."
    exit 1
fi

# Extract version from PKGBUILD (rough extraction)
PKGVER=$(grep "^pkgver=" "$PKGBUILD_PATH" | cut -d'=' -f2)
PKGREL=$(grep "^pkgrel=" "$PKGBUILD_PATH" | cut -d'=' -f2)
TARGET_VERSION="${PKGVER}-${PKGREL}"

# Check installed version
if pacman -Q "$PKG_NAME" &>/dev/null; then
    INSTALLED_VERSION=$(pacman -Q "$PKG_NAME" | awk '{print $2}')
else
    INSTALLED_VERSION="None"
fi

log "Local PKGBUILD version: $TARGET_VERSION"
log "Installed version:      $INSTALLED_VERSION"

if [ "$TARGET_VERSION" != "$INSTALLED_VERSION" ]; then
    echo ""
    warn "A new version (or uninstalled version) is available."
    echo -e "  Current: $INSTALLED_VERSION"
    echo -e "  Target:  $TARGET_VERSION"
    echo ""
    
    read -p "Do you want to build and install this version now? [Y/n] " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        log "Starting installation..."
        PKGBUILD_SUBDIR="$(dirname "$PKGBUILD_PATH")" \
        ANTIGRAVITY_PKG_NAME="$PKG_NAME" \
        ./_install_local.sh
    else
        log "Update skipped by user."
    fi
else
    success "You are already on the latest version ($INSTALLED_VERSION)."
fi
