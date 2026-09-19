# L4 PPT · 第 6、7 页重建文案（对齐 slide4「一步一步来」版式）

> **用途**：9/14 晚第 6、7 页开头丢失后的重建稿——按 pppig 在 slide4 的口吻（短句步骤 + 「注：」提示）书写，直接照着搓 PPT
> **内容来源**：《L4-HUD场景拼接-手把手.md》Step 4/5/6/7（按钮 / 挂载 / 壳验证）
> **前情**：slide4=背景和标题（Mask+TitlePanel+Message）、slide5=计分 Label（半成品）

---

## 第 6 页 · 一步一步来：按钮

**页面标题：** 一步一步来：按钮

**页面内容：**

```
创建 Button，命名为 StartButton
├─ 拖入黄色按钮贴图（theme_override_styles 三态）：
│    normal → 黄色渐变贴图 / hover、pressed → 黄色高光贴图
│    （素材在 assets/ui-kenney/PNG/Yellow/Default/）
├─ 输入文字"开始游戏"，调整字体大小和颜色
└─ 锚点预设：底部居中（Center Bottom）

注：按钮的三态 = 鼠标离开 / 悬停 / 按下，三种贴图就是"按下去"的手感

创建 Button，命名为 RestartButton
├─ 蓝色贴图（assets/ui-kenney/PNG/Blue/Default/）
├─ 文字"重新开始"、右上角（锚点预设 Top Right）
└─ Visible 取消勾选（初始隐藏）

注：隐藏 = 对局中才出现；标题态只露幕布、标题、开始按钮三样
```

---

## 第 7 页 · 挂进 Main + 壳验证

**页面标题：** 挂进 Main，F5 看看壳

**页面内容：**

```
打开 scenes/main.tscn → 选中 Main 根节点
→ 点"实例化子场景"（链环图标）→ 选 hud.tscn
→ 实例名默认 HUD

注：和 L1 的 gem.tscn 一模一样——独立图纸放进场景就是实例

F5 运行：
✅ 标题界面：幕布 + 亮黄底板 + 「宝石迷阵」+ 亮黄开始按钮
✅ 鼠标移到按钮上变亮（hover 高光）

注：点"开始游戏"暂不响应 = 正常！
    壳只有外表没有行为——行为（hud.gd 代码）下一步就装
```

---

*v1：2026-09-16 | 小龙虾 🦞 · 丢失页重建稿（源自拼接手册 Step 4-7，对齐 pppig 版式）*
