# Local Delta From This Repo

This file records how the current Ubuntu machine differs from this dotfiles repo.
Use it as a reference when refining the Fedora setup later.

## Scope

Compared paths:

- Repo Waybar: `config/waybar`
- Live Waybar: `~/.config/waybar`
- Repo Hypr: `config/hypr`
- Live Hypr: `~/.config/hypr`

The repo itself currently also has one local modification:

- `config/waybar/scripts/system-info.sh`

## High-Level Summary

The live Ubuntu machine diverged from the repo in two main ways:

1. It uses a different multi-monitor Hyprland and Waybar layout.
2. It trims the repo's hardware-heavy Waybar setup into a simpler CPU/RAM/network/audio-oriented bar.

In practice, the live machine is a lighter, more Ubuntu-specific desktop variant of the Fedora-oriented repo.

## Waybar Differences

### Layout

Repo:

- Single Waybar definition
- Height `38`
- Includes GPU group
- Uses one central `clock`

Live machine:

- Three Waybar instances in one config array
- Bound to `DP-1`, `DP-2`, `DP-3`
- Height reduced to `34`
- Main bar on `DP-1`
- Side bars on `DP-2` and `DP-3`
- Uses `clock#main` and `clock#side`
- No GPU group in the active layout

### Modules

Repo keeps more modules enabled:

- `bluetooth`
- `custom/input-source`
- `group/gpu`
- GPU scripts and telemetry

Live machine keeps a narrower set:

- `custom/spotify`
- `pulseaudio`
- `network`
- `custom/cpu`
- `custom/cpu-temp`
- `memory`
- `custom/theme-toggle`
- `custom/power`

Live-only module structure changes:

- Added `custom/launcher`
- Shortened `hyprland/window` max length from `80` to `48`
- Split clock into `clock#main` and `clock#side`
- Removed Bluetooth and input-source from active connectivity group

### Styling

Repo style direction:

- Larger font size: `12.5px`
- Noto Sans based stack
- More modules styled, including GPU and IME
- Slightly roomier spacing

Live style direction:

- Smaller bar and tighter spacing
- Global font size `11px`
- Text-heavy modules forced to `JetBrains Mono`
- Icon-heavy modules forced to `JetBrainsMono Nerd Font Mono`
- Tooltip font heavily overridden to force a mono look

Important font note:

- The exact repo font family names `Font Awesome 6 Free` and `Symbols Nerd Font Mono` do not resolve cleanly on this Ubuntu machine.
- Installed and actually usable families here include `Noto Sans`, `Noto Sans CJK SC`, `JetBrains Mono`, `JetBrainsMono Nerd Font Mono`, and `Noto Sans Mono`.

### Spotify

Repo and live both now use the custom `custom/spotify` module instead of the built-in MPRIS module.

Live-specific adjustments:

- Poll loop reduced from `1s` to `0.2s` to reduce visible play/pause lag
- Bar still relies on polling, not DBus event push

### Power Menu

Repo power menu:

- YAD-based list dialog
- Included Windows reboot path
- More Fedora-oriented session wording

Live power menu:

- `wofi`/`fuzzel`/`rofi` dropdown menu
- Plain text labels only
- No Windows reboot path

### CPU / RAM Click Behavior

Repo baseline:

- Click opens a YAD popup in `system-info.sh`

Live machine currently:

- Click opens a `zenity --text-info` dialog
- Static snapshot, not live-updating
- Chosen because this machine does not have `yad`

Why it diverged:

- `yad` is absent on this machine
- `wofi`-based and repeated-notification experiments were tried and then abandoned
- `zenity` is the cleanest currently-installed non-spamming GUI fallback

## Waybar Script Differences

### Repo-only scripts not present on the live machine

- `config/waybar/scripts/bluetooth-toggle.sh`
- `config/waybar/scripts/clipboard-menu.sh`
- `config/waybar/scripts/clipboard-status.sh`
- `config/waybar/scripts/gpu-status.sh`
- `config/waybar/scripts/hw-head.sh`

### Live script differences worth carrying back selectively

`~/.config/waybar/scripts/spotify.sh`

- Removed unused `refresh_waybar` relaunch attempt
- Poll interval changed to `0.2s`

`~/.config/waybar/scripts/power-menu.sh`

- Uses dropdown menu apps instead of YAD
- Plain text actions
- Simpler session menu logic

`~/.config/waybar/scripts/system-info.sh`

- Reworked from YAD popup into `zenity` text dialog
- CPU and memory only
- No GPU section

`~/.config/waybar/scripts/temp-status.sh`

- More defensive CPU temperature probing
- Broader thermal fallback path
- GPU temp explicitly disabled on this machine

`~/.config/waybar/scripts/theme-toggle.sh`

- Reloads Waybar with explicit `-c` and `-s` arguments

## Hyprland Differences

### Monitor Model

Repo Hyprland:

- Built around Fedora desktop monitors such as `DP-2` and `HDMI-A-2`
- Includes monitor profile switching binds
- Includes NVIDIA-specific environment variables

Live Hyprland:

- Three fixed monitors: `DP-1`, `DP-2`, `DP-3`
- Adds default workspaces pinned per monitor
- No NVIDIA-specific env block
- No monitor profile switching binds

### Autostart

Repo Hyprland autostarts more desktop services:

- `xdg-desktop-portal-hyprland`
- `xdg-desktop-portal`
- `mako`
- `blueman-applet`
- `nm-applet`
- `hyprpaper`
- `hypridle`

Live Hyprland autostart is leaner:

- `waybar`
- `nm-applet --indicator`
- polkit agent
- `fcitx5`
- `keepassxc`

### Window Rules

Repo rules are broader and more Fedora-desktop oriented:

- Firefox, VSCode, RStudio workspace pinning
- File Roller float rule
- KeePassXC special workspace
- Waybar session picker rule

Live rules are more machine-specific:

- Firefox pinned to workspace `X`
- VSCode pinned to workspace `V`
- Spotify main window pinned to workspace `2`
- Chromium-based Spotify mini window pinned to `special:music`

### Files Missing On Live Machine

Present in repo but not in live `~/.config/hypr`:

- `hypridle.conf`
- `hyprpaper.conf`

## Repo Changes Made During This Session

The repo itself is not fully untouched. It currently has one modified file:

- `config/waybar/scripts/system-info.sh`

That change came from exploring alternative popup behavior. Treat the live machine files, not that repo-side script edit, as the main reference for Fedora refinement unless you intentionally keep that repo change.

## Known Open Issues

These are still not considered fully solved:

1. Tooltip/dropdown font for Spotify, volume, and LAN may still not match the intended font perfectly, even after aggressive CSS forcing.
2. CPU/RAM dialog is static under `zenity`; it is cleaner than repeated notifications, but not yet a live panel.
3. Spotify status is faster now, but still polling-based rather than event-driven.

## Recommended Fedora Follow-Up

When refining the Fedora system, decide explicitly which of these you want:

- Keep the repo's richer hardware/status model, or keep the live machine's simpler bar
- Keep YAD popups, or standardize on Zenity, or install a proper live popup tool everywhere
- Keep the single-bar layout, or adopt the three-bar monitor-specific layout
- Keep the repo font stack as-is, or replace it with the fonts that are actually installed across both machines

## Useful Diff Commands

To regenerate this comparison later:

```bash
diff -ru ~/.dotfiles/config/waybar ~/.config/waybar
diff -ru ~/.dotfiles/config/hypr ~/.config/hypr
git -C ~/.dotfiles status --short
```
