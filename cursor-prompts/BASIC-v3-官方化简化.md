# BASIC v3 · 官方化简化（对齐 Dodge the Creeps 风格）

> 目标：把教学版三消简化到接近官方「Your first 2D game (Dodge the Creeps)」的复杂度——
> **场景即节点类型、一场景一脚本、贴图资源直接挂在节点上、代码只写行为**。
> 背景：完整版（godot-match3 目录）保留全部功能不动；本目录（BasicMode）只做减法。

## 总原则

1. **只做下面清单内的改动**，其余一律不动（防死局、连锁计分、信号架构、场景实例化、选中遮罩都在保留清单里）。
2. **不要重构**：不优化性能、不改命名风格、不加新功能。
3. 改动后保持项目可运行：`godot --headless --import` 无错误，F5 可玩。
4. 目标代码量：5 文件 ~790 行 → 4 文件 ~490 行（main ~100 / board ~300 / gem ~50 / hud ~50）。

---

## 改动 1：gem.tscn + gem.gd —— 贴图直接挂载，砍动态切帧动画

**现状**：gem.gd 用代码静态构建 SpriteFrames（6 色 × 40 帧 AtlasTexture 旋转动画），AnimatedSprite2D 播放。
**目标**：Sprite2D 静态贴图，贴图资源在 tscn 里定义，代码只负责换 texture。

### gem.tscn 改法
- 节点树保持：`Gem (Node2D, 挂 gem.gd)` → `Sprite (Sprite2D)` + `SelectMask (ColorRect)`
- `Sprite`：把 `AnimatedSprite2D` 换成 `Sprite2D`
  - `centered = false`
  - `scale = Vector2(1.2308, 1.2308)`（52px 贴图 → 64px 格子，写死在场景里，代码不算）
  - `texture` 默认挂「红色」AtlasTexture（见下）
- 新增 6 个 `AtlasTexture` 子资源（`atlas = res://assets/sprites/gems/gem_bomb_rainbow.png`，`region` 取各色**第一帧** 52×52，即 row×52, col=0）：
  - RED: row 12（红）
  - BLUE: row 0
  - GREEN: row 3
  - ORANGE: row 6
  - PURPLE: row 9
  - YELLOW: row 18
- `SelectMask` 保持现状（64×64、visible=false、半透明白）
- 根节点 `Gem` 增加 `@export gem_textures: Array[Texture2D]`，在 tscn 里按 **enum 顺序**（RED, BLUE, GREEN, YELLOW, PURPLE, ORANGE）填 6 个子资源引用

### gem.gd 目标（~50 行）
```gdscript
extends Node2D
## 单个宝石：静态贴图 + 半透明选中遮罩。
class_name Gem

## 六种宝石颜色
enum GemType { RED, BLUE, GREEN, YELLOW, PURPLE, ORANGE }

## 六色贴图（tscn 里按 enum 顺序挂 AtlasTexture）
@export var gem_textures: Array[Texture2D] = []

## 当前宝石类型
var type: int = GemType.RED
## 网格坐标 (col, row)
var grid_pos: Vector2i = Vector2i.ZERO

@onready var _sprite: Sprite2D = $Sprite
@onready var _select_mask: ColorRect = $SelectMask

## 初始化：类型 + 网格坐标
func setup(gem_type: int, pos: Vector2i) -> void:
	type = gem_type
	grid_pos = pos
	set_type(gem_type)

## 更换类型：换一张贴图
func set_type(gem_type: int) -> void:
	type = gem_type
	_sprite.texture = gem_textures[gem_type]

## 选中反馈：半透明白色遮罩
func set_selected(on: bool) -> void:
	_select_mask.visible = on

## 滑动交换
func animate_swap_to(target: Vector2) -> void:
	var tween := create_tween()
	tween.tween_property(self, "position", target, 0.15)
	await tween.finished

## 消除：缩小 + 淡出
func animate_clear() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(0.2, 0.2), 0.2)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await tween.finished

## 下落
func animate_fall_to(target: Vector2, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(self, "position", target, duration)
	await tween.finished
```
**删除**：`SHEET`、`FRAME_SIZE`、`FRAMES_PER_ANIM`、`GEM_ROW`、`ANIM_NAME`、`_shared_frames`、`_build_frames()`、`get_shared_frames()`、`_cell_size`、setup 的 `cell_size/_colors` 参数、`set_type` 的 `_colors` 参数、`_sprite.scale` 计算。

---

## 改动 2：board.gd —— 砍限步模式 + 合并 board_resolve.gd

**现状**：限步逻辑散布 board/main/hud；结算逻辑在 board_resolve.gd（RefCounted 辅助类）。
**目标**：删掉全部限步相关；`board_resolve.gd` 的内容合并回 board.gd 末尾，删除该文件。一场景一脚本。

