# Cursor Prompt · FULL 完整成品（社课三消 v1.0）

> 使用方法：把本文档全文复制给 Cursor，在 `D:\Godot Projects\godot-match3` 现有 M1 项目基础上，一次性完成**完整可玩成品**。
> 背景：这是社课教学项目的最终版本，后续会模仿官方教程拆解成 4 课时教学。代码必须保持教学友好。

---

你是资深 Godot 游戏开发工程师，正在完成社团社课教学项目「宝石迷阵三消」的**完整成品**。项目已有 M1 基础（8×8 网格 + gem.tscn 场景实例化 + 开局防自消），请在此基础上完成全部玩法、UI、音效、BGM、胜负与导出。

## 技术约束（必须遵守）

1. 引擎：Godot 4.7，语言 GDScript
2. **代码注释全中文**，关键逻辑附简短教学解释；函数命名自解释（find_matches / try_swap / fall_and_refill）
3. 代码简单直白，避免 lambda/装饰器/高级语法；不用 autoload
4. 单脚本 ≤150 行，超了拆文件（board.gd 拆出 board_resolve.gd）
5. **遵循官方命名规范**：节点/类 PascalCase、变量/函数 snake_case、常量 ALL_CAPS
6. 不引入外部插件；美术/音频用项目 assets/ 下已备好的素材（见下）
7. 每完成一个模块保证可运行，最后交付完整可玩版本

## 已备素材（CC0，直接用）

- **宝石贴图**：`assets/sprites/gems/gem_bomb_rainbow.png`（7 色 × 40 帧旋转动画 sheet，52×52/帧；含红/蓝/绿/黄/紫/橙+白）——用 AnimatedSprite2D 切帧，映射我们 6 色枚举
- **UI 包**：`assets/ui-kenney/PNG/Blue/Default/`（按钮 `button_rectangle_flat` 等；结算面板；图标；星标）
- **字体**：`assets/ui-kenney/Font/Kenney Future.ttf`（分数/步数显示，导出时嵌入）
- **音效**：`assets/ui-kenney/Sounds/`（click-a/b 点击、switch-a/b 交换、tap-a/b 消除/选中）
- **BGM**：`assets/audio/bgm/bgm_main.ogg`（默认，NES 8-bit 轻快循环；备选 bgm_alt_pizzi.ogg）
- 素材清单与使用指引：`assets/素材清单.md`

## 完整功能清单

### 1. 棋盘与宝石（继承 M1，需调整）
- 8×8 网格、`grid[col][row]` 二维数组、坐标换算
- 宝石从 ColorRect 占位升级为 **AnimatedSprite2D 贴图**（gem_bomb_rainbow.png 切帧，6 色对应 6 颗宝石；旋转动画播放）
- 开局防自消 `ensure_no_initial_matches()` 保留

### 2. 交互与三消（M2 完整实现）
- 鼠标输入：`_unhandled_input` + `get_global_mouse_position()` → `world_to_grid`
- InputMap `click` 动作（已配置）
- 状态：IDLE → SELECTED（选中高亮，如放大/描边）→ 点相邻宝石交换 / 点其他取消
- `try_swap(a, b)`：相邻校验、交换检测、无匹配动画回滚（不扣步）
- `find_matches()`：行列扫描 ≥3 同色，去重返回
- `clear_matches()`：消除动画（缩放+淡出）、计分（3个=30分，多1个+10）、`score_changed` 信号
- **仅成功交换（产生匹配）扣 1 步**

### 3. 下落连锁与状态机（M3 完整实现）
- `fall_and_refill()`：逐列从下往上压实 + 顶部补新宝石（Tween 下落动画）
- 连锁：`resolve_board()` async 管道（while find_matches → await 消除 → await 下落），**动画串行，禁止并发 Tween**
- 完整状态机：`enum State { IDLE, SELECTED, SWAPPING, RESOLVING, GAME_OVER }`，动画期间锁输入
- 连锁加分：连锁次数 n 倍率 ×n，`moves_changed` 信号

### 4. UI、音效、胜负、导出（M4 完整实现）
- **HUD（CanvasLayer + Control）**：
  - ScoreLabel / MovesLabel（Kenney Future 字体，锚点定位）
  - StartButton / RestartButton（Kenney 按钮贴图）
  - 结算 Panel（最终分数 + 重开按钮，初始隐藏）
- **信号解耦**：`score_changed` / `moves_changed` / `game_over(final_score)`，ui.gd 监听更新
- **音效**：AudioStreamPlayer 播放——消除用 tap、交换用 switch、按钮用 click
- **BGM**：AudioStreamPlayer autoplay 播放 bgm_main.ogg，音量 0.3~0.5，循环
- **胜负**：步数用尽即结束（当前 RESOLVING 结束后进 GAME_OVER，显示结算）
- **重开**：重建棋盘 + 重置分数/步数 + 回 IDLE
- **导出预设**：Windows Desktop (.exe) 配置好；Web (HTML5) 关 thread_support（备选）
- **README.md**：项目简介、玩法说明、运行/导出方法、CC0 素材 Credits（来源见 assets/素材清单.md）、MIT 协议

## 验收标准（全部满足才算完成）

- ✅ 运行后：8×8 宝石网格（贴图+旋转动画）、无初始三消
- ✅ 点击选中/交换/三消消除/下落/连锁/计分全流程正常
- ✅ 分数、剩余步数实时更新；连锁正确加倍
- ✅ 动画流畅、串行无错位；动画期间点击无效
- ✅ 消除/交换/按钮有音效；BGM 循环播放
- ✅ 步数耗尽 → 结算界面 → 重开新局
- ✅ 能导出 Windows exe 并运行
- ✅ README 完整（含 Credits）

## 输出

在现有项目上增量完成，最后列出：文件结构、功能清单、运行/导出方法、素材使用情况。
