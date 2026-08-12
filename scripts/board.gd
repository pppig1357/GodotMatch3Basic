extends Node2D
## 8×8 棋盘：生成、匹配检测、交换判定。
## 消除/下落/连锁见 board_resolve.gd（教学点：过长就拆文件）。

signal score_changed(score: int)
signal moves_changed(moves: int)
## 每次消除开始时发出（供音效监听）
signal match_cleared

const GRID_SIZE := 8
const CELL_SIZE := 64
const MOVES_DEFAULT := 20

## 宝石场景（教学点：场景实例化 = Godot 核心工作流）
const GEM_SCENE := preload("res://scenes/gem.tscn")
## 消除→下落→连锁辅助类
const ResolveHelper = preload("res://scripts/board_resolve.gd")

## GemType → Color 映射（备用/占位；贴图模式下仍传入 setup）
const GEM_COLORS := {
	Gem.GemType.RED: Color(0.90, 0.22, 0.21),
	Gem.GemType.BLUE: Color(0.20, 0.60, 0.86),
	Gem.GemType.GREEN: Color(0.18, 0.80, 0.44),
	Gem.GemType.YELLOW: Color(0.95, 0.77, 0.06),
	Gem.GemType.PURPLE: Color(0.61, 0.35, 0.71),
	Gem.GemType.ORANGE: Color(0.90, 0.49, 0.13),
}

## 二维数组 grid[col][row]，元素为 Gem 或 null
var grid: Array = []
## 网格左上角世界坐标（用于居中）
var origin: Vector2 = Vector2.ZERO
## 当前分数
var score: int = 0
## 剩余步数（仅限步模式且成功交换时减 1）
var moves_left: int = MOVES_DEFAULT
## 是否开启限步模式（默认关闭 = 无限步）
var moves_limited: bool = false
## 连锁结算辅助对象（非节点，不进场景树）
var _resolve


func _ready() -> void:
	_resolve = ResolveHelper.new(self)
	_compute_origin()
	# 标题阶段不生成宝石，等「开始游戏」再 fill_grid


## 清空棋盘（回标题时调用）
func clear_board() -> void:
	for child in get_children():
		child.queue_free()
	grid.clear()


## 重开/开始：重建棋盘并重置分数与步数
func reset_game(limited: bool) -> void:
	moves_limited = limited
	moves_left = MOVES_DEFAULT
	score = 0
	fill_grid()
	ensure_no_initial_matches()
	ensure_has_moves()
	score_changed.emit(score)
	moves_changed.emit(moves_left)


## 让 512×512 棋盘在视口中居中
func _compute_origin() -> void:
	var board_pixels := GRID_SIZE * CELL_SIZE
	var vp := get_viewport_rect().size
	origin = Vector2(
		(vp.x - board_pixels) / 2.0,
		(vp.y - board_pixels) / 2.0
	)


## 网格坐标 → 世界坐标（左上角像素）
func grid_to_world(pos: Vector2i) -> Vector2:
	return origin + Vector2(pos.x, pos.y) * CELL_SIZE


## 世界坐标 → 网格坐标；越界返回 (-1, -1)
func world_to_grid(world: Vector2) -> Vector2i:
	var local := world - origin
	var col := int(floor(local.x / CELL_SIZE))
	var row := int(floor(local.y / CELL_SIZE))
	if col < 0 or col >= GRID_SIZE or row < 0 or row >= GRID_SIZE:
		return Vector2i(-1, -1)
	return Vector2i(col, row)


## 取指定格的宝石；越界、空盘或空位返回 null
func get_gem_at(pos: Vector2i) -> Gem:
	if grid.is_empty():
		return null
	if pos.x < 0 or pos.x >= GRID_SIZE or pos.y < 0 or pos.y >= GRID_SIZE:
		return null
	return grid[pos.x][pos.y] as Gem


## 随机一种宝石类型（0~5）
func random_gem_type() -> int:
	return randi() % 6


## 清空旧宝石，重新铺满 8×8 随机网格
func fill_grid() -> void:
	for child in get_children():
		child.queue_free()
	grid.clear()
	for col in range(GRID_SIZE):
		var column: Array = []
		for row in range(GRID_SIZE):
			var pos := Vector2i(col, row)
			column.append(_spawn_gem(random_gem_type(), pos))
		grid.append(column)


## 创建宝石实例：必须先 add_child 再 setup（@onready 需进树）
func _spawn_gem(gem_type: int, pos: Vector2i) -> Gem:
	var gem: Gem = GEM_SCENE.instantiate() as Gem
	gem.position = grid_to_world(pos)
	add_child(gem)
	gem.setup(gem_type, pos, CELL_SIZE, GEM_COLORS)
	return gem


