#!/usr/bin/env bash
set -euo pipefail

: "${SOURCE_REPO:?SOURCE_REPO is required}"
: "${SOURCE_BRANCH:?SOURCE_BRANCH is required}"
: "${OPENWRT_DIR:?OPENWRT_DIR is required}"

if [ -d "$OPENWRT_DIR" ]; then
  echo "OpenWrt source already exists: $OPENWRT_DIR"
  exit 0
fi

git clone --depth 1 --branch "$SOURCE_BRANCH" "$SOURCE_REPO" "$OPENWRT_DIR"

# Work around VIKINGYFY/immortalwrt 4952576: the trailing continuation
# folds BuildTarget into DEFAULT_PACKAGES and corrupts tmp/.config-target.in.
QUALCOMMBE_MAKEFILE="$OPENWRT_DIR/target/linux/qualcommbe/Makefile"
if grep -q 'kmod-dsa kmod-dsa-qca8k kmod-phy-aquantia kmod-phy-qca83xx \\$' "$QUALCOMMBE_MAKEFILE" 2>/dev/null; then
  sed -i '/kmod-dsa kmod-dsa-qca8k kmod-phy-aquantia kmod-phy-qca83xx \\$/s/ \\$//' "$QUALCOMMBE_MAKEFILE"
  echo "Fixed qualcommbe DEFAULT_PACKAGES trailing continuation"
fi

# Remove download mirrors that may fail on GitHub Actions runners
PROJECT_MIRRORS_FILE="$OPENWRT_DIR/scripts/projectsmirrors.json"
if [ -f "$PROJECT_MIRRORS_FILE" ]; then
  sed -i '/\.cn\//d; /tencent/d; /aliyun/d' "$PROJECT_MIRRORS_FILE"
  echo "Removed restricted mirrors from projectsmirrors.json"
fi
