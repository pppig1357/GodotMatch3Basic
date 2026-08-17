extends Node2D
## ============================================================
## board.gd —— 游戏「规则权威」（棋盘脚本）
## ============================================================
## 角色定位：棋盘的一切规则都由它说了算——生成、判定、交换、消除、下落。
## 教学黑盒法：main.gd 只调它的 5 个对外接口，不需要读懂全部实现：
##   reset_game()        开局：重建棋盘 + 重置分数
##   get_gem_at(pos)     取某格的宝石（没有返回 null）
##   try_swap(a, b)      尝试交换两颗（有匹配 true / 无匹配弹回 false）
##   resolve_board()     结算：反复消除→下落→连锁，直到棋盘稳定
##   world_to_grid(w)    屏幕坐标 → 网格坐标（配合 grid_to_world 互逆）
##
## 代码块划分（课件可拆块讲解）：
##   ① 信号 + 常量         —— 对外广播什么 / 棋盘规格
##   ② 变量 + _ready       —— 数据都在哪
##   ③ reset_game 开局     —— 对外接口①
##   ④ 坐标换算            —— grid_to_world / world_to_grid / get_gem_at
##   ⑤ 棋盘生成            —— random_gem_type / fill_grid / _spawn_gem
##   ⑥ 匹配判定            —— find_match_groups / find_matches（核心算法）
##   ⑦ 开局防死局          —— ensure_no_initial_matches / has_moves / ensure_has_moves
##   ⑧ 交换               —— is_adjacent / _swap_grid_data / _animate_swap_pair / try_swap
##   ⑨ 结算循环            —— resolve_board（连锁引擎）
##   ⑩ 消除计分            —— clear_matches / _calc_score
##   ⑪ 下落填充            —— fall_and_refill
## ============================================================

## 对外信号：分数变化时发出（HUD 监听它刷新显示）
signal score_changed(score: int)
## 对外信号：每次消除开始时发出（Main 监听它播消除音效）
signal match_cleared

## 棋盘规格：8 列 × 8 行
const GRID_SIZE := 8
## 每格边长（像素），棋盘总尺寸 = 8 × 64 = 512 像素
const CELL_SIZE := 64
## 每下落一格的时长（秒）：下落 3 格 = 0.24 秒，形成近似恒定速度
const FALL_PER_CELL := 0.08

## 宝石场景（教学点：场景实例化 = Godot 核心工作流）
## gem.tscn 是"图纸"，instantiate() 把它复制成一颗颗真实的宝石
const GEM_SCENE := preload("res://scenes/gem.tscn")

## 二维数组 grid[col][row]：第一维是列，第二维是行
## 元素是 Gem（有宝石）或 null（空位）
var grid: Array = []
## 棋盘左上角的世界坐标（用于把 512×512 棋盘在窗口中居中）
var origin: Vector2 = Vector2.ZERO
## 当前分数
var score: int = 0


func _ready() -> void:
	_compute_origin()
	# 注意：标题阶段不生成宝石，等玩家点「开始游戏」才 fill_grid（延后生成）

## ============================================================
## ③ 开局（对外接口①）
## ============================================================

## 重开/开始：重置分数 → 铺满棋盘 → 排除初始三消 → 保证有可行步
func reset_game() -> void:
	score = 0
	fill_grid()                    # 铺满 64 颗随机宝石
	ensure_no_initial_matches()    # 开局不能自带三消（否则一开场就消除，像 bug）
	ensure_has_moves()             # 开局必须至少一步能走（否则玩家第一手就卡死）
	score_changed.emit(score)      # 通知 HUD 分数归零

## ============================================================
## ④ 坐标换算（棋盘网格 ↔ 屏幕像素）
## ============================================================

## 让 512×512 棋盘在视口（窗口）中居中
func _compute_origin() -> void:
	var board_pixels := GRID_SIZE * CELL_SIZE
	var vp := get_viewport_rect().size
	origin = Vector2(
		(vp.x - board_pixels) / 2.0,
		(vp.y - board_pixels) / 2.0
	)

## 网格坐标 → 世界坐标：第 (col,row) 格的左上角像素位置
func grid_to_world(pos: Vector2i) -> Vector2:
	return origin + Vector2(pos.x, pos.y) * CELL_SIZE

