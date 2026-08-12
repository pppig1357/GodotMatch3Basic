extends CanvasLayer
## HUD：半遮罩标题/结算 + 对局 HUD；通过信号通知 Main。
signal start_game(limited: bool)
signal back_to_title

@onready var score_label: Label = $ScoreLabel
@onready var moves_label: Label = $MovesLabel
@onready var message: Label = $Message
@onready var start_button: Button = $StartButton
@onready var restart_button: Button = $RestartButton
@onready var moves_check: CheckButton = $MovesLimitedCheck
@onready var mask: ColorRect = $Mask


func _ready() -> void:
	show_title()


func update_score(score: int) -> void:
	score_label.text = "分数: %d" % score


func update_moves(limited: bool, moves: int) -> void:
	if limited:
		moves_label.text = "步数: %d" % moves
	else:
		moves_label.text = "步数: ∞"


func show_title() -> void:
	mask.show()
	message.text = "宝石迷阵（三消）"
	message.show()
	start_button.text = "开始游戏"
	start_button.show()
	moves_check.show()
	restart_button.hide()
	score_label.hide()
	moves_label.hide()


func prepare_playing() -> void:
	mask.hide()
	message.hide()
	start_button.hide()
	moves_check.hide()
	restart_button.show()
	score_label.show()
	moves_label.show()


func show_game_over(final_score: int) -> void:
	mask.show()
	message.text = "游戏结束\n最终分数: %d" % final_score
	message.show()
	start_button.text = "再来一局"
	start_button.show()
	moves_check.show()
	restart_button.hide()
	score_label.hide()
	moves_label.hide()


func _on_start_button_pressed() -> void:
	start_game.emit(moves_check.button_pressed)


func _on_restart_button_pressed() -> void:
	show_title()
	back_to_title.emit()
