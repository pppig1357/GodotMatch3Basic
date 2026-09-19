# L3-清理死代码：gem.gd 删除 animate_swap_to / animate_fall_to（2026-09-09）

> **背景**：教学版 gem.gd 的"动画三件套"里，`animate_swap_to` 和 `animate_fall_to` 是**零调用的死代码**（交换动画实际由 board.gd 的 `_animate_swap_pair` 播放，下落动画由 `fall_and_refill` 的 movers 统一 Tween 播放；完整版 M5 的 gem.gd 本来就没有这两个函数）。教学定案：删除，只保留 `animate_clear`，省下的课堂时间改讲 Tween 组件本身。

## 修改内容（只动 gem.gd 一个文件）

1. 删除 `animate_swap_to(target: Vector2)` 整个函数（含注释）
2. 删除 `animate_fall_to(target: Vector2, duration: float)` 整个函数（含注释）
3. `animate_clear()` 保留不动（board.gd 的 `clear_matches` 在调用它）
4. 文件头部的代码块划分注释「④ 动画三件套」改为「④ 动画（animate_clear）」

## 修改后 gem.gd 的 ④ 动画区应长这样

```gdscript
## 动画：消除（缩小到 0.2 倍 + 淡出到透明，0.2 秒，两个效果同时进行）
func animate_clear() -> void:
	var tween := create_tween()
	tween.set_parallel(true)    # 并行模式：缩小和淡出一起播
	tween.tween_property(self, "scale", Vector2(0.2, 0.2), 0.2)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)   # modulate:a = 透明度
	await tween.finished
```

## 验证

1. Godot 打开项目，检查脚本无报错（`animate_swap_to` / `animate_fall_to` 无引用残留）
2. 全局搜索两个函数名，确认没有其他地方调用（board.gd / main.gd / hud.gd 都不该有）
3. F5 运行：交换、消除、下落、连锁一切正常（消除动画还在——它走的是 animate_clear）
4. 输出面板无报错

## 注意

- 只删 gem.gd 里的两个函数，**不要动其他任何代码**
- `animate_clear` 的 `await tween.finished`（T3 模板）是课件重点，注释保留
- 不要重排函数顺序（setup / set_type / set_selected / animate_clear 保持原序）
