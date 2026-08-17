extends Node2D
## ============================================================
## gem.gd —— 游戏「棋子」（单颗宝石）
## ============================================================
## 角色定位：一颗宝石长什么样、怎么动。它自己不决定游戏规则，
## 只提供"表现"能力，被 board.gd 和 main.gd 调用。
##
## 代码块划分（课件可拆块讲解）：
##   ① 类型枚举 + 贴图     —— 六色怎么表示、贴图从哪来
##   ② 初始化             —— setup / set_type
##   ③ 选中反馈           —— set_selected（半透明白遮罩）
##   ④ 动画三件套         —— 交换 / 消除 / 下落
## ============================================================
class_name Gem

## 六种宝石颜色（枚举 = 一组有名字的整数常量）
## RED=0, BLUE=1, GREEN=2, YELLOW=3, PURPLE=4, ORANGE=5
enum GemType { RED, BLUE, GREEN, YELLOW, PURPLE, ORANGE }

## 六色贴图数组：在 gem.tscn 场景里按 enum 顺序挂好 6 张 PNG
## （索引 0 对应 RED，1 对应 BLUE…换贴图只需这一行数组，不写代码）
@export var gem_textures: Array[Texture2D] = []

## 当前宝石类型（默认红色）
var type: int = GemType.RED
## 网格坐标 (col, row)——它在棋盘的哪一格
var grid_pos: Vector2i = Vector2i.ZERO

## @onready：进场景树后才取子节点
## $Sprite     = 显示贴图的精灵节点（贴图是场景里挂的资源，不是代码画的）
## $SelectMask = 选中遮罩（半透明白色方块，选中时显示）
@onready var _sprite: Sprite2D = $Sprite
@onready var _select_mask: ColorRect = $SelectMask


## 初始化：设置类型 + 网格坐标（由 board._spawn_gem 在创建时调用）
func setup(gem_type: int, pos: Vector2i) -> void:
	type = gem_type
	grid_pos = pos
	set_type(gem_type)      # 立刻换上对应颜色的贴图


## 更换类型：换一张贴图（ensure_no_initial_matches 换色时也会调用）
func set_type(gem_type: int) -> void:
	type = gem_type
	_sprite.texture = gem_textures[gem_type]   # 从数组里取对应颜色的贴图


## 选中反馈：true 亮遮罩 / false 熄遮罩
func set_selected(on: bool) -> void:
	_select_mask.visible = on


## 动画①：滑动交换（移动到目标位置，0.15 秒）
func animate_swap_to(target: Vector2) -> void:
	var tween := create_tween()
	tween.tween_property(self, "position", target, 0.15)
	await tween.finished    # 等动画播完才返回（模板 T3：动画必须 await 串行）


## 动画②：消除（缩小到 0.2 倍 + 淡出到透明，0.2 秒，两个效果同时进行）
func animate_clear() -> void:
	var tween := create_tween()
	tween.set_parallel(true)    # 并行模式：缩小和淡出一起播
	tween.tween_property(self, "scale", Vector2(0.2, 0.2), 0.2)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)   # modulate:a = 透明度
	await tween.finished


## 动画③：下落（移动到目标位置，时长由下落格数决定——格数多花的时间长）
func animate_fall_to(target: Vector2, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(self, "position", target, duration)
	await tween.finished
