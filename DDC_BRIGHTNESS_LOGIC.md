# DDC Brightness Logic

This file documents the current external-monitor brightness path used by Hyprland.

## Current Flow

1. Hyprland receives the hardware brightness key event.
2. The bind in [`hyprland.conf`](/home/kaixin/.dotfiles/config/hypr/hyprland.conf#L178) runs:
   - `XF86MonBrightnessUp` -> `/usr/local/sbin/ddcci8-brightness up`
   - `XF86MonBrightnessDown` -> `/usr/local/sbin/ddcci8-brightness down`
3. The helper script [`/usr/local/sbin/ddcci8-brightness`](/usr/local/sbin/ddcci8-brightness) calls `ddcutil` directly on DDC bus `8`.
4. `ddcutil` sends VCP code `0x10` (brightness) to the monitor.

## Why It Works This Way

The old path used the kernel `ddcci` backlight device plus `brightnessctl`. That path depended on:

- a boot-time systemd service: [`ddcci-i2c8-init.service`](/etc/systemd/system/ddcci-i2c8-init.service)
- a temporary `/sys/class/backlight/ddcci8` device
- `brightnessctl -d ddcci8 ...`

That path was unstable:

- the service still ran at boot
- it often failed to create the backlight device
- it touched the monitor during graphical startup
- it correlated with black-screen/login instability

Because direct DDC on bus `8` works reliably, the current logic bypasses the `ddcci` kernel-backlight path entirely.

## Current Script Logic

The current helper does this:

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

## Meaning of the Parameters

- `bus=8`
  - hardcodes the monitor I2C/DDC bus to `8`
  - this avoids scanning or guessing monitor mappings

- `step=5`
  - each key press changes brightness by `5`
  - can be overridden with `STEP_PERCENT`

- `setvcp 10`
  - VCP code `0x10` is monitor brightness

- `+ "$step"` / `- "$step"`
  - uses direct relative writes
  - avoids reading the current brightness before every key press

- `--noverify`
  - skips post-write verification
  - removes an extra round trip

- `--skip-ddc-checks`
  - skips extra DDC validation work
  - improves responsiveness

## Performance Logic

The helper used to be slower because it did:

1. `ddcutil getvcp 10 --terse --bus 8`
2. parse the current value
3. `ddcutil setvcp 10 <absolute value> --bus 8`

That meant one read plus one write per key press.

The current helper does only one write:

- `ddcutil setvcp 10 + 5 --bus 8 --noverify --skip-ddc-checks`
- `ddcutil setvcp 10 - 5 --bus 8 --noverify --skip-ddc-checks`

That is why it is noticeably faster.

## Service State

The old boot-time initializer is intentionally disabled:

- [`ddcci-i2c8-init.service`](/etc/systemd/system/ddcci-i2c8-init.service)

Reason:

- it is no longer required for brightness control
- it previously failed often
- it touched DDC during startup with no benefit

## Important Operational Notes

- Brightness control now does **not** require `sudo`.
- Hyprland binds call the helper directly.
- If bus `8` ever changes in the future, only the helper needs updating.
- If `ddcutil` stops responding, test manually with:

```bash
ddcutil getvcp 10 --bus 8
ddcutil setvcp 10 + 5 --bus 8 --noverify --skip-ddc-checks
```

## Summary

Current design:

- Hyprland keybind
- direct helper call
- direct `ddcutil` write on bus `8`
- no `brightnessctl`
- no `ddcci` backlight dependency
- no boot-time `ddcci` init service dependency

This is the full current brightness-control logic for the external monitor.
