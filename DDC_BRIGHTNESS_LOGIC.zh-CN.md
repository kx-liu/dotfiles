# DDC 亮度控制逻辑

本文档说明当前 Hyprland 中外接显示器亮度控制的完整路径。

## 当前流程

1. Hyprland 收到亮度快捷键事件。
2. [`hyprland.conf`](/home/kaixin/.dotfiles/config/hypr/hyprland.conf#L178) 中的绑定执行：
   - `XF86MonBrightnessUp` -> `/usr/local/sbin/ddcci8-brightness up`
   - `XF86MonBrightnessDown` -> `/usr/local/sbin/ddcci8-brightness down`
3. 辅助脚本 [`/usr/local/sbin/ddcci8-brightness`](/usr/local/sbin/ddcci8-brightness) 直接调用 `ddcutil`，并固定使用 DDC bus `8`。
4. `ddcutil` 向显示器发送 VCP `0x10`（Brightness）命令。

## 为什么现在这样实现

旧路径使用的是内核 `ddcci` 背光设备加 `brightnessctl`。它依赖：

- 启动期 systemd 服务：[`ddcci-i2c8-init.service`](/etc/systemd/system/ddcci-i2c8-init.service)
- 临时创建的 `/sys/class/backlight/ddcci8`
- `brightnessctl -d ddcci8 ...`

这条路径不稳定，主要问题是：

- 服务每次开机都会运行
- 经常无法成功创建 `ddcci8` 背光设备
- 会在图形会话启动时碰显示器的 DDC
- 与黑屏和自动登出问题有关联

因为直接通过 DDC bus `8` 控制已经可以稳定工作，所以现在完全绕过 `ddcci` 内核背光路径。

## 当前脚本逻辑

当前脚本核心逻辑如下：

```bash
#!/usr/bin/env bash
set -euo pipefail

die() { echo "usage: $0 {up|down|set <0-100%>}" >&2; exit 2; }

bus="${DDCUTIL_BUS:-8}"
step="${STEP_PERCENT:-5}"
common_args=(--bus "$bus" --noverify --skip-ddc-checks)

command -v /usr/bin/ddcutil >/dev/null 2>&1 || {
  echo "ddcutil not found" >&2
  exit 1
}

case "${1:-}" in
  up)   exec /usr/bin/ddcutil setvcp 10 + "$step" "${common_args[@]}" ;;
  down) exec /usr/bin/ddcutil setvcp 10 - "$step" "${common_args[@]}" ;;
  set)
    v="${2:-}"
    [[ "$v" =~ ^([0-9]{1,3})%$ ]] || die
    n="${BASH_REMATCH[1]}"
    (( n>=0 && n<=100 )) || die
    exec /usr/bin/ddcutil setvcp 10 "$n" "${common_args[@]}" ;;
  *) die ;;
esac
```

## 参数含义

- `bus=8`
  - 直接把显示器所在的 I2C/DDC 总线固定为 `8`
  - 不再做扫描、猜测、映射查找

- `step=5`
  - 每次按键增减 `5`
  - 可以通过 `STEP_PERCENT` 覆盖

- `setvcp 10`
  - VCP `0x10` 就是显示器亮度

- `+ "$step"` / `- "$step"`
  - 直接做相对写入
  - 避免每次按键前先读取当前亮度

- `--noverify`
  - 跳过写入后的校验
  - 少一次往返

- `--skip-ddc-checks`
  - 跳过额外的 DDC 检查
  - 用来降低延迟

## 为什么现在更快

之前的慢路径是：

1. `ddcutil getvcp 10 --terse --bus 8`
2. 解析当前亮度
3. `ddcutil setvcp 10 <绝对值> --bus 8`

也就是说，每按一次键都要做一次读取加一次写入。

现在的新路径只做一次写入：

- `ddcutil setvcp 10 + 5 --bus 8 --noverify --skip-ddc-checks`
- `ddcutil setvcp 10 - 5 --bus 8 --noverify --skip-ddc-checks`

这就是现在明显更快的原因。

## 服务状态

旧的启动期初始化服务现在是刻意禁用的：

- [`ddcci-i2c8-init.service`](/etc/systemd/system/ddcci-i2c8-init.service)

原因：

- 它已经不是亮度控制所必需
- 它以前经常失败
- 它会在启动期碰 DDC，但没有实际收益

## 运行注意事项

- 现在亮度控制**不需要** `sudo`
- Hyprland 直接调用脚本
- 如果未来 bus `8` 发生变化，只需要改这个脚本
- 如果 `ddcutil` 未来失效，可以手动测试：

```bash
ddcutil getvcp 10 --bus 8
ddcutil setvcp 10 + 5 --bus 8 --noverify --skip-ddc-checks
```

## 总结

当前设计是：

- Hyprland 键位绑定
- 直接调用辅助脚本
- 脚本直接向 DDC bus `8` 写入
- 不再依赖 `brightnessctl`
- 不再依赖 `ddcci` 背光设备
- 不再依赖启动期 `ddcci` 初始化服务

这就是当前这台机器上外接显示器亮度控制的完整逻辑。
