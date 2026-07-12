#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

cat > "$tmp_dir/config.yaml" <<'YAML'
source:
  repo: https://example.test/immortalwrt
  branch: main
target:
  arch: qualcommax
  subtarget: ipq60xx
  device: multiple devices
  devices:
    - zn_m2
    - link_nn6000-v2
output:
  artifact: true
YAML

python3 "$repo_root/scripts/parse_config.py" "$tmp_dir/config.yaml" "$tmp_dir/env" >/dev/null
grep -qx 'TARGET_DEVICE_SYMBOLS=zn_m2 link_nn6000-v2' "$tmp_dir/env"