## 世界坐标 → 网格坐标：像素位置落在第几格；点在棋盘外返回 (-1,-1)
func world_to_grid(world: Vector2) -> Vector2i:
	var local := world - origin              # 相对棋盘左上角的偏移
	var col := int(floor(local.x / CELL_SIZE))
	var row := int(floor(local.y / CELL_SIZE))
	if col < 0 or col >= GRID_SIZE or row < 0 or row >= GRID_SIZE:
		return Vector2i(-1, -1)              # 越界标记
	return Vector2i(col, row)

## 取指定格的宝石；越界、空盘或空位都返回 null
func get_gem_at(pos: Vector2i) -> Gem:
	if grid.is_empty():
		return null
	if pos.x < 0 or pos.x >= GRID_SIZE or pos.y < 0 or pos.y >= GRID_SIZE:
		return null
	return grid[pos.x][pos.y] as Gem

## ============================================================
## ⑤ 棋盘生成
## ============================================================

## 随机一种宝石类型：randi() 随机整数 % 6 → 0~5，正好对应 GemType 六色
func random_gem_type() -> int:
	return randi() % 6

## 清空旧棋盘，重新铺满 8×8 随机宝石（开局和防死局重排都会用到）
func fill_grid() -> void:
	for child in get_children():        # 删掉棋盘上所有旧宝石节点
		child.queue_free()
	grid.clear()                        # 清空数据表
	for col in range(GRID_SIZE):        # 外层循环：逐列
		var column: Array = []
		for row in range(GRID_SIZE):    # 内层循环：该列的逐行
			var pos := Vector2i(col, row)
			column.append(_spawn_gem(random_gem_type(), pos))
		grid.append(column)

## 创建一颗宝石实例：先 add_child 进场景树，再 setup
## （顺序不能反——gem.gd 里的 @onready 变量需要先进入场景树才能取到子节点）
func _spawn_gem(gem_type: int, pos: Vector2i) -> Gem:
	var gem: Gem = GEM_SCENE.instantiate() as Gem   # 按"图纸"复制实例
	gem.position = grid_to_world(pos)               # 摆到正确格子
	add_child(gem)                                  # 挂到棋盘节点下（必须先进树）
	gem.setup(gem_type, pos)                        # 设置颜色类型和网格坐标
	return gem

## ============================================================
## ⑥ 匹配判定（核心算法）
## ============================================================

## 找出所有匹配组：每组是一段连续 ≥3 个同色宝石的列表
## 算法思路（伪代码版）：
##   逐行扫描：找到一段连续同色 run，长度 ≥3 就收进结果
##   逐列扫描：同上
##   返回：所有组的数组（一组 = 一个宝石数组）
func find_match_groups() -> Array:
	var groups: Array = []
	# —— 横向（逐行扫）——
	for row in range(GRID_SIZE):
		var run_start := 0
		while run_start < GRID_SIZE:
			var gem0: Gem = grid[run_start][row] as Gem
			if gem0 == null:                # 空位跳过
				run_start += 1
				continue
			var run_type: int = gem0.type   # 这段连续段的颜色
			var run_end := run_start + 1
			while run_end < GRID_SIZE:      # 向右延伸，直到颜色不同或越界
				var g: Gem = grid[run_end][row] as Gem
				if g == null or g.type != run_type:
					break
				run_end += 1
			if run_end - run_start >= 3:    # 连续 ≥3 才算一组
				var group: Array = []
				for c in range(run_start, run_end):
					group.append(grid[c][row])
				groups.append(group)
			run_start = run_end             # 从这段之后继续找下一段
	# —— 纵向（逐列扫，逻辑同上，只是 col/row 互换）——
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

## 把匹配组"摊平"成一个宝石数组（一颗宝石可能同时属于横/纵两组，需去重）
func find_matches() -> Array:
	var matched: Array = []
	var groups := find_match_groups()
	for group in groups:
		for gem in group:
			_add_unique(matched, gem as Gem)
	return matched

## 朴素去重：gem 不在数组里才追加（避免同一颗被横纵两组重复计算）
func _add_unique(arr: Array, gem: Gem) -> void:
	if gem == null:
		return
	if arr.has(gem):
		return
	arr.append(gem)

## ============================================================
## ⑦ 开局防死局（避免学员以为游戏出 bug 的两个保险）
## ============================================================

## 保险①：开局消除初始三消——有匹配就把那颗换随机色，直到棋盘稳定
func ensure_no_initial_matches() -> void:
	var safety := 0
	while safety < 100:
		var matches := find_matches()
		if matches.is_empty():
			return                      # 没有匹配了，稳定
		for gem in matches:
			(gem as Gem).set_type(random_gem_type())  # 换色（set_type 会同步换贴图）
		safety += 1
	push_warning("ensure_no_initial_matches: 超过安全次数仍有匹配")

