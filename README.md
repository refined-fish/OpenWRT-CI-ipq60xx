# OpenWRT-CI-ipq60xx

个人自用的 ipq60xx OpenWrt/ImmortalWrt GitHub Actions 编译仓库。目标是尽量复刻本地 `make menuconfig && make` 的编译流程，只把耗时构建放到 GitHub runner 上执行。

仓库只保留这几个入口：

- `.github/workflows/ci.yml`：手动触发的完整编译流程。
- `config.yaml`：源码、target、feeds、镜像和上传配置。
- `applist`：没有 `config/.config` 时追加的软件包列表。
- `config/.config`：可选，存在时优先使用手工配置。
- `scripts/`：workflow 调用的脚本。

## 使用方法

1. 编辑 `config.yaml`，确认源码、分支、架构、设备、feeds、额外包、镜像和输出方式。
2. 如果已有本地 `make menuconfig` 生成的配置，把它放到 `config/.config`。
3. 如果没有 `config/.config`，编辑 `applist`，一行一个 OpenWrt 包名。
4. 如需预置固件根目录文件，设置 GitHub Secret `FILES_ZIP_URL`。
5. 如需 WebDAV 上传，设置 `WEBDAV_URL`、`WEBDAV_USERNAME`、`WEBDAV_PASSWORD`。
6. 打开 GitHub Actions，手动运行 `OpenWrt CI`。

## config.yaml

源码配置：

```yaml
source:
  repo: "https://github.com/VIKINGYFY/immortalwrt"
  branch: "main"
```

target 配置使用 OpenWrt Kconfig symbol。ipq60xx 设备在当前源码中对应 `qualcommax/ipq60xx`：

```yaml
target:
  arch: "qualcommax"
  subtarget: "ipq60xx"
  device: "multiple devices"
  devices:
    - "zn_m2"
    - "link_nn6000-v2"
```

`zn_m2` 对应 OpenWrt 配置符号 `CONFIG_TARGET_DEVICE_qualcommax_ipq60xx_DEVICE_zn_m2`。

### 查询准确的设备名称

`devices` 填写的是源码中的设备 profile，不是路由器的商品名。名称必须以 `config.yaml` 中 `source.repo` 和 `source.branch` 指向的源码版本为准：