## 返回匹配组数组，每组是一段连续 ≥3 同色的 Gem 列表
func find_match_groups() -> Array:
	var groups: Array = []
	# —— 横向 ——
	for row in range(GRID_SIZE):
		var run_start := 0
		while run_start < GRID_SIZE:
			var gem0: Gem = grid[run_start][row] as Gem
			if gem0 == null:
				run_start += 1
				continue
			var run_type: int = gem0.type
			var run_end := run_start + 1
			while run_end < GRID_SIZE:
				var g: Gem = grid[run_end][row] as Gem
				if g == null or g.type != run_type:
					break
				run_end += 1
			if run_end - run_start >= 3:
				var group: Array = []
				for c in range(run_start, run_end):
					group.append(grid[c][row])
				groups.append(group)
			run_start = run_end
	# —— 纵向 ——
	for col in range(GRID_SIZE):
		var run_start := 0
		while run_start < GRID_SIZE:
			var gem0: Gem = grid[col][run_start] as Gem
			if gem0 == null:
				run_start += 1
				continue
			var run_type: int = gem0.type
			var run_end := run_start + 1
			while run_end < GRID_SIZE:
				var g: Gem = grid[col][run_end] as Gem
				if g == null or g.type != run_type:
					break
				run_end += 1
			if run_end - run_start >= 3:
				var group: Array = []
				for r in range(run_start, run_end):
					group.append(grid[col][r])
				groups.append(group)
			run_start = run_end
	return groups


## 扁平化匹配组并去重，返回 Gem 数组
func find_matches() -> Array:
	var matched: Array = []
	var groups := find_match_groups()
	for group in groups:
		for gem in group:
			_add_unique(matched, gem as Gem)
	return matched


## 若 gem 不在数组中则追加（朴素去重）
func _add_unique(arr: Array, gem: Gem) -> void:
	if gem == null:
		return
	if arr.has(gem):
		return
	arr.append(gem)


## 开局消除初始三消：有匹配就换色，直到棋盘稳定
func ensure_no_initial_matches() -> void:
	var safety := 0
	while safety < 100:
		var matches := find_matches()
		if matches.is_empty():
			return
		for gem in matches:
			(gem as Gem).set_type(random_gem_type(), GEM_COLORS)
		safety += 1
	push_warning("ensure_no_initial_matches: 超过安全次数仍有匹配")


## 是否存在至少一步可产生匹配的相邻交换。
## 教学点：这是 find_matches 的逆向应用——枚举所有可能交换并模拟验证；
## 与 ensure_no_initial_matches 是兄弟函数；将来提示系统（hint）也同族。
func has_moves() -> bool:
	for col in range(GRID_SIZE):
		for row in range(GRID_SIZE):
			var a: Gem = get_gem_at(Vector2i(col, row))
			if a == null:
				continue
			# 只查右、下邻居，避免同一对交换被枚举两次
			for d in [Vector2i(1, 0), Vector2i(0, 1)]:
				var b: Gem = get_gem_at(Vector2i(col, row) + d)
				if b == null:
					continue
				_swap_grid_data(a, b)
				var ok: bool = not find_matches().is_empty()
				_swap_grid_data(a, b)  # 模拟后必须换回
				if ok:
					return true
	return false


## 开局保证至少有一步可走；无解则重排（fill + 去初始三消），与 ensure_no_initial_matches 成对调用
func ensure_has_moves() -> void:
	var safety := 0
	while not has_moves():
		if safety >= 100:
			push_warning("ensure_has_moves: 超过安全次数仍无可行步")
			return
		fill_grid()
		ensure_no_initial_matches()
		safety += 1


## 上下左右相邻（曼哈顿距离为 1）
func _is_adjacent(a: Gem, b: Gem) -> bool:
	var dx := absi(a.grid_pos.x - b.grid_pos.x)
	var dy := absi(a.grid_pos.y - b.grid_pos.y)
	return dx + dy == 1


## 只交换 grid 引用与 grid_pos，不改屏幕 position（动画另做）
func _swap_grid_data(a: Gem, b: Gem) -> void:
	var pos_a := a.grid_pos
	var pos_b := b.grid_pos
	grid[pos_a.x][pos_a.y] = b
	grid[pos_b.x][pos_b.y] = a
	a.grid_pos = pos_b
	b.grid_pos = pos_a


## 两颗宝石并行滑到各自新格子位置
func _animate_swap_pair(a: Gem, b: Gem) -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(a, "position", grid_to_world(a.grid_pos), 0.15)
	tween.tween_property(b, "position", grid_to_world(b.grid_pos), 0.15)
	await tween.finished


## 尝试交换：有匹配返回 true；无匹配弹回返回 false。
## 仅限步模式才扣步。
func try_swap(a: Gem, b: Gem) -> bool:
	if a == null or b == null:
		return false
	if not _is_adjacent(a, b):
		return false

	_swap_grid_data(a, b)
	await _animate_swap_pair(a, b)

	var matches := find_matches()
	if matches.is_empty():
		_swap_grid_data(a, b)
		await _animate_swap_pair(a, b)
		return false

	if moves_limited:
		moves_left -= 1
		moves_changed.emit(moves_left)
	return true


## 委托给 board_resolve：消除→下落→连锁直到稳定
func resolve_board() -> void:
	await _resolve.resolve_board()
