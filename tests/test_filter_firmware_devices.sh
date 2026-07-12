#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

openwrt_dir="$tmp_dir/openwrt"
workspace_dir="$tmp_dir/workspace"
targets_dir="$openwrt_dir/bin/targets/qualcommax/ipq60xx"
mkdir -p "$targets_dir/packages" "$workspace_dir"

touch \
  "$targets_dir/immortalwrt-qualcommax-ipq60xx-zn_m2-initramfs-uImage.itb" \
  "$targets_dir/immortalwrt-qualcommax-ipq60xx-zn_m2-squashfs-factory.ubi" \
  "$targets_dir/immortalwrt-qualcommax-ipq60xx-zn_m2-squashfs-sysupgrade.bin" \
  "$targets_dir/immortalwrt-qualcommax-ipq60xx-link_nn6000-v2-squashfs-factory.bin" \
  "$targets_dir/packages/base-files.apk"

OPENWRT_DIR="$openwrt_dir" \
WORKSPACE_DIR="$workspace_dir" \
TARGET_DEVICE_SYMBOLS='zn_m2 link_nn6000-v2' \
FILES_VARIANT_NAME=default \
  bash "$repo_root/scripts/filter_firmware.sh" >/dev/null

test -f "$workspace_dir/firmware-output/immortalwrt-qualcommax-ipq60xx-zn_m2-squashfs-factory.ubi"
grep -q $'^default\tzn_m2\t' "$workspace_dir/firmware-output/firmware-list.txt"
grep -q $'^default\tlink_nn6000-v2\t' "$workspace_dir/firmware-output/firmware-list.txt"

rm -f "$targets_dir/immortalwrt-qualcommax-ipq60xx-link_nn6000-v2-squashfs-factory.bin"
rm -rf "$workspace_dir/firmware-output"
if OPENWRT_DIR="$openwrt_dir" \
  WORKSPACE_DIR="$workspace_dir" \
  TARGET_DEVICE_SYMBOLS='zn_m2 link_nn6000-v2' \
  FILES_VARIANT_NAME=default \
  bash "$repo_root/scripts/filter_firmware.sh" >"$tmp_dir/missing.log" 2>&1; then
  echo "filter_firmware.sh accepted incomplete device output" >&2
  exit 1
fi
grep -q 'Missing release firmware for requested device: link_nn6000-v2' "$tmp_dir/missing.log"

rm -rf "$openwrt_dir/bin/targets" "$workspace_dir/firmware-output"
mkdir -p "$targets_dir"
touch \
  "$targets_dir/immortalwrt-qualcommax-ipq60xx-foo-squashfs-sysupgrade.bin" \
  "$targets_dir/immortalwrt-qualcommax-ipq60xx-foo-v2-squashfs-sysupgrade.bin"

OPENWRT_DIR="$openwrt_dir" \
WORKSPACE_DIR="$workspace_dir" \
TARGET_DEVICE_SYMBOLS='foo foo-v2' \
FILES_VARIANT_NAME=default \
  bash "$repo_root/scripts/filter_firmware.sh" >/dev/null

grep -q $'^default\tfoo\t' "$workspace_dir/firmware-output/firmware-list.txt"
grep -q $'^default\tfoo-v2\t' "$workspace_dir/firmware-output/firmware-list.txt"
