# L1 · board.gd 拆页文案（从零复刻版 · 洋葱式拆解 v2）

> **用途**：L1 课件 Part 4（board.gd）的 PPT 页面序列
> **方法论（2026-08-18 定稿）**：**伪代码前置 + 洋葱式拆解**——嵌套调用（A 里调 B）先讲最小函数 B 再讲 A；每个嵌套链最前面给一份伪代码；每页都是已验证的完整小块，最后 `_ready` 总装即跑通
> **配套**：`课件代码块/L1-从零复刻-建项目与棋盘生成.md`（v1.1）Step 5 块 B1~B5
> **衔接**：前接 gem.gd 拆页（A~G）→ 挂图页 → main.tscn 搭建（PPT 28 页）；29 页起是 board.gd 代码内容
> **临时代码约定**：简化版 `find_matches`（块 B4）**整段贴、一句话带过**，不逐行讲——L2 精讲 30min 升级分组版

**洋葱结构总览（14 页）：**

| 层 | 页 | 代码量 | 内容 | 角色 |
|---|---|---|---|---|
| 层0 | T0 | — | **伪代码地图**（生成链 + 防三消链全景） | 全局地图 |
| 层1 | T1 | 2 行 | `const` 常量（8×8、64px） | 原料 |
| 层1 | T2 | 1 行 | `preload` 宝石图纸 | 原料 |
| 层1 | T3 | 2 行 | `grid` / `origin`（先列后行） | 原料 |
| 层2 | T4 | 2 行 | `random_gem_type`（掷骰子） | 最小零件 |
| 层2 | T5 | 2 行 | `grid_to_world`（格子→像素） | 最小零件 |
| 层3 | T6 | 6 行 | `_spawn_gem` ⭐（套 T5 + gem.setup） | 组装① |
| 层4 | T7 | 10 行 | `fill_grid` ⭐（套 T6 + T4） | 组装② |
| 层5 | T8 | 40 行 | `find_matches`（临时件，一笔带过） | 临时 |
| 层6 | T9 | 10 行 | `ensure_no_initial_matches`（套 T8 + set_type） | 组装③ |
| 层7 | T10 | 3 行 | `reset_game`（套 T7 + T9） | 组装④ |
| 层8 | T11 | 6 行 | `_compute_origin`（居中） | 收口① |
| 层8 | T12 | 2 行 | `_ready`（总装：T11 + T10） | 收口② |
| 层9 | T13 | — | F5 验证 + GRID_SIZE 8→10 实操 | 成功画面 |

---

## 层 0 · T0 · 伪代码地图（本课代码全景）

**标题：** 先看地图：本课代码要干两件事

**页面内容（伪代码，不贴真实代码）：**

```
【伪代码 · 本课代码全景】

一、生成棋盘（64 颗宝石）
   开场 _ready：
     ① 算好棋盘居中位置
     ② 铺满棋盘：
        清空旧的
        对每一列 col（0~7）：
          对每一行 row（0~7）：
            随机颜色 → 造一颗宝石 → 放到该格 → 登记

二、排除初始三消（体验保护）
   循环（最多 100 次）：
     查出所有「连续 ≥3 个同色」的宝石
     没有 → 完成！开局成立
     有 → 把那些宝石换成随机颜色 → 再查一遍
```

**讲师讲什么：**
- 本课所有代码就这两件事：**铺出 8×8 棋盘 + 保证开局没有三连**
- 记住这张地图——接下来每一页都是地图上的一小块；最后 `_ready` 把两块拼起来，F5 就跑通
- 现在开始，从最小的零件造起，一层层往上套

**验证点：** 无，开始造零件。

---

## 层 1 · T1 · 原料：const 常量

**标题：** 常量：棋盘多大，格子多大

**代码块（复制粘贴处）：**

```gdscript
const GRID_SIZE := 8
const CELL_SIZE := 64
```

**讲师讲什么：**
- `const` = **常量**：定下来就不能改的数值（区别于 var 变量）
- `GRID_SIZE := 8`：8 列 × 8 行；`CELL_SIZE := 64`：每格边长 64px → 棋盘总尺寸 8×64 = **512×512**
- 为什么用常量不直接写数字？——棋盘尺寸到处要用（生成、居中、换算），写死数字改一处漏一处；常量**改一处全变**

