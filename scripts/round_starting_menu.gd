class_name RoundStartingMenu
extends MenuBase

@onready var timer: Timer = $Timer
@onready var countdown_label: Label = $Background/HBoxContainer/VBoxContainer/Countdown
@export var countdown_time: float = 3.0

signal start_round_requested


func _process(delta: float) -> void:
	# Convert float -> int -> String
	countdown_label.text = str(int(timer.time_left))


func _ready() -> void:
	timer.timeout.connect(_on_countdown_ends)


func initalize_countdown() -> void:
	timer.wait_time = countdown_time
	show()
	timer.start()


func _on_countdown_ends() -> void:
	start_round_requested.emit()
	hide()
