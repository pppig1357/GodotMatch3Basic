# L4 课件 · HUD 场景拼接手把手（纯编辑器 · 零脚本）

> **定位**：对齐 L1「从零复刻」+ 官方 Dodge the Creeps 06 HUD 章节——学员在编辑器里**从空场景亲手拼出 hud.tscn**（节点树 / 贴图 / 锚点 / 属性），**全程不碰代码**；`hud.gd` 在拆页 **Part B（代码环节）** 才创建
> **两段式节奏**：**Part A 拼壳**（本手册 Step 1-7，纯编辑器）→ **Part B 写行为**（拆页 B1-B4 + 本手册 Step 8-11，建 hud.gd）
> **代码来源**：教学版 v3.2（`scenes/hud.tscn` / `scripts/hud.gd`）——**拼出的场景与成品同构**（节点名、属性逐字对齐）
> **Part A 终点**：F5 看到标题界面（幕布 + 底板 + 标题 + 按钮），按钮 hover 有高光；**点开始暂不响应 = 正常**（还没装"行为"）
> **预计时长**：Part A 约 20min；Part B（代码）约 20min
> **配套**：拆页文案 Part A（A1 图纸 / A2 概览 / A3 幕后）+ Part B（B1-B4）

---

## 0. 讲师视角：这节教什么、不教什么

**一句话教学线：场景管"长什么样"，代码管"干什么"。** 壳先拼好，行为后装——这是官方 Dodge the Creeps 的节奏（官方也是节点搭完才加脚本）。

| 环节 | 学员做什么 | 不做什么 |
|------|-----------|---------|
| Part A 拼壳（本手册 Step 1-7） | 建场景、加节点、拖贴图、设锚点、调属性、挂进 main | **不碰 hud.gd，不连信号** |
| Part B 行为（拆页 B1-B4 + Step 8-11） | 新建 hud.gd → 敲/贴代码 → 连信号 → 全验证 | 不写新玩法逻辑 |

**为什么信号也留到 Part B：** 官方是写完函数才连 `pressed`。拼接时没脚本，连了信号也是空的——不如把"接线"和"代码"一起讲，学员看到的是"函数写好了 → 接上线 → 有反应"的完整闭环。

**课前准备（讲师做）：**
1. **学员版 `scenes/main.tscn` 移除 HUD 实例**（否则拼完无法挂载；成品版保留）
2. 确认 `assets/ui-kenney/` 素材已就位（L1 已整包拷入：PNG/Yellow、PNG/Blue、Font/Kenney Future.ttf、Sounds/ogg）
3. ⚠️ **学员项目里暂不要放 `scripts/hud.gd`**——Part B 由学员现场新建（"不着急创建"）

---

# Part A · 拼壳（纯编辑器，零脚本，~20min）

## Step 1 · 新建 hud.tscn（2min）

**操作步骤：**
1. 菜单 **场景 → 新建场景** → 根节点选 **CanvasLayer** → 命名 `HUD` → 保存为 `scenes/hud.tscn`
2. ⚠️ **不挂脚本**——根节点就这样空着，脚本 Part B 才建

**场景树：**
```
HUD (CanvasLayer)
```

**讲师讲什么：** CanvasLayer = UI 专用层，永远盖在游戏内容上面，不会被棋盘挡住。**注意：现在这个场景还没有脚本、没有行为——它就是一张"图纸"，接下来我们把节点一个个放上去。**

---

## Step 2 · 标题幕布：Mask + TitlePanel（5min）

**操作步骤：**
1. 选中 `HUD` → 点 **+ 添加子节点** → **ColorRect**，命名 `Mask`
   - **锚点预设 → 全屏（Full Rect）**（四角拉满窗口）
   - **Color**：`(0.1, 0.12, 0.16, 0.72)`（半透明深色幕布，Alpha 0.72）
2. 选中 `Mask` → **+ 添加子节点** → **NinePatchRect**，命名 `TitlePanel`
   - **锚点预设 → 居中（Center）**
   - **Offset**：左 `-220` / 上 `-100` / 右 `220` / 下 `60`（440×160 的底板）
   - **Texture**：拖 `assets/ui-kenney/PNG/Yellow/Default/button_rectangle_depth_flat.png`（亮黄底板）
   - **Patch Margin**：左/上/右/下都填 `14`（九宫格：拉伸不变形）

