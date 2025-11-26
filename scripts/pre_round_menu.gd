class_name PreRoundMenu
extends MenuBase

@onready var timer: Timer = $Timer
@onready var start_button: Button = $Background/HBoxContainer/VBoxContainer/StartButton
@onready var countdown_label: Label = $Background/HBoxContainer/VBoxContainer/Countdown
@onready var starting_label: Label = $Background/HBoxContainer/VBoxContainer/RoundStarting
@onready var waiting_label: Label = $Background/HBoxContainer/VBoxContainer/Waiting

@export var countdown_time: float = 4.0


func _process(delta: float) -> void:
	countdown_label.text = str(int(timer.time_left))


func _ready() -> void:
	timer.timeout.connect(_on_countdown_ends)
	waiting_label.visible = not Lobby.is_host()
	if Lobby.is_host():
		start_button.visible = true
		start_button.pressed.connect(initalize_countdown.rpc)


@rpc("authority", "call_local", "reliable")
func initalize_countdown() -> void:
	countdown_label.visible = true
	starting_label.visible = true
	waiting_label.visible = false
	start_button.visible = false
	timer.wait_time = countdown_time
	timer.start()

func open():
	super ()
	starting_label.visible = false
	countdown_label.visible = false
	start_button.visible = Lobby.is_host()
	waiting_label.visible = not Lobby.is_host()

func _on_countdown_ends() -> void:
	if Lobby.is_host():
		SceneManager.change_scene_multiplayer(SceneManager.Scene.GAME)
	GameManager.change_state(Globals.GameState.IN_ROUND)
	close()