1. 打开源码中的 `target/linux/<arch>/image/<subtarget>.mk`。当前配置对应 [VIKINGYFY/immortalwrt 的 ipq60xx.mk](https://github.com/VIKINGYFY/immortalwrt/blob/main/target/linux/qualcommax/image/ipq60xx.mk)。
2. 在文件中搜索设备型号，通过同一设备定义中的 `DEVICE_VENDOR`、`DEVICE_MODEL` 和 `DEVICE_VARIANT` 核对厂商、型号及硬件版本。
3. 找到该设备对应的 `TARGET_DEVICES += <profile>`，以 `<profile>` 为准确名称。
4. 把 `<profile>` 原样填入 `devices`，不要改写其中的连字符或下划线。

例如 NN6000 v2 的源码定义是 `TARGET_DEVICES += link_nn6000-v2`，因此应填写：

```yaml
devices:
  - "link_nn6000-v2"
```

工作流会据此生成 `CONFIG_TARGET_DEVICE_qualcommax_ipq60xx_DEVICE_link_nn6000-v2`。如果修改了 `source.repo`、`source.branch`、`target.arch` 或 `target.subtarget`，必须到对应源码和版本中重新查询，不能直接沿用这里的示例。

多设备编译写法：

```yaml
target:
  arch: "qualcommax"
  subtarget: "ipq60xx"
  device: "multiple devices"
  devices:
    - "zn_m2"
    - "link_nn6000-v2"
```

额外 feeds 会追加到 `feeds.conf.default` 后执行 `./scripts/feeds update -a` 和 `./scripts/feeds install -a`：

```yaml
feeds:
  - name: nikki
    url: https://github.com/nikkinikki-org/OpenWrt-nikki
    branch: main
  - name: sqm-nss
    url: https://github.com/rickkdotnet/sqm-scripts-nss
    branch: main
```

不支持 feeds 的第三方包使用 `extra_packages` 克隆到 OpenWrt 源码目录内：

```yaml
extra_packages:
  - name: easytier
    url: https://github.com/EasyTier/luci-app-easytier
    dir: package/luci-app-easytier
```

`dir` 必须是源码目录内的相对路径。

镜像配置：

```yaml
image:
  filesystems:
    - squashfs
  initramfs: false
  recovery: false
  rootfs_size_mb: "512"
```

输出配置：

```yaml
output:
  artifact: false
  webdav: true

upload:
  webdav_path: /openwrt
  webdav_mode: bundle
```

至少启用 `artifact` 或 `webdav` 之一。启用 WebDAV 时必须设置对应 Secrets。

## .config 与 applist

如果 `config/.config` 存在，workflow 会直接复制它到 OpenWrt 源码根目录，执行 `make defconfig` 补全后开始编译。这种模式会跳过按 `config.yaml` 和 `applist` 生成配置的步骤，最接近本地已有配置复用。

如果 `config/.config` 不存在，脚本会生成一个 seed `.config`：

- 写入 target 架构、subtarget 和 device。
- 按 `build.language` 启用 LuCI 中文相关包。
- 读取 `applist` 中的软件包并写入 `CONFIG_PACKAGE_<name>=y`。
- 写入 `image` 中的 rootfs 和镜像文件系统选项；x86 专用引导和虚拟化镜像选项不会用于 ipq60xx。
- 最后执行 `make defconfig` 补全依赖。

`make defconfig` 后会逐项确认请求的设备 profile 仍为 `y`。任何设备 symbol 被上游 Kconfig 删除时，workflow 会在正式编译前失败并指出缺失设备。

`applist` 支持空行和 `#` 注释。

## files.zip

`FILES_ZIP_URL` 是 GitHub Secret，指向一个 zip 或一个包含多个 zip 链接的 HTTP/WebDAV 目录。

单个 zip 时，内容会被解压到 OpenWrt 源码根目录的 `files/`。zip 首层应直接是固件根目录内容，例如：

```text
etc/config/network
usr/bin/custom-script
```

目录中存在多个 zip 时，每个 zip 会作为一个 files 变体。第一个变体执行完整编译，后续变体会清空并重新解压 `files/`，移出旧的 `bin/targets` 产物后再次执行完整 `make -j$(nproc) V=s`，让 OpenWrt 按当前 `files/` 内容增量生成新固件。输出固件会加上 zip 文件名对应的前缀。

zip 解压使用 Python 实现，会校验 zip、规避路径穿越、尝试处理 UTF-8/GBK 文件名，并把解压出的普通文件赋予可执行权限。

workflow 不会根据 `applist` 自动下载或补充固件根目录文件。mihomo、geoip/geosite、Model.bin、zashboard、EasyTier 二进制等内容如需预置，必须包含在用户提供的 zip 中；解压后不会再被仓库脚本覆盖。

## 缓存

这个 workflow 会缓存 5 类内容：

| 缓存族 | 内容 | 什么时候最容易失效 |
|---|---|---|
| `openwrt-dl-*` | `dl` 下载文件 | 源码仓库 / 分支 / target / `CACHE_DIGEST` 变化时 |
| `openwrt-toolchain-*` | `staging_dir/host*`、`staging_dir/tool*`、`build_dir/host`、`build_dir/toolchain-*` | 编译环境、配置摘要或 target 变化时 |
| `openwrt-target-*` | `staging_dir/target-*`、`build_dir/target-*` | target、`.config`、`applist`、feeds 相关内容变化时 |
| `openwrt-feeds-*` | `feeds`、`package/feeds` | feeds、`extra_packages`、源码分支或 target 变化时 |
| `openwrt-ccache-*` | `.ccache` | 源码、target、编译参数变化时；仅在 `build.use_ccache` 启用时使用 |

缓存恢复阶段不会按剩余空间跳过 `target` 或 `feeds` 缓存。当前 GitHub runner 空间足以完成本项目编译，因此不额外运行磁盘清理 action。

### 先看结论

- 你改的是 `config.yaml`、`applist`、`scripts/prepare_feeds.sh`、`scripts/prepare_config.sh`、`scripts/build_openwrt.sh`、`scripts/parse_config.py`，会影响 `CACHE_DIGEST`，进而让本次优先命中的缓存键变化。
- 你改的是 `config/.config`，也会进入 `CACHE_DIGEST`。
- 你改的是 `feeds` 或 `extra_packages`，通常会影响 `feeds` 缓存和 `target` / `toolchain` / `ccache` 的命中情况。
- 你只是重新跑同一份配置，通常可以继续复用缓存。

### 改什么，会影响哪些缓存

| 你改了什么 | 主要受影响的缓存 | 说明 |
|---|---|---|
| `config.yaml` | 全部缓存族 | 仓库、分支、target、镜像、输出、feeds、额外包等配置都会参与缓存摘要。 |
| `config/.config` | `toolchain`、`target`、`ccache`、`dl` | 该文件会直接进入 `CACHE_DIGEST`，配置变化越大，旧缓存越不容易复用。 |
| `applist` | `toolchain`、`target`、`ccache` | 包列表变化会改变生成配置，通常会让编译缓存失去最佳命中。 |
| `feeds` | `feeds`、`target`、`toolchain`、`ccache` | feeds 更新会直接影响 package tree，也会间接影响后续编译缓存。 |
| `extra_packages` | `feeds`、`target`、`toolchain`、`ccache` | 额外包会在源码树内更新、重置或重新克隆，相关缓存更容易失效。 |
| `source.repo` / `source.branch` | 全部缓存族 | 源码不同，缓存基本不能混用。 |
| `target.arch` / `target.subtarget` / `target.device` | 全部缓存族 | 目标不同，缓存基本不能混用。 |
| `build.use_ccache` | `ccache` | 只有开启时才会恢复、保存 `ccache`。 |

### 什么情况下建议直接清缓存

遇到下面这些情况，建议在运行时把 `clean_cache` 设为 `true`：

- 换了源码仓库或源码分支。
- 换了架构、subtarget 或设备。
- 大量修改了 `feeds`、`extra_packages`、`applist` 或 `.config`。
- 之前的失败看起来像缓存污染，而不是代码本身的问题。
- 你希望这次编译尽量从干净状态重新来过。

`clean_cache=true` 时，workflow 会先清理当前源码仓库、源码分支和 target 相关的旧缓存，再跳过本次缓存恢复；如果后续编译成功，仍会保存新缓存。

### 还要知道的几件事

- 这个 workflow 的缓存是“带回退”的：先尝试精确的 `CACHE_DIGEST` 键，再回退到更宽的同仓库、同分支、同 target 前缀。
- 保存和修剪都是 success-only：只有当前 workflow 成功时才会保存缓存，也只会在对应缓存保存成功后修剪旧缓存。
- 普通编译失败不会主动删掉旧缓存，旧缓存会继续留到后续成功运行、手动清理或 GitHub 自己回收。
- GitHub Actions 缓存有配额限制，旧缓存也可能因配额或平台策略被回收。
- 这里不缓存最终固件、`bin/targets` 输出、artifact 包或 WebDAV 上传结果。

## 上传

固件筛选支持目标发布的 `.bin`、`.ubi` 和常见虚拟磁盘格式，并继续排除 kernel、rootfs、initramfs、manifest 等非发布文件。`firmware-list.txt` 每行依次记录 files 变体、设备 symbol、大小和文件名；每个请求设备都必须至少有一个可发布固件，否则 workflow 失败且不会上传不完整 artifact。

`artifact` 启用时，`firmware-output/` 中的每个文件都会作为独立的 GitHub Actions artifact 上传，保留 14 天，可按需选择下载。artifact 名称包含目标和原文件名；多 files 变体的固件原文件名会带上变体名前缀，避免同名并便于区分。workflow 内部用于跨 job 传输的临时 artifact 会在独立制品发布成功后自动删除。

`webdav` 启用时，固件会先打包成 `tar.zst`，再上传到：

```text
<WEBDAV_URL>/<upload.webdav_path>/<arch>/<subtarget>/<device>/<时间戳>/
```

`upload.webdav_mode` 默认为 `bundle`，会把 `firmware-output/` 打包成一个 `tar.zst` 上传；也可以设为 `direct` 逐文件上传。

需要设置 Secrets：

- `WEBDAV_URL`
- `WEBDAV_USERNAME`
- `WEBDAV_PASSWORD`

如果同时启用 artifact 和 WebDAV，WebDAV 失败不会导致整个 workflow 失败，artifact 会作为兜底产物。

## 本地文件规范

workflow 运行在 Ubuntu，脚本和配置文件需要使用 LF 换行。`.gitattributes` 已固定常用文本文件换行，workflow 也会在运行时对 shell 脚本执行 `dos2unix` 和 `chmod +x`。
