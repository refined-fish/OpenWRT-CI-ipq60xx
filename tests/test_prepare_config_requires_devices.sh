#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

mkdir -p "$tmp_dir/bin" "$tmp_dir/workspace" "$tmp_dir/openwrt/scripts/config" "$tmp_dir/openwrt/tmp"
printf 'Target-Profile: DEVICE_link_nn6000-v2\n' > "$tmp_dir/openwrt/tmp/.targetinfo"
cat > "$tmp_dir/bin/make" <<'EOF'
#!/usr/bin/env bash
sed -i '/DEVICE_link_nn6000-v2=y/d' .config
EOF
chmod +x "$tmp_dir/bin/make"

log_file="$tmp_dir/run.log"
if OPENWRT_DIR="$tmp_dir/openwrt" \
  WORKSPACE_DIR="$tmp_dir/workspace" \
  TARGET_ARCH=qualcommax \
  TARGET_SUBTARGET_SYMBOL=ipq60xx \
  TARGET_DEVICE_SYMBOL=multiple \
  TARGET_DEVICE_SYMBOLS='zn_m2 link_nn6000-v2' \
  TARGET_MULTI_PROFILE=true \
  USE_CCACHE=false \
  PATH="$tmp_dir/bin:$PATH" \
  bash "$repo_root/scripts/prepare_config.sh" >"$log_file" 2>&1; then
  echo "prepare_config.sh accepted a missing requested device" >&2
  exit 1
fi

grep -q 'CONFIG_TARGET_DEVICE_qualcommax_ipq60xx_DEVICE_link_nn6000-v2' "$log_file"
grep -q 'Target-Profile: DEVICE_link_nn6000-v2' "$log_file"