**场景树：**
```
HUD (CanvasLayer)
└── Mask (ColorRect)          # 全屏半透明幕布
    └── TitlePanel (NinePatchRect)   # 亮黄底板，居中
```

**讲师讲什么：** Mask 是"幕布"，TitlePanel 是"底板"。标题界面 = 幕布 + 底板 + 标题文字 + 开始按钮。NinePatchRect 的 Patch Margin 是"九宫格"——贴图四角不动、中间拉伸，所以 440×160 也不会糊。

---

## Step 3 · 标题文字 Message（3min）

**操作步骤：**
1. 选中 `HUD` → **+ 添加子节点** → **Label**，命名 `Message`
2. **锚点预设 → 居中（Center）**；**Offset**：左 `-200` / 上 `-80` / 右 `200` / 下 `40`
3. **Text** 填 `宝石迷阵`（Part C 收尾再换成自己的名字）
4. 样式三连：
   - **theme_override_fonts/font** → 拖 `assets/ui-kenney/Font/Kenney Future.ttf`
   - **theme_override_font_sizes/font_size** → `28`
   - **theme_override_colors/font_color** → 深色 `(0.12, 0.1, 0.05)`
5. **Horizontal Alignment / Vertical Alignment** 都选居中

**讲师讲什么：** Label 就是文字控件；字体、字号、颜色全是"资源 + 检查器属性"——改任何一样都不用写代码。theme_override_ 前缀的意思是"覆盖默认主题"。

---

## Step 4 · 开始按钮 StartButton（5min）

**操作步骤：**
1. 选中 `HUD` → **+ 添加子节点** → **Button**，命名 `StartButton`
2. **锚点预设 → 底部居中（Center Bottom）**；**custom_minimum_size** 填 `200 × 56`；**Offset**：左 `-100` / 上 `-140` / 右 `100` / 下 `-84`
3. **Text** 填 `开始游戏`
4. 字体字色：**font** 拖 Kenney Future.ttf；**font_size** `22`；**font_color** 深色 `(0.15, 0.12, 0.05)`
5. 三态样式（StyleBoxTexture，都在 **theme_override_styles** 下新建）：
   - **normal** → 拖 `PNG/Yellow/Default/button_rectangle_depth_gradient.png`（亮黄主按钮）
   - **hover** / **pressed** → 拖 `button_rectangle_depth_gloss.png`（亮黄高光，悬停/按下变亮）
   - **focus** → 用 normal 同款

**讲师讲什么：** 按钮 = 贴图样式 + 文字 + 信号。normal / hover / pressed 是"三个状态"——配不同贴图就有"按下去"的手感。**样式是资源，不是代码**。注意：按钮现在只是"好看"，它还没有"点了要干嘛"——那是 Part B 的事。

---

## Step 5 · 对局两件套：ScoreLabel + RestartButton（4min）

**操作步骤：**
1. 选中 `HUD` → **+ 添加子节点** → **Label**，命名 `ScoreLabel`
   - **Visible 勾掉**（初始隐藏，对局中才显示）
   - **锚点预设 → 左上角（Top Left）**；**Offset**：左 `16` / 上 `12` / 右 `280` / 下 `44`
   - **Text** 填 `分数: 0`；**font** Kenney；**font_size** `22`；**font_color** 浅色 `(0.92, 0.93, 0.95)`
2. 选中 `HUD` → **+ 添加子节点** → **Button**，命名 `RestartButton`
   - **Visible 勾掉**（初始隐藏）
   - **锚点预设 → 右上角（Top Right）**；**Offset**：左 `480` / 上 `12` / 右 `624` / 下 `52`
   - **Text** 填 `重新开始`；**font** Kenney；**font_size** `18`；**font_color** 浅色 `(0.95, 0.97, 1)`
   - 三态样式：**normal** → `PNG/Blue/Default/button_rectangle_depth_flat.png`；**hover / pressed** → `button_rectangle_depth_gradient.png`（蓝色系次按钮）

**讲师讲什么：** 为什么两个控件初始隐藏？——标题态只露"幕布 + 标题 + 开始按钮"，分数和重开是**对局态**才出现。这个"藏 3 亮 2"的切换，Part B 的 `prepare_playing()` 会负责——**场景把初始状态定好，脚本负责运行时切换**。

---

## Step 6 · 挂进 main.tscn（3min）

