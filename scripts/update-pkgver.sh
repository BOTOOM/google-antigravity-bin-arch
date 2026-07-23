#!/bin/bash

# Script to update package version in PKGBUILD
# Usage: ./update-pkgver.sh package-name new-version

if [ $# -ne 2 ]; then
    echo "Usage: $0 package-name new-version"
    exit 1
fi

PACKAGE=$1
VERSION=$2

case "$PACKAGE" in
    google-antigravity-bin|antigravity-ide|ide)
        PKGBUILD_PATH="${PKGBUILD_PATH:-package/PKGBUILD}"
        ;;
    google-antigravity-2-0-bin|antigravity-2.0|antigravity-2-0|2.0|hub)
        PKGBUILD_PATH="${PKGBUILD_PATH:-package-2.0/PKGBUILD}"
        ;;
    *)
        echo "Error: unsupported package '$PACKAGE'"
        exit 1
        ;;
esac

if [ ! -f "$PKGBUILD_PATH" ]; then
    echo "Error: PKGBUILD not found for package $PACKAGE"
    exit 1
fi

# Update pkgver in PKGBUILD
sed -i "s/^pkgver=.*$/pkgver=$VERSION/" "$PKGBUILD_PATH"

# Reset pkgrel to 1
sed -i "s/^pkgrel=.*$/pkgrel=1/" "$PKGBUILD_PATH"

# Update checksums
cd "package"
updpkgsums

echo "Updated $PACKAGE to version $VERSION"
