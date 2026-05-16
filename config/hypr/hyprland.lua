-- Migrated from hyprland.conf to Hyprland 0.55 Lua config.
-- Keep hypridle.conf, hyprlock.conf, and hyprpaper.conf as .conf files.

local mod = "SUPER"
local filemanager = "dolphin"
local terminal = "ghostty"

-- ---------- Monitors ----------
-- DP right: 3440x1440@143.97
hl.monitor({
  output = "DP-2",
  mode = "3440x1440@143.97501",
  position = "0x0",
  scale = 1,
})

-- HDMI left: 4K@60, scale 1.67, currently disabled
hl.monitor({
  output = "HDMI-A-2",
  disabled = true,
})

-- ---------- Workspace defaults ----------
require("workspaces-1-9-a-z")

-- ---------- NVIDIA / Wayland compatibility ----------
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")

-- hl.env("GTK_IM_MODULE", "fcitx")
hl.env("QT_IM_MODULE", "fcitx")
hl.env("XMODIFIERS", "@im=fcitx")
hl.env("SDL_IM_MODULE", "fcitx")

-- ---------- Autostart essentials ----------
hl.on("hyprland.start", function()
  hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE")
  hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE")
  hl.exec_cmd("systemctl --user start hyprpolkitagent")
  hl.exec_cmd("/usr/libexec/pam_kwallet_init")

  hl.exec_cmd("mako")
  hl.exec_cmd("fcitx5 -d")
  hl.exec_cmd("waybar")
  hl.exec_cmd("blueman-applet")
  hl.exec_cmd("nm-applet")
  hl.exec_cmd("hypridle")
  hl.exec_cmd("hyprpaper")

  hl.exec_cmd("wl-paste --watch cliphist store")
  hl.exec_cmd("wl-paste --type text --watch cliphist store")
  hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)

-- ---------- Keybinds: apps / session ----------
hl.bind("ALT + SPACE", hl.dsp.exec_cmd("rofi -show drun"))
hl.bind("ALT + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind("ALT + T", hl.dsp.exec_cmd(filemanager))
hl.bind("ALT + Q", hl.dsp.window.close())
hl.bind("ALT + M", hl.dsp.exit())
hl.bind("ALT + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(
  "CTRL + ALT + V",
  hl.dsp.exec_cmd([[sh -lc 'cliphist list | rofi -dmenu -i -p "Clipboard" | cliphist decode | wl-copy; wtype -M ctrl -k v -m ctrl']])
)

-- Screenshot
hl.bind("ALT + SHIFT + 4", hl.dsp.exec_cmd([[grim -g "$(slurp)" - | wl-copy]]))

-- ---------- Keybinds: mako ----------
hl.bind("ALT + N", hl.dsp.exec_cmd("makoctl restore"))
hl.bind(
  "ALT + SHIFT + N",
  hl.dsp.exec_cmd([[sh -c 'makoctl mode | grep -qx reading && makoctl mode -r reading || makoctl mode -a reading']])
)

-- ---------- Keybinds: KeePassXC scratchpad ----------
hl.bind("ALT + K", hl.dsp.workspace.toggle_special("keepass"))
hl.bind("ALT + SHIFT + K", hl.dsp.exec_cmd("keepassxc"))

-- ---------- Keybinds: numeric workspaces ----------
for i = 1, 10 do
  local key = i == 10 and "0" or tostring(i)

  hl.bind(mod .. " + " .. key, hl.dsp.focus({
    workspace = tostring(i),
    on_current_monitor = true,
  }))

  hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({
    workspace = tostring(i),
    follow = true,
  }))
end

-- ---------- Keybinds: semantic letter workspaces ----------
hl.bind(mod .. " + R", hl.dsp.focus({ workspace = "name:R" }))
hl.bind(mod .. " + V", hl.dsp.focus({ workspace = "name:V" }))
hl.bind(mod .. " + X", hl.dsp.focus({ workspace = "name:X" }))
hl.bind(mod .. " + S", hl.dsp.focus({ workspace = "name:S" }))
hl.bind(mod .. " + M", hl.dsp.focus({ workspace = "name:M" }))

hl.bind(mod .. " + SHIFT + R", hl.dsp.window.move({ workspace = "name:R", follow = true }))
hl.bind(mod .. " + SHIFT + V", hl.dsp.window.move({ workspace = "name:V", follow = true }))
hl.bind(mod .. " + SHIFT + X", hl.dsp.window.move({ workspace = "name:X", follow = true }))
hl.bind(mod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "name:S", follow = true }))
hl.bind(mod .. " + SHIFT + M", hl.dsp.window.move({ workspace = "name:M", follow = true }))

