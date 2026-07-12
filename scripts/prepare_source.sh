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

IPQ60XX_IMAGE_MAKEFILE="$OPENWRT_DIR/target/linux/qualcommax/image/ipq60xx.mk"
if grep -Fq '$(Device/link_nn6000-common)' "$IPQ60XX_IMAGE_MAKEFILE" 2>/dev/null; then
  patch -d "$OPENWRT_DIR" -p1 <<'PATCH'
--- a/target/linux/qualcommax/image/ipq60xx.mk
+++ b/target/linux/qualcommax/image/ipq60xx.mk
@@ -1,24 +1,18 @@
-define Device/link_nn6000-common
-	$(call Device/FitImage)
-	$(call Device/EmmcImage)
-	DEVICE_VENDOR := Link
-	SOC := ipq6000
-	KERNEL_SIZE := 6144k
-	DEVICE_DTS_CONFIG := config@cp03-c1
-	DEVICE_PACKAGES := ipq-wifi-link_nn6000
-	IMAGE/factory.bin := append-kernel | pad-to $$(KERNEL_SIZE) | append-rootfs | append-metadata
-endef
-
-define Device/link_nn6000-v1
-	$(Device/link_nn6000-common)
-	DEVICE_MODEL := NN6000 v1
-	DEVICE_VARIANT := v1
-endef
-TARGET_DEVICES += link_nn6000-v1
-
-define Device/link_nn6000-v2
-	$(Device/link_nn6000-common)
-	DEVICE_MODEL := NN6000 v2
-	DEVICE_VARIANT := v2
-endef
-TARGET_DEVICES += link_nn6000-v2
+define Device/link_nn6000-v1
+	$(call Device/FitImage)
+	$(call Device/EmmcImage)
+	DEVICE_VENDOR := Link
+	DEVICE_MODEL := NN6000 v1
+	SOC := ipq6000
+	KERNEL_SIZE := 6144k
+	DEVICE_DTS_CONFIG := config@cp03-c1
+	DEVICE_PACKAGES := ipq-wifi-link_nn6000
+	IMAGE/factory.bin := append-kernel | pad-to $$(KERNEL_SIZE) | append-rootfs | append-metadata
+endef
+TARGET_DEVICES += link_nn6000-v1
+
+define Device/link_nn6000-v2
+	$(Device/link_nn6000-v1)
+	DEVICE_MODEL := NN6000 v2
+endef
+TARGET_DEVICES += link_nn6000-v2
PATCH
  echo "Replaced broken NN6000 common profile with upstream device inheritance"
fi

# Remove download mirrors that may fail on GitHub Actions runners
PROJECT_MIRRORS_FILE="$OPENWRT_DIR/scripts/projectsmirrors.json"
if [ -f "$PROJECT_MIRRORS_FILE" ]; then
  sed -i '/\.cn\//d; /tencent/d; /aliyun/d' "$PROJECT_MIRRORS_FILE"
  echo "Removed restricted mirrors from projectsmirrors.json"
fi
