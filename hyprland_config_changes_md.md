# Hyprland 配置改动说明

本文档解释新版 `hyprland.conf` 相比原配置的主要变化、设计意图、使用方式和验证方法。

## 0. 总体目标

这次修改不是单纯换快捷键，而是重新定义 Hyprland 中三类对象的职责：

| 对象 | 新职责 |
|---|---|
| 数字 workspace `1..10` | 临时工作区，适合当天任务、临时窗口组合 |
| 字母 workspace `R/V/X/M/W/F/T` | 全局语义工作区，作为长期记忆锚点 |
| special workspace | 抽屉式应用，例如 KeePassXC |

核心原则：

```text
workspace 名字负责“去哪里工作”
monitor move 负责“临时把窗口摆到哪个屏幕”
resize 的 +/- 负责“当前窗口变大/变小”
```

---

## 1. KeePassXC：改成后台启动 + special workspace 抽屉

### 原配置行为

原配置已经有 KeePassXC 自启动，并尝试把它放到 special workspace：

```ini
exec-once = sh -c 'sleep 3 && keepassxc'
windowrule = match:class ^org.keepassxc.KeePassXC$, workspace special:keepass
windowrule = match:class ^org.keepassxc.KeePassXC$, float on
windowrule = match:class ^org.keepassxc.KeePassXC$, center 1
windowrule = match:class ^org.keepassxc.KeePassXC$, size 70% 70%
```

但缺点是：启动时仍有可能抢焦点或短暂弹出。

### 新配置行为

新版改为：

```ini
exec-once = sh -c 'sleep 3 && keepassxc'

windowrule = match:class ^org\\.keepassxc\\.KeePassXC$, workspace special:keepass silent
windowrule = match:class ^org\\.keepassxc\\.KeePassXC$, no_initial_focus on
windowrule = match:class ^org\\.keepassxc\\.KeePassXC$, float on
windowrule = match:class ^org\\.keepassxc\\.KeePassXC$, center 1
windowrule = match:class ^org\\.keepassxc\\.KeePassXC$, size 70% 70%
windowrule = match:class ^org\\.keepassxc\\.KeePassXC$, persistent_size on
```

并新增：

```ini
bind = ALT, K, togglespecialworkspace, keepass
bind = ALT SHIFT, K, exec, keepassxc
```

### 为什么这么改

- `special:keepass`：把 KeePassXC 当作抽屉应用，而不是普通 workspace。
- `silent`：启动时不切走当前 workspace。
- `no_initial_focus`：避免首次启动抢焦点。
- `ALT+K`：显示/隐藏密码抽屉。
- `ALT+SHIFT+K`：兜底启动 KeePassXC。

这里没有使用 `$mod+K`，因为 `$mod+K` 已经分配给 Vim 风格的向上移动焦点。

### 验证

```bash
hyprctl reload
hyprctl clients | grep -i keepass -A20
```

预期：

- 登录后 KeePassXC 已启动。
- 不会主动弹出到当前屏幕。
- 按 `ALT+K` 可以显示/隐藏。
- `hyprctl clients` 中 KeePassXC 位于 `special:keepass`。

---

## 2. 字母 workspace：从“拉到当前屏幕”改成“跳到它所在屏幕”

### 原配置行为

原配置中字母 workspace 使用的是：

```ini
bind = $mod, R, focusworkspaceoncurrentmonitor, name:R
bind = $mod, X, focusworkspaceoncurrentmonitor, name:X
...
```

这个 dispatcher 的行为是：把目标 workspace 聚焦到当前 monitor。实际效果就是：

```text
显示器 1 有 workspace R
显示器 2 有 workspace M
在显示器 2 按 $mod+R
结果：R 被拉到显示器 2
```

这正是原来的多屏幕问题。

### 新配置行为

新版中字母 workspace 改成：

```ini
bind = $mod, R, workspace, name:R
bind = $mod, V, workspace, name:V
bind = $mod, X, workspace, name:X
bind = $mod, M, workspace, name:M
bind = $mod, W, workspace, name:W
bind = $mod, F, workspace, name:F
bind = $mod, T, workspace, name:T
```

现在语义变成：

```text
$mod+R = 去 R 所在的显示器
不是把 R 拉到当前显示器
```

### 保留的兜底能力

如果确实想把语义 workspace 拉到当前 monitor，可以显式使用：

```ini
bind = $mod CTRL, R, focusworkspaceoncurrentmonitor, name:R
bind = $mod CTRL, V, focusworkspaceoncurrentmonitor, name:V
bind = $mod CTRL, X, focusworkspaceoncurrentmonitor, name:X
bind = $mod CTRL, M, focusworkspaceoncurrentmonitor, name:M
bind = $mod CTRL, W, focusworkspaceoncurrentmonitor, name:W
bind = $mod CTRL, F, focusworkspaceoncurrentmonitor, name:F
bind = $mod CTRL, T, focusworkspaceoncurrentmonitor, name:T
```

