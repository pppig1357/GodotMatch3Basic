# C# → GDScript 快速对照卡（讲师自用，勿对学员讲 C#）

> **用途**：pppig 是 C# 程序员（AllinCards/Unity），快速换挡到 GDScript 读代码/讲课
> **原则**：GDScript = "Python 的皮 + C# 的骨"——语法像 Python（缩进/冒号），类型和类概念像 C#
> **⚠️ 学员零基础，讲课时千万别提 C# 对照**——这份卡只给讲师自己复习用
> **对照基准**：教学版 4 个脚本（main.gd / board.gd / gem.gd / hud.gd）里实际出现的语法

---

## 一、核心差异速览（10 条就够上路）

| # | 概念 | C#（你熟悉） | GDScript（项目里） |
|---|------|-------------|-------------------|
| 1 | 变量 | `int score = 0;` | `var score: int = 0`（类型可省；`:=` 自动推断：`var pos := Vector2i(3, 5)`） |
| 2 | 常量 | `const int GRID_SIZE = 8;` | `const GRID_SIZE := 8` |
| 3 | 函数 | `void ResetGame() { }` | `func reset_game() -> void:`（冒号+缩进，无大括号） |
| 4 | 私有 | `private void Calc()` | `func _calc():`（**下划线开头 = 约定"内部用"**，不是强制） |
| 5 | if | `if (a > 3) { }` | `if a > 3:`（无括号，无大括号） |
| 6 | for | `for (int i = 0; i < 8; i++)` | `for i in range(8):`（没有 C 风格 for） |
| 7 | while | `while (n < 100) { }` | `while n < 100:`（几乎一样） |
| 8 | 节点引用 | `GetNode<Sprite2D>("Sprite")` | `$Sprite`（路径简写）；`@onready var _sprite = $Sprite` |
| 9 | 事件/委托 | `event Action<int> ScoreChanged` | `signal score_changed(score: int)`（见下方专节） |
| 10 | async | `async Task` / `await` | 函数**不需要标记**，内部有 `await` 自动变协程 |

---

## 二、信号 = C# 事件（一对一）

| 操作 | C# | GDScript |
|------|-----|----------|
| 声明 | `public event Action<int> ScoreChanged;` | `signal score_changed(score: int)` |
| 触发 | `ScoreChanged?.Invoke(score);` | `score_changed.emit(score)` |
| 订阅 | `ScoreChanged += OnScoreChanged;` | `score_changed.connect(on_score_changed)` |
| 回调 | `void OnScoreChanged(int s)` | `func _on_score_changed(score: int)` |

**项目实例**（hud.gd ↔ main.gd）：
```gdscript
# hud.gd 声明 + 触发
signal start_game
func _on_start_button_pressed() -> void:
	start_game.emit()

# main.gd 订阅
hud.start_game.connect(new_game)
```
对应 C# 里：按钮 Click 事件 → 订阅 → 执行。概念一模一样。

---

## 三、Unity 生命周期 ↔ Godot 生命周期

