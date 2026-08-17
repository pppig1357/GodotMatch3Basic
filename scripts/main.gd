extends Node2D
## ============================================================
## main.gd —— 游戏「指挥中心」（主场景脚本）
## ============================================================
## 角色定位：Main 是主场景的大脑，负责三件事——
##   1. 接收 HUD 的按钮信号（开始游戏 / 重新开始）
##   2. 处理鼠标输入（点哪颗宝石、要不要交换）
##   3. 指挥 Board 干活（开局、交换、结算）——自己不碰棋盘数据
##
## 代码块划分（课件可拆块讲解）：
##   ① 状态枚举 State        —— 游戏当前处于什么阶段
##   ② 节点引用              —— 怎么拿到 Board / HUD
##   ③ _ready 信号连接       —— HUD 按钮 → 这里的函数
##   ④ new_game 新一局       —— 开局流程
##   ⑤ _unhandled_input 输入 —— 鼠标点击入口
##   ⑥ _on_pointer_down 点选 —— 交互核心规则
##   ⑦ 选中/取消辅助函数     —— _select / _deselect
##   ⑧ _do_swap 交换流程     —— 调 Board 完成一次交换
## ============================================================

## 游戏状态机：任何时刻游戏都处于其中一个状态（同一时间只有一个）
## IDLE      = 空闲，等待玩家点击（标题界面和对局中都可能处于它）
## SELECTED  = 已选中一颗宝石，等待下一步（交换/取消/换选）
## SWAPPING  = 交换动画播放中 → 锁输入，防止连点出 bug
## RESOLVING = 消除/下落动画播放中 → 锁输入
enum State { IDLE, SELECTED, SWAPPING, RESOLVING }

## 预加载 board.gd 脚本，用它给 board 变量标注类型（相当于一张"说明书"）
const BoardScript = preload("res://scripts/board.gd")

## @onready：等场景节点全部就绪后才赋值（比直接 var 更安全）
## $Board = 场景树里叫 Board 的节点（棋盘，规则权威）
## $HUD   = 场景树里叫 HUD 的节点（界面层）
@onready var board: BoardScript = $Board
@onready var hud: CanvasLayer = $HUD

## 当前状态：初始 IDLE（游戏刚打开 = 标题界面）
var state: int = State.IDLE
## 当前选中的宝石；null = 没有选中任何宝石
var selected: Gem = null


func _ready() -> void:
	## 信号连接（观察者模式）：HUD/Board 发信号 → 这里接住执行
	## HUD 不直接认识 Main 的函数，只负责"喊一声"，实现界面与逻辑解耦
	hud.start_game.connect(new_game)               # 点「开始游戏」→ 开新局
	hud.restart.connect(new_game)                  # 点「重新开始」→ 也是开新局（简化版不回标题）
	board.score_changed.connect(hud.update_score)  # Board 分数变化 → HUD 刷新显示
	board.match_cleared.connect(_on_match_cleared) # Board 开始消除 → 播放消除音效
	_setup_music_loop()                            # BGM 设为循环播放
	hud.update_score(board.score)                  # 初始显示分数 0
	$Music.play()                                  # 开始播 BGM


## 消除音效：Board 每次开始消除都会 emit match_cleared 信号
func _on_match_cleared() -> void:
	$SfxClear.play()


## BGM 循环：把音乐资源的 loop 属性设为 true（无缝循环）
func _setup_music_loop() -> void:
	if $Music.stream is AudioStreamOggVorbis:
		($Music.stream as AudioStreamOggVorbis).loop = true


## 新一局（对应官方教程 new_game 的写法）
func new_game() -> void:
	_deselect()                       # 清掉可能残留的选中态
	board.reset_game()                # 核心活交给 Board：重建棋盘 + 重置分数
	hud.prepare_playing()             # HUD 切换成对局界面（隐藏标题遮罩）
	hud.update_score(board.score)     # 分数归零显示
	state = State.IDLE                # 状态复位，开始接收点击
	$SfxClick.play()                  # 按钮点击音效
	if not $Music.playing:            # BGM 没在播就播
		$Music.play()


## 输入处理：所有没被 UI 控件消费的输入都会进这个函数
## event.is_action_pressed("click") = InputMap 里名为 click 的动作（鼠标左键）
## 用「动作名」判断而不是「具体按键」：以后想改成触摸/键盘，只需改配置，不用改代码
func _unhandled_input(event: InputEvent) -> void:
	# 动画播放中（SWAPPING/RESOLVING）直接忽略输入——状态锁，防止连点
	if state == State.SWAPPING or state == State.RESOLVING:
		return
	if event.is_action_pressed("click"):
		await _on_pointer_down()


## 点选交互（核心规则，课件"交互规则表"）：
## - IDLE 点击宝石      → 选中它（进入 SELECTED）
## - SELECTED 点自己    → 取消选中（回 IDLE）
## - SELECTED 点相邻    → 交换两颗（核心玩法）
## - SELECTED 点非相邻  → 换成选那颗
## - 点击空白           → 取消选中
func _on_pointer_down() -> void:
	var world := get_global_mouse_position()                     # 鼠标的屏幕坐标
	var clicked: Gem = board.get_gem_at(board.world_to_grid(world))  # 坐标换算→取那颗宝石
	if clicked == null:                                          # 点到空白（棋盘外）
		_deselect()
		state = State.IDLE
		return
	if state == State.SELECTED and selected != null:
		if clicked == selected:                                  # ① 点自己 → 取消选中
			_deselect()
			state = State.IDLE
			$SfxClick.play()
			return
		if board.is_adjacent(selected, clicked):                 # ② 点相邻 → 交换（相邻判断由 Board 负责）
			await _do_swap(selected, clicked)
			return
		_deselect()                                              # ③ 点非相邻 → 换成选它
		_select(clicked)
		$SfxSelect.play()
		return
	_select(clicked)                                             # 空闲状态点宝石 → 选中
	state = State.SELECTED
	$SfxSelect.play()


## 选中：记录引用 + 点亮遮罩（视觉反馈）
func _select(gem: Gem) -> void:
	selected = gem
	if selected != null:
		selected.set_selected(true)


## 取消选中：熄灭遮罩 + 清空记录
func _deselect() -> void:
	if selected != null and is_instance_valid(selected):
		selected.set_selected(false)
	selected = null


## 交换流程（只管流程，规则判定在 Board.try_swap）：
## 1. 状态切 SWAPPING（锁输入）
## 2. 让 Board 尝试交换（播放动画 + 判定是否有匹配）
## 3. 成功 → 切 RESOLVING，等 Board 结算完（消除/下落/连锁）→ 回 IDLE
## 4. 失败（交换后无匹配）→ 直接回 IDLE（Board 已自动弹回原位）
func _do_swap(a: Gem, b: Gem) -> void:
	state = State.SWAPPING
	_deselect()
	$SfxSwap.play()
	var ok: bool = await board.try_swap(a, b)
	if not ok:
		state = State.IDLE
		return
	state = State.RESOLVING
	await board.resolve_board()
	state = State.IDLE
