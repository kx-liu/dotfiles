# Fedora → Ubuntu 字体与 Waybar 字体迁移说明（按当前 Fedora 实况更新）

这份文档用于把当前 Fedora/Hyprland 机器上的字体与 Waybar 字体设置迁移到另一台 Ubuntu 机器。

## 1. 当前 Fedora 字体状态结论

当前 Fedora 的字体安装状态整体正常，Waybar 显示正常，因此不建议为了“追求理论完美”大改系统字体。

当前已确认存在的关键字体家族：

```text
中文/UI 主字体：Noto Sans CJK SC
中文衬线字体：Noto Serif CJK SC
中文等宽字体：Noto Sans Mono CJK SC
Nerd Font / Waybar 英文数字：JetBrainsMono Nerd Font（需用精确 family name 验证）
备用 Nerd Font / Powerlevel10k：MesloLGS NF
Waybar 图标补充：Font Awesome 6 Free
Emoji：Noto Color Emoji
```

已确认 Fedora 上存在这些字体包或字体家族：Noto CJK、Noto Serif CJK、Noto Color Emoji、MesloLGS NF、Font Awesome 6 Free。`fc-match "JetBrains Mono"` 返回 Noto Sans 并不代表当前 Waybar 有问题，因为 Waybar 实际 CSS 使用的是 `JetBrainsMono Nerd Font`，不是普通的 `JetBrains Mono`。

## 2. 当前 Fedora Waybar 字体设置

当前 `~/.config/waybar/style.css` 的全局字体是：

```css
font-family: "JetBrainsMono Nerd Font", "Noto Sans CJK SC", "Font Awesome 6 Free", "Noto Color Emoji", sans-serif;
```

CPU/GPU/Memory 等硬件数字模块使用：

```css
font-family: "JetBrainsMono Nerd Font", "Noto Sans Mono CJK SC", monospace;
```

这说明当前 Waybar 走的是“统一 Nerd 风格”：英文、数字、图标优先走 JetBrainsMono Nerd Font；中文 fallback 到 Noto Sans CJK SC；Font Awesome 6 Free 和 Noto Color Emoji 分别补图标和 emoji。

旧备份文件 `~/.config/waybar/style.css.bak.20260502-234259` 里曾经使用过：

```css
font-family: "Noto Sans CJK SC", "MesloLGS NF", "Font Awesome 6 Free", "Noto Color Emoji", sans-serif;
```

但这不是当前实际配置，只能作为历史备份参考。

## 3. Fedora 当前是否需要修正

### 不需要修正的部分

当前这些情况不是缺陷：

```text
fc-match sans-serif  -> Noto Sans
fc-match serif       -> Noto Serif
fc-match monospace   -> Noto Sans Mono
```

这只是 Fedora 默认 generic alias 没有强制指向 CJK 字体。Waybar 已经在 CSS 里明确指定了 CJK fallback，所以不影响 Waybar 中文显示。

`Noto Color Emoji` 在 Fedora 上可能显示为：

```text
Noto-COLRv1.ttf: "Noto Color Emoji" "Regular"
```

这也是正常的，不必要求文件名一定是 `NotoColorEmoji.ttf`。

### 唯一建议补充验证的部分

需要验证 `JetBrainsMono Nerd Font` 这个精确 family name 是否真的存在：

```bash
fc-match "JetBrainsMono Nerd Font"
fc-list : family | tr ',' '\n' | sed 's/^ *//; s/ *$//' | sort -u | grep -Ei 'JetBrains.*Nerd|Meslo|Font Awesome 6 Free|Noto Sans CJK SC|Noto Color Emoji'
```

理想情况应看到类似：

```text
JetBrainsMonoNerdFont-Regular.ttf: "JetBrainsMono Nerd Font" "Regular"
```

如果 `fc-match "JetBrainsMono Nerd Font"` 返回的是 Noto Sans、DejaVu、Liberation 等其他字体，则说明 Waybar CSS 的第一字体没有真正命中。此时有两个低风险选择：

1. 保持当前视觉，安装 JetBrainsMono Nerd Font。
2. 不装新字体，把 Waybar CSS 改回已确认存在的 MesloLGS NF 方案。

如果 Waybar 显示正常，并且 `fc-match "JetBrainsMono Nerd Font"` 命中正确字体，就不需要改 Fedora 配置。

## 4. Fedora 本机最终验证脚本

在 Fedora 上执行：