| Unity (C#) | Godot (GDScript) | 项目里的用途 |
|------------|------------------|-------------|
| `Start()` | `_ready()` | main.gd：连接信号、播音乐 |
| `Update()` | `_process(delta)` | 本游戏没用（点击式，不需要每帧逻辑） |
| `Update()` 里查输入 | `_unhandled_input(event)` | main.gd：鼠标点击分发 |
| `OnDestroy()` | `_exit_tree()` | 本游戏没用 |

---

## 四、项目代码"翻译演练"（对照着看，10 分钟换挡）

### 1. C# 直觉 → GDScript 实例（board.gd）

```csharp
// 你习惯的 C#
public class Board : Node2D {
    public const int GridSize = 8;
    private Gem[,] grid;
    private int score;

    public void ResetGame() {
        score = 0;
        FillGrid();
        EnsureNoInitialMatches();
    }
}
```

```gdscript
# 项目里的 GDScript
extends Node2D
const GRID_SIZE := 8
var grid: Array = []      # 二维数组，grid[列][行]
var score: int = 0

func reset_game() -> void:
	score = 0
	fill_grid()
	ensure_no_initial_matches()
	# ...（完整版还有 ensure_has_moves() 和 score_changed.emit(score)，见 board.gd ③）
```

**差异点：**
- `public/private` 没了 → 下划线开头表示"内部"
- 类名不写 `class Board`，用 `class_name`（gem.gd 有：`class_name Gem`）
- 成员变量直接声明在文件里，不需要构造函数
- 函数/变量全蛇形命名（`reset_game` 不是 `ResetGame`）

### 2. foreach ↔ for-in（find_match_groups 里的）

```csharp
foreach (var gem in matches) { gem.SetType(rand); }
```
```gdscript
for gem in matches:
	(gem as Gem).set_type(random_gem_type())
```
GDScript 的 `for x in 数组:` = C# 的 `foreach`。项目里所有 `for i in range(n)` = C# 的 `for (int i = 0; i < n; i++)`。

### 3. 类型转换

```csharp
var gem = node as Gem;        // C#
```
```gdscript
var gem: Gem = node as Gem    # GDScript——as 一模一样
```
注意项目里常见 `(gem as Gem).set_type(...)`——临时转换后调用，等价 C# 的 `(gem as Gem).SetType(...)`。

### 4. 字典（fall_and_refill 里的 movers）

```csharp
var movers = new List<Dictionary<string, object>>();
movers.Add(new Dictionary<string, object> { ["gem"] = gem, ["target"] = pos });
var target = (Vector2)movers[0]["target"];
```
```gdscript
var movers: Array = []
movers.append({"gem": gem, "target": target, "duration": dur})
var target: Vector2 = item["target"] as Vector2
```
GDScript 字典字面量 `{"键": 值}`，取值 `dict["键"]`——比 C# 省一半代码。

### 5. 字符串拼接/格式化

```csharp
scoreLabel.text = $"分数: {score}";
```
```gdscript
score_label.text = "分数: %d" % score    # %d = 整数占位符，% 填值
```

### 6. await 协程（Tween 动画，C# 里你会用协程/DOTween）

```csharp
// C# 协程（Unity）
IEnumerator Swap() { yield return new WaitForSeconds(0.15f); }
```
```gdscript
# GDScript——直接 await 信号，不用 yield/枚举器
func _do_swap(a: Gem, b: Gem) -> void:
	state = State.SWAPPING
	var ok: bool = await board.try_swap(a, b)   # 等 Board 干完活
	# ...（完整版还有音效、弹回分支、RESOLVING 状态锁，见 main.gd ⑧）
	state = State.IDLE
```
`await xxx` = "等 xxx 完成再继续"。`await tween.finished` = 等动画播完。**await 只能在函数内部用，且调用方也要 await**（main 里 `await _on_pointer_down()`）。

---

## 五、GDScript 特有、C# 没有的（讲课重点，也是学员重点）

| 语法 | 说明 | 项目实例 |
|------|------|---------|
| `$NodePath` | 取子节点的简写 | `$Sprite`、`$Mask` |
| `@onready var` | 进场景后才赋值（防扑空） | gem.gd 取子节点 |
| `@export var` | 场景面板可填的变量 | gem.gd 的贴图数组 |
| `preload()` | 编译期加载资源 | `preload("res://scenes/gem.tscn")` |
| `enum` + 类型 | 枚举当类型用 | `GemType.RED` |
| `class_name` | 注册全局类型 | `class_name Gem` |
| `push_warning()` | 打警告日志 | board.gd 防死局超限 |
| `queue_free()` | 延迟安全删除 | 消除宝石 |
| `is_instance_valid()` | 节点是否还活着 | `_deselect` 里的防御检查 |

---

## 六、最容易踩的 5 个 GDScript 坑（你讲课时学员会踩，你也会）

1. **`abs()` 返回 Variant，警告当错误下编不过** → 用 `absi()`（整数版）。项目里 `is_adjacent` 就是这么写的
2. **`instantiate()` 后必须 `as Gem`** → 不然类型不认
3. **先 `add_child` 再 `setup`** → `@onready` 依赖进树
4. **Tween 必须 `await` 串行** → 并发会宝石乱飞
5. **数组越界**：`grid[col][row]` 只有 0~7

---

## 七、教学提醒（很重要）

- **讲课时全程只讲 GDScript**，绝不提"这相当于 C# 的 X"——学员零基础，提 C# 只会增加认知负担
- 本对照卡的价值：你读代码/备课快；但**出口必须翻译成"人话"**（用 L1-逐行讲稿.md 的风格）
- 你想用 C# 写 Godot 完全可以（Godot 官方支持），但社课选 GDScript 是因为：语法轻、教学直观、和官方教程一致

---

*v1：2026-08-13 | 小龙虾 🦞 · 给 C# 背景讲师 10 分钟换挡用*
