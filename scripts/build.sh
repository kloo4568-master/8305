#!/bin/bash
set -euo pipefail

OPENWRT_VERSION=${1:-22.03.5}
TARGET=${2:-}
SUBTARGET=${3:-}
PROFILE=${4:-}
PACKAGES=${5:-"kmod-usb-core kmod-usb2 kmod-usb3 kmod-usb-storage kmod-scsi-core kmod-fs-ext4 kmod-fs-vfat block-mount mount-utils e2fsprogs"}

if [ -z "$TARGET" ] || [ -z "$SUBTARGET" ] || [ -z "$PROFILE" ]; then
  echo "Usage: $0 <openwrt-version> <target> <subtarget> <profile> [packages]"
  exit 2
fi

IB_NAME="openwrt-imagebuilder-${OPENWRT_VERSION}-${TARGET}-${SUBTARGET}.Linux-x86_64.tar.xz"
IB_URL="https://downloads.openwrt.org/releases/${OPENWRT_VERSION}/targets/${TARGET}/${SUBTARGET}/${IB_NAME}"

echo "Downloading $IB_URL"
wget -nv -O "${IB_NAME}" "${IB_URL}"

# Clean previous extracted imagebuilder directories only (do not remove the downloaded tar)
# Use find to remove directories only to avoid deleting the downloaded tarfile
find . -maxdepth 1 -type d -name 'openwrt-imagebuilder-*' -exec rm -rf {} + || true
rm -f "${IB_NAME}".part || true

# Extract imagebuilder archive
if [ ! -f "${IB_NAME}" ]; then
  echo "Error: ${IB_NAME} not found after download" >&2
  exit 1
fi

tar -xJf "${IB_NAME}"

# Find the extracted imagebuilder directory safely
EXTRACT_DIR=$(find . -maxdepth 1 -type d -name 'openwrt-imagebuilder-*' -print -quit || true)
if [ -z "$EXTRACT_DIR" ]; then
  echo "Error: extracted imagebuilder directory not found" >&2
  ls -la || true
  exit 1
fi

# Normalize and cd
EXTRACT_DIR=${EXTRACT_DIR#./}
cd "$EXTRACT_DIR"

# If PACKAGES is empty, fall back to default
if [ -z "${PACKAGES}" ]; then
  PACKAGES="kmod-usb-core kmod-usb2 kmod-usb3 kmod-usb-storage kmod-scsi-core kmod-fs-ext4 kmod-fs-vfat block-mount mount-utils e2fsprogs"
fi

# Pre-check available packages and filter out missing ones to avoid hard failure
AVAILABLE=""
if find dl -type f -name 'Packages*' -print0 | read -r -d '' _ 2>/dev/null; then
  AVAILABLE=$(find dl -type f -name 'Packages*' -print0 2>/dev/null | xargs -0 zcat 2>/dev/null || true)
  AVAILABLE=$(printf "%s" "$AVAILABLE" | awk '/^Package: /{print $2}' | sort -u || true)
fi

if [ -n "$AVAILABLE" ]; then
  FILTERED=""
  for p in $PACKAGES; do
    if printf "%s" "$AVAILABLE" | grep -qx "$p"; then
      FILTERED="$FILTERED $p"
    else
      echo "Warning: package '$p' not found in imagebuilder feeds — skipping"
    fi
  done
  PACKAGES="${FILTERED## }"
else
  echo "Warning: could not read available package lists from dl/; proceeding with PACKAGES unfiltered"
fi

echo "Running make image with PACKAGES: $PACKAGES"
make image PROFILE="${PROFILE}" PACKAGES="$PACKAGES" FILES="../files"
mkdir -p ../out
cp -r bin/targets/*/* ../out/ || true

echo "Done. Artifacts in ../out"
