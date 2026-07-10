# Device Name Query Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 修正 NN6000 v2 的设备 profile，并让用户能从所选上游源码准确查询 `target.devices` 配置值。

**Architecture:** 以 `source.repo` 和 `source.branch` 对应源码中的 `target/linux/<arch>/image/<subtarget>.mk` 为唯一依据。README 解释如何从 `TARGET_DEVICES` 找到 profile、用设备元数据核对型号，并按现有解析器规则把连字符转换为下划线。

**Tech Stack:** YAML、Markdown、现有 Python 配置解析器

---

### Task 1: 修正设备 profile

**Files:**
- Modify: `config.yaml`

- [ ] **Step 1: 修正 NN6000 v2 配置值**

将：

```yaml
- "nn6000_v2"
```

改为：

```yaml
- "link_nn6000_v2"
```

- [ ] **Step 2: 验证配置解析结果**

Run:

```powershell
$envFile = New-TemporaryFile
python scripts/parse_config.py config.yaml $envFile
Select-String -Path $envFile -Pattern '^TARGET_DEVICE_SYMBOLS=.*link_nn6000_v2'
Remove-Item $envFile
```

Expected: 输出的 `TARGET_DEVICE_SYMBOLS` 包含 `link_nn6000_v2`。

### Task 2: 增加查询指南

**Files:**
- Modify: `README.md`

- [ ] **Step 1: 在 target 配置说明后增加设备名称查询章节**

章节必须说明：

```text
1. 以 config.yaml 中的 source.repo 和 source.branch 为准打开上游源码。
2. 前往 target/linux/<arch>/image/<subtarget>.mk；当前配置对应 target/linux/qualcommax/image/ipq60xx.mk。
3. 搜索硬件型号，通过 DEVICE_VENDOR、DEVICE_MODEL、DEVICE_VARIANT 核对型号和版本。
4. 以 TARGET_DEVICES += 后面的 profile 为准，将其中的 - 替换为 _ 后填入 target.devices。
5. NN6000 v2：link_nn6000-v2 -> link_nn6000_v2 -> CONFIG_TARGET_DEVICE_qualcommax_ipq60xx_DEVICE_link_nn6000_v2。
```

同时提供当前上游文件的 GitHub 链接，并提醒切换源码仓库或分支时必须查询对应版本，不能沿用示例猜测。

- [ ] **Step 2: 核对 README 与配置一致**

Run:

```powershell
rg -n "link_nn6000-v2|link_nn6000_v2|TARGET_DEVICES|ipq60xx.mk" README.md config.yaml
```

Expected: README 同时包含上游 profile、配置值、查询位置和转换规则；`config.yaml` 使用 `link_nn6000_v2`。

- [ ] **Step 3: 提交实现**

```powershell
git add -- config.yaml README.md
git commit -m "Document device profile lookup"
```
