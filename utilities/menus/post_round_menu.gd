class_name PostRoundMenu
extends MenuBase


@onready var timer: Timer = $Timer
@onready var starting_label: Label = $Background/MarginContainer/VBoxContainer/StartingLabel
@onready var player_scores_container: VBoxContainer = $Background/MarginContainer/VBoxContainer/PlayerScores
const COUNTDOWN_FORMAT = "Next round is starting in %d seconds"

@export var player_score_scene: PackedScene
@export var countdown_time: float = 11.0

func _ready() -> void:
	timer.wait_time = countdown_time
	starting_label.text = COUNTDOWN_FORMAT % countdown_time
	timer.timeout.connect(_on_countdown_ended)

func _on_countdown_ended() -> void:
	if Lobby.is_host():
		GameManager.change_state_multiplayer(Globals.GameState.IN_ROUND)

func _process(delta: float) -> void:
	starting_label.text = COUNTDOWN_FORMAT % int(timer.time_left)

func open():
	super ()
	if Lobby.is_host():
		update_scores.rpc(GameManager.player_scores)
		start_timer.rpc()

@rpc("authority", "call_local", "reliable")
func start_timer() -> void:
	timer.start()

@rpc("authority", "call_local", "reliable")
func update_scores(scores: Dictionary[int, int]):
	for child in player_scores_container.get_children():
		child.queue_free()
	for key in scores:
		var player_score: PlayerScore = player_score_scene.instantiate()
		if !player_score:
			push_error("Player score scene is null")
			return
		player_score.player_name = Lobby.get_player_name(key)
		player_score.player_score = scores[key]
		player_scores_container.add_child(player_score)

func close():
	super ()
	for child in player_scores_container.get_children():
		child.queue_free()
