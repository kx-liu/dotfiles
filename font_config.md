下面这份可以直接存成 `fonts-waybar-migration.md`，给另一台 Ubuntu 机器照着做。

# Fedora → Ubuntu 字体与 Waybar 字体迁移说明

## 1. 当前这台机器的字体策略

这台 Fedora/Hyprland 的字体策略是：

```text
中文/UI 主字体：Noto Sans CJK SC
中文衬线字体：Noto Serif CJK SC
中文等宽字体：Noto Sans Mono CJK SC
终端 / Nerd Font / 图标补充：MesloLGS NF
Waybar 图标补充：Font Awesome 6 Free
Emoji：Noto Color Emoji
```

当前 Waybar 全局字体是：

```css
font-family: "Noto Sans CJK SC", "MesloLGS NF", "Font Awesome 6 Free", "Noto Color Emoji", sans-serif;
```

CPU/GPU/Memory 这些数字模块单独用了等宽字体：

```css
font-family: "Noto Sans Mono CJK SC", "MesloLGS NF", monospace;
```

你的 `style.css` 里全局 `*` 确实设置了 `Noto Sans CJK SC → MesloLGS NF → Font Awesome 6 Free → Noto Color Emoji`，数字/硬件模块则设置为 `Noto Sans Mono CJK SC → MesloLGS NF → monospace`。

旧系统包清单里也有相关字体：`google-noto-sans-cjk-fonts`、`google-noto-color-emoji-fonts`、`jetbrains-mono-fonts`、`fontawesome4-fonts`，完整 RPM 清单还显示 Fedora 侧装过 `fontawesome-6-free-fonts`、Noto CJK、Noto Color Emoji、JetBrains Mono 等字体包。 

## 2. Ubuntu 上安装对应字体

Ubuntu/Debian 上对应包名建议先装这些：

```bash
sudo apt update

sudo apt install -y \
  fontconfig \
  fonts-noto-cjk \
  fonts-noto-color-emoji \
  fonts-jetbrains-mono \
  fonts-font-awesome \
  curl unzip
```

`fonts-noto-cjk` 是 Ubuntu 官方包，说明为覆盖 CJK 的 Noto 字体家族；`fonts-jetbrains-mono` 在 Ubuntu 包库中也有；`fonts-font-awesome` 这个包在 Ubuntu/Debian 里存在，但它不一定提供字体家族名 `Font Awesome 6 Free`，所以 Waybar 若严格依赖 FA6，建议另装 Font Awesome 6。([Ubuntu Packages][1])

## 3. 安装 MesloLGS NF

MesloLGS NF 主要给 Powerlevel10k、终端和 Waybar 图标 fallback 用。Powerlevel10k 官方建议手动安装四个 MesloLGS NF TTF：Regular、Bold、Italic、Bold Italic。([GitHub][2])

```bash
mkdir -p ~/.local/share/fonts/MesloLGS-NF

curl -fL -o ~/.local/share/fonts/MesloLGS-NF/"MesloLGS NF Regular.ttf" \
  "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf"

curl -fL -o ~/.local/share/fonts/MesloLGS-NF/"MesloLGS NF Bold.ttf" \
  "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf"

curl -fL -o ~/.local/share/fonts/MesloLGS-NF/"MesloLGS NF Italic.ttf" \
  "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf"

curl -fL -o ~/.local/share/fonts/MesloLGS-NF/"MesloLGS NF Bold Italic.ttf" \
  "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf"

fc-cache -fv
```

验证：

```bash
fc-match "MesloLGS NF"
```

## 4. 可选：安装 Font Awesome 6 Free

Ubuntu 的 `fonts-font-awesome` 可能不是 Font Awesome 6。为了和当前 Waybar CSS 的 `"Font Awesome 6 Free"` 完全匹配，建议手动安装 Font Awesome 6 Free 的 webfont。Font Awesome Free 的字体文件是开源字体文件，官方仓库说明 fonts 部分使用 SIL OFL 1.1 许可证。([GitHub][3])

