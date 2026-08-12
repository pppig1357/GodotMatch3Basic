# Cursor Prompt · M4 UI 与发布（第4课时交付）

> 使用方法：把本文档全文复制给 Cursor，在已有 M3 项目基础上继续开发。

---

你是资深 Godot 游戏开发工程师，完成教学项目「宝石迷阵三消」的最后阶段：在 M3（完整循环+状态机）基础上，加入**完整 HUD、音效、胜负结算、导出配置**，交付成品。

## 技术约束（必须遵守）

1. 引擎：Godot 4.7，语言 GDScript；沿用现有项目结构
2. 零外部资源：音效用 Godot 程序化生成（AudioStreamGenerator 生成简单音效，或用内置方式合成短音），不下载外部素材
3. 代码注释**全中文**；简单直白；不用 autoload；单文件 ≤150 行
4. 不破坏 M1~M3 已有功能

## 本阶段目标（M4）

1. **完整 HUD**（UI CanvasLayer → Control）：
   - ScoreLabel（分数）、MovesLabel（剩余步数）
   - StartButton（开始游戏）、RestartButton（重新开始）
   - 游戏结束结算界面（显示最终分数 + 重新开始按钮，可用 Panel + Label + Button 组合，初始隐藏）
2. **信号解耦**：
   - board 发出 `score_changed(score)` / `moves_changed(moves)` / `game_over(final_score)`
   - ui.gd 用信号连接更新显示（教学点：UI 与逻辑解耦）
   - 按钮 `pressed` 信号连接开始/重开逻辑（重开 = 重建棋盘 + 重置分数/步数 + 回 IDLE）
3. **音效（改：启动时预生成短音，不用实时发生器）**：
   - 官方提示 AudioStreamGenerator 在 GDScript 里实时推帧性能差、易爆音
   - 正确做法：`_ready()` 时一次性生成短 WAV/PCM 缓冲（如 0.1s 方波/正弦短音），存入 AudioStreamWAV
   - 消除时 `AudioStreamPlayer.play()` 播放该流；仍满足「零外部素材」
4. **胜负判定（统一约定）**：步数用尽即结束——剩余步数为 0 时，当前 RESOLVING 结束后进入 GAME_OVER → 显示结算界面（带最终分数 `game_over(final_score)` 信号）
5. **导出配置**：
   - 配置导出预设：Windows Desktop（.exe）
   - 说明导出步骤（Project → Export → 添加预设 → 导出）
   - 可选：Web (HTML5) 预设——**关闭 thread_support**（线程版需 COOP/COEP 头，静态托管跑不了），关线程后 itch.io 等静态托管即可跑
6. **README**：在项目根目录写 `README.md`（项目简介、玩法说明、运行/导出方法、开源协议建议 MIT）

## 验收标准

- 完整可玩：开始 → 玩 → 步数耗尽 → 结算 → 重开
- 分数/步数实时更新，连锁正确加倍
- 消除有音效，动画流畅
- 能导出 Windows exe 并正常运行

## 输出

在现有项目上增量修改，列出：新增/修改的文件、功能清单、导出步骤、运行方法。
