#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

mkdir -p "$tmp_dir/bin" "$tmp_dir/source/target/linux/qualcommax/image"
cat > "$tmp_dir/source/target/linux/qualcommax/image/ipq60xx.mk" <<'EOF'
define Device/link_nn6000-v1
	$(Device/link_nn6000-common)
endef
define Device/link_nn6000-v2
	$(Device/link_nn6000-common)
endef
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
[ "$(grep -Fc '$(call Device/link_nn6000-common,$(1))' "$makefile")" -eq 2 ]
! grep -Fq '$(Device/link_nn6000-common)' "$makefile"
