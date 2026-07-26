#!/bin/bash
set -euo pipefail

# WR8305RT ImageBuilder build script
# Target:
#   Device: ZBT-WR8305RT
#   CPU: MT7620A
#   OpenWrt: 22.03.7
#   Target: ramips/mt7620


OPENWRT_VERSION=${1:-22.03.7}
TARGET=${2:-ramips}
SUBTARGET=${3:-mt7620}
PROFILE=${4:-zbtlink_zbt-wr8305rt}


PACKAGES=${5:-"
kmod-usb-core
kmod-usb2
kmod-usb-storage
kmod-scsi-core
kmod-fs-ext4
block-mount
e2fsprogs
e2fsprogs-extra
"}


echo "================================="
echo "OpenWrt ImageBuilder"
echo "Version : $OPENWRT_VERSION"
echo "Target  : $TARGET"
echo "Sub     : $SUBTARGET"
echo "Profile : $PROFILE"
echo "================================="


# 检查 files

if [ ! -f "../files/etc/config/fstab" ]; then
    echo "ERROR: missing files/etc/config/fstab"
    exit 1
fi


if [ ! -f "../files/etc/uci-defaults/99-extroot" ]; then
    echo "WARNING: missing 99-extroot"
fi



IB_NAME="openwrt-imagebuilder-${OPENWRT_VERSION}-${TARGET}-${SUBTARGET}.Linux-x86_64.tar.xz"

IB_URL="https://downloads.openwrt.org/releases/${OPENWRT_VERSION}/targets/${TARGET}/${SUBTARGET}/${IB_NAME}"


echo "Downloading ImageBuilder:"
echo "$IB_URL"



# 清理旧文件

rm -rf openwrt-imagebuilder-* || true
rm -f "$IB_NAME" || true



wget -nv \
    -O "$IB_NAME" \
    "$IB_URL"



echo "Extracting..."

tar -xJf "$IB_NAME"



IB_DIR=$(find . \
    -maxdepth 1 \
    -type d \
    -name "openwrt-imagebuilder-*" \
    -print -quit)


if [ -z "$IB_DIR" ]; then
    echo "ERROR: ImageBuilder directory not found"
    exit 1
fi



cd "$IB_DIR"



echo "Checking profile..."

make info | grep "$PROFILE" || {
    echo "ERROR: profile not found:"
    echo "$PROFILE"
    exit 1
}



echo "Building firmware..."

make image \
    PROFILE="$PROFILE" \
    PACKAGES="$PACKAGES" \
    FILES="../files"



echo "Collect firmware..."

mkdir -p ../out


cp -rv \
    bin/targets/*/* \
    ../out/



echo "================================="
echo "Build finished"
echo "Output:"
ls -lh ../out
echo "================================="
