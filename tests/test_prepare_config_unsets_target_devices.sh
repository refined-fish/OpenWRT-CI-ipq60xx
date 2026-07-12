#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

mkdir -p "$tmp_dir/bin" "$tmp_dir/workspace/config" "$tmp_dir/openwrt/scripts/config"
echo 'CONFIG_TARGET_qualcommax=y' > "$tmp_dir/workspace/config/.config"

cat > "$tmp_dir/bin/make" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [ -n "${TARGET_DEVICES+x}" ]; then
  echo "TARGET_DEVICES leaked into OpenWrt make: $TARGET_DEVICES" >&2
  exit 1
fi
EOF
chmod +x "$tmp_dir/bin/make"

OPENWRT_DIR="$tmp_dir/openwrt" \
WORKSPACE_DIR="$tmp_dir/workspace" \
TARGET_ARCH=qualcommax \
TARGET_SUBTARGET_SYMBOL=ipq60xx \
TARGET_DEVICE_SYMBOL=multiple \
TARGET_DEVICES='zn_m2|link_nn6000-v2' \
USE_CCACHE=false \
PATH="$tmp_dir/bin:$PATH" \
  bash "$repo_root/scripts/prepare_config.sh"