**备注框（埋钩子）：** ⚠️ 记住 `GRID_SIZE`——本课最后会让你把它改成 `10`，按 F5 棋盘直接变大（人生第一次改代码，T13 见）。

**验证点：** 无，继续。

---

## 层 1 · T2 · 原料：preload 宝石图纸

**标题：** preload：提前把「图纸」拿在手里

**代码块（复制粘贴处）：**

```gdscript
const GEM_SCENE := preload("res://scenes/gem.tscn")
```

**讲师讲什么：**
- `preload("...")` = 启动时**提前加载**指定的场景文件，存进 `GEM_SCENE`
- `gem.tscn` 是「图纸」，`GEM_SCENE` 是拿在手里的图纸副本——之后用它 `instantiate()` 照图纸造宝石（T6）
- 还记得 gem 单元的月饼模具吗？**图纸（gem.tscn）→ 模具（GEM_SCENE）→ 月饼（实例）**

**验证点：** 无，继续。

---

## 层 1 · T3 · 原料：grid 和 origin

**标题：** 数据放哪：grid 数组 + origin 原点

**代码块（复制粘贴处）：**

```gdscript
var grid: Array = []
var origin: Vector2 = Vector2.ZERO
```

**讲师讲什么：**
- `grid`：二维数组 `grid[col][row]`，记录**每格放了哪颗宝石**（元素是 Gem 或 null 空位）
- ⚠️ **先列后行**——第一维是列、第二维是行，和「先横后竖」的直觉相反，这是本课最容易混的地方（T7 的双层循环就是按这个顺序写的）
- `origin`：棋盘左上角的世界坐标（Vector2 位置），居中时用它当起点（T11）
- 现在都是空的——`_ready` 会负责填上

**备注框：** 为什么 `grid` 不直接用「行 × 列」？——因为生成宝石时外层循环走列（T7），数据结构和代码顺序保持一致，就不容易错位。

**验证点：** 无，继续。

---

## 层 2 · T4 · 零件：random_gem_type

**标题：** 随机颜色：randi() % 6

**代码块（复制粘贴处）：**

```gdscript
func random_gem_type() -> int:
	return randi() % 6
```

**讲师讲什么：**
- `randi()` = 随机整数；`% 6` = 除以 6 取余数 → 结果永远落在 **0~5**，正好对应 GemType 六色编号（gem.gd 第 20 页）
- 一颗宝石的颜色 = 掷一次骰子（0~5）——64 颗宝石就是掷 64 次
- 这是全棋盘**最底层的零件**：所有宝石的颜色都来自它

**备注框（作业预告）：** 把 `% 6` 改成 `% 5` → 骰子变成 0~4，棋盘少一种颜色（五色棋盘）——改一个数字，整个画面变化，这就是「代码 = 规则」。

**验证点：** 无，继续。

---

## 层 2 · T5 · 零件：grid_to_world

**标题：** grid_to_world：格子在屏幕的哪里？

**代码块（复制粘贴处）：**

```gdscript
func grid_to_world(pos: Vector2i) -> Vector2:
	return origin + Vector2(pos.x, pos.y) * CELL_SIZE
```

**讲师讲什么：**
- 为什么需要换算：格子是**逻辑坐标 (col, row)**，屏幕要**像素坐标**——两套坐标系（gem.gd 第 21 页埋过这个伏笔）
- 伪代码：**像素位置 = 棋盘左上角 + 格子坐标 × 格子大小**
- 验证：`grid_to_world(Vector2i(0, 0))` = origin = 左上角第一格；`(7, 7)` = 右下角
- 下一课学反向的 `world_to_grid`（屏幕点 → 格子，做点击选中用）

**备注框：** 这颗「零件」要配合 T11 的 `origin` 用——`origin` 现在还是零，等居中算好（T11）才有意义。零件先造好，组装时自然接上。

**验证点：** 无，继续。

---

## 层 3 · T6 · 组装①：_spawn_gem ⭐

