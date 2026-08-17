# L1 · 代码块 PPT 页面序列 —— gem 宝石单元（块1 + 块2）

> **用途**：gem.tscn + gem.gd 的 PPT 页面序列设计（实操①：拆解宝石）
> **性质**：简单单元示例——gem.gd 只有 58 行、没有外部调用链（它是"被调用"的棋子，不主动叫别人干活），所以页面比 fill_grid 轻，但结构一致
> **配套**：代码块文档 `L1-生成棋盘.md` 块1/块2 + 逐行讲稿 `L1-逐行讲稿.md` 块1/块2

---

## 页面 1/6 · 目标页

**标题：** 拆开一颗宝石，看它里面有什么

**页面内容：**
- 一句话：棋盘上有 64 颗宝石，但它们是同一个"图纸"造出来的——拆开一颗看看图纸长什么样
- 配图：一颗宝石放大图（带节点树示意图）
- 右下角：👇 5 页拆完

**代码地图标签：** 📍 `gem.tscn` + `gem.gd`（图纸 + 行为）

**讲师口播：**
「我们棋盘上的 64 颗宝石，全是 gem.tscn 这张图纸造出来的（还记得月饼模具吗？）。那这张图纸里面长什么样？拆开看看——它其实就三部分：一个身体、一张脸、一个面具。」

---

## 页面 2/6 · 结构图页（gem 的"伪代码"）

**标题：** 一颗宝石 = 身体 + 脸 + 面具 + 行为

**页面内容（结构图，PPT 画成分解图）：**

```
一颗宝石（Gem）
│
├─ 身体：Node2D        —— 一个"点"，负责位置（在哪格）
├─ 脸：Sprite2D        —— 显示图片（texture = 拖进去的 PNG）
│     └─ 6 张图按编号排队：0红 1蓝 2绿 3黄 4紫 5橙
├─ 面具：SelectMask    —— 半透明白色方块，平时藏起来（选中才亮，第2课用）
└─ 行为：gem.gd        —— 两个函数：
      setup(颜色, 位置)  出生时：记下颜色位置 + 换上对应贴图
      set_type(编号)    换色：换一张贴图（gem_textures[编号]）
```

**人话：** 宝石是个"纸片人"：Node2D 是定位点，Sprite2D 是它的脸（贴图），SelectMask 是面具（现在收着），gem.gd 是它的行为说明书。

**代码地图标签：** 📍 `gem.tscn` → 节点树

**讲师口播：**
「记住这个结构：**身体（位置）+ 脸（贴图）+ 面具（选中高亮）+ 行为（脚本）**。下面看真实文件——gem.tscn 就是身体脸面具，gem.gd 就是行为。」

---

## 页面 3/6 · gem.tscn 全貌

**标题：** gem.tscn —— 图纸的"长相"

**页面内容（场景文件代码）：**

```tscn
[node name="Gem" type="Node2D"]
script = ExtResource("1_gem")
gem_textures = Array[Texture2D]([ExtResource("2_red"), ExtResource("3_blue"), ...])

[node name="Sprite" type="Sprite2D" parent="."]
scale = Vector2(1.2308, 1.2308)
texture = ExtResource("2_red")
centered = false

[node name="SelectMask" type="ColorRect" parent="."]
visible = false
offset_right = 64.0
offset_bottom = 64.0
color = Color(1, 1, 1, 0.45)
```

**人话（对应结构图）：**
- `Gem (Node2D)` = 身体（结构图第 1 行）
- `Sprite (Sprite2D)` = 脸，`texture` 槽里挂着一张 PNG（**贴图是拖进去的资源，不是代码画的**）；52px 图放大 1.23 倍 = 64px 格子
- `SelectMask (ColorRect)` = 面具，`visible=false` 藏起来了
- `gem_textures` = 6 张图按顺序排队（0红 1蓝 2绿 3黄 4紫 5橙）

**代码地图标签：** 📍 `gem.tscn` → 节点树

**讲师口播：**
「这就是图纸的长相：一个 Node2D 身体，底下挂着 Sprite（脸）和 SelectMask（面具）。注意 Sprite 的 texture——**图片是直接拖进去的**，不是代码画出来的。还有 `scale` 这个数字 1.2308，是把 52 像素的图放大到 64 像素，已经算好写死了。」

---

## 页面 4/6 · gem.gd 全貌

**标题：** gem.gd —— 图纸的"行为"

**页面内容（相关代码，一页放完）：**

