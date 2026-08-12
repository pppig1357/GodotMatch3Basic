# GodotMatch3 · 宝石迷阵三消（教学版）

> GitHub：**main 分支 = 教学版（本目录）**；`full` 分支 = M5 完整版（特殊宝石/多模式/存档），tag `v2.0`。

Infoco 编程社 × 独游社 联合社课成品。引擎：**Godot 4.7**（GDScript）。

## 玩法

- 点击选中宝石，再点相邻宝石交换；**或按住拖动交换**（28px 阈值，视觉跟随限一格）
- 再点已选中宝石 → 取消选中
- 横/竖连续 ≥3 同色消除，上方下落并顶部补新，可连锁
- 计分：每组 3 个 30 分，多 1 个 +10；连锁倍率 ×n
- 开局自动排除死局（无可行步则重排）
- **限步模式可选**：开始界面勾选「限步模式（20 步）」后，成功交换才扣步，步数用尽结算；默认无限步

## 运行

1. 用 Godot 4.7 打开本目录
2. 按 **F5** 运行

## 导出

编辑器：**项目 → 导出**

| 预设 | 说明 |
|------|------|
| Windows Desktop | 输出 `build/GodotMatch3.exe`（需已下载对应导出模板） |
| Web | `thread_support` 已关闭，便于静态托管 / itch.io |

首次导出前：编辑器 → 管理导出模板 → 安装与引擎版本一致的模板。

## 项目结构

```
scenes/main.tscn, hud.tscn, gem.tscn
scripts/main.gd, hud.gd, board.gd, board_resolve.gd, gem.gd
assets/sprites/gems/          # 宝石 sprite sheet（gem_bomb_rainbow.png）
assets/ui-kenney/             # Kenney UI（按钮图/字体/音效，按引用精简）
```

> **BGM**：House In a Forest Loop 音频数据内嵌于 `scenes/main.tscn`（OggPacketSequence），来自 Godot 官方示例项目 Dodge the Creeps 自带（原作者 Kenney，CC0）。外部 .ogg 未随仓库提供，详见 `assets/素材清单.md`。

UI / 音频对齐官方「您的第一个 2D 游戏」写法：`HUD` 独立场景用信号开局；`Music` / `Sfx*` 为 Main 下的 AudioStreamPlayer。

## Credits（素材来源）

| 素材 | 作者 | 来源 | 协议 |
|------|------|------|------|
| Rotating Gems for Match3 | Bondoki | [OpenGameArt](https://opengameart.org/content/rotating-gems-for-match3) | CC0 |
| UI Pack（按钮/字体/音效） | Kenney | [kenney.nl/assets/ui-pack](https://kenney.nl/assets/ui-pack) | CC0 |
| House In a Forest Loop（BGM） | Kenney | Godot 官方示例项目 Dodge the Creeps 自带（[Music Jingles](https://kenney.nl/assets/music-jingles) 同源） | CC0 |

详见 `assets/素材清单.md`。

---

Infoco × 独游社 | Godot 4.7 | 2026
