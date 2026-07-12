#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

mkdir -p "$tmp_dir/bin" "$tmp_dir/source/target/linux/qualcommax/image"
cat > "$tmp_dir/source/target/linux/qualcommax/image/ipq60xx.mk" <<'EOF'
define Device/link_nn6000-common
	$(call Device/FitImage)
	$(call Device/EmmcImage)
	DEVICE_VENDOR := Link
	SOC := ipq6000
	KERNEL_SIZE := 6144k
	DEVICE_DTS_CONFIG := config@cp03-c1
	DEVICE_PACKAGES := ipq-wifi-link_nn6000
	IMAGE/factory.bin := append-kernel | pad-to $$(KERNEL_SIZE) | append-rootfs | append-metadata
endef

define Device/link_nn6000-v1
	$(Device/link_nn6000-common)
	DEVICE_MODEL := NN6000 v1
	DEVICE_VARIANT := v1
endef
TARGET_DEVICES += link_nn6000-v1

define Device/link_nn6000-v2
	$(Device/link_nn6000-common)
	DEVICE_MODEL := NN6000 v2
	DEVICE_VARIANT := v2
endef
TARGET_DEVICES += link_nn6000-v2
EOF

cat > "$tmp_dir/bin/git" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
target="${@: -1}"
mkdir -p "$target"
cp -R "$FAKE_SOURCE/." "$target/"
EOF
chmod +x "$tmp_dir/bin/git"

OPENWRT_DIR="$tmp_dir/openwrt" \
SOURCE_REPO=https://example.test/immortalwrt.git \
SOURCE_BRANCH=main \
FAKE_SOURCE="$tmp_dir/source" \
PATH="$tmp_dir/bin:$PATH" \
  bash "$repo_root/scripts/prepare_source.sh"

makefile="$tmp_dir/openwrt/target/linux/qualcommax/image/ipq60xx.mk"
grep -Fq '$(call Device/FitImage)' "$makefile"
grep -Fq '$(Device/link_nn6000-v1)' "$makefile"
! grep -Fq 'link_nn6000-common' "$makefile"