**操作步骤：**
1. 打开 `scenes/main.tscn` → 选中 `Main` 根节点 → 点工具条 **实例化子场景**（链环图标）→ 选 `scenes/hud.tscn` → 实例名默认 `HUD`
2. ⚠️ 如果场景树里已经有一个旧 HUD 实例：**先删掉再加**，保证只有一份
3. 顺手补两个音频节点（main.gd 的 `_ready` 要用，不补会报 null）：
   - 添加 **AudioStreamPlayer** 命名 `Music` → stream 拖 `assets/House In a Forest Loop.ogg` → **Volume dB** 调 `-8`
   - 添加 **AudioStreamPlayer** 命名 `SfxClear` → stream 拖 `assets/ui-kenney/Sounds/tap-a.ogg`

**讲师讲什么：** hud.tscn 是独立"图纸"，main 里放一个实例——**和 L1 的 gem.tscn 一模一样**，这就是场景实例化。main.gd 里 `$HUD` 拿到的就是这个节点。

---

## Step 7 · 壳验证（3min）

**验证清单（Part A 只验"壳"）：**

| 操作 | 期望 |
|------|------|
| 启动 | 标题界面：半透明幕布 + 亮黄底板 + 「宝石迷阵」+ 亮黄开始按钮，**看不见棋盘** |
| 鼠标移到开始按钮上 | 按钮变亮（hover 高光生效） |
| 点「开始游戏」 | **暂不响应 = 正常**——行为（代码）还没装，Part B 装完就有反应了 |

**讲师讲什么：** 壳拼好了，但现在它"只有外表、没有灵魂"——按钮点了没反应，因为还没有代码告诉它要干嘛。**接下来 Part B：给它装上行为。**（这也是个教学点：界面管长相，代码管行为，两者分开。）

---

# Part B · 写行为（hud.gd，~20min）

> 拆页对照：B1 = 本 Step 9 第一段 / B2 = 第二段 / B3 = 接线与 main 连接 / B4 = 为什么解耦

## Step 8 · 新建 hud.gd（2min）

**操作步骤：**
1. 回到 `scenes/hud.tscn` → 选中 `HUD` 根节点 → 检查器 → **新建脚本**（New Script）
2. 路径填 `scripts/hud.gd`，Inherits 保持 `CanvasLayer` → Create

**讲师讲什么：** 场景拼完了，现在给它"装大脑"。**之前所有的 UI 操作都不写代码；从这一步开始才是代码的事。**

## Step 9 · 敲入代码（两段，10min）

**第一段（对应拆页 B1，信号 + 节点引用 + 按钮回调）：**

```gdscript
extends CanvasLayer

## 对外信号：玩家点了「开始游戏」
signal start_game
## 对外信号：玩家点了「重新开始」
signal restart

## @onready：进场景树后取子节点（hud.tscn 里预置的控件）
@onready var score_label: Label = $ScoreLabel
@onready var restart_button: Button = $RestartButton

## 开始按钮被点 → 发 start_game 信号（Main 收到后开新局）
func _on_start_button_pressed() -> void:
	start_game.emit()

## 重新开始按钮被点 → 发 restart 信号（Main 收到后开新局）
func _on_restart_button_pressed() -> void:
	restart.emit()
```

**第二段（对应拆页 B2，界面切换 + 分数刷新）：**

```gdscript
## 进入对局：隐藏标题界面，显示分数与重开按钮
func prepare_playing() -> void:
	$Mask.hide()             # 隐藏半透明遮罩（标题画面的"幕布"）
	$Message.hide()          # 隐藏标题文字
	$StartButton.hide()      # 隐藏开始按钮
	restart_button.show()    # 显示重新开始按钮
	score_label.show()       # 显示分数

## 刷新分数显示：分数 Label 的文字
func update_score(score: int) -> void:
	score_label.text = "分数: %d" % score    # %d 是占位符，被 score 替换
```

**讲师讲什么：** 逐段讲（详见拆页 B1-B2 口播）——`signal` = 喇叭；`@onready` = 拿控件引用；`emit()` = 喊一声；`prepare_playing` = 藏 3 亮 2；`%d` = 占位符。

## Step 9.5 · main.gd 补 L4 新增段（10min，对应拆页 B3-B5）

**操作步骤：** 打开 `scripts/main.gd`，按拆页 B3-B5 抄三块：
1. 顶部 `@onready var board = $Board` 下面加：`@onready var hud: CanvasLayer = $HUD`（B3 声明）
2. 末尾加 `_ready()` 接线段（B3）——四条 connect + BGM 初始化
3. 末尾加 `new_game()`（B4）
4. 末尾加 `_on_match_cleared()` + `_setup_music_loop()`（B5）