## 是否存在至少一步可产生匹配的相邻交换？
## 教学点：find_matches 的"逆向应用"——枚举所有相邻对，模拟交换后看有没有匹配
## 与 ensure_no_initial_matches 是兄弟函数；将来做「提示系统」也用它
func has_moves() -> bool:
	for col in range(GRID_SIZE):
		for row in range(GRID_SIZE):
			var a: Gem = get_gem_at(Vector2i(col, row))
			if a == null:
				continue
			# 只查右、下两个邻居，避免同一对交换被枚举两次（上/左已由别的格子查过）
			for d in [Vector2i(1, 0), Vector2i(0, 1)]:
				var b: Gem = get_gem_at(Vector2i(col, row) + d)
				if b == null:
					continue
				_swap_grid_data(a, b)                    # 模拟交换
				var ok: bool = not find_matches().is_empty()
				_swap_grid_data(a, b)                    # 模拟后必须换回（只查不改）
				if ok:
					return true
	return false

## 保险②：开局保证至少一步可走——无解就整盘重排，最多试 100 次
func ensure_has_moves() -> void:
	var safety := 0
	while not has_moves():
		if safety >= 100:
			push_warning("ensure_has_moves: 超过安全次数仍无可行步")
			return
		fill_grid()                  # 重铺
		ensure_no_initial_matches()  # 再排掉初始三消
		safety += 1

## ============================================================
## ⑧ 交换（对外接口③的核心）
## ============================================================

## 两颗宝石是否上下左右相邻？曼哈顿距离 == 1（横差+纵差为 1）
## 公开给 main.gd 调用：网格的"相邻"由 Board 说了算
func is_adjacent(a: Gem, b: Gem) -> bool:
	var dx := absi(a.grid_pos.x - b.grid_pos.x)
	var dy := absi(a.grid_pos.y - b.grid_pos.y)
	return dx + dy == 1

## 只交换"数据"（grid 数组里的引用 + 各自的 grid_pos），不动屏幕位置
## 屏幕动画由 _animate_swap_pair 单独负责——数据与表现分离
func _swap_grid_data(a: Gem, b: Gem) -> void:
	var pos_a := a.grid_pos
	var pos_b := b.grid_pos
	grid[pos_a.x][pos_a.y] = b
	grid[pos_b.x][pos_b.y] = a
	a.grid_pos = pos_b
	b.grid_pos = pos_a

## 两颗宝石并行滑到各自新位置（一颗 Tween 同时动画两行）
func _animate_swap_pair(a: Gem, b: Gem) -> void:
	var tween := create_tween()
	tween.set_parallel(true)                                       # 并行模式
	tween.tween_property(a, "position", grid_to_world(a.grid_pos), 0.15)
	tween.tween_property(b, "position", grid_to_world(b.grid_pos), 0.15)
	await tween.finished                                           # 等动画播完（模板 T3：动画必须 await 串行）

## 尝试交换（对外接口③）：合法且有匹配返回 true；无匹配自动弹回返回 false
func try_swap(a: Gem, b: Gem) -> bool:
	if a == null or b == null:
		return false
	if not is_adjacent(a, b):
		return false

	_swap_grid_data(a, b)              # ① 数据交换
	await _animate_swap_pair(a, b)     # ② 播放交换动画

	var matches := find_matches()      # ③ 检查交换后有没有匹配
	if matches.is_empty():
		_swap_grid_data(a, b)          # ④ 没有 → 换回去（弹回）
		await _animate_swap_pair(a, b)
		return false

	return true                        # ⑤ 有匹配 → 交换成立

## ============================================================
## ⑨ 结算循环（连锁引擎，对外接口④）
## ============================================================

## 连锁结算（模板 T2：while 循环）：
##   只要棋盘还有匹配：消除 → 下落填充 → 再检查（连锁可能引发新的匹配）
##   chain 记录第几次消除，用于连锁倍率计分（第 n 次消除 ×n）
func resolve_board() -> void:
	var chain := 1
	while true:
		var matches: Array = find_matches()
		if matches.is_empty():
			break                        # 没有匹配了，结算结束
		await clear_matches(matches, chain)   # 消除 + 计分
		await fall_and_refill()               # 下落 + 顶部补新
		chain += 1                            # 连锁次数 +1

## ============================================================
## ⑩ 消除与计分
## ============================================================

