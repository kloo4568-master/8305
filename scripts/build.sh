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
wget -nv -O ${IB_NAME} ${IB_URL}

# Clean previous extracted imagebuilder dirs to avoid multiple matches
rm -rf openwrt-imagebuilder-* || true

# Extract imagebuilder archive
tar -xJf ${IB_NAME}

# Enter the first matching extracted directory safely
shopt -s nullglob
dirs=(openwrt-imagebuilder-*)
if [ ${#dirs[@]} -eq 0 ]; then
  echo "Error: extracted imagebuilder directory not found" >&2
  exit 1
fi
cd "${dirs[0]}"

make image PROFILE="${PROFILE}" PACKAGES="${PACKAGES}" FILES="../files"
mkdir -p ../out
cp -r bin/targets/*/* ../out/ || true

echo "Done. Artifacts in ../out"