**讲师讲什么：** 「这就是拆页 B3-B5 的实操落点——**hud.gd 是给 HUD 装行为，main.gd 是给整台机器接线**。三块抄完，`_ready` 里引用的函数就全部有主了，报错消失。」

**常见坑：** 漏 `@onready var hud` 声明 → hud not declared（B3 第一行就是它）；只抄 `_ready` 不抄三个函数 → 依旧报 not declared（**三块全部抄完才算完**）。

## Step 10 · 连信号（3min）

**操作步骤：**
1. 选中 `StartButton` → 右上角 **节点（Node）页签** → 双击 **pressed** → 目标选 `HUD`、方法 `_on_start_button_pressed`（脚本里刚写好的，下拉里直接有）→ **Connect**
2. 选中 `RestartButton` → 双击 **pressed** → 目标 HUD、方法 `_on_restart_button_pressed` → Connect

**讲师讲什么：** 现在函数写好了，接上线就有反应了——这就是"编辑器里连信号"和 main.gd 里 `connect()` 是一回事。按钮被点 → 发 `pressed` → hud 喊 `start_game` →（B3 会讲）main 接住。

## Step 11 · 全验证（3min）

| 操作 | 期望 |
|------|------|
| 点「开始游戏」 | **有反应了**：开局，分数显示 `分数: 0`，重开按钮出现 |
| 点「重新开始」 | 直接开新局（不回标题） |
| 消除一组宝石 | 分数变化（30/40…） |

**讲师讲什么：** 对比 Step 7——同一个场景，装上行为之后就"活"了。**这就是"壳 + 行为"：界面管长什么样（Part A），代码管干什么（Part B）。**

---

# Part C · 个性化收尾（对应拆页 C1，5min）

**操作步骤：**
1. **换色**：选中 `StartButton` → theme_override_styles 三态 → 换成 `PNG/Blue/Default/` 系列（或随便拖别的贴图试）
2. **改名**：`Message` 的 Text 改成你给游戏起的名字
3. **F5 验收**：按钮变色 ✅ 标题是你的名字 ✅ 正常开局 ✅

**讲师讲什么：** 这就是"界面层随便改、逻辑层毫发无损"——hud.gd 一行没动，整个门面变成你的了。**换皮肤 = 换资源，不是改程序。**

---

## 常见坑

| 坑 | 现象 | 解法 |
|----|------|------|
| Mask 忘了全屏锚点 | 幕布只有一角 | 锚点预设 → 全屏 |
| TitlePanel 没设 Patch Margin | 底板拉伸变形 | Patch Margin 四项填 14 |
| Message/StartButton 挂到 TitlePanel 里 | 视觉没错，但和成品结构不一致 | 本课特意**平铺在 HUD 下**——位置靠锚点，不靠嵌套（教学点） |
| 字体没挂 | 显示默认字体 | theme_override_fonts/font 拖 Kenney Future.ttf |
| Part A 就急着点开始 | 没反应，以为拼错了 | **正常**——行为在 Part B 才装；先验"壳"（界面显示 + hover） |
| 信号漏连/连错目标 | 装完代码点开始仍没反应 | 查 StartButton 节点页签的 pressed 连接 |
| 连信号时选中了 HUD 根节点 | 点按钮没反应（tscn 里 from="." = 自连） | **选中按钮**（不是 HUD）→ 节点页签 → pressed → 连到 HUD 回调；检查 connection 行的 from 应是按钮名 |
| 忘了实例化进 main.tscn | F5 打开没有 HUD | Step 6 实例化 hud.tscn |
| main 里有两个 HUD | main.gd `$HUD` 拿到不确定的哪个 | 删掉旧的，只留一份 |

---

## 对应拆页（L4 前半）

| 拆页 | 对应 |
|------|------|
| A1 图纸 / A2 概览 / A3 幕后 | Part A（Step 1-7） |
| B1-B4 hud.gd 代码与接线 | Part B（Step 8-11） |
| C1 实操收尾 | Part C（个性化） |

---

*v2：2026-09-14 | 小龙虾 🦞 · 拼壳与代码彻底分家（Part A 纯编辑器零脚本 / Part B 才建 hud.gd，对齐官方 Dodge 06 节奏）——取代 v1（脚本提前挂 + 拼接时连信号）*