```bash
cat > /tmp/font-fedora-final-check.sh <<'EOF'
#!/usr/bin/env bash
set -u

echo "== Exact font matches =="
for f in \
  "JetBrainsMono Nerd Font" \
  "Noto Sans CJK SC" \
  "Noto Serif CJK SC" \
  "Noto Sans Mono CJK SC" \
  "MesloLGS NF" \
  "Font Awesome 6 Free" \
  "Noto Color Emoji"
do
  printf '%-28s -> ' "$f"
  fc-match "$f"
done

echo
echo "== Generic aliases, informational only =="
printf '%-28s -> ' "sans-serif"; fc-match sans-serif
printf '%-28s -> ' "serif"; fc-match serif
printf '%-28s -> ' "monospace"; fc-match monospace

echo
echo "== Installed family names of interest =="
fc-list : family | tr ',' '\n' | sed 's/^ *//; s/ *$//' | sort -u | grep -Ei \
'JetBrains.*Nerd|JetBrains Mono|Noto Sans CJK SC|Noto Serif CJK SC|Noto Sans Mono CJK SC|Noto Color Emoji|MesloLGS|Font Awesome 6 Free' || true

echo
echo "== Current Waybar font-family lines =="
grep -n 'font-family' ~/.config/waybar/style.css || true

echo
echo "== Waybar current fallback order preview =="
fc-match -s "JetBrainsMono Nerd Font, Noto Sans CJK SC, Font Awesome 6 Free, Noto Color Emoji, sans-serif" | head -20

echo
echo "== Hardware module fallback order preview =="
fc-match -s "JetBrainsMono Nerd Font, Noto Sans Mono CJK SC, monospace" | head -20
EOF

bash /tmp/font-fedora-final-check.sh
```

判断标准：

```text
JetBrainsMono Nerd Font  -> 应命中 JetBrainsMono Nerd Font
Noto Sans CJK SC         -> 应命中 Noto Sans CJK SC
Noto Serif CJK SC        -> 应命中 Noto Serif CJK SC
Noto Sans Mono CJK SC    -> 应命中 Noto Sans Mono CJK SC
MesloLGS NF              -> 应命中 MesloLGS NF
Font Awesome 6 Free      -> 应命中 Font Awesome 6 Free
Noto Color Emoji         -> 应命中 Noto Color Emoji
```

如果这些都通过，Fedora 当前字体配置无需修改。

## 5. Fedora 可选修正：仅当 JetBrainsMono Nerd Font 未命中时使用

### 方案 A：保留当前 Waybar 风格，安装 JetBrainsMono Nerd Font

先搜索 Fedora 是否已有合适包名：

```bash
dnf search nerd-fonts jetbrains
```

如果能找到 JetBrainsMono Nerd Font 相关包，就优先用 DNF 安装。

如果不想折腾包名，也可以手动安装 Nerd Fonts 的 JetBrainsMono 字体到用户目录。安装后执行：

```bash
fc-cache -fv
fc-match "JetBrainsMono Nerd Font"
```

### 方案 B：不装新字体，把 Waybar 改回 MesloLGS NF

如果 `JetBrainsMono Nerd Font` 不存在，但你不想再装字体，可以把 Waybar 改为已确认存在的 MesloLGS NF 方案：

```bash
cp -a ~/.config/waybar/style.css ~/.config/waybar/style.css.bak.$(date +%Y%m%d-%H%M%S)

sed -i \
  's/"JetBrainsMono Nerd Font", "Noto Sans CJK SC"/"Noto Sans CJK SC", "MesloLGS NF"/g; s/"JetBrainsMono Nerd Font", "Noto Sans Mono CJK SC"/"Noto Sans Mono CJK SC", "MesloLGS NF"/g' \
  ~/.config/waybar/style.css

pkill -x waybar 2>/dev/null || true
hyprctl dispatch exec waybar
```

如果 Waybar 当前看起来正常，不建议执行这个方案。

## 6. Ubuntu 上安装对应字体

Ubuntu/Debian 上先安装官方包：

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

注意：`fonts-jetbrains-mono` 通常是普通 JetBrains Mono，不等于 `JetBrainsMono Nerd Font`。如果 Ubuntu Waybar 要完全复刻当前 Fedora 风格，需要额外安装 JetBrainsMono Nerd Font。

## 7. Ubuntu 上安装 JetBrainsMono Nerd Font

建议把 Nerd Font 安装到用户字体目录：

```bash
mkdir -p ~/.local/share/fonts/JetBrainsMonoNerd
cd /tmp

curl -fL -o JetBrainsMono.zip \
  https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip

unzip -o JetBrainsMono.zip -d JetBrainsMonoNerd
find JetBrainsMonoNerd -type f \( -name "*.ttf" -o -name "*.otf" \) -exec cp -v {} ~/.local/share/fonts/JetBrainsMonoNerd/ \;

fc-cache -fv
fc-match "JetBrainsMono Nerd Font"
```

理想输出应包含：

```text
JetBrainsMonoNerdFont-Regular.ttf: "JetBrainsMono Nerd Font" "Regular"
```

## 8. Ubuntu 上安装 MesloLGS NF

MesloLGS NF 主要给 Powerlevel10k、终端和备用 Nerd glyph fallback 用：

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
fc-match "MesloLGS NF"
```

## 9. Ubuntu 上可选安装 Font Awesome 6 Free

Ubuntu 的 `fonts-font-awesome` 不一定提供精确 family name `Font Awesome 6 Free`。为了和 Waybar CSS 完全匹配，可以手动安装 Font Awesome 6 Free：

```bash
mkdir -p ~/.local/share/fonts/FontAwesome6
cd /tmp

curl -fL -o fontawesome-free.zip \
  https://github.com/FortAwesome/Font-Awesome/releases/download/6.7.2/fontawesome-free-6.7.2-desktop.zip