hl.bind(mod .. " + CTRL + R", hl.dsp.focus({ workspace = "name:R", on_current_monitor = true }))
hl.bind(mod .. " + CTRL + V", hl.dsp.focus({ workspace = "name:V", on_current_monitor = true }))
hl.bind(mod .. " + CTRL + X", hl.dsp.focus({ workspace = "name:X", on_current_monitor = true }))
hl.bind(mod .. " + CTRL + S", hl.dsp.focus({ workspace = "name:S", on_current_monitor = true }))
hl.bind(mod .. " + CTRL + M", hl.dsp.focus({ workspace = "name:M", on_current_monitor = true }))

-- Back-and-forth: previous workspace per monitor
hl.bind(mod .. " + TAB", hl.dsp.focus({ workspace = "previous_per_monitor" }))

-- ---------- Keybinds: Vim focus / monitor move / local rearrange ----------
hl.bind(mod .. " + H", hl.dsp.focus({ direction = "l" }))
hl.bind(mod .. " + J", hl.dsp.focus({ direction = "d" }))
hl.bind(mod .. " + K", hl.dsp.focus({ direction = "u" }))
hl.bind(mod .. " + L", hl.dsp.focus({ direction = "r" }))

hl.bind(mod .. " + SHIFT + H", hl.dsp.window.move({ monitor = "l" }))
hl.bind(mod .. " + SHIFT + J", hl.dsp.window.move({ monitor = "d" }))
hl.bind(mod .. " + SHIFT + K", hl.dsp.window.move({ monitor = "u" }))
hl.bind(mod .. " + SHIFT + L", hl.dsp.window.move({ monitor = "r" }))

hl.bind(mod .. " + CTRL + H", hl.dsp.window.swap({ direction = "l" }))
hl.bind(mod .. " + CTRL + J", hl.dsp.window.swap({ direction = "d" }))
hl.bind(mod .. " + CTRL + K", hl.dsp.window.swap({ direction = "u" }))
hl.bind(mod .. " + CTRL + L", hl.dsp.window.swap({ direction = "r" }))

hl.bind(mod .. " + left", hl.dsp.focus({ monitor = "l" }))
hl.bind(mod .. " + right", hl.dsp.focus({ monitor = "r" }))
hl.bind(mod .. " + up", hl.dsp.focus({ monitor = "u" }))
hl.bind(mod .. " + down", hl.dsp.focus({ monitor = "d" }))

hl.bind(mod .. " + SHIFT + left", hl.dsp.workspace.move({ monitor = "l" }))
hl.bind(mod .. " + SHIFT + right", hl.dsp.workspace.move({ monitor = "r" }))
hl.bind(mod .. " + SHIFT + up", hl.dsp.workspace.move({ monitor = "u" }))
hl.bind(mod .. " + SHIFT + down", hl.dsp.workspace.move({ monitor = "d" }))

-- ---------- Keybinds: brightness / media / volume ----------
-- hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -d ddcci8 set +10%"), { repeating = true })
-- hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -d ddcci8 set 10%-"), { repeating = true })
-- hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("/usr/local/sbin/ddcci8-brightness up"), { repeating = true })
-- hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("/usr/local/sbin/ddcci8-brightness down"), { repeating = true })

hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"))
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"))

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"), { repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%-"), { repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))

-- M590 wheel tilt: workspace cycle 1-9, A-Z
local ws_cycle_script = os.getenv("HOME") .. "/.config/hypr/scripts/ws-cycle-1-9-a-z.sh"

hl.bind("mouse_left", hl.dsp.exec_cmd(ws_cycle_script .. " prev"))
hl.bind("mouse_right", hl.dsp.exec_cmd(ws_cycle_script .. " next"))

-- ---------- Resize mode ----------
-- SUPER + minus enters resize mode. Press Esc or Enter to exit.
local enter_resize_submap = hl.dsp.submap("resize")
local reset_submap = hl.dsp.submap("reset")

hl.bind(mod .. " + minus", enter_resize_submap)