```gdscript
class_name Gem

## 六种宝石颜色（枚举 = 给数字起名字：RED=0, BLUE=1, ..., ORANGE=5）
enum GemType { RED, BLUE, GREEN, YELLOW, PURPLE, ORANGE }

## 六色贴图数组（gem.tscn 里按顺序挂好）
@export var gem_textures: Array[Texture2D] = []

## 当前宝石类型（默认红色）
var type: int = GemType.RED
## 网格坐标 (col, row)
var grid_pos: Vector2i = Vector2i.ZERO

@onready var _sprite: Sprite2D = $Sprite
@onready var _select_mask: ColorRect = $SelectMask

## 出生：设置类型 + 坐标，换贴图
func setup(gem_type: int, pos: Vector2i) -> void:
	type = gem_type
	grid_pos = pos
	set_type(gem_type)

## 换色 = 换贴图：gem_textures[编号]
func set_type(gem_type: int) -> void:
	type = gem_type
	_sprite.texture = gem_textures[gem_type]
```

**代码地图标签：** 📍 `gem.gd` → ①② 类型与贴图 + 初始化

---

## 页面 5/6 · 分段精讲 —— 两个关键对应关系

**标题：** 颜色编号 ↔ 贴图 ↔ 代码（全课最重要的"对应关系"）

**页面内容①（enum = 给数字起名字）：**

```gdscript
enum GemType { RED, BLUE, GREEN, YELLOW, PURPLE, ORANGE }
```

**人话：** 代码里宝石颜色就是 0~5 的数字，但写 `GemType.RED` 比写 `0` 好懂一万倍。**RED=0，BLUE=1，GREEN=2，YELLOW=3，PURPLE=4，ORANGE=5**——这个顺序和 gem.tscn 里贴图排队顺序必须一致！

**页面内容②（换色 = 换贴图，一行）：**

```gdscript
_sprite.texture = gem_textures[gem_type]
```

**人话：** `set_type(3)` = 从贴图数组里取第 3 张（黄色图）贴到脸上 = 宝石变黄。**颜色和贴图的对应关系就是靠这个编号串起来的。**

**板书：** 画对应表：`0→红图 1→蓝图 2→绿图 3→黄图 4→紫图 5→橙图`

**代码地图标签：** 📍 `gem.gd` → ① 类型与贴图

**讲师口播：**
「记住这个**对应关系**：enum 编号 ↔ 贴图数组下标 ↔ 宝石颜色。三者的顺序都是红蓝绿黄紫橙，任何一边乱了这个游戏就穿帮了。这就是为什么之前强调 gem.tscn 里挂图顺序不能乱。」

---

## 页面 6/6 · 互动 + 伏笔

**标题：** 考考你 + 一个伏笔

**页面内容：**
1. **互动**：gem_textures 数组里第 4 张是什么颜色的图？（紫色）`set_type(2)` 会把宝石变成什么色？（绿色）
2. **伏笔**：还记得 SelectMask 那个藏起来的面具吗？它什么时候会亮起来？——**第 2 课：你点中宝石的时候**。先记住它存在。
3. **预告**：下一块代码：棋盘怎么把这 64 颗宝石摆出来（fill_grid，已讲）→ 其实我们刚从那里过来 😄

**代码地图标签：** 📍 `gem.gd` → ① 类型与贴图

**讲师口播：**
「两个小问题考考大家：数组第 4 张图是什么颜色？对，紫色。`set_type(2)` 变什么色？绿色——就是换第 2 张图。最后留个伏笔：那个白面具 SelectMask，**第 2 课你点宝石的时候它就会亮起来**——到时候你们就知道它是干嘛的了。」

---

## 页面序列动画说明

| 页面 | 动画建议 |
|------|---------|
| ① 目标页 | 宝石放大图 + 节点树浮现 |
| ② 结构图页 | 四部分依次出现（身体/脸/面具/行为） |
| ③ gem.tscn | 无动画（供阅读） |
| ④ gem.gd | 无动画（供阅读） |
| ⑤ 精讲 | 对应表动画：编号↔颜色↔贴图 连线 |
| ⑥ 互动 | 问题先出，答案点击后出现 |

---

## 轻量版要点（gem 单元示范的）

- **没有调用链的代码块**：伪代码 = 结构图（数据 + 函数一览），不用画调用树
- **简单单元 6 页封顶**：目标 → 结构图 → 全貌（场景+脚本）→ 精讲 → 互动收尾
- **钩子设计**：SelectMask 伏笔 → L2 选中反馈（前后呼应，学员记得住）
- **对应关系板书**：enum 编号 ↔ 贴图下标 ↔ 颜色——三边一致，全课最重要的一一对应

---

*v1：2026-08-13 | 小龙虾 🦞 · gem 单元轻量版页面序列*
