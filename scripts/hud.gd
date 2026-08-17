extends CanvasLayer
## ============================================================
## hud.gd —— 游戏「界面层」（HUD 脚本）
## ============================================================
## 角色定位：只管"显示"——标题界面、分数、按钮。不碰任何游戏规则。
## 它通过信号通知 Main（观察者模式）：点按钮只是"喊一声"，具体干什么由 Main 决定。
##
## 代码块划分（课件可拆块讲解）：
##   ① 信号 + 节点引用     —— HUD 对外喊什么 / 要操作哪些控件
##   ② prepare_playing     —— 标题界面 → 对局界面切换
##   ③ update_score        —— 刷新分数显示
##   ④ 按钮信号处理        —— 转发给 Main
## ============================================================

## 对外信号：玩家点了「开始游戏」
signal start_game
## 对外信号：玩家点了「重新开始」
signal restart

## @onready：进场景树后取子节点（hud.tscn 里预置的控件）
@onready var score_label: Label = $ScoreLabel
@onready var restart_button: Button = $RestartButton


## 进入对局：隐藏标题界面（遮罩/标题文字/开始按钮），显示分数与重开按钮
## 注意：不需要"回标题"函数——简化版点「重新开始」直接开新局
func prepare_playing() -> void:
	$Mask.hide()             # 隐藏半透明遮罩（标题画面的"幕布"）
	$Message.hide()          # 隐藏标题文字
	$StartButton.hide()      # 隐藏开始按钮
	restart_button.show()    # 显示重新开始按钮
	score_label.show()       # 显示分数


## 刷新分数显示：分数 Label 的文字
func update_score(score: int) -> void:
	score_label.text = "分数: %d" % score    # %d 是占位符，被 score 替换


## 开始按钮被点 → 发 start_game 信号（Main 收到后开新局）
func _on_start_button_pressed() -> void:
	start_game.emit()


## 重新开始按钮被点 → 发 restart 信号（Main 收到后开新局）
func _on_restart_button_pressed() -> void:
	restart.emit()
