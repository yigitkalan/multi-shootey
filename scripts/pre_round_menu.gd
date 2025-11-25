class_name PreRoundMenu
extends Control

@onready var timer: Timer = $Timer
@onready var countdown_label: Label = $Background/HBoxContainer/VBoxContainer/Countdown
@export var countdown_time: float = 3.0


func _process(delta: float) -> void:
	countdown_label.text = str(int(timer.time_left))


func _ready() -> void:
	timer.timeout.connect(_on_countdown_ends)


@rpc("authority", "call_local", "reliable")
func initalize_countdown() -> void:
	timer.wait_time = countdown_time
	show()
	timer.start()


func _on_countdown_ends() -> void:
	GameManager.change_state(GameManager.GameState.IN_ROUND)
	hide()