### 删（限步相关）
- `MOVES_DEFAULT` 常量
- `moves_changed` 信号
- `moves_left`、`moves_limited` 变量
- `reset_game(limited)` 的 limited 参数 → `reset_game()`
- `try_swap` 里的扣步块：
  ```gdscript
  if moves_limited:
  	moves_left -= 1
  	moves_changed.emit(moves_left)
  ```

### 删（辅助类相关）
- `const ResolveHelper = preload("res://scripts/board_resolve.gd")`
- `_resolve` 变量、`_ready` 里的实例化
- `resolve_board()` 委托 → 直接内联实现

### 合并（从 board_resolve.gd 搬入 board.gd，放文件末尾）
- `resolve_board()`（`_resolve.resolve_board()` 改为直接循环）
- `clear_matches(matches, chain)`
- `_calc_score(groups)`
- `fall_and_refill()`
- 注意把 `board.xxx` 引用改为 `self`（如 `board.grid` → `grid`，`board.GRID_SIZE` → `GRID_SIZE`，`board._spawn_gem(...)` → `_spawn_gem(...)`，`board.grid_to_world(...)` → `grid_to_world(...)`，`board.create_tween()` → `create_tween()`）

### 改（配合 gem.gd 新签名）
- `_spawn_gem(gem_type, pos)`：`gem.setup(gem_type, pos, CELL_SIZE, GEM_COLORS)` → `gem.setup(gem_type, pos)`
- `ensure_no_initial_matches`：`(gem as Gem).set_type(random_gem_type(), GEM_COLORS)` → `(gem as Gem).set_type(random_gem_type())`
- **删除** `GEM_COLORS` 字典（贴图模式下无用）

### 保留不动
`GRID_SIZE`、`CELL_SIZE`、`score_changed`/`match_cleared` 信号、`grid`/`origin`/`score`、`clear_board`、`_compute_origin`、`grid_to_world`/`world_to_grid`、`get_gem_at`、`random_gem_type`、`fill_grid`、`find_match_groups`/`find_matches`/`_add_unique`、`ensure_no_initial_matches`、`has_moves`/`ensure_has_moves`、`_is_adjacent`、`_swap_grid_data`、`_animate_swap_pair`、`try_swap`。

### 删除文件
`res://scripts/board_resolve.gd`（连同 `.uid` 文件；确认无其他引用后删）。

---

## 改动 3：main.gd —— 砍拖拽 + 砍 GAME_OVER 状态

**现状**：210 行，含拖拽全套（_dragging/_press_world/_gem_home/_drag_swapped/阈值/方向判定）+ GAME_OVER。
**目标**：~100 行，纯点选交互，无游戏结束（无限步）。

### 删
- `State.GAME_OVER`（枚举只剩 WAITING, IDLE, SELECTED, SWAPPING, RESOLVING）
- 全部拖拽相关：`DRAG_SWAP_THRESHOLD`、`_dragging`、`_press_world`、`_gem_home`、`_drag_swapped`、`_start_drag_on_selected()`、`_on_pointer_drag()`、`_clamp_drag_offset()`、`_drag_direction()`、`_on_pointer_up()`
- `_on_moves_changed()`、`hud.update_moves(...)` 调用
- `new_game(limited)` 的 limited 参数 → `new_game()`
- `_do_swap` 里的 GAME_OVER 分支：
  ```gdscript
  if board.moves_limited and board.moves_left <= 0:
  	state = State.GAME_OVER
  	$Music.stop()
  	hud.show_game_over(board.score)
  else:
  	state = State.IDLE
  ```
  → 直接 `state = State.IDLE`

### 交互逻辑（保留点选三规则）
```
IDLE 点击宝石     → 选中（SELECTED）
SELECTED 点自己   → 取消（回 IDLE）
SELECTED 点相邻   → 交换（SWAPPING → RESOLVING → IDLE）
SELECTED 点非相邻 → 换选（保持 SELECTED）
点击空白          → 取消选中（回 IDLE）
```
`_unhandled_input`：`WAITING / SWAPPING / RESOLVING` 忽略；只处理左键按下（不再有 MouseMotion 分支）。

### 保留不动
`enum State`（去掉 GAME_OVER 后）、`BoardScript` preload、`@onready board/hud`、信号连接（`start_game`/`back_to_title`/`score_changed`/`match_cleared`）、`_setup_music_loop`、`$SfxClick/SfxSelect/SfxSwap/SfxClear` 音效调用、`_select/_deselect/_is_adjacent/_do_swap` 骨架。

---

## 改动 4：hud.tscn + hud.gd —— 删限步控件

**现状**：HUD 有 ScoreLabel / MovesLabel / RestartButton / Message / Mask / MovesLimitedCheck。
**目标**：删 MovesLabel + MovesLimitedCheck，其余保留（RestartButton 语义简化）。

