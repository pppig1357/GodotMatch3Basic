extends RefCounted
## 消除 → 下落 → 连锁管道。
## 教学点：board.gd 过长时拆文件——本脚本专管「结算棋盘」逻辑。

## 每下落一格的时长（秒），形成近似恒定速度
const FALL_PER_CELL := 0.08

## 持有 Board 引用（由 Board._ready 传入）
var board


func _init(board_ref) -> void:
	board = board_ref


## 连锁结算：反复消除+下落，直到无匹配
func resolve_board() -> void:
	var chain := 1
	while true:
		var matches: Array = board.find_matches()
		if matches.is_empty():
			break
		await clear_matches(matches, chain)
		await fall_and_refill()
		chain += 1


## 消除并计分：基础分 × 连锁倍率 chain
func clear_matches(matches: Array, chain: int) -> void:
	board.match_cleared.emit()
	var groups: Array = board.find_match_groups()
	var base: int = _calc_score(groups)
	var gained: int = base * chain
	board.score += gained
	board.score_changed.emit(board.score)

	# 先从 grid 移除
	for gem in matches:
		if gem == null:
			continue
		var g: Gem = gem as Gem
		var pos: Vector2i = g.grid_pos
		board.grid[pos.x][pos.y] = null

	# 并行消除动画：只 await 第一颗（时长相同）
	var first: Gem = null
	for gem in matches:
		if gem == null:
			continue
		var g2: Gem = gem as Gem
		if first == null:
			first = g2
		else:
			g2.animate_clear()
	if first != null:
		await first.animate_clear()

	for gem in matches:
		if gem != null and is_instance_valid(gem):
			(gem as Gem).queue_free()


## 每组：3 个 = 30 分，每多 1 个 +10
func _calc_score(groups: Array) -> int:
	var total := 0
	for group in groups:
		var n: int = group.size()
		if n >= 3:
			total += 30 + (n - 3) * 10
	return total


## 逐列自下而上压实空位，顶部生成新宝石并并行下落动画
func fall_and_refill() -> void:
	var grid_size: int = board.GRID_SIZE
	# 每项：{ "gem": Gem, "target": Vector2, "duration": float }
	var movers: Array = []

	for col in range(grid_size):
		var write_row: int = grid_size - 1
		# 1) 现有宝石下沉
		for row in range(grid_size - 1, -1, -1):
			var gem: Gem = board.grid[col][row] as Gem
			if gem == null:
				continue
			if write_row != row:
				board.grid[col][row] = null
				board.grid[col][write_row] = gem
				var from_row: int = gem.grid_pos.y
				gem.grid_pos = Vector2i(col, write_row)
				var cells: int = write_row - from_row
				var duration: float = maxf(FALL_PER_CELL, float(cells) * FALL_PER_CELL)
				movers.append({
					"gem": gem,
					"target": board.grid_to_world(Vector2i(col, write_row)),
					"duration": duration,
				})
			write_row -= 1

		# 2) 顶部空位生成新宝石（从网格上方落入）
		var spawn_index := 0
		while write_row >= 0:
			var target_pos := Vector2i(col, write_row)
			# 起始在网格上方：-1, -2, ... 依次更高
			var start_pos := Vector2i(col, -1 - spawn_index)
			var gem2: Gem = board._spawn_gem(board.random_gem_type(), target_pos)
			gem2.position = board.grid_to_world(start_pos)
			board.grid[col][write_row] = gem2
			var cells2: int = write_row - start_pos.y
			var duration2: float = maxf(FALL_PER_CELL, float(cells2) * FALL_PER_CELL)
			movers.append({
				"gem": gem2,
				"target": board.grid_to_world(target_pos),
				"duration": duration2,
			})
			spawn_index += 1
			write_row -= 1

	if movers.is_empty():
		return

	# 同一阶段：Board 上一个并行 Tween，await 一次
	var tween: Tween = board.create_tween()
	tween.set_parallel(true)
	for item in movers:
		var g3: Gem = item["gem"] as Gem
		var target: Vector2 = item["target"] as Vector2
		var dur: float = item["duration"] as float
		tween.tween_property(g3, "position", target, dur)
	await tween.finished