### 验证

```text
1. 在显示器 1 打开 workspace R。
2. 在显示器 2 打开 workspace M。
3. 聚焦显示器 2。
4. 按 $mod+R。
```

预期：

```text
焦点跳到显示器 1 的 R。
R 不会被拉到显示器 2。
```

再测试：

```text
在显示器 2 按 $mod+CTRL+R。
```

预期：

```text
这次 R 会被显式拉到当前显示器。
```

---

## 3. 数字 workspace：保留 per-monitor 临时工作区逻辑

### 原配置行为

数字 workspace 原本就是：

```ini
bind = $mod, 1, focusworkspaceoncurrentmonitor, 1
bind = $mod, 2, focusworkspaceoncurrentmonitor, 2
...
```

这套逻辑适合作为“当前显示器上的临时 workspace”。

### 新配置行为

新版保留数字 workspace 的这个行为：

```ini
bind = $mod, 1, focusworkspaceoncurrentmonitor, 1
bind = $mod, 2, focusworkspaceoncurrentmonitor, 2
...
bind = $mod, 0, focusworkspaceoncurrentmonitor, 10
```

### 为什么保留

数字 workspace 适合临时任务，不必和某个应用或显示器强绑定。

例如：

```text
显示器 1：RStudio / Research
显示器 2：workspace 2 临时放浏览器、终端、文件管理器
```

数字 workspace 的心智模型是：

```text
当前显示器要一个临时桌面 → $mod+数字
```

而不是：

```text
我要去全局某个固定语义桌面
```

---

## 4. 移动窗口到 workspace：数字和字母都“移动并跟过去”

### 新配置行为

数字 workspace：

```ini
bind = $mod SHIFT, 1, movetoworkspace, 1
bind = $mod SHIFT, 2, movetoworkspace, 2
...
```

字母 workspace：

```ini
bind = $mod SHIFT, R, movetoworkspace, name:R
bind = $mod SHIFT, V, movetoworkspace, name:V
bind = $mod SHIFT, X, movetoworkspace, name:X
...
```

### 语义

```text
$mod+SHIFT+2 = 把当前窗口移动到 workspace 2，并跟过去
$mod+SHIFT+R = 把当前窗口移动到 workspace R，并跟过去
```

### 为什么没有默认使用 silent

你明确希望：

```text
如果显示器 1 里 workspace R 的窗口想挪到显示器 2 里的 workspace 2，
就直接 $mod+SHIFT+2 移动过去。
```

如果目标 workspace 已经在另一个显示器上，`movetoworkspace` 会把窗口送到那里，并让你跟过去观察结果。

### 验证

```text
1. 显示器 1 的 R 中选中一个窗口。
2. 显示器 2 当前显示 workspace 2。
3. 在显示器 1 按 $mod+SHIFT+2。
```

预期：

```text
窗口移动到 workspace 2。
焦点也跟到 workspace 2。
```

---

## 5. 跨显示器移动：新增“移动到相邻显示器当前 workspace”

### 原配置行为

原来的 `$mod+SHIFT+J/K/I/L` 更像是在当前 workspace 内移动窗口布局。

### 新配置行为

新版改成：

```ini
bind = $mod SHIFT, H, movewindow, mon:l
bind = $mod SHIFT, J, movewindow, mon:d
bind = $mod SHIFT, K, movewindow, mon:u
bind = $mod SHIFT, L, movewindow, mon:r
```

### 语义

```text
$mod+SHIFT+H = 当前窗口移动到左侧显示器当前 workspace
$mod+SHIFT+L = 当前窗口移动到右侧显示器当前 workspace
$mod+SHIFT+K = 当前窗口移动到上方显示器当前 workspace
$mod+SHIFT+J = 当前窗口移动到下方显示器当前 workspace
```

### 为什么这么设计

这是为了处理临时布局变化：

```text
Firefox 平时属于 X。
但现在我只想临时把 Firefox 放到右边显示器。
```

此时不应该改 workspace 名字，也不需要创建一个“右屏 X”。

直接：

```text
聚焦 Firefox
$mod+SHIFT+L
```

它会去右侧显示器当前正在显示的 workspace。

### 验证

```text
1. 中间或右侧显示器选中一个窗口。
2. 按 $mod+SHIFT+H。
```

预期：

```text
窗口移动到左侧显示器当前 workspace。
workspace 名字不变。
```

---

## 6. Vim HJKL：替换原来的 J/K/I/L 风格

### 原配置行为

原配置使用类似 AeroSpace 的方向键：

```ini
bind = $mod, J, movefocus, l
bind = $mod, K, movefocus, d
bind = $mod, I, movefocus, u
bind = $mod, L, movefocus, r
```

