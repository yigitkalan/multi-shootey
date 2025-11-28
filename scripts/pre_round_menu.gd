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
	if Lobby.is_host():
		start_button.pressed.connect(initalize_countdown.rpc)
	
func close():
	super ()
	# Only disconnect if we're the host (signal was only connected on host)
	if Lobby.is_host() and start_button.pressed.is_connected(initalize_countdown.rpc):
		start_button.pressed.disconnect(initalize_countdown.rpc)

func _on_countdown_ends() -> void:
	if Lobby.is_host():
		GameManager.change_state(Globals.GameState.IN_ROUND)
	close()