unzip -o fontawesome-free.zip -d fontawesome-free
find fontawesome-free -type f \( -name "*.otf" -o -name "*.ttf" \) -exec cp -v {} ~/.local/share/fonts/FontAwesome6/ \;

fc-cache -fv
fc-match "Font Awesome 6 Free"
fc-list | grep -i "Font Awesome"
```

## 10. Ubuntu 上建议的 fontconfig

如果 Ubuntu 中文 fallback 没问题，可以先不写全局 fontconfig。

如果希望迁移后中文字体选择更确定，可以写用户级配置：

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
fc-match "JetBrainsMono Nerd Font"
fc-match "MesloLGS NF"
fc-match "Font Awesome 6 Free"
```

## 11. Ubuntu Waybar 字体设置

### 推荐：复刻当前 Fedora 风格

放到 Ubuntu 的 `~/.config/waybar/style.css`：

```css
* {
  border: 0;
  font-family: "JetBrainsMono Nerd Font", "Noto Sans CJK SC", "Font Awesome 6 Free", "Noto Color Emoji", sans-serif;
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
  font-family: "JetBrainsMono Nerd Font", "Noto Sans Mono CJK SC", monospace;
}
```

### 保守方案：Noto CJK 优先，MesloLGS NF 兜底

如果不想在 Ubuntu 上安装 JetBrainsMono Nerd Font，可以使用：

```css
* {
  border: 0;
  font-family: "Noto Sans CJK SC", "MesloLGS NF", "Font Awesome 6 Free", "Noto Color Emoji", sans-serif;
  font-size: 13px;
}

#custom-cpu,
#custom-cpu-temp,
#custom-gpu,
#custom-gpu-temp,
#custom-memory {
  font-family: "Noto Sans Mono CJK SC", "MesloLGS NF", monospace;
}
```

## 12. Ghostty / 终端字体

如果想和 Waybar 当前风格统一，终端可以用：

```ini
font-family = JetBrainsMono Nerd Font
font-size = 12
```

如果主要为了 Powerlevel10k 稳定，也可以用：

```ini
font-family = MesloLGS NF
font-size = 12
```

## 13. 迁移后的检查脚本

在 Ubuntu 上执行：

```bash
cat > /tmp/font-check.sh <<'EOF'
#!/usr/bin/env bash
set -e

echo "== Core font matches =="
fc-match "JetBrainsMono Nerd Font"
fc-match "Noto Sans CJK SC"
fc-match "Noto Serif CJK SC"
fc-match "Noto Sans Mono CJK SC"
fc-match "Noto Color Emoji"
fc-match "MesloLGS NF"
fc-match "Font Awesome 6 Free"

echo
echo "== Generic aliases =="
fc-match sans-serif
fc-match serif
fc-match monospace

echo
echo "== Installed font families of interest =="
fc-list : family | tr ',' '\n' | sed 's/^ *//; s/ *$//' | sort -u | grep -Ei 'JetBrains.*Nerd|Noto Sans CJK SC|Noto Serif CJK SC|Noto Sans Mono CJK SC|Noto Color Emoji|MesloLGS|Font Awesome' || true
EOF

bash /tmp/font-check.sh
```

Waybar 测试：

```bash
pkill -x waybar 2>/dev/null || true
waybar
```

如果终端没有明显报错，且图标、中文、emoji 都正常，再改成：

```bash
hyprctl dispatch exec waybar
```

## 14. 推荐迁移顺序

1. 安装 Ubuntu 官方字体包：Noto CJK、Noto Color Emoji、JetBrains Mono、Font Awesome、fontconfig。
2. 手动安装 JetBrainsMono Nerd Font。
3. 手动安装 MesloLGS NF。
4. 可选手动安装 Font Awesome 6 Free。
5. 视需要写 `~/.config/fontconfig/conf.d/10-noto-cjk-simple.conf`。
6. 执行 `fc-cache -fv`。
7. 用 `fc-match` 验证精确字体家族名。
8. 复制 Waybar CSS。
9. 手动运行 `waybar` 检查图标、中文、emoji 和硬件数字模块。

## 15. 最容易踩的坑

1. `JetBrains Mono` 和 `JetBrainsMono Nerd Font` 不是同一个 family name。Waybar 当前用的是后者。
2. `fonts-jetbrains-mono` 不等于 Nerd Font；Nerd glyph 需要额外安装 Nerd Fonts 版本。
3. Fedora 上 `Noto Color Emoji` 文件名可能是 `Noto-COLRv1.ttf`，这是正常现象。
4. `fc-match sans-serif` 没有指向 CJK 不一定是缺陷；Waybar CSS 显式写了 CJK fallback 更重要。
5. 旧的 `style.css.bak.*` 只能说明历史配置，不能代表当前 Waybar 实际字体顺序。
6. Waybar fallback 是按 glyph 粒度发生的：同一个模块里的英文、数字、中文、图标、emoji 可能来自不同字体。当前配置的目标是让英文数字和图标更统一，中文与 emoji 再分别 fallback。