**标题：** _spawn_gem()：图纸 → 产品（本课最重要概念）

**伪代码先行：**

```
【伪代码】造一颗宝石：
  ① 照图纸复制一个实例
  ② 摆到 (col,row) 格的像素位置（用 T5）
  ③ 挂到棋盘节点下（进树）
  ④ 登记：颜色 + 坐标（gem.setup，gem.gd 第 24 页）
  ⑤ 交出去
```

**代码块（复制粘贴处）：**

```gdscript
func _spawn_gem(gem_type: int, pos: Vector2i) -> Gem:
	var gem: Gem = GEM_SCENE.instantiate() as Gem   # ① 照图纸复制实例
	gem.position = grid_to_world(pos)               # ② 摆到正确格子（T5）
	add_child(gem)                                  # ③ 挂到棋盘节点下
	gem.setup(gem_type, pos)                        # ④ 登记：颜色 + 坐标（gem.gd 第 24 页）
	return gem                                      # ⑤ 交出去
```

**讲师讲什么：**
- **场景实例化（本课最重要概念）**：`GEM_SCENE.instantiate()` = 照图纸（gem.tscn）复制出一个真实宝石节点；月饼模具 → 月饼。64 颗宝石 = 调了 64 次 `_spawn_gem`
- **三步顺序不能反**：摆位置 → 进树（add_child）→ setup——因为 gem.gd 的 `@onready` 变量**必须先进场景树才能取到子节点**（gem.gd 第 22 页）
- `as Gem`：把复制出来的节点转成 Gem 类型——这就是 gem.gd 写 `class_name Gem` 的原因（gem.gd 第 19 页）
- 注意这页已经**套了两层**：用了 T5（grid_to_world）+ gem.gd 的 setup——零件凑齐，开始组装

**备注框：** 为什么 setup 在 add_child 后面？——gem.gd 里 `@onready var _sprite = $Sprite` 要等节点进树才拿得到 Sprite。顺序反了，`_sprite` 还是 null，直接报错。

**验证点：** 无，继续。

---

## 层 4 · T7 · 组装②：fill_grid ⭐

**标题：** fill_grid()：64 颗宝石，双层循环一次铺完

**伪代码先行：**

```
【伪代码】铺满棋盘：
  ① 删掉旧宝石节点（清场）
  ② 清空数据表（清表）
  ③ 对每一列 col（0~7）：
       对每一行 row（0~7）：
         随机颜色（T4）→ 造一颗宝石（T6）→ 登记进 grid[col][row]
```

**代码块（复制粘贴处）：**

```gdscript
func fill_grid() -> void:
	for child in get_children():        # ① 删掉旧宝石节点
		child.queue_free()
	grid.clear()                        # ② 清空数据表
	for col in range(GRID_SIZE):        # ③ 外层：逐列（8 列）
		var column: Array = []
		for row in range(GRID_SIZE):    #    内层：该列逐行（8 行）
			var pos := Vector2i(col, row)
			column.append(_spawn_gem(random_gem_type(), pos))
		grid.append(column)             # ④ 整列装进 grid
```

**讲师讲什么：**
- 四步：**清场 → 清表 → 双层循环 → 装表**
- **双层 for = 8×8 = 64 次**：外层走列、内层走行，每次调 `_spawn_gem` 造一颗——「生成棋盘」的全部秘密
- 为什么先删旧节点 + 清空数据？——重复调用不叠两层（第 2 课「防死局重排」还会再调它）
- 为什么先攒一个 `column` 数组再塞进 grid？——呼应 T3：`grid[col][row]` **先列后行**，一列齐了整列塞进去
- 现在这页套了三层：T4（随机色）→ T6（造宝石）→ 本页（铺满）

**备注框：** 顺序是先删后建——「清场再开工」。忘了清场，重开会叠出两层宝石。

**验证点：** 无，继续。

---

## 层 5 · T8 · 临时件：find_matches（一笔带过 ⚠️）

**标题：** find_matches()：查出所有三连（临时版，照抄即可）

**代码块（整段复制粘贴，约 40 行）：**