这不是 Vim 标准 HJKL。

### 新配置行为

新版改成：

```ini
bind = $mod, H, movefocus, l
bind = $mod, J, movefocus, d
bind = $mod, K, movefocus, u
bind = $mod, L, movefocus, r
```

### 新增当前 workspace 内交换窗口

因为 `$mod+SHIFT+HJKL` 已经用于跨显示器移动，所以当前 workspace 内交换窗口改成：

```ini
bind = $mod CTRL, H, swapwindow, l
bind = $mod CTRL, J, swapwindow, d
bind = $mod CTRL, K, swapwindow, u
bind = $mod CTRL, L, swapwindow, r
```

### 快捷键语义总结

```text
$mod+H/J/K/L        = 移动焦点
$mod+SHIFT+H/J/K/L  = 窗口跨显示器移动
$mod+CTRL+H/J/K/L   = 当前 workspace 内交换窗口
```

---

## 7. Resize：区分“当前窗口变大/变小”和“物理推边界”

### 原配置问题

原配置中 resize 使用 `resizeactive`：

```ini
binde = , J, resizeactive, -60 0
binde = , L, resizeactive,  60 0
binde = , K, resizeactive,  0 -60
binde = , I, resizeactive,  0  60
```

问题是：`resizeactive` 更接近“推 split 边界”，不保证“当前窗口一定变大”。

例如：

```text
workspace 1 有左右两个窗口
聚焦右侧窗口
按横向 + resize
结果可能是右侧窗口变小
```

这不是错觉，而是 Dwindle 二叉树布局下的 split 边界行为。

### 新配置行为

新版加入：

```ini
dwindle {
  smart_resizing = true
  split_bias = 1
}
```

并在 resize mode 中设置：

```ini
binde = , equal, layoutmsg, splitratio +0.05
binde = SHIFT, equal, layoutmsg, splitratio +0.05
binde = , minus, layoutmsg, splitratio -0.05
```

细调：

```ini
binde = CTRL, equal, layoutmsg, splitratio +0.01
binde = CTRL SHIFT, equal, layoutmsg, splitratio +0.01
binde = CTRL, minus, layoutmsg, splitratio -0.01
```

同时保留物理方向 resize：

```ini
binde = , H, resizeactive, -60 0
binde = , L, resizeactive,  60 0
binde = , K, resizeactive,  0 -60
binde = , J, resizeactive,  0  60
```

### 新心智模型

```text
= / +  = 当前窗口变大
-      = 当前窗口变小
HJKL   = 物理方向推 split 边界
```

### 验证

```text
1. workspace 1 放左右两个窗口。
2. 聚焦右边窗口。
3. 按 $mod+- 进入 resize mode。
4. 按 =。
```

预期：

```text
右边窗口变大。
```

再按：

```text
-
```

预期：

```text
右边窗口变小。
```

如果按：

```text
H / L
```

预期：

```text
这是物理方向推边界，可能不等价于“当前窗口变大/变小”。
```

---

## 8. 字母 workspace 精简：从 A-Z 改成少量高频语义锚点

### 原配置问题

原配置倾向于占用大量字母 workspace。这样记忆上看似方便，但会带来几个问题：

1. 和 Vim HJKL 冲突。
2. 和应用快捷键冲突。
3. 多屏幕时容易误以为 workspace 是 monitor-local。
4. 长期维护成本高。

### 新配置保留的字母 workspace

```text
R = RStudio / Research
V = VS Code
X = Firefox / Web
M = Mail / Messaging / Music，根据实际习惯使用
W = Web / Writing / Work，根据实际习惯使用
F = Files
T = Terminal / Tools
```

这些是“全局语义 home workspace”。

### 为什么不限制每个显示器独有 workspace 名字

Hyprland 的 workspace 名字是全局唯一的，不是每个显示器各有一套。

也就是说：

```text
name:X 只能存在一个
workspace 2 也只能存在一个
```

如果强行做 monitor-local 命名，例如：

```text
L:X
C:X
R:X
```

虽然能保证每个显示器都有自己的 X，但快捷键、window rule 和记忆成本都会明显上升。

新版采用更简单的 5A 策略：

```text
不限制 workspace 名字
用 monitor move 解决临时变化
```

例如：

```text
Firefox 平时在 X。
想临时放右屏：
聚焦 Firefox → $mod+SHIFT+L
```

这样不需要创建“右屏 X”，也不会破坏 workspace 语义。

---

## 9. Window rule：应用默认进入语义 workspace，但不抢焦点

新版保留并强化了应用归位规则：

```ini
windowrule = match:class ^(firefox|firefox-esr|org\\.mozilla\\.firefox)$, workspace name:X silent
windowrule = match:class ^(code|Code|code-oss|com\\.visualstudio\\.code)$, workspace name:V silent
windowrule = match:class ^(rstudio|RStudio|com\\.rstudio\\.desktop)$, workspace name:R silent
```

