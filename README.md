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
- `group/connectivity` bundles input source, audio, Bluetooth, and network into one visual block.
- The input-source module no longer depends on the older `ime.sh` helper. It queries `fcitx5-remote` inline and renders `EN` or `中`.
- CPU, GPU, and RAM are back to the original tooltip-based status model. CPU usage comes from `cpu-status.sh`, temperatures from `temp-status.sh`, GPU usage from `gpu-status.sh`, and memory uses Waybar's built-in `memory` module.
- `custom/theme-toggle` flips between transparent and solid Waybar themes.
- `custom/power` launches a `yad` session chooser. Its placement is controlled by Hyprland window rules rather than Waybar itself.

The helper scripts under `config/waybar/scripts` follow a simple pattern: each script prints either plain text or a small JSON object that Waybar consumes.

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