```gdscript
func find_matches() -> Array:
	var matched: Array = []
	# 横向：逐行扫，找连续同色段
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
				for c in range(run_start, run_end):
					_add_unique(matched, grid[c][row] as Gem)
			run_start = run_end
	# 纵向：逐列扫，逻辑同上（col/row 互换）
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
				for r in range(run_start, run_end):
					_add_unique(matched, grid[col][r] as Gem)
			run_start = run_end
	return matched

## 去重：同一颗宝石不重复进数组（可能同时属于横/纵匹配）
func _add_unique(arr: Array, gem: Gem) -> void:
	if gem != null and not arr.has(gem):
		arr.append(gem)
```

**讲师讲什么（只讲一句话，不逐行）：**
- 作用一句话：**横着扫一遍、竖着扫一遍，把所有「连续 ≥3 个同色」的宝石收集起来**
- L1 只需要「能不能查出三连」（下一页防初始三消要用），所以给最小简化版——**照抄即可，不要求当场读懂**
- ⚠️ 第 2 课会精讲这个算法 30 分钟，并升级成正式「分组版」——到时候只多一个「分组」概念

**备注框：** 这段是**临时代码**：能干活、够用，但不是最终形态。别花时间背它，理解它存在的目的就够了。

**验证点：** 无，继续。

---

## 层 6 · T9 · 组装③：ensure_no_initial_matches

**标题：** 体验保护①：开局不能自带三连

**伪代码先行：**

```
【伪代码】排除初始三消：
  循环（最多 100 次）：
    查出所有三连（T8）
    没有 → 完成！
    有 → 每颗换成随机颜色（gem.set_type，gem.gd 第 23 页）→ 再查一遍
```

**代码块（复制粘贴处）：**

```gdscript
func ensure_no_initial_matches() -> void:
	var safety := 0
	while safety < 100:
		var matches := find_matches()      # 找出当前所有匹配（T8）
		if matches.is_empty():
			return                         # 没有匹配了，稳定
		for gem in matches:                # 有匹配 → 每颗换随机色
			(gem as Gem).set_type(random_gem_type())
		safety += 1
	push_warning("ensure_no_initial_matches: 超过安全次数仍有匹配")
```

**讲师讲什么：**
- 为什么必须排除（呼应设计拆解「体验保护」）：纯随机可能铺出「红红红」——现在还没消除逻辑看不出问题，但**第 2 课一加上交换消除，开局就会自动消一排**，学员会以为自己写坏了
- 解法：**查匹配 → 有就换随机色 → 再查**，循环到没有为止
- `while safety < 100`：**安全阀**——万一运气差一直消不干净，100 次后放弃并警告（防止死循环卡死游戏）
- `return` 直接退出函数：查完没匹配就收工
- 这页套了：T8（查三连）+ gem.gd 第 23 页（set_type 换色）+ T4（随机色）——三层零件

**备注框：** 还记得 gem.gd 第 23 页吗？换色 = 改一个编号，画面自动跟上。防三消就是靠它反复换色。

**验证点：** 无，继续。

---

## 层 7 · T10 · 组装④：reset_game

**标题：** reset_game()：开局，就两步

**伪代码先行：**

```
【伪代码】开局：
  ① 铺满棋盘（64 颗随机宝石）（T7）
  ② 排除初始三消（T9）
```

**代码块（复制粘贴处）：**

```gdscript
func reset_game() -> void:
	fill_grid()                    # 铺满 64 颗随机宝石（T7）
	ensure_no_initial_matches()    # 排除初始三消（T9）
```

**讲师讲什么：**
- 开局就两步：**铺满 + 排除三连**——两个「组装层」到这里汇合，生成链和防三消链接上了
- 函数名 `reset` 的由来：以后重开一局、重新开始，都是调它——「棋盘重置成初始状态」
- 三行代码，套了整条链：T7（→T6→T5/T4）+ T9（→T8/T4）

**备注框：** 现在代码已经凑齐「生成」和「防三消」两块拼图——只差 `_ready` 把电源插上（T12）。

**验证点：** 无，继续。

---

## 层 8 · T11 · 收口①：_compute_origin

**标题：** 居中：让 512 的棋盘站在 640×720 的窗口中央

**代码块（复制粘贴处）：**