```bash
mkdir -p ~/.local/share/fonts/FontAwesome6
cd /tmp

curl -fL -o fontawesome-free.zip \
  https://github.com/FortAwesome/Font-Awesome/releases/download/6.7.2/fontawesome-free-6.7.2-desktop.zip

unzip -o fontawesome-free.zip -d fontawesome-free
find fontawesome-free -type f \( -name "*.otf" -o -name "*.ttf" \) -exec cp -v {} ~/.local/share/fonts/FontAwesome6/ \;

fc-cache -fv
```

验证：

```bash
fc-match "Font Awesome 6 Free"
fc-list | grep -i "Font Awesome"
```

如果 `fc-match "Font Awesome 6 Free"` 找不到，但 Waybar 图标已经都能显示，也可以不纠结；MesloLGS NF 已经能兜底大部分 Nerd 图标。

## 5. 建议的 fontconfig 配置

迁移到 Ubuntu 后，建议建立一个用户级 fontconfig，把通用字体指向 Noto CJK SC。

```bash
mkdir -p ~/.config/fontconfig/conf.d

cat > ~/.config/fontconfig/conf.d/10-noto-cjk-simple.conf <<'EOF'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
<fontconfig>
  <alias>
    <family>sans-serif</family>
    <prefer>
      <family>Noto Sans CJK SC</family>
    </prefer>
  </alias>

  <alias>
    <family>serif</family>
    <prefer>
      <family>Noto Serif CJK SC</family>
    </prefer>
  </alias>

  <alias>
    <family>monospace</family>
    <prefer>
      <family>Noto Sans Mono CJK SC</family>
    </prefer>
  </alias>
</fontconfig>
EOF

fc-cache -fv
```

验证：

```bash
fc-match sans-serif
fc-match serif
fc-match monospace
fc-match "Noto Sans CJK SC"
fc-match "Noto Serif CJK SC"
fc-match "Noto Sans Mono CJK SC"
fc-match "Noto Color Emoji"
fc-match "MesloLGS NF"
fc-match "Font Awesome 6 Free"
```

理想输出应大致包含：

```text
NotoSansCJK-Regular.ttc: "Noto Sans CJK SC"
NotoSerifCJK-Regular.ttc: "Noto Serif CJK SC"
NotoSansCJK-Regular.ttc: "Noto Sans Mono CJK SC"
NotoColorEmoji.ttf: "Noto Color Emoji"
MesloLGS NF Regular.ttf: "MesloLGS NF"
Font Awesome 6 Free...
```

## 6. Waybar 字体设置

### 推荐版：保留当前 Fedora 风格

放到 Ubuntu 的 `~/.config/waybar/style.css`：

```css
* {
  border: 0;
  font-family: "Noto Sans CJK SC", "MesloLGS NF", "Font Awesome 6 Free", "Noto Color Emoji", sans-serif;
  font-size: 13px;
}

tooltip label {
  font-family: "Noto Sans CJK SC", "Noto Sans CJK TC", "Noto Sans CJK JP", "Noto Sans", "Noto Color Emoji", sans-serif;
  font-size: 12.5px;
  padding: 2px 4px;
}

#custom-cpu,
#custom-cpu-temp,
#custom-gpu,
#custom-gpu-temp,
#custom-memory {
  font-family: "Noto Sans Mono CJK SC", "MesloLGS NF", monospace;
}
```

这个是最接近你当前 Fedora 的版本。全局 UI/中文走 Noto CJK，图标/Nerd glyph 走 MesloLGS NF 或 Font Awesome，emoji 走 Noto Color Emoji。

### 统一 Nerd 风格版

如果你喜欢之前上传/下载模块那种字体感，可以把 MesloLGS NF 放第一位：

