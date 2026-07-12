# Dual-Device Firmware Output Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让双设备构建保留所有请求的 profile，并只在每个设备都有可发布固件时输出 artifact。

**Architecture:** 在 `make defconfig` 后立即校验请求的设备 symbol，阻止无效配置进入小时级编译；筛选阶段先列出完整目标目录，再按请求设备记录和校验固件。上游 profile 问题只在远端诊断证明根因后做针对性兼容修复。

**Tech Stack:** Bash、OpenWrt Kconfig/Make、GitHub Actions

---

### Task 1: 校验最终设备配置

**Files:**
- Create: `tests/test_prepare_config_requires_devices.sh`
- Modify: `scripts/prepare_config.sh`

- [ ] 写入失败测试：模拟 `make defconfig` 删除 NN6000 symbol，并断言脚本失败且输出缺失 symbol。
- [ ] 运行 `bash tests/test_prepare_config_requires_devices.sh`，确认当前实现因错误地返回成功而失败。
- [ ] 在 `defconfig` 后遍历 `TARGET_DEVICE_SYMBOLS`，用现有 `target_device_config_symbol` 生成完整 symbol；缺失时打印 `.config-target.in` 中的相关 profile 后退出。
- [ ] 重跑测试，确认通过。

### Task 2: 按设备筛选和验收固件

**Files:**
- Create: `tests/test_filter_firmware_devices.sh`
- Modify: `scripts/filter_firmware.sh`

- [ ] 写入失败测试，覆盖 `.ubi` 被收集、manifest 含设备字段、缺任一请求设备时失败。
- [ ] 运行测试并确认当前筛选器按预期失败。
- [ ] 在筛选前输出 `bin/targets` 完整文件名，把 `.ubi` 加入允许类型，并按规范化后的设备 symbol 匹配文件名。
- [ ] 每个变体结束时检查所有 `TARGET_DEVICE_SYMBOLS` 至少命中一个固件；缺失时列出设备并退出。
- [ ] 重跑测试，确认通过。

### Task 3: 远端根因验证

**Files:**
- Modify only if evidence requires: `scripts/prepare_source.sh`
- Create only if evidence requires: `tests/test_prepare_source_nn6000_profile.sh`

- [ ] 运行项目指南中的全部本地测试、`bash -n scripts/*.sh tests/*.sh` 和 `git diff --check`。
- [ ] 提交并推送 Tasks 1-2，触发 `gh workflow run ci.yml -f clean_cache=true`。
- [ ] 从失败日志核对 `.config-target.in` 是否存在 `link_nn6000_v2`，并检查上游 `ipq60xx.mk` 对应设备定义。
- [ ] 若上游 profile 元数据缺失，先写复现该上游定义的失败测试，再在 `prepare_source.sh` 做仅匹配该已知定义的补丁；若元数据存在，则根据日志暴露的实际边界修复，不改动其他设备。
- [ ] 再次推送并触发干净构建，下载 artifact，核对两台设备、`.ubi`、manifest 和最终 `build.config`。
- [ ] 按最终行为同步 `README.md`，再运行全部本地检查。