hl.define_submap("resize", function()
  hl.bind("equal", hl.dsp.layout("splitratio +0.05"), { repeating = true })
  hl.bind("minus", hl.dsp.layout("splitratio -0.05"), { repeating = true })
  hl.bind("CTRL + equal", hl.dsp.layout("splitratio +0.01"), { repeating = true })
  hl.bind("CTRL + minus", hl.dsp.layout("splitratio -0.01"), { repeating = true })

  hl.bind("H", hl.dsp.window.resize({ x = -60, y = 0, relative = true }), { repeating = true })
  hl.bind("L", hl.dsp.window.resize({ x = 60, y = 0, relative = true }), { repeating = true })
  hl.bind("K", hl.dsp.window.resize({ x = 0, y = -60, relative = true }), { repeating = true })
  hl.bind("J", hl.dsp.window.resize({ x = 0, y = 60, relative = true }), { repeating = true })
  hl.bind("SHIFT + H", hl.dsp.window.resize({ x = -10, y = 0, relative = true }), { repeating = true })
  hl.bind("SHIFT + L", hl.dsp.window.resize({ x = 10, y = 0, relative = true }), { repeating = true })
  hl.bind("SHIFT + K", hl.dsp.window.resize({ x = 0, y = -10, relative = true }), { repeating = true })
  hl.bind("SHIFT + J", hl.dsp.window.resize({ x = 0, y = 10, relative = true }), { repeating = true })

  hl.bind("escape", reset_submap)
  hl.bind("RETURN", reset_submap)
end)

-- ---------- Monitor profiles ----------
hl.bind(
  mod .. " + F1",
  hl.dsp.exec_cmd([[hyprctl --batch "keyword monitor DP-2,3440x1440@143.97501,0x0,1; keyword monitor HDMI-A-2,disable"]])
)

hl.bind(
  mod .. " + F2",
  hl.dsp.exec_cmd([[hyprctl --batch "keyword monitor HDMI-A-2,3840x2160@60,0x0,1.67; keyword monitor DP-2,disable"]])
)

hl.bind(
  mod .. " + F3",
  hl.dsp.exec_cmd([[hyprctl --batch "keyword monitor DP-2,3440x1440@143.97501,0x0,1; keyword monitor HDMI-A-2,3840x2160@60,auto-left,1.67"]])
)

-- ---------- Input / cursor / XWayland ----------
hl.config({
  input = {
    kb_layout = "us",
    follow_mouse = 1,
    repeat_delay = 250,
    repeat_rate = 20,
    touchpad = {
      natural_scroll = true,
    },
  },

  cursor = {
    -- 0 = use hardware cursors if possible. This preserves old false.
    no_hardware_cursors = 0,
  },

  xwayland = {
    force_zero_scaling = true,
  },
})

-- ---------- Appearance / layout ----------
hl.config({
  general = {
    gaps_in = 5,
    gaps_out = 5,
    border_size = 2,
  },

  decoration = {
    rounding = 10,
    rounding_power = 2,
    inactive_opacity = 0.95,

    shadow = {
      enabled = true,
      range = 4,
      render_power = 3,
      color = "rgba(1a1a1aee)",
    },

    blur = {
      enabled = true,
      size = 3,
      passes = 1,
      vibrancy = 0.1696,
    },
  },

  animations = {
    enabled = true,
  },

  dwindle = {
    smart_resizing = true,
    split_bias = 1,
  },
})

hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "default", style = "fade" })
hl.animation({ leaf = "windows", enabled = true, speed = 5, bezier = "default", style = "slide" })

-- ---------- Window rules: pin apps to semantic workspaces ----------
hl.window_rule({
  match = { class = "^(firefox|firefox-esr|org\\.mozilla\\.firefox)$" },
  workspace = "name:X silent",
})

hl.window_rule({
  match = { class = "^(code|Code|code-oss|com\\.visualstudio\\.code)$" },
  workspace = "name:V silent",
})

hl.window_rule({
  match = { class = "^(rstudio|RStudio|com\\.rstudio\\.desktop)$" },
  workspace = "name:R silent",
})

hl.window_rule({
  match = { class = "org.gnome.FileRoller" },
  float = true,
})

-- KeePassXC: hidden special workspace / password drawer.
hl.window_rule({
  match = { class = "^org\\.keepassxc\\.KeePassXC$" },
  workspace = "special:keepass silent",
})

hl.window_rule({
  match = { class = "^org\\.keepassxc\\.KeePassXC$" },
  no_initial_focus = true,
})

hl.window_rule({
  match = { class = "^org\\.keepassxc\\.KeePassXC$" },
  float = true,
})

hl.window_rule({
  match = { class = "^org\\.keepassxc\\.KeePassXC$" },
  center = true,
})

hl.window_rule({
  match = { class = "^org\\.keepassxc\\.KeePassXC$" },
  size = { "80%", "80%" },
})

hl.window_rule({
  match = { class = "^org\\.keepassxc\\.KeePassXC$" },
  persistent_size = true,
})

-- Waybar session picker
hl.window_rule({
  match = { class = "^(yad|Yad)$", title = "^Waybar Session$" },
  float = true,
})

hl.window_rule({
  match = { class = "^(yad|Yad)$", title = "^Waybar Session$" },
  center = true,
})

hl.window_rule({
  match = { class = "^(yad|Yad)$", title = "^Waybar Session$" },
  size = { "36%", "34%" },
})