```css
* {
  border: 0;
  font-family: "MesloLGS NF", "Noto Sans CJK SC", "Font Awesome 6 Free", "Noto Color Emoji", sans-serif;
  font-size: 13px;
}

#custom-cpu,
#custom-cpu-temp,
#custom-gpu,
#custom-gpu-temp,
#custom-memory {
  font-family: "MesloLGS NF", "Noto Sans Mono CJK SC", monospace;
}
```

缺点是英文和数字会更像终端字体；优点是 Waybar 各模块视觉更统一，Nerd 图标不容易 fallback 到不同字体。

## 7. Ghostty / 终端字体

另一台 Ubuntu 如果也用 Ghostty，建议终端字体用 MesloLGS NF：

```ini
font-family = MesloLGS NF
font-size = 12
```

如果不是 Ghostty，而是 Kitty/Alacritty/Foot，也尽量把终端字体设为：

```text
MesloLGS NF
```

这样 Powerlevel10k、zsh prompt、Nerd glyph 都最稳。

## 8. 迁移后的检查脚本

在 Ubuntu 上执行：

```bash
cat > /tmp/font-check.sh <<'EOF'
#!/usr/bin/env bash
set -e

echo "== Core font matches =="
fc-match sans-serif
fc-match serif
fc-match monospace
fc-match "Noto Sans CJK SC"
fc-match "Noto Serif CJK SC"
fc-match "Noto Sans Mono CJK SC"
fc-match "Noto Color Emoji"
fc-match "MesloLGS NF"
fc-match "Font Awesome 6 Free"

echo
echo "== Installed font families of interest =="
fc-list | grep -Ei 'Noto Sans CJK SC|Noto Serif CJK SC|Noto Sans Mono CJK SC|Noto Color Emoji|MesloLGS|Font Awesome|JetBrains' | sort -u
EOF

bash /tmp/font-check.sh
```

Waybar 测试：

```bash
pkill -x waybar 2>/dev/null || true
waybar
```

如果终端没有明显报错，且图标/中文/emoji 都正常，再改成：

```bash
hyprctl dispatch exec waybar
```

## 9. 推荐迁移顺序

1. `apt install` Noto CJK、Noto Color Emoji、JetBrains Mono、fontconfig。
2. 手动安装 MesloLGS NF。
3. 可选手动安装 Font Awesome 6 Free。
4. 写 `~/.config/fontconfig/conf.d/10-noto-cjk-simple.conf`。
5. `fc-cache -fv`。
6. `fc-match` 验证字体家族名。
7. 复制 Waybar CSS。
8. 手动运行 `waybar` 看 fallback 是否一致。

## 10. 迁移时最容易踩的坑

Ubuntu 上 `fonts-font-awesome` 不一定提供 `"Font Awesome 6 Free"` 这个精确 family name，所以 CSS 里写了 `"Font Awesome 6 Free"` 但图标仍 fallback，是可能的。最稳做法是手动安装 Font Awesome 6 Free，或干脆让 MesloLGS NF 承担主要图标 fallback。

Noto CJK 的同一个 `.ttc` 里会包含 `Noto Sans CJK SC` 和 `Noto Sans Mono CJK SC`，所以 `fc-match` 看到同一个 `NotoSansCJK-Regular.ttc` 不代表错。你这台 Fedora 机器最初也是这样识别的。

Waybar 的字体 fallback 是按 glyph 粒度发生的：同一个模块里文字、箭头、emoji 可能来自不同字体。想减少“某个模块字体看起来不一样”，就把 Nerd Font 放到 `font-family` 更靠前的位置。

[1]: https://packages.ubuntu.com/noble/fonts-noto-cjk?utm_source=chatgpt.com "Ubuntu – Details of package fonts-noto-cjk in noble"
[2]: https://github.com/romkatv/powerlevel10k/blob/master/font.md?utm_source=chatgpt.com "powerlevel10k/font.md at master · romkatv/powerlevel10k · GitHub"
[3]: https://github.com/FortAwesome/Font-Awesome?utm_source=chatgpt.com "GitHub - FortAwesome/Font-Awesome: The iconic SVG, font, and CSS ..."

