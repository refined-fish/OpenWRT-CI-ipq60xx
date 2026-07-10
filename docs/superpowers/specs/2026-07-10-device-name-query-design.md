# 设备名称查询指南设计

## 目标

让用户能从 `config.yaml` 指定的上游源码和分支中查询准确的设备 profile 名称，并正确填写 `target.devices`，避免工作流因猜测商品名而选不中设备。

## 修改范围

- 修正 `config.yaml` 中不完整的 `nn6000_v2` 为 `link_nn6000_v2`。
- 在 README 的 `target` 配置说明附近增加查询指南。
- 不增加脚本、依赖或工作流校验。

## 查询规则

1. 根据 `source.repo` 和 `source.branch` 打开对应上游源码。
2. 根据 `target.arch` 和 `target.subtarget` 定位 `target/linux/<arch>/image/<subtarget>.mk`；本仓库对应 `target/linux/qualcommax/image/ipq60xx.mk`。
3. 在文件中搜索硬件型号，并以 `TARGET_DEVICES += <profile>` 的值为准；`DEVICE_VENDOR`、`DEVICE_MODEL` 和 `DEVICE_VARIANT` 用于核对完整硬件名称及版本。
4. 填入 `config.yaml` 时，将 profile 中的连字符 `-` 替换为下划线 `_`，与本仓库生成的 Kconfig symbol 一致。
5. 用 NN6000 v2 示例说明：上游 profile 是 `link_nn6000-v2`，配置值是 `link_nn6000_v2`，最终符号是 `CONFIG_TARGET_DEVICE_qualcommax_ipq60xx_DEVICE_link_nn6000_v2`。

## 验证

- 检查 README 中的路径、转换规则和示例与当前上游源码一致。
- 运行现有配置解析器，确认输出包含 `link_nn6000_v2` 对应的设备符号。
