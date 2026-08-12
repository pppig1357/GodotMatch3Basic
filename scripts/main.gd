extends Node2D
## 主场景（对齐官方教程）：HUD 信号开局、AudioStreamPlayer 播音乐/音效。

enum State { WAITING, IDLE, SELECTED, SWAPPING, RESOLVING, GAME_OVER }

const BoardScript = preload("res://scripts/board.gd")
const DRAG_SWAP_THRESHOLD := 28.0

@onready var board: BoardScript = $Board
@onready var hud: CanvasLayer = $HUD

var state: int = State.WAITING
var selected: Gem = null
var _dragging: bool = false
var _press_world: Vector2 = Vector2.ZERO
var _gem_home: Vector2 = Vector2.ZERO
var _drag_swapped: bool = false


func _ready() -> void:
	# 官方教程写法：HUD 发信号，Main 开局；Music 循环
	hud.start_game.connect(new_game)
	hud.back_to_title.connect(_on_back_to_title)
	board.score_changed.connect(hud.update_score)
	board.moves_changed.connect(_on_moves_changed)
	board.match_cleared.connect(_on_match_cleared)
	_setup_music_loop()
	hud.update_score(board.score)
	hud.update_moves(board.moves_limited, board.moves_left)
	$Music.play()


func _on_match_cleared() -> void:
	$SfxClear.play()


func _setup_music_loop() -> void:
	if $Music.stream is AudioStreamOggVorbis:
		($Music.stream as AudioStreamOggVorbis).loop = true


## 新一局（对应教程 new_game）
func new_game(limited: bool) -> void:
	_cancel_drag()
	_deselect()
	board.reset_game(limited)
	hud.prepare_playing()
	hud.update_score(board.score)
	hud.update_moves(board.moves_limited, board.moves_left)
	state = State.IDLE
	$SfxClick.play()
	if not $Music.playing:
		$Music.play()


func _on_back_to_title() -> void:
	_cancel_drag()
	_deselect()
	board.clear_board()
	state = State.WAITING
	$SfxClick.play()


func _on_moves_changed(moves: int) -> void:
	hud.update_moves(board.moves_limited, moves)


func _unhandled_input(event: InputEvent) -> void:
	if state == State.WAITING or state == State.SWAPPING \
			or state == State.RESOLVING or state == State.GAME_OVER:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			await _on_pointer_down()
		else:
			_on_pointer_up()
		return
	if event is InputEventMouseMotion and _dragging and selected != null:
		await _on_pointer_drag()


## 交互规则（v2.1 正式化）：
## - IDLE 点击宝石 → 选中 + 进入可拖拽态
## - SELECTED 点击已选中 → 取消选中回 IDLE
## - SELECTED 点击相邻 → 交换；点击非相邻 → 换选 + 可拖拽态
## - 选中后按下并移动 → 拖拽交换（28px 阈值）；原地松开 → 保持选中
## 教学点：拖拽 =「按下+位移」连续输入；点选交换 = 离散输入 —— 两种模式并存。
func _on_pointer_down() -> void:
	var world := get_global_mouse_position()
	var clicked: Gem = board.get_gem_at(board.world_to_grid(world))
	_drag_swapped = false
	_press_world = world
	if clicked == null:
		_cancel_drag()
		_deselect()
		state = State.IDLE
		return
	if state == State.SELECTED and selected != null:
		if clicked == selected:
			# 再次点击已选中宝石 → 取消选中（不进入拖拽）
			_cancel_drag()
			_deselect()
			state = State.IDLE
			$SfxClick.play()
			return
		if _is_adjacent(selected, clicked):
			await _do_swap(selected, clicked)
			return
		_deselect()
		_select(clicked)
		_start_drag_on_selected()
		$SfxSelect.play()
		return
	_select(clicked)
	state = State.SELECTED
	_start_drag_on_selected()
	$SfxSelect.play()


func _start_drag_on_selected() -> void:
	if selected == null:
		return
	_dragging = true
	_gem_home = board.grid_to_world(selected.grid_pos)
	_press_world = get_global_mouse_position()


func _on_pointer_drag() -> void:
	if selected == null or _drag_swapped:
		return
	var delta: Vector2 = get_global_mouse_position() - _press_world
	selected.position = _gem_home + _clamp_drag_offset(delta)
	var dir := _drag_direction(delta)
	if dir == Vector2i.ZERO:
		return
	var other: Gem = board.get_gem_at(selected.grid_pos + dir)
	if other == null:
		return
	_drag_swapped = true
	_dragging = false
	selected.position = _gem_home
	await _do_swap(selected, other)


func _on_pointer_up() -> void:
	if state == State.SWAPPING or state == State.RESOLVING:
		_dragging = false
		return
	if _drag_swapped:
		_dragging = false
		_drag_swapped = false
		return
	if not _dragging or selected == null:
		_dragging = false
		return
	selected.position = _gem_home
	_dragging = false
	state = State.SELECTED


func _clamp_drag_offset(delta: Vector2) -> Vector2:
	var cell: float = float(board.CELL_SIZE)
	if absf(delta.x) >= absf(delta.y):
		return Vector2(clampf(delta.x, -cell, cell), 0.0)
	return Vector2(0.0, clampf(delta.y, -cell, cell))


func _drag_direction(delta: Vector2) -> Vector2i:
	if absf(delta.x) < DRAG_SWAP_THRESHOLD and absf(delta.y) < DRAG_SWAP_THRESHOLD:
		return Vector2i.ZERO
	if absf(delta.x) >= absf(delta.y):
		return Vector2i(1 if delta.x > 0.0 else -1, 0)
	return Vector2i(0, 1 if delta.y > 0.0 else -1)


func _cancel_drag() -> void:
	if selected != null and is_instance_valid(selected):
		selected.position = board.grid_to_world(selected.grid_pos)
	_dragging = false
	_drag_swapped = false


func _is_adjacent(a: Gem, b: Gem) -> bool:
	return absi(a.grid_pos.x - b.grid_pos.x) + absi(a.grid_pos.y - b.grid_pos.y) == 1


func _select(gem: Gem) -> void:
	selected = gem
	if selected != null:
		selected.set_selected(true)


func _deselect() -> void:
	if selected != null and is_instance_valid(selected):
		selected.set_selected(false)
	selected = null


func _do_swap(a: Gem, b: Gem) -> void:
	state = State.SWAPPING
	_cancel_drag()
	_deselect()
	$SfxSwap.play()
	var ok: bool = await board.try_swap(a, b)
	if not ok:
		state = State.IDLE
		return
	state = State.RESOLVING
	await board.resolve_board()
	if board.moves_limited and board.moves_left <= 0:
		state = State.GAME_OVER
		$Music.stop()
		hud.show_game_over(board.score)
	else:
		state = State.IDLE
