#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

mkdir -p "$tmp_dir/bin" "$tmp_dir/source/target/linux/qualcommbe"
cat > "$tmp_dir/source/target/linux/qualcommbe/Makefile" <<'EOF'
DEFAULT_PACKAGES += \
	kmod-dsa kmod-dsa-qca8k kmod-phy-aquantia kmod-phy-qca83xx \

$(eval $(call BuildTarget))
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

makefile="$tmp_dir/openwrt/target/linux/qualcommbe/Makefile"
if grep -q 'kmod-phy-qca83xx \\$' "$makefile"; then
  echo "qualcommbe DEFAULT_PACKAGES still escapes into BuildTarget" >&2
  exit 1
fi
grep -Fqx '$(eval $(call BuildTarget))' "$makefile"