### hud.tscn
- 删除节点：`MovesLabel`、`MovesLimitedCheck`
- 删除不再使用的子资源：`StyleBoxTexture_check`

### hud.gd 目标（~50 行）
```gdscript
extends CanvasLayer
## HUD：标题/遮罩 + 对局 HUD；通过信号通知 Main。
signal start_game
signal restart

@onready var score_label: Label = $ScoreLabel
@onready var message: Label = $Message
@onready var start_button: Button = $StartButton
@onready var restart_button: Button = $RestartButton
@onready var mask: ColorRect = $Mask

func _ready() -> void:
	show_title()

func update_score(score: int) -> void:
	score_label.text = "分数: %d" % score

func show_title() -> void:
	mask.show()
	message.text = "宝石迷阵（三消）"
	message.show()
	start_button.text = "开始游戏"
	start_button.show()
	restart_button.hide()
	score_label.hide()

func prepare_playing() -> void:
	mask.hide()
	message.hide()
	start_button.hide()
	restart_button.show()
	score_label.show()

func _on_start_button_pressed() -> void:
	start_game.emit()

func _on_restart_button_pressed() -> void:
	restart.emit()
```
**删除**：`start_game(limited)` 参数、`back_to_title` 信号、`moves_label`/`moves_check` 引用、`update_moves()`、`show_game_over()`。

### main.gd 配合改
- `hud.start_game.connect(new_game)`（信号无参了）
- `hud.back_to_title.connect(_on_back_to_title)` → 改为 `hud.restart.connect(new_game)`
- **删除** `_on_back_to_title()` 和 `board.clear_board()` 调用（标题界面只在首次启动出现；对局中 RestartButton 直接开新局）
- `_ready` 里删 `hud.update_moves(board.moves_limited, board.moves_left)`
- 注意：`RestartButton` 的 `pressed` 连接从 `_on_restart_button_pressed`（现在 emit restart）保持不变即可

---

## 改动 5：main.tscn —— BGM 内嵌改外部引用

**现状**：`Music` 的 stream 是内嵌 `OggPacketSequence`（1.9MB 数据在 tscn 里）。
**目标**：改为 ext_resource 引用 `res://assets/House In a Forest Loop.ogg`（文件已存在）。
- 删掉 tscn 里的 `[sub_resource type="OggPacketSequence" ...]` 及那行 1.9MB 数据
- `Music` 节点加 `stream = ExtResource(...)` 引用外部 ogg
- `main.gd` 的 `_setup_music_loop()` 逻辑保持不变（loop 属性设置仍有效）

---

## 改动 6：README.md 玩法段落更新

替换「玩法」小节为：
```markdown
## 玩法

- 点击选中宝石，再点相邻宝石交换；再点已选中宝石取消选中
- 横/竖连续 ≥3 同色消除，上方下落并顶部补新，可连锁
- 计分：每组 3 个 30 分，多 1 个 +10；连锁倍率 ×n
- 开局自动排除死局（无可行步则重排）
- 无限步模式，自由游玩；右上角「重新开始」随时开新局
```
同时更新「项目结构」中的脚本列表（删掉 board_resolve.gd），并在 BGM 说明处改为「BGM 为外部引用 `assets/House In a Forest Loop.ogg`，随仓库提供」。

---

## 保留清单（红线，勿动）

- ✅ 防死局：`ensure_no_initial_matches` + `has_moves` + `ensure_has_moves`
- ✅ 连锁计分 ×n、消除/下落动画（`animate_clear` / `animate_fall_to` / `animate_swap_to`）
- ✅ 信号架构：`score_changed` / `match_cleared` / HUD `start_game` / `restart`
- ✅ 场景实例化：`gem.tscn` + `preload + instantiate + add_child`
- ✅ 选中遮罩 `SelectMask`（半透明白高亮）
- ✅ 音效 4 个（click/select/swap/clear）+ BGM 循环
- ✅ 窗口 640×720、`click` InputMap、GL Compatibility

## 验收清单（改完后自查）

1. `godot --headless --import` 退出码 0，无资源缺失报错
2. F5 运行：
   - 标题界面只有「开始游戏」按钮（无限步勾选）
   - 开局无初始三消、至少一步可走
   - 点选交换：相邻交换成功消除；无效交换弹回；点自己取消；点空白取消
   - 消除 → 下落 → 连锁正常，分数累加
   - 「重新开始」直接开新局（不经过标题）
   - 无 GAME_OVER 路径（永远不会出现「游戏结束」）
3. 代码量：main < 120 行，gem < 60 行，hud < 60 行，board < 330 行
4. 全项目搜索 `moves` / `limited` / `GAME_OVER` / `drag` / `board_resolve` 无残留引用（README 说明文字除外）

---

*v3 简化版：2026-08-13 | 小龙虾 🦞 · 对齐官方 Dodge the Creeps 教学风格*