## 消除一组匹配并计分：基础分 × 连锁倍率
func clear_matches(matches: Array, chain: int) -> void:
	match_cleared.emit()                       # 发信号 → Main 播消除音效
	var groups: Array = find_match_groups()    # 重新取分组（计分按"组"算，3个=30分）
	var base: int = _calc_score(groups)
	var gained: int = base * chain             # 连锁倍率：第 2 次消除 ×2，第 3 次 ×3…
	score += gained
	score_changed.emit(score)                  # 发信号 → HUD 刷新分数

	# ① 先从数据表移除（grid 里清成 null）
	for gem in matches:
		if gem == null:
			continue
		var g: Gem = gem as Gem
		var pos: Vector2i = g.grid_pos
		grid[pos.x][pos.y] = null

	# ② 并行播放消除动画（缩小+淡出）——只 await 第一颗（所有动画时长相同）
	var first: Gem = null
	for gem in matches:
		if gem == null:
			continue
		var g2: Gem = gem as Gem
		if first == null:
			first = g2                # 第一颗：稍后 await
		else:
			g2.animate_clear()        # 其余：直接开播，不等待
	if first != null:
		await first.animate_clear()   # 等第一颗播完 = 所有都播完

	# ③ 动画结束后真正删除节点（queue_free 是安全的延迟删除）
	for gem in matches:
		if gem != null and is_instance_valid(gem):
			(gem as Gem).queue_free()

## 计分规则：每组 3 个 = 30 分，每多 1 个 +10（4 连 = 40，5 连 = 50…）
## 这是第 2 课实操题：学员要自己重写这个函数体
func _calc_score(groups: Array) -> int:
	var total := 0
	for group in groups:
		var n: int = group.size()
		if n >= 3:
			total += 30 + (n - 3) * 10
	return total

## ============================================================
## ⑪ 下落与填充
## ============================================================

## 逐列处理：①现有宝石下沉压实空位 ②顶部生成新宝石补缺
## 所有移动记录进 movers，最后用一个并行 Tween 一起播放下落动画
func fall_and_refill() -> void:
	# 每个 mover 记录：哪颗宝石、落到哪、花多久
	# 每项：{ "gem": Gem, "target": Vector2, "duration": float }
	var movers: Array = []

	for col in range(GRID_SIZE):
		var write_row: int = GRID_SIZE - 1    # 从最底行开始找"落点"
		# ① 现有宝石下沉：自下而上扫，把宝石压实到列底
		for row in range(GRID_SIZE - 1, -1, -1):
			var gem: Gem = grid[col][row] as Gem
			if gem == null:
				continue
			if write_row != row:              # 下面有空洞 → 需要下落
				grid[col][row] = null         # 原位置清空
				grid[col][write_row] = gem    # 数据移到新位置
				var from_row: int = gem.grid_pos.y
				gem.grid_pos = Vector2i(col, write_row)
				var cells: int = write_row - from_row
				var duration: float = maxf(FALL_PER_CELL, float(cells) * FALL_PER_CELL)  # 按格数算时长
				movers.append({
					"gem": gem,
					"target": grid_to_world(Vector2i(col, write_row)),
					"duration": duration,
				})
			write_row -= 1                    # 落点向上移一格

		# ② 顶部空位生成新宝石：从网格上方（行 -1, -2…）落入
		var spawn_index := 0
		while write_row >= 0:
			var target_pos := Vector2i(col, write_row)
			# 起始点在网格上方：-1, -2, ... 越靠上的空位，起点越高（视觉上排队落下来）
			var start_pos := Vector2i(col, -1 - spawn_index)
			var gem2: Gem = _spawn_gem(random_gem_type(), target_pos)
			gem2.position = grid_to_world(start_pos)   # 先放到屏幕外上方
			grid[col][write_row] = gem2
			var cells2: int = write_row - start_pos.y
			var duration2: float = maxf(FALL_PER_CELL, float(cells2) * FALL_PER_CELL)
			movers.append({
				"gem": gem2,
				"target": grid_to_world(target_pos),
				"duration": duration2,
			})
			spawn_index += 1
			write_row -= 1

	if movers.is_empty():
		return                                # 没有移动（理论上不会发生，防御性返回）

	# 同一阶段：Board 上一个并行 Tween，统一播放所有下落动画，await 一次
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	for item in movers:
		var g3: Gem = item["gem"] as Gem
		var target: Vector2 = item["target"] as Vector2
		var dur: float = item["duration"] as float
		tween.tween_property(g3, "position", target, dur)
	await tween.finished