```gdscript
func _compute_origin() -> void:
	var board_pixels := GRID_SIZE * CELL_SIZE   # 512
	var vp := get_viewport_rect().size          # 窗口尺寸 (640, 720)
	origin = Vector2(
		(vp.x - board_pixels) / 2.0,    # (640-512)/2 = 64
		(vp.y - board_pixels) / 2.0     # (720-512)/2 = 104
	)
```

**讲师讲什么：**
- 问题：窗口 640×720，棋盘 512×512，直接放会贴左上角——得**居中**
- 解法一句话：**（窗口尺寸 − 棋盘尺寸）÷ 2 = 左边距 / 上边距**
- `get_viewport_rect().size`：**动态取**当前窗口尺寸——窗口以后放大缩小，棋盘照样居中
- 结果：棋盘左上角在 (64, 104)，右下角在 (64+512, 104+512) = (576, 616)——上下左右留白均匀
- 这页给 T5 的 `origin` 填上了值——零件在 T5 造好，在这里接上电源

**备注框：** 带学生心算一遍：(640−512)÷2 = 64，(720−512)÷2 = 104——居中不是玄学，是减法除法。

**验证点：** 无，继续。

---

## 层 8 · T12 · 收口②：_ready（总装）

**标题：** _ready()：总装！把电源插上

**伪代码先行：**

```
【伪代码】开场：
  ① 算好棋盘居中位置（T11）
  ② 开局：铺棋盘 + 防三消（T10）
```

**代码块（复制粘贴处）：**

```gdscript
func _ready() -> void:
	_compute_origin()
	reset_game()
```

**讲师讲什么：**
- `_ready()`：节点进入场景树时**自动调用一次**——游戏的「开场白」
- 两行 = 总装：**算居中 → 开局**，前面 11 页的零件全部接上
- ⚠️ 注意：L1 一运行就直接生成棋盘（因为没有开始按钮）；成品是「点开始游戏才生成」——第 4 课讲完 HUD 会改回来

**备注框（洋葱收尾）：** 回顾 T0 地图——生成链（_ready → reset_game → fill_grid → _spawn_gem）和防三消链（reset_game → ensure_no_initial_matches → find_matches）已经全部拼完，代码写完！

**验证点：🎉 按 F5！** 第一次按下就是成功画面——8×8 彩色棋盘、居中、**没有任何一行/列出现连续 3 个同色**。本课代码全部完成！

---

## 层 9 · T13 · F5 验证 + 实操（收尾）

**标题：** 启动！以及人生第一次改代码

**验证清单（学员做到 = 本课过关）：**
- [ ] F5 运行，看到 8×8 彩色棋盘，居中显示
- [ ] 棋盘上没有任何一行/列出现连续 3 个同色（讲师可带大家扫一遍）
- [ ] 能说出「场景实例化」= 图纸（gem.tscn）造产品（64 颗宝石）

**实操：**

```gdscript
const GRID_SIZE := 8    # ← 改成 10，按 F5 看棋盘变大！
```

**讲师引导：**
- 改一个数字，整个游戏变了——「代码 = 规则」的第一次体验
- 64 颗变成多少颗？（10×10 = 100）——双层循环的乘法直觉
- 作业：`randi() % 6` 改成 `% 5` → 少一种颜色（五色棋盘）

---

## 衔接说明

- 本序列前接：gem.gd 拆页（PPT 19-24）→ 挂图页（25-26）→ main.tscn 搭建（28）
- 本序列后接：L2（交换/选中/正式 find_matches）
- 临时代码标记：T8（find_matches）是 L1 唯一「临时代码」，L2 升级为分组版；其余页面代码与成品 v3.2 逐字同构
- **洋葱式拆解要点**：每页都是「已验证的完整小块」；组装页（T6/T7/T9/T10/T12）配伪代码先行；嵌套调用先讲被调函数（T4/T5 在 T6 前，T8 在 T9 前，T7/T9 在 T10 前）

*v2：2026-08-18 凌晨 | 小龙虾 🦞 · board.gd 洋葱式拆解重排（伪代码前置 + 自底向上，对齐 gem.gd 拆页粒度）*
