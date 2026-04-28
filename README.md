# Dotfiles Overview

This repo is centered on a Fedora Wayland desktop built around Hyprland, Waybar, and a modular zsh setup.

## Layout

- `config/hypr`: Hyprland, hypridle, and hyprpaper configuration
- `config/waybar`: bar layout, module definitions, CSS, and helper scripts
- `home`: shell dotfiles, mainly `.zshrc` and ordered fragments in `.zshrc.d`

## Hyprland Logic

`config/hypr/hyprland.conf` is the main desktop entry point.

- The session is Wayland-first and tuned for NVIDIA, with the environment block and cursor setup declared near the top.
- Monitor definitions are explicit. `DP-2` is the main display, and `HDMI-A-2` is present but disabled by default. There are keybinds to switch monitor profiles quickly.
- Autostart is handled with `exec-once`. It brings up the portal stack, polkit, `fcitx5`, Waybar, clipboard history, networking, Bluetooth, `hypridle`, `hyprpaper`, and KeePassXC.
- Input is keyboard-heavy. `SUPER` is used for navigation, workspace movement, resize mode, and layout control. `ALT` is used more for app launching and session actions.
- Workspaces mix numbers and named letter workspaces. Firefox is routed to `X`, VS Code to `V`, and RStudio to `R`.
- KeePassXC is treated as a floating special workspace, effectively acting as a password drawer.
- The power menu is opened from Waybar but managed in Hyprland with a dedicated floating and centered rule for the `Waybar Session` dialog.

## Waybar Logic

`config/waybar/config` keeps one top bar with three regions:

- Left: Hyprland workspaces, submap indicator, active window title
- Center: clock and calendar tooltip
- Right: Spotify, connectivity, CPU, GPU, memory, theme toggle, power

Detailed module behavior lives in `config/waybar/modules.json`.

- `custom/spotify` is a custom script-backed module using `playerctl`. It runs in watch mode so state changes inside Spotify are reflected in Waybar without needing a manual click refresh.
- `group/connectivity` bundles audio, Bluetooth, and network into one visual block.
- The input-source module is archived in `modules.json` but not currently shown in the bar. It no longer depends on the older `ime.sh` helper; if restored, it queries `fcitx5-remote` inline and renders `EN` or `中`.
- CPU, GPU, and RAM use tooltip-based status modules. CPU usage comes from `cpu-status.sh`, temperatures from `temp-status.sh`, GPU usage from `gpu-status.sh`, and RAM comes from `memory-status.sh` so its live percentage can keep a stable width.
- `custom/theme-toggle` flips between transparent and solid Waybar themes.
- `custom/power` launches a `yad` session chooser. Its placement is controlled by Hyprland window rules rather than Waybar itself.

The helper scripts under `config/waybar/scripts` follow a simple pattern: each script prints either plain text or a small JSON object that Waybar consumes.

## Live Ubuntu Waybar Refinements

The current Ubuntu machine under `~/.config/waybar` has moved ahead of the Fedora reference in this repo. Treat it as the better Waybar variant to review before porting changes back into `config/waybar`.

Compared with the Fedora version, the Ubuntu Waybar differs in these ways:

- `config` is a three-bar, three-output layout instead of one global bar. The main `DP-1` bar carries the full module set, while the side bars on `DP-2` and `DP-3` keep only workspaces, the active window title, and a compact side clock.
- The bar is denser: height is `34` instead of `38`, module margins are reduced, workspace padding is tighter, and the global font size is `11px` instead of `12.5px`.
- `hyprland/window` is shortened to `max-length: 48` and has its tooltip disabled. The built-in Hyprland window tooltip did not inherit fonts consistently, so the cleaner solution on Ubuntu is to suppress that tooltip.
- `clock` is split into `clock#main` and `clock#side`, allowing the main monitor to show the full date/time while side monitors show only `%H:%M`.
- `group/connectivity` is simplified to audio, LAN/Wi-Fi, and live upload/download speed. Bluetooth is removed from the visible group.
- Network display is more polished: Wi-Fi/disconnected states use Nerd Font icons, Ethernet intentionally displays plain `LAN`, and all network tooltips use explicit `Noto Sans 10` Pango markup.
- Upload/download speed modules use fixed-width right-aligned numeric fields, with left-pinned arrows. This avoids Waybar jitter when digit counts change.
- CPU, CPU temperature, and RAM keep whole-number precision matching the Fedora visual style, but their tooltips are generated with explicit `Noto Sans 10` markup for consistent dropdown fonts.
- CPU temperature detection is broader on Ubuntu. `temp-status.sh` tries `k10temp`, `zenpower`, `coretemp`, `x86_pkg_temp`, `acpitz`, and thermal zones, which makes it work better across machines.
- GPU modules are removed from the Ubuntu bar and `group/gpu` is not shown. The temperature script keeps a disabled GPU fallback rather than depending on `nvidia-smi`.
- Spotify keeps the custom script-backed module, uses explicit tooltip font markup, fixes tooltip newlines, and polls every `0.2s` instead of every second.
- `custom/memory` remains script-backed so RAM display and tooltip content are controlled consistently.
- `mpris#spotify` exists in `modules.json` as an alternate Spotify module, but the visible bar still uses `custom/spotify`.

Upload/download speed details:

In `modules.json`, the visible connectivity group keeps audio, network state, and the two custom speed modules together:

```json
"custom/net-down": {
  "exec": "~/.config/waybar/scripts/network-speed.sh down",
  "return-type": "json",
  "interval": 1,
  "format": "{text}",
  "tooltip": true,
  "escape": false
},

"custom/net-up": {
  "exec": "~/.config/waybar/scripts/network-speed.sh up",
  "return-type": "json",
  "interval": 1,
  "format": "{text}",
  "tooltip": true,
  "escape": false
},

"group/connectivity": {
  "orientation": "inherit",
  "modules": ["pulseaudio", "network", "custom/net-down", "custom/net-up"]
}
```

In `style.css`, the speed modules are narrower than the Fedora version, but still reserve enough width to avoid digit-count jitter. The label font is pinned to monospace:

```css
#custom-net-down {
  color: @sky;
  min-width: 68px;
  padding-left: 5px;
  padding-right: 5px;
}

#custom-net-up {
  color: @peach;
  min-width: 68px;
  padding-left: 5px;
  padding-right: 5px;
}

#custom-net-down label,
#custom-net-up label {
  font-family: "JetBrains Mono", "Noto Sans Mono", monospace;
}
```

The important script-side difference from Fedora is that `network-speed.sh` formats the rate into a fixed six-character field, right-aligns the number and unit, and leaves the arrow at the left:

```bash
format_rate() {
  awk -v bps="$1" 'BEGIN {
    if (bps < 1000) {
      printf "%.0fB/s", bps
    } else if (bps < 1000 * 1000) {
      printf "%.0fK/s", bps / 1000
    } else if (bps < 1000 * 1000 * 1000) {
      printf "%.0fM/s", bps / 1000 / 1000
    } else {
      printf "%.0fG/s", bps / 1000 / 1000 / 1000
    }
  }'
}

format_fixed_markup() {
  local arrow="$1"
  local rate="$2"
  local padded

  printf -v padded '%6s' "$rate"
  padded="${padded// /\&#160;}"
  printf '<span font_family="JetBrains Mono">%s %s</span>' "$arrow" "$padded"
}

format_rate_markup() {
  format_fixed_markup "$1" "$(format_rate "$2")"
}
```

The emitted JSON text and tooltip use that fixed-width markup and explicit tooltip font markup:

```bash
down_text="$(format_rate_markup "↓" "$rx_rate")"
up_text="$(format_rate_markup "↑" "$tx_rate")"
tooltip="$(printf '<span font_desc="Noto Sans 10">%s\nDownload: %s\nUpload: %s</span>' \
  "$iface" \
  "$(format_rate "$rx_rate")" \
  "$(format_rate "$tx_rate")")"
```

Fedora's script uses padded numeric text such as `%3.0fK/s` and separate font spans for the arrow and rate. The Ubuntu version moves the alignment into one monospace span and uses non-breaking spaces, which is what stops the visible Waybar module from shifting as values change.

Files that differ from the Fedora reference and should be reviewed before porting:

- `~/.config/waybar/config`
- `~/.config/waybar/modules.json`
- `~/.config/waybar/style.css`
- `~/.config/waybar/scripts/network-speed.sh`
- `~/.config/waybar/scripts/spotify.sh`
- `~/.config/waybar/scripts/cpu-status.sh`
- `~/.config/waybar/scripts/temp-status.sh`
- `~/.config/waybar/scripts/memory-status.sh`

The main Fedora features not currently carried into the Ubuntu bar are Bluetooth, GPU display, and the archived input-source indicator.

## Tooltip Research Notes

Waybar's normal tooltip behavior is hover-based. The documentation does not expose a generic "click to open tooltip" switch for ordinary module tooltips.

What *is* available instead:

- `menu`: attach a GTK menu description to a module and trigger it from a mouse action such as `on-click-right` or `on-click-middle`
- group drawer `click-to-reveal`: click a group to expand or reveal grouped modules
- custom scripts / external popups: use `on-click` to launch a separate UI such as `yad`, `wofi`, `zenity`, or another custom popup

So if a future Fedora refinement wants "click to open something tooltip-like", the practical path is usually to replace the tooltip with either a `menu` or a custom popup, rather than trying to convert Waybar's built-in hover tooltip into a click-triggered one.

## Shell Logic

`home/.zshrc` is intentionally small. It only does three things:

- exits early for non-interactive shells
- optionally runs `fastfetch` before Powerlevel10k instant prompt
- sources numbered files from `home/.zshrc.d` in order

That fragment directory is the real shell configuration:

- `00-dotfiles.zsh`: `dot` helper for managing this repo from `$HOME`
- `10-xdg.zsh`: XDG paths
- `20-history.zsh`: history behavior
- `30-zle.zsh`: line editor settings
- `40-autosuggest.zsh`: autosuggestions
- `50-oh-my-zsh.zsh`: Oh My Zsh, theme, plugins
- `60-aliases.zsh`: aliases
- `70-fzf.zsh`: `fzf` integration
- `80-completion.zsh`: completions and `fzf-tab`
- `85-paths.zsh`: PATH additions such as Cargo
- `90-funcs.zsh`: shell helper functions
- `99-powerlevel10k.zsh`: final Powerlevel10k load

## Reloading

Useful commands after editing:

```bash
pkill waybar && waybar &
hyprctl reload
exec zsh
```

## Runtime Dependencies

This setup assumes these tools are available:

- `fcitx5`
- `playerctl`
- `yad`
- `nvidia-smi`
- `wl-clipboard`
- `cliphist`
- `blueman`
- `nm-applet`
- `hypridle`
- `hyprpaper`
