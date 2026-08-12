extends Node2D
## 单个宝石：AnimatedSprite2D 贴图 + 半透明选中遮罩。
## 教学点：sprite sheet 切帧 → SpriteFrames → 按类型播放旋转动画。
class_name Gem

## 六种宝石颜色
enum GemType { RED, BLUE, GREEN, YELLOW, PURPLE, ORANGE }

const SHEET := preload("res://assets/sprites/gems/gem_bomb_rainbow.png")
const FRAME_SIZE := 52
const FRAMES_PER_ANIM := 40
## 每色三行（宝石/心/环），只用几何宝石行
const GEM_ROW := {
	GemType.BLUE: 0,
	GemType.GREEN: 3,
	GemType.ORANGE: 6,
	GemType.PURPLE: 9,
	GemType.RED: 12,
	GemType.YELLOW: 18,
}
const ANIM_NAME := {
	GemType.RED: "red",
	GemType.BLUE: "blue",
	GemType.GREEN: "green",
	GemType.YELLOW: "yellow",
	GemType.PURPLE: "purple",
	GemType.ORANGE: "orange",
}

## 全宝石共享一份 SpriteFrames（只切一次）
static var _shared_frames: SpriteFrames = null

## 当前宝石类型
var type: int = GemType.RED
## 网格坐标 (col, row)
var grid_pos: Vector2i = Vector2i.ZERO

@onready var _sprite: AnimatedSprite2D = $Sprite
@onready var _select_mask: ColorRect = $SelectMask
var _cell_size: int = 64


## 构建六色旋转动画（静态，全局一次）
static func _build_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	for gem_type in GEM_ROW.keys():
		var anim: String = ANIM_NAME[gem_type]
		var row: int = GEM_ROW[gem_type]
		frames.add_animation(anim)
		frames.set_animation_speed(anim, 12.0)
		frames.set_animation_loop(anim, true)
		for i in range(FRAMES_PER_ANIM):
			var atlas := AtlasTexture.new()
			atlas.atlas = SHEET
			atlas.region = Rect2(i * FRAME_SIZE, row * FRAME_SIZE, FRAME_SIZE, FRAME_SIZE)
			frames.add_frame(anim, atlas)
	return frames


static func get_shared_frames() -> SpriteFrames:
	if _shared_frames == null:
		_shared_frames = _build_frames()
	return _shared_frames


## 初始化：尺寸、贴图动画、类型
func setup(gem_type: int, pos: Vector2i, cell_size: int, _colors: Dictionary) -> void:
	type = gem_type
	grid_pos = pos
	_cell_size = cell_size
	var cell := Vector2(_cell_size, _cell_size)
	if _select_mask != null:
		_select_mask.size = cell
	if _sprite != null:
		_sprite.sprite_frames = get_shared_frames()
		_sprite.centered = false
		# 52px 贴图缩放到格子大小
		var s: float = float(_cell_size) / float(FRAME_SIZE)
		_sprite.scale = Vector2(s, s)
	set_type(gem_type, _colors)


## 更换类型并播放对应旋转动画
func set_type(gem_type: int, _colors: Dictionary) -> void:
	type = gem_type
	if _sprite == null:
		return
	if _sprite.sprite_frames == null:
		_sprite.sprite_frames = get_shared_frames()
	var anim: String = ANIM_NAME[gem_type]
	_sprite.play(anim)


## 选中反馈：半透明白色遮罩
func set_selected(on: bool) -> void:
	if _select_mask != null:
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
