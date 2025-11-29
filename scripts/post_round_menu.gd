class_name PostRoundMenu
extends MenuBase


@onready var player_scores_container: VBoxContainer = $Background/MarginContainer/PlayerScores
@export var player_score_scene: PackedScene

func open():
	super ()
	if Lobby.is_host():
		update_scores.rpc(GameManager.player_scores)

@rpc("authority", "call_local", "reliable")
func update_scores(scores: Dictionary[int, int]):
	for child in player_scores_container.get_children():
		child.queue_free()
	for key in scores:
		var player_score: PlayerScore = player_score_scene.instantiate()
		if !player_score:
			push_error("Player score scene is null")
			return
		player_score.player_name = str(key)
		player_score.player_score = scores[key]
		player_scores_container.add_child(player_score)


func close():
	super ()
	for child in player_scores_container.get_children():
		child.queue_free()
