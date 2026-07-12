#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

workspace_dir="$tmp_dir/workspace"
openwrt_dir="$tmp_dir/openwrt"
mkdir -p "$tmp_dir/bin" "$workspace_dir/scripts" "$workspace_dir/files-variants" "$openwrt_dir"

cat > "$tmp_dir/bin/make" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [ -n "${TARGET_DEVICES+x}" ]; then
  echo "TARGET_DEVICES leaked into OpenWrt build: $TARGET_DEVICES" >&2
  exit 1
fi
EOF
chmod +x "$tmp_dir/bin/make"

for command in lscpu free df du; do
  cat > "$tmp_dir/bin/$command" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
  chmod +x "$tmp_dir/bin/$command"
done

cat > "$tmp_dir/bin/nproc" <<'EOF'
#!/usr/bin/env bash
echo 1
EOF
chmod +x "$tmp_dir/bin/nproc"

cat > "$workspace_dir/scripts/apply_files.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [ "$1" = prepare ]; then
  printf 'default\t\n' > "$WORKSPACE_DIR/files-variants/variants.tsv"
fi
EOF
cat > "$workspace_dir/scripts/filter_firmware.sh" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$workspace_dir/scripts/"*.sh

OPENWRT_DIR="$openwrt_dir" \
WORKSPACE_DIR="$workspace_dir" \
TARGET_ARCH=qualcommax \
TARGET_DEVICES='zn_m2|link_nn6000-v2' \
USE_CCACHE=false \
PATH="$tmp_dir/bin:$PATH" \
  bash "$repo_root/scripts/build_openwrt.sh"