### 语义

```text
Firefox → X
VS Code → V
RStudio → R
```

### 为什么加 silent

避免打开应用时强制切走当前 workspace。

例如：

```text
你正在 workspace 2 写东西。
后台启动 Firefox。
Firefox 应该去 X，但你不应该被强制切到 X。
```

---

## 10. 最终快捷键总表

| 快捷键 | 行为 |
|---|---|
| `ALT+SPACE` | rofi 启动器 |
| `ALT+RETURN` | 打开终端 |
| `ALT+T` | 打开文件管理器 |
| `ALT+Q` | 关闭当前窗口 |
| `ALT+K` | 显示/隐藏 KeePassXC |
| `ALT+SHIFT+K` | 兜底启动 KeePassXC |
| `$mod+1..0` | 当前显示器切到数字 workspace |
| `$mod+SHIFT+1..0` | 当前窗口移动到数字 workspace，并跟过去 |
| `$mod+R/V/X/M/W/F/T` | 跳到语义 workspace 所在显示器 |
| `$mod+SHIFT+R/V/X/M/W/F/T` | 当前窗口移动到语义 workspace，并跟过去 |
| `$mod+CTRL+R/V/X/M/W/F/T` | 显式把语义 workspace 拉到当前显示器 |
| `$mod+H/J/K/L` | Vim 方向移动焦点 |
| `$mod+SHIFT+H/J/K/L` | 当前窗口移动到相邻显示器当前 workspace |
| `$mod+CTRL+H/J/K/L` | 当前 workspace 内交换窗口 |
| `$mod+TAB` | 当前 monitor 的上一个 workspace |
| `$mod+-` | 进入 resize mode |
| resize mode: `=` / `+` | 当前窗口变大 |
| resize mode: `-` | 当前窗口变小 |
| resize mode: `H/J/K/L` | 物理方向推 split 边界 |
| resize mode: `Esc` / `Enter` / `$mod+-` | 退出 resize mode |

其中 `$mod` 当前仍是：

```ini
$mod = SUPER
```

如果想把这些操作真的改成 Alt，需要把配置里的：

```ini
$mod = SUPER
```

改成：

```ini
$mod = ALT
```

但这会影响所有 `$mod` 相关快捷键，建议确认没有和应用内快捷键冲突后再改。

---

## 11. 应用后的验证 checklist

### 重新加载

```bash
hyprctl reload
```

### 检查 keybind

```bash
hyprctl binds | grep -E 'movefocus|movewindow|movetoworkspace|focusworkspaceoncurrentmonitor|layoutmsg|resizeactive'
```

### 检查 monitor / workspace

```bash
hyprctl monitors
hyprctl workspaces
```

### 检查 KeePassXC

```bash
hyprctl clients | grep -i keepass -A20
```

### 手动测试场景

#### 场景 A：字母 workspace 不搬家

```text
1. 显示器 1 打开 R。
2. 显示器 2 打开 M。
3. 聚焦显示器 2。
4. 按 $mod+R。
```

预期：

```text
焦点跳到显示器 1 的 R。
R 不被拉到显示器 2。
```

#### 场景 B：窗口移动到另一个显示器上的 workspace 2

```text
1. 显示器 1 的 R 中选中窗口。
2. 显示器 2 当前为 workspace 2。
3. 按 $mod+SHIFT+2。
```

预期：

```text
窗口进入 workspace 2。
焦点跟过去。
```

#### 场景 C：窗口临时移动到左侧显示器当前 workspace

```text
1. 中间或右侧显示器选中窗口。
2. 按 $mod+SHIFT+H。
```

预期：

```text
窗口进入左侧显示器当前 workspace。
workspace 名字不改变。
```

#### 场景 D：resize 当前窗口

```text
1. 一个 workspace 中放左右两个窗口。
2. 聚焦右侧窗口。
3. 按 $mod+- 进入 resize mode。
4. 按 =。
```

预期：

```text
右侧窗口变大。
```

---

## 12. 后续可选优化

当前版本故意没有做这些事情：

1. 没有强绑定每个显示器只能使用某些 workspace 名。
2. 没有把 workspace 命名做成 `L:X / C:X / R:X`。
3. 没有把所有窗口移动改成 silent。
4. 没有把 `$mod` 从 `SUPER` 改成 `ALT`。

原因是当前目标是：

```text
稳定、好记、少折腾、允许临时变化窗口布局。
```

等这版稳定后，可以再考虑：

```text
- 给 R/V/X 绑定默认 monitor
- 给 Waybar 添加 semantic workspace 图标
- 给特殊应用增加更多 special workspace
- 为三屏布局补充更明确的 monitor profile
```

